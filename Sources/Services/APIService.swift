import Foundation
import Network
import Security

// MARK: - Sash R14: Local REST API & Web Dashboard

/// Built-in HTTP server for Sash REST API (port 8771)
final class SashAPIService: ObservableObject {
    static let shared = SashAPIService()

    struct APIResponse {
        let statusCode: Int
        let body: String
    }

    private struct ParsedRequest {
        let method: String
        let path: String
        let headers: [String: String]
        let body: String

        init?(rawValue: String) {
            let parts = rawValue.components(separatedBy: "\r\n\r\n")
            let headerBlock = parts.first ?? rawValue
            body = parts.count > 1 ? parts.dropFirst().joined(separator: "\r\n\r\n") : ""

            let lines = headerBlock.components(separatedBy: "\r\n")
            guard let requestLine = lines.first else { return nil }
            let requestParts = requestLine.split(separator: " ")
            guard requestParts.count >= 2 else { return nil }

            method = String(requestParts[0])
            path = String(requestParts[1]).components(separatedBy: "?").first ?? String(requestParts[1])

            var parsedHeaders: [String: String] = [:]
            for line in lines.dropFirst() {
                let segments = line.split(separator: ":", maxSplits: 1)
                guard segments.count == 2 else { continue }
                parsedHeaders[String(segments[0]).lowercased()] = String(segments[1]).trimmingCharacters(in: .whitespaces)
            }
            headers = parsedHeaders
        }

        func header(named name: String) -> String? {
            headers[name.lowercased()]
        }
    }

    private var listener: NWListener?
    private let port: UInt16 = 8771
    private let keychainService = "com.sash.local-api"
    private let keychainAccount = "default-api-key"
    private let isoFormatter = ISO8601DateFormatter()
    private var rateLimitWindowStart = Date()
    private var requestsInWindow = 0
    @Published var isRunning = false
    @Published var requestCount = 0

    private lazy var apiKey: String = loadOrCreateAPIKey()

    private init() {
        _ = apiKey
    }

    func start() {
        guard listener == nil else { return }
        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async { self?.isRunning = state == .ready }
            }
            listener?.newConnectionHandler = { [weak self] conn in
                self?.handleConnection(conn)
            }
            listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("SashAPI failed to start: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        DispatchQueue.main.async { self.isRunning = false }
    }

    private func handleConnection(_ conn: NWConnection) {
        conn.start(queue: .global(qos: .userInitiated))
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            guard let data = data, let request = String(data: data, encoding: .utf8) else {
                conn.cancel()
                return
            }
            let response = self?.processRequest(request) ?? Self.notFound()
            let httpResponse = """
            HTTP/1.1 \(response.statusCode)\r\nContent-Type: application/json\r\nContent-Length: \(response.body.count)\r\n\r\n\(response.body)
            """
            conn.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
            DispatchQueue.main.async { self?.requestCount += 1 }
        }
    }

    private func processRequest(_ request: String) -> APIResponse {
        guard checkRateLimit() else {
            return APIResponse(statusCode: 429, body: #"{"error":"Rate limit exceeded"}"#)
        }
        guard let parsed = ParsedRequest(rawValue: request) else { return Self.notFound() }
        guard parsed.header(named: "X-API-Key") == apiKey else {
            return APIResponse(statusCode: 401, body: #"{"error":"Unauthorized"}"#)
        }

        switch (parsed.method, parsed.path) {
        case ("GET", "/folders"):
            return APIResponse(statusCode: 200, body: jsonFolders())
        case ("GET", "/conflicts"):
            return APIResponse(statusCode: 200, body: jsonConflicts())
        case ("GET", "/activity"):
            return APIResponse(statusCode: 200, body: jsonActivity())
        case ("GET", "/stats"):
            return APIResponse(statusCode: 200, body: jsonStats())
        case ("GET", "/openapi.json"):
            return APIResponse(statusCode: 200, body: openAPISpec())
        case ("POST", "/folders"):
            return createFolder(from: parsed.body)
        default:
            break
        }

        if parsed.method == "GET", let folderId = folderStatusID(for: parsed.path) {
            return APIResponse(statusCode: 200, body: jsonFolderStatus(id: folderId))
        }
        if parsed.method == "DELETE", let folderId = folderID(forDeletionPath: parsed.path) {
            return deleteFolder(id: folderId)
        }
        if parsed.method == "POST", let conflictId = conflictID(forResolutionPath: parsed.path) {
            return resolveConflict(id: conflictId)
        }

        return Self.notFound()
    }

    private func jsonFolders() -> String {
        let folders = CollaborationService.shared.teamFolders
        let data = folders.map { folder -> String in
            let guestCount = CollaborationService.shared.guestAccesses.filter { $0.folderId == folder.id }.count
            return #"{"id":"\#(folder.id)","name":"\#(escape(folder.name))","members":\#(folder.members.count),"guests":\#(guestCount)}"#
        }
        return "[\(data.joined(separator: ","))]"
    }

    private func jsonFolderStatus(id: UUID) -> String {
        guard let folder = CollaborationService.shared.teamFolders.first(where: { $0.id == id }) else {
            return #"{"error":"Folder not found"}"#
        }
        let activeLockCount = activeLocks().filter { $0.path.contains(folder.name) }.count
        let guestCount = CollaborationService.shared.guestAccesses.filter { $0.folderId == folder.id }.count
        return #"{"id":"\#(folder.id)","status":"synced","members":\#(folder.members.count),"guests":\#(guestCount),"activeLocks":\#(activeLockCount)}"#
    }

    private func jsonConflicts() -> String {
        let rows = activeLocks().map {
            #"{"id":"\#($0.id)","path":"\#(escape($0.path))","lockedBy":"\#(escape($0.lockedBy))","lockedAt":"\#(isoFormatter.string(from: $0.lockedAt))"}"#
        }
        return "[\(rows.joined(separator: ","))]"
    }

    private func jsonActivity() -> String {
        let items = CollaborationService.shared.activityFeed.prefix(20)
        let rows = items.map {
            #"{"type":"\#($0.type.rawValue)","user":"\#(escape($0.user))","detail":"\#(escape($0.detail))","timestamp":"\#(isoFormatter.string(from: $0.timestamp))"}"#
        }
        return "[\(rows.joined(separator: ","))]"
    }

    private func jsonStats() -> String {
        #"{"totalFolders":\#(CollaborationService.shared.teamFolders.count),"activeLocks":\#(activeLocks().count),"auditEntries":\#(EnterpriseService.shared.auditLog.count),"devices":\#(EnterpriseService.shared.enrolledDevices.count),"requestsThisMinute":\#(requestsInWindow)}"#
    }

    private func openAPISpec() -> String {
        #"{"openapi":"3.0.0","info":{"title":"Sash API","version":"1.0"},"paths":{"/folders":{"get":{"summary":"List synced folders"},"post":{"summary":"Add folder to sync"}},"/folders/{id}/status":{"get":{"summary":"Folder sync status"}},"/conflicts":{"get":{"summary":"List active conflicts"}},"/conflicts/{id}/resolve":{"post":{"summary":"Resolve a conflict"}},"/activity":{"get":{"summary":"Recent activity"}},"/stats":{"get":{"summary":"Sync statistics"}}}}"#
    }

    private func createFolder(from body: String) -> APIResponse {
        let payload = jsonObject(from: body)
        let folderName = ((payload?["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "Team Folder"
        let adminName = ((payload?["adminName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "API Admin"
        let adminEmail = ((payload?["adminEmail"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? "admin@sash.local"

        let admin = TeamMember(id: UUID(), name: adminName, email: adminEmail, role: .admin)
        let folder = CollaborationService.shared.createTeamFolder(name: folderName, admin: admin)
        CollaborationService.shared.logActivity(type: .fileShared, folderId: folder.id, user: admin.email, detail: "Created shared folder \(folder.name)")
        EnterpriseService.shared.logAudit(action: .fileShared, detail: "Folder created via API: \(folder.name)", user: admin.email)
        return APIResponse(statusCode: 201, body: #"{"id":"\#(folder.id)","name":"\#(escape(folder.name))"}"#)
    }

    private func deleteFolder(id: UUID) -> APIResponse {
        guard let folder = CollaborationService.shared.teamFolders.first(where: { $0.id == id }) else {
            return APIResponse(statusCode: 404, body: #"{"error":"Folder not found"}"#)
        }
        CollaborationService.shared.teamFolders.removeAll { $0.id == id }
        CollaborationService.shared.activityFeed.removeAll { $0.folderId == id }
        CollaborationService.shared.guestAccesses.removeAll { $0.folderId == id }
        CollaborationService.shared.saveState()
        EnterpriseService.shared.logAudit(action: .fileChanged, detail: "Folder removed via API: \(folder.name)")
        return APIResponse(statusCode: 200, body: #"{"deleted":true,"id":"\#(id)"}"#)
    }

    private func resolveConflict(id: UUID) -> APIResponse {
        guard let lock = activeLocks().first(where: { $0.id == id }) else {
            return APIResponse(statusCode: 404, body: #"{"error":"Conflict not found"}"#)
        }
        CollaborationService.shared.unlockFile(path: lock.path)
        EnterpriseService.shared.logAudit(action: .fileChanged, detail: "Resolved conflict for \(lock.path)")
        return APIResponse(statusCode: 200, body: #"{"resolved":true,"id":"\#(id)"}"#)
    }

    private func activeLocks() -> [FileLock] {
        CollaborationService.shared.fileLocks.filter { !$0.isExpired }
    }

    private func folderStatusID(for path: String) -> UUID? {
        let parts = path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).split(separator: "/")
        guard parts.count == 3, parts[0] == "folders", parts[2] == "status" else { return nil }
        return UUID(uuidString: String(parts[1]))
    }

    private func folderID(forDeletionPath path: String) -> UUID? {
        let parts = path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).split(separator: "/")
        guard parts.count == 2, parts[0] == "folders" else { return nil }
        return UUID(uuidString: String(parts[1]))
    }

    private func conflictID(forResolutionPath path: String) -> UUID? {
        let parts = path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).split(separator: "/")
        guard parts.count == 3, parts[0] == "conflicts", parts[2] == "resolve" else { return nil }
        return UUID(uuidString: String(parts[1]))
    }

    private func jsonObject(from body: String) -> [String: Any]? {
        guard let data = body.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object
    }

    private func checkRateLimit() -> Bool {
        let now = Date()
        if now.timeIntervalSince(rateLimitWindowStart) >= 60 {
            rateLimitWindowStart = now
            requestsInWindow = 0
        }
        guard requestsInWindow < 100 else { return false }
        requestsInWindow += 1
        return true
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private func loadOrCreateAPIKey() -> String {
        if let existing = keychainValue(for: keychainAccount) {
            return existing
        }
        let generated = UUID().uuidString.replacingOccurrences(of: "-", with: "") + UUID().uuidString.replacingOccurrences(of: "-", with: "")
        setKeychainValue(generated, for: keychainAccount)
        return generated
    }

    private func keychainValue(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func setKeychainValue(_ value: String, for account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    private static func notFound() -> APIResponse {
        APIResponse(statusCode: 404, body: #"{"error":"Not found"}"#)
    }
}
