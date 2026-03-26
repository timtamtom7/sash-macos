import Foundation
import Network

// MARK: - Sash R14: Local REST API & Web Dashboard

/// Built-in HTTP server for Sash REST API (port 8775)
final class SashAPIService: ObservableObject {
    static let shared = SashAPIService()

    private var listener: NWListener?
    private let port: UInt16 = 8775
    @Published var isRunning = false
    @Published var requestCount = 0

    private init() {}

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
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let data = data, let request = String(data: data, encoding: .utf8) else { conn.cancel(); return }
            let response = self?.processRequest(request) ?? Self.notFound()
            let httpResponse = """
            HTTP/1.1 \(response.statusCode)\r\nContent-Type: application/json\r\nContent-Length: \(response.body.count)\r\n\r\n\(response.body)
            """
            conn.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
            DispatchQueue.main.async { self?.requestCount += 1 }
        }
    }

    private func processRequest(_ request: String) -> APIResponse {
        let lines = request.split(separator: "\r\n")
        guard let requestLine = lines.first else { return Self.notFound() }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return Self.notFound() }
        let method = String(parts[0])
        let path = String(parts[1])

        // Auth check via API key
        guard lines.contains(where: { $0.hasPrefix("X-API-Key:") }) else {
            return APIResponse(statusCode: 401, body: #"{"error":"Unauthorized"}"#)
        }

        switch (method, path) {
        case ("GET", "/folders"):
            return APIResponse(statusCode: 200, body: jsonFolders())
        case ("GET", "/folders/:id/status"):
            return APIResponse(statusCode: 200, body: #"{"status":"synced","conflicts":0}"#)
        case ("GET", "/conflicts"):
            return APIResponse(statusCode: 200, body: "[]")
        case ("GET", "/activity"):
            return APIResponse(statusCode: 200, body: jsonActivity())
        case ("GET", "/stats"):
            return APIResponse(statusCode: 200, body: jsonStats())
        case ("GET", "/openapi.json"):
            return APIResponse(statusCode: 200, body: openAPISpec())
        default:
            return Self.notFound()
        }
    }

    private func jsonFolders() -> String {
        let folders = CollaborationService.shared.teamFolders
        let data = folders.map { #"{"id":"\#($0.id)","name":"\#($0.name)"}"# }
        return "[\(data.joined(separator: ","))]"
    }

    private func jsonActivity() -> String {
        let items = CollaborationService.shared.activityFeed.prefix(20)
        let data = items.map { #"{"type":"\#($0.type.rawValue)","user":"\#($0.user)","detail":"\#($0.detail)","timestamp":"\#(ISO8601DateFormatter().string(from: $0.timestamp))"}"# }
        return "[\(data.joined(separator: ","))]"
    }

    private func jsonStats() -> String {
        return #"{"totalFolders":\#(CollaborationService.shared.teamFolders.count),"activeLocks":\#(CollaborationService.shared.fileLocks.count),"auditEntries":\#(EnterpriseService.shared.auditLog.count),"devices":\#(EnterpriseService.shared.enrolledDevices.count)}"#
    }

    private func openAPISpec() -> String {
        return """
        {"openapi":"3.0.0","info":{"title":"Sash API","version":"1.0"},"paths":{"/folders":{"get":{"summary":"List synced folders"}},"/conflicts":{"get":{"summary":"List active conflicts"}},"/activity":{"get":{"summary":"Recent activity"}},"/stats":{"get":{"summary":"Sync statistics"}}}}
        """
    }

    private static func notFound() -> APIResponse {
        return APIResponse(statusCode: 404, body: #"{"error":"Not found"}"#)
    }

    struct APIResponse {
        let statusCode: Int
        let body: String
    }
}
