import Foundation

// MARK: - Sash R15: iOS Companion App Service

/// Stub service representing iOS companion app features.
/// The actual iOS app is built separately (sash-ios).
final class iOSCompanionService: ObservableObject {
    static let shared = iOSCompanionService()

    @Published var syncStatus: iOSSyncStatus = .synced
    @Published var pendingConflicts: Int = 0
    @Published var recentActivity: [iOSActivityItem] = []

    enum iOSSyncStatus: String {
        case synced, syncing, offline, conflicts
    }

    struct iOSActivityItem: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let timestamp: Date
    }

    private init() {}

    // MARK: - iOS Widget Data

    func widgetData() -> [String: Any] {
        return [
            "status": syncStatus.rawValue,
            "conflicts": pendingConflicts,
            "lastSync": ISO8601DateFormatter().string(from: Date())
        ]
    }

    // MARK: - Siri & Shortcuts

    func shortcutsStatus() -> String {
        return "Sash sync status: \(syncStatus.rawValue). \(pendingConflicts) conflicts."
    }

    func handleShortcut(named name: String) -> Bool {
        switch name {
        case "CheckSyncStatus": syncStatus = .synced; return true
        case "ResolveConflicts": pendingConflicts = 0; return true
        default: return false
        }
    }
}
