import AppKit
import SwiftUI

// MARK: - Menu Bar Extra (R17)

struct SashMenuBarView: View {
    @State private var showingPopover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status header
            HStack {
                Image(systemName: "rectangle.split.2x1")
                    .foregroundColor(.accentColor)
                Text("Sash")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(SubscriptionManager.shared.currentTier.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Quick actions
            MenuBarActionButton(icon: "arrow.left.square", title: "Snap Left", shortcut: "⌃⌥←") {
                WindowManager.shared.snapFocusedWindow(to: .leftHalf)
            }

            MenuBarActionButton(icon: "arrow.right.square", title: "Snap Right", shortcut: "⌃⌥→") {
                WindowManager.shared.snapFocusedWindow(to: .rightHalf)
            }

            MenuBarActionButton(icon: "arrow.up.square", title: "Snap Top", shortcut: "⌃⌥↑") {
                WindowManager.shared.snapFocusedWindow(to: .topHalf)
            }

            MenuBarActionButton(icon: "arrow.down.square", title: "Snap Bottom", shortcut: "⌃⌥↓") {
                WindowManager.shared.snapFocusedWindow(to: .bottomHalf)
            }

            Divider()

            // Layouts submenu
            MenuBarActionButton(icon: "rectangle.split.2x2", title: "All Layouts") {
                // Open layouts panel
            }

            Divider()

            // Settings
            MenuBarActionButton(icon: "gear", title: "Preferences") {
                // Open preferences
            }

            MenuBarActionButton(icon: "arrow.clockwise", title: "Restore Purchases") {
                Task {
                    await SubscriptionManager.shared.restorePurchases()
                }
            }

            Divider()

            MenuBarActionButton(icon: "power", title: "Quit Sash") {
                NSApp.terminate(nil)
            }
        }
        .frame(width: 220)
    }
}

// MARK: - Menu Bar Action Button

struct MenuBarActionButton: View {
    let icon: String
    let title: String
    let shortcut: String?
    let action: () -> Void

    init(icon: String, title: String, shortcut: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.shortcut = shortcut
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.system(size: 12))
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Folder Actions Service (R17)

final class FolderActionsService {
    static let shared = FolderActionsService()

    /// Attaches Sash monitoring to a folder path
    /// Uses FSEvents for real-time file system monitoring
    func attachToFolder(_ path: String) {
        // Stub: In production, use FSEvents or NSFilePresenter
        // to monitor folder changes and trigger sync
        print("Attached to folder: \(path)")
    }

    /// Detaches Sash monitoring from a folder path
    func detachFromFolder(_ path: String) {
        print("Detached from folder: \(path)")
    }

    /// Gets the list of folders Sash is attached to
    func getAttachedFolders() -> [String] {
        UserDefaults.standard.stringArray(forKey: "sash_attached_folders") ?? []
    }
}

// MARK: - Focus Integration (R17)

final class FocusIntegrationService {
    static let shared = FocusIntegrationService()

    /// Called when Focus mode changes
    func handleFocusChange(isActive: Bool) {
        if isActive {
            // Enter quiet sync mode during Focus
            UserDefaults.standard.set("quiet", forKey: "sash_sync_mode")
        } else {
            // Resume normal sync
            UserDefaults.standard.removeObject(forKey: "sash_sync_mode")
        }
    }
}
