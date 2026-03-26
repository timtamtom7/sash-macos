import Foundation

// MARK: - Sash R13: Enterprise & IT Features

/// Service for MDM, DLP, Audit Logging, SSO, and Compliance
final class EnterpriseService: ObservableObject {
    static let shared = EnterpriseService()

    @Published var auditLog: [AuditEntry] = []
    @Published var dlpRules: [DLPRule] = []
    @Published var retentionPolicies: [RetentionPolicy] = []
    @Published var enrolledDevices: [ManagedDevice] = []

    private init() {
        loadState()
    }

    // MARK: - MDM / Managed Device Support

    func enrollDevice(id: String, name: String, managed: Bool) -> ManagedDevice {
        let device = ManagedDevice(id: id, name: name, isManaged: managed, enrolledAt: Date(), compliance: .compliant)
        enrolledDevices.append(device)
        logAudit(action: .deviceEnrolled, detail: "Device \(name) enrolled")
        saveState()
        return device
    }

    func checkCompliance(deviceId: String) -> DeviceCompliance {
        guard let device = enrolledDevices.first(where: { $0.id == deviceId }) else { return .notEnrolled }
        return device.compliance
    }

    // MARK: - DLP

    func addDLPRule(name: String, type: DLPRuleType, action: DLPAction) -> DLPRule {
        let rule = DLPRule(id: UUID(), name: name, ruleType: type, action: action, isEnabled: true)
        dlpRules.append(rule)
        logAudit(action: .dlpRuleAdded, detail: "DLP rule '\(name)' added")
        saveState()
        return rule
    }

    func evaluateDLP(path: String) -> DLPEvaluation {
        for rule in dlpRules where rule.isEnabled {
            if rule.ruleType.matches(path: path) {
                return DLPEvaluation(allowed: rule.action == .allow, rule: rule, path: path)
            }
        }
        return DLPEvaluation(allowed: true, rule: nil, path: path)
    }

    // MARK: - Retention Policies

    func addRetentionPolicy(name: String, duration: RetentionDuration, documentType: String?) -> RetentionPolicy {
        let policy = RetentionPolicy(id: UUID(), name: name, duration: duration, documentType: documentType)
        retentionPolicies.append(policy)
        logAudit(action: .retentionPolicySet, detail: "Retention policy '\(name)' created")
        saveState()
        return policy
    }

    // MARK: - Audit Log

    func logAudit(action: AuditAction, detail: String, user: String = "system") {
        let entry = AuditEntry(id: UUID(), action: action, user: user, detail: detail, timestamp: Date())
        auditLog.insert(entry, at: 0)
        if auditLog.count > 10000 { auditLog = Array(auditLog.prefix(10000)) }
        saveState()
    }

    func exportAuditLog(format: ExportFormat) -> Data? {
        let encoder: JSONEncoder
        switch format {
        case .json:
            encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
        case .csv:
            encoder = JSONEncoder() // fallback
        }
        return try? encoder.encode(auditLog)
    }

    // MARK: - SSO

    func configureSSO(provider: SSOProvider) {
        logAudit(action: .ssoConfigured, detail: "SSO configured for \(provider.rawValue)")
        saveState()
    }

    // MARK: - Persistence

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sash/enterprise.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = EnterpriseState(auditLog: auditLog, dlpRules: dlpRules, retentionPolicies: retentionPolicies, enrolledDevices: enrolledDevices)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(EnterpriseState.self, from: data) else { return }
        auditLog = state.auditLog
        dlpRules = state.dlpRules
        retentionPolicies = state.retentionPolicies
        enrolledDevices = state.enrolledDevices
    }
}

// MARK: - Models

struct ManagedDevice: Identifiable, Codable {
    let id: String
    var name: String
    var isManaged: Bool
    var enrolledAt: Date
    var compliance: DeviceCompliance
}

enum DeviceCompliance: String, Codable {
    case compliant, nonCompliant, notEnrolled
}

struct DLPRule: Identifiable, Codable {
    let id: UUID
    var name: String
    var ruleType: DLPRuleType
    var action: DLPAction
    var isEnabled: Bool
}

enum DLPRuleType: Codable {
    case noExportFolder(path: String)
    case blockedFileType(extension: String)
    case watermark

    func matches(path: String) -> Bool {
        switch self {
        case .noExportFolder(let p): return path.hasPrefix(p)
        case .blockedFileType(let ext): return path.hasSuffix(".\(ext)")
        case .watermark: return true
        }
    }

    private enum Keys: String, CodingKey { case type, path, ext }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "noExportFolder": self = .noExportFolder(path: try container.decode(String.self, forKey: .path))
        case "blockedFileType": self = .blockedFileType(extension: try container.decode(String.self, forKey: .ext))
        default: self = .watermark
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        switch self {
        case .noExportFolder(let p): try container.encode("noExportFolder", forKey: .type); try container.encode(p, forKey: .path)
        case .blockedFileType(let e): try container.encode("blockedFileType", forKey: .type); try container.encode(e, forKey: .ext)
        case .watermark: try container.encode("watermark", forKey: .type)
        }
    }
}

enum DLPAction: String, Codable {
    case allow, block, warn
}

struct DLPEvaluation {
    let allowed: Bool
    let rule: DLPRule?
    let path: String
}

struct RetentionPolicy: Identifiable, Codable {
    let id: UUID
    var name: String
    var duration: RetentionDuration
    var documentType: String?
}

enum RetentionDuration: String, Codable {
    case days30 = "30 days"
    case days90 = "90 days"
    case oneYear = "1 year"
    case indefinite
}

struct AuditEntry: Identifiable, Codable {
    let id: UUID
    let action: AuditAction
    let user: String
    let detail: String
    let timestamp: Date
}

enum AuditAction: String, Codable {
    case fileAccessed, fileChanged, fileShared, deviceEnrolled, dlpRuleAdded, retentionPolicySet, ssoConfigured
}

enum ExportFormat {
    case json, csv
}

enum SSOProvider: String, Codable {
    case okta, azureAD, googleWorkspace
}

struct EnterpriseState: Codable {
    var auditLog: [AuditEntry]
    var dlpRules: [DLPRule]
    var retentionPolicies: [RetentionPolicy]
    var enrolledDevices: [ManagedDevice]
}
