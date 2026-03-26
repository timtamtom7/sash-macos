import AppIntents
import Foundation

// MARK: - App Shortcuts Provider (R17 - Extended)

struct SashShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Window snapping shortcuts (existing)
        AppShortcut(
            intent: SnapWindowLeftIntent(),
            phrases: [
                "Snap window left in \(.applicationName)",
                "Left snap with \(.applicationName)"
            ],
            shortTitle: "Snap Left",
            systemImageName: "rectangle.lefthalf.filled"
        )

        AppShortcut(
            intent: SnapWindowRightIntent(),
            phrases: [
                "Snap window right in \(.applicationName)",
                "Right snap with \(.applicationName)"
            ],
            shortTitle: "Snap Right",
            systemImageName: "rectangle.righthalf.filled"
        )

        AppShortcut(
            intent: SnapWindowTopIntent(),
            phrases: [
                "Snap window top in \(.applicationName)",
                "Maximize with \(.applicationName)"
            ],
            shortTitle: "Snap Top",
            systemImageName: "rectangle.tophalf.filled"
        )

        // R17 Sync shortcuts
        AppShortcut(
            intent: GetSyncStatusIntent(),
            phrases: [
                "Get sync status in \(.applicationName)",
                "Check \(.applicationName) sync"
            ],
            shortTitle: "Get Sync Status",
            systemImageName: "arrow.triangle.2.circlepath"
        )

        AppShortcut(
            intent: SyncFolderIntent(),
            phrases: [
                "Sync folder in \(.applicationName)",
                "Sync with \(.applicationName)"
            ],
            shortTitle: "Sync Folder",
            systemImageName: "arrow.clockwise"
        )

        AppShortcut(
            intent: GetRecentChangesIntent(),
            phrases: [
                "Get recent changes in \(.applicationName)",
                "What changed in \(.applicationName)"
            ],
            shortTitle: "Recent Changes",
            systemImageName: "clock"
        )

        AppShortcut(
            intent: GetConflictListIntent(),
            phrases: [
                "Get conflict list in \(.applicationName)",
                "Show \(.applicationName) conflicts"
            ],
            shortTitle: "Conflict List",
            systemImageName: "exclamationmark.triangle"
        )

        AppShortcut(
            intent: ResolveConflictIntent(),
            phrases: [
                "Resolve conflict in \(.applicationName)",
                "Fix sync conflict with \(.applicationName)"
            ],
            shortTitle: "Resolve Conflict",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: AddFolderIntent(),
            phrases: [
                "Add folder to \(.applicationName)",
                "Sync folder with \(.applicationName)"
            ],
            shortTitle: "Add Folder",
            systemImageName: "folder.badge.plus"
        )
    }
}

// MARK: - Snap Window Left Intent

struct SnapWindowLeftIntent: AppIntent {
    static var title: LocalizedStringResource = "Snap Window Left"
    static var description = IntentDescription("Snaps the focused window to the left half of the screen")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = await MainActor.run {
            WindowManager.shared.snapFocusedWindow(to: .leftHalf)
        }

        switch result {
        case .success:
            return .result(dialog: "Window snapped to left")
        case .noFocusedWindow:
            return .result(dialog: "No focused window to snap")
        case .cannotResize:
            return .result(dialog: "Cannot resize window")
        case .accessibilityNotGranted:
            return .result(dialog: "Accessibility permission required")
        }
    }
}

// MARK: - Snap Window Right Intent

struct SnapWindowRightIntent: AppIntent {
    static var title: LocalizedStringResource = "Snap Window Right"
    static var description = IntentDescription("Snaps the focused window to the right half of the screen")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = await MainActor.run {
            WindowManager.shared.snapFocusedWindow(to: .rightHalf)
        }

        switch result {
        case .success:
            return .result(dialog: "Window snapped to right")
        case .noFocusedWindow:
            return .result(dialog: "No focused window to snap")
        case .cannotResize:
            return .result(dialog: "Cannot resize window")
        case .accessibilityNotGranted:
            return .result(dialog: "Accessibility permission required")
        }
    }
}

// MARK: - Snap Window Top Intent

struct SnapWindowTopIntent: AppIntent {
    static var title: LocalizedStringResource = "Snap Window Top"
    static var description = IntentDescription("Snaps the focused window to the top half (maximize)")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = await MainActor.run {
            WindowManager.shared.snapFocusedWindow(to: .topHalf)
        }

        switch result {
        case .success:
            return .result(dialog: "Window maximized")
        case .noFocusedWindow:
            return .result(dialog: "No focused window to snap")
        case .cannotResize:
            return .result(dialog: "Cannot resize window")
        case .accessibilityNotGranted:
            return .result(dialog: "Accessibility permission required")
        }
    }
}

// MARK: - R17 Sync Shortcuts

struct GetSyncStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sync Status"
    static var description = IntentDescription("Returns the current sync status for all folders")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let status = await SyncServiceR17.shared.getStatusSummary()
        return .result(value: status, dialog: "Sync status: \(status)")
    }
}

struct SyncFolderIntent: AppIntent {
    static var title: LocalizedStringResource = "Sync Folder"
    static var description = IntentDescription("Triggers sync for a named folder")

    @Parameter(title: "Folder Name")
    var folderName: String?

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let name = folderName ?? "all"
        await SyncServiceR17.shared.syncFolder(named: name)
        return .result(dialog: "Syncing \(name)")
    }
}

struct GetRecentChangesIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Recent Changes"
    static var description = IntentDescription("Lists recent changes across all synced folders")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<[String]> & ProvidesDialog {
        let changes = await SyncServiceR17.shared.getRecentChanges(limit: 5)
        let changeDescriptions = changes.map { "\($0.action) - \($0.fileName)" }
        let summary = changeDescriptions.joined(separator: ", ")
        return .result(
            value: changeDescriptions,
            dialog: changeDescriptions.isEmpty ? "No recent changes" : "Recent: \(summary)"
        )
    }
}

struct GetConflictListIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Conflict List"
    static var description = IntentDescription("Lists active sync conflicts")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<[String]> & ProvidesDialog {
        let conflicts = await SyncServiceR17.shared.getActiveConflicts()
        let conflictDescriptions = conflicts.map { $0.fileName }
        return .result(
            value: conflictDescriptions,
            dialog: conflicts.isEmpty ? "No conflicts" : "\(conflicts.count) conflict(s)"
        )
    }
}

struct ResolveConflictIntent: AppIntent {
    static var title: LocalizedStringResource = "Resolve Conflict"
    static var description = IntentDescription("Resolves a sync conflict with the specified strategy")

    @Parameter(title: "File Name")
    var fileName: String

    @Parameter(title: "Strategy", default: .keepLocal)
    var strategy: ShortcutConflictResolutionStrategy

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await SyncServiceR17.shared.resolveConflict(fileName: fileName, strategy: strategy)
        return .result(dialog: "Resolved conflict for \(fileName) using \(strategy.rawValue)")
    }
}

struct AddFolderIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Folder to Sash"
    static var description = IntentDescription("Adds a folder to Sash sync by path")

    @Parameter(title: "Folder Path")
    var folderPath: String

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await SyncServiceR17.shared.addFolder(at: folderPath)
        return .result(dialog: "Added \(folderPath) to sync")
    }
}

enum ShortcutConflictResolutionStrategy: String, AppEnum {
    case keepLocal = "local"
    case keepRemote = "remote"
    case keepBoth = "both"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Strategy"

    static var caseDisplayRepresentations: [ShortcutConflictResolutionStrategy: DisplayRepresentation] = [
        .keepLocal: "Keep Local",
        .keepRemote: "Keep Remote",
        .keepBoth: "Keep Both"
    ]
}

// MARK: - Sync Service R17

@MainActor
final class SyncServiceR17 {
    static let shared = SyncServiceR17()

    func getStatusSummary() -> String {
        "All folders synced"
    }

    func syncFolder(named: String) async {
        // Stub - triggers folder sync
    }

    func getRecentChanges(limit: Int) async -> [ChangeRecord] {
        []
    }

    func getActiveConflicts() async -> [ConflictRecord] {
        []
    }

    func resolveConflict(fileName: String, strategy: ShortcutConflictResolutionStrategy) async {
        // Stub - resolves conflict
    }

    func addFolder(at path: String) async {
        // Stub - adds folder to sync
    }
}

struct ChangeRecord {
    let fileName: String
    let action: String
    let timestamp: Date
}

struct ConflictRecord {
    let fileName: String
    let path: String
    let detectedAt: Date
}

// MARK: - R17 Automation Trigger Service

@MainActor
final class AutomationTriggerService: ObservableObject {
    static let shared = AutomationTriggerService()

    @Published private(set) var activeTriggers: [AutomationTrigger] = []

    struct AutomationTrigger: Identifiable, Codable {
        let id: UUID
        var name: String
        var triggerType: TriggerType
        var action: TriggerAction
        var isEnabled: Bool

        enum TriggerType: String, Codable {
            case conflictDetected = "conflict"
            case folderChanged = "folder_change"
            case deviceOnline = "device_online"
            case newDevice = "new_device"
        }

        enum TriggerAction: Codable {
            case syncAll
            case notify
            case runShortcut(name: String)
            case sendEmail
        }
    }

    private init() {
        loadTriggers()
    }

    func addTrigger(_ trigger: AutomationTrigger) {
        activeTriggers.append(trigger)
        saveTriggers()
    }

    func removeTrigger(_ id: UUID) {
        activeTriggers.removeAll { $0.id == id }
        saveTriggers()
    }

    func evaluateTrigger(type: AutomationTrigger.TriggerType, context: [String: Any]) async {
        for trigger in activeTriggers where trigger.triggerType == type && trigger.isEnabled {
            await executeTrigger(trigger)
        }
    }

    private func executeTrigger(_ trigger: AutomationTrigger) async {
        switch trigger.action {
        case .syncAll:
            await SyncServiceR17.shared.syncFolder(named: "all")
        case .notify:
            break
        case .runShortcut(let name):
            await runShortcut(named: name)
        case .sendEmail:
            break
        }
    }

    private func runShortcut(named: String) async {
        // Stub - runs a named Shortcuts shortcut
    }

    private func saveTriggers() {
        if let data = try? JSONEncoder().encode(activeTriggers) {
            UserDefaults.standard.set(data, forKey: "sash_automation_triggers")
        }
    }

    private func loadTriggers() {
        if let data = UserDefaults.standard.data(forKey: "sash_automation_triggers"),
           let triggers = try? JSONDecoder().decode([AutomationTrigger].self, from: data) {
            activeTriggers = triggers
        }
    }
}
