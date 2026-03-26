import Foundation

// MARK: - Sash Models R12-R15

struct SashProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var appRules: [AppRule]
    var isActive: Bool
    var createdAt: Date
    var syncEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        appRules: [AppRule] = [],
        isActive: Bool = false,
        createdAt: Date = Date(),
        syncEnabled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.appRules = appRules
        self.isActive = isActive
        self.createdAt = createdAt
        self.syncEnabled = syncEnabled
    }
}

struct AppRule: Identifiable, Codable {
    let id: UUID
    var appBundleId: String
    var appName: String
    var windowState: WindowState
    var visibility: Visibility
    var triggers: [Trigger]

    init(
        id: UUID = UUID(),
        appBundleId: String,
        appName: String,
        windowState: WindowState = .normal,
        visibility: Visibility = .visible,
        triggers: [Trigger] = []
    ) {
        self.id = id
        self.appBundleId = appBundleId
        self.appName = appName
        self.windowState = windowState
        self.visibility = visibility
        self.triggers = triggers
    }
}

struct WindowState: Codable {
    var frame: CGRect
    var isMaximized: Bool
    var isMinimized: Bool

    init(frame: CGRect = .zero, isMaximized: Bool = false, isMinimized: Bool = false) {
        self.frame = frame
        self.isMaximized = isMaximized
        self.isMinimized = isMinimized
    }
}

enum Visibility: String, Codable {
    case visible
    case hidden
    case minimized
}

struct Trigger: Identifiable, Codable {
    let id: UUID
    var type: TriggerType
    var conditions: [Condition]

    init(id: UUID = UUID(), type: TriggerType, conditions: [Condition] = []) {
        self.id = id
        self.type = type
        self.conditions = conditions
    }
}

enum TriggerType: String, Codable {
    case time = "Time-based"
    case location = "Location-based"
    case network = "Network"
    case power = "Power State"
}

struct Condition: Codable {
    var key: String
    var value: String
    var comparison: Comparison

    enum Comparison: String, Codable {
        case equals
        case notEquals
        case contains
        case greaterThan
        case lessThan
    }
}

struct SyncSettings: Codable {
    var iCloudEnabled: Bool
    var localNetworkEnabled: Bool
    var peerDevices: [PeerDevice]
    var lastSyncDate: Date?

    init(
        iCloudEnabled: Bool = false,
        localNetworkEnabled: Bool = false,
        peerDevices: [PeerDevice] = [],
        lastSyncDate: Date? = nil
    ) {
        self.iCloudEnabled = iCloudEnabled
        self.localNetworkEnabled = localNetworkEnabled
        self.peerDevices = peerDevices
        self.lastSyncDate = lastSyncDate
    }
}

struct PeerDevice: Identifiable, Codable {
    let id: UUID
    var name: String
    var deviceType: String
    var isOnline: Bool
    var lastSeen: Date
}

struct UsageAnalytics: Codable {
    var totalActivations: Int
    var mostUsedProfile: UUID?
    var averageSessionDuration: TimeInterval
    var topApps: [String: Int]
    var weeklyUsage: [DayUsage]
}

struct DayUsage: Identifiable, Codable {
    let id: UUID
    var date: Date
    var activationCount: Int
    var appSwitches: Int

    init(id: UUID = UUID(), date: Date = Date(), activationCount: Int = 0, appSwitches: Int = 0) {
        self.id = id
        self.date = date
        self.activationCount = activationCount
        self.appSwitches = appSwitches
    }
}
