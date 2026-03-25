import AppIntents
import Foundation

// MARK: - App Shortcuts Provider

struct SashShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
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
