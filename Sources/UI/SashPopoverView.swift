import SwiftUI
import AppKit

struct SashPopoverView: View {
    @ObservedObject var sashStore: SashStore
    @State private var showAccessibilityGuide: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)

            Divider()
                .background(Theme.Colors.border)

            // Accessibility Guide or Snap Positions
            if !WindowManager.shared.isAccessibilityEnabled() || sashStore.showAccessibilityAlert {
                accessibilityGuideView
            } else {
                snapPositionsView
            }

            Divider()
                .background(Theme.Colors.border)
                .padding(.top, Theme.Spacing.sm)

            // Status Line
            statusLineView
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)

            Divider()
                .background(Theme.Colors.border)

            // Footer
            footerView
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
        }
        .frame(width: 400, height: 340)
        .background(Theme.Colors.background)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("Sash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button(action: openSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)

            Button(action: quitApp) {
                Image(systemName: "power")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Snap Positions

    private var snapPositionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SNAP POSITIONS")
                .font(Theme.Typography.sectionHeader)
                .foregroundColor(Theme.Colors.textTertiary)
                .tracking(0.06)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)

            ForEach(SnapPosition.allCases) { position in
                SnapPositionRow(position: position)
                    .padding(.horizontal, Theme.Spacing.md)
                if position != SnapPosition.allCases.last {
                    Divider()
                        .background(Theme.Colors.border)
                        .padding(.leading, 44)
                }
            }

            Spacer()
        }
    }

    // MARK: - Accessibility Guide

    private var accessibilityGuideView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.accent)

            Text("Accessibility Access Required")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            Text("Sash needs accessibility permission to move and resize windows.")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            Button(action: requestAccessibility) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Grant Access")
                }
                .font(Theme.Typography.body)
                .foregroundColor(.white)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.accent)
                .cornerRadius(Theme.CornerRadius.small)
            }
            .buttonStyle(.plain)

            Text("System Settings → Privacy & Security → Accessibility")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
    }

    // MARK: - Status Line

    private var statusLineView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Focused:")
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text(sashStore.focusedAppName)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .font(Theme.Typography.caption)

                if let position = sashStore.lastSnapResult.position {
                    HStack(spacing: 4) {
                        Text("Position:")
                            .foregroundColor(Theme.Colors.textTertiary)
                        Text(position.rawValue)
                            .foregroundColor(Theme.Colors.accent)
                    }
                    .font(Theme.Typography.caption)
                }
            }

            Spacer()

            if case .cannotResize = sashStore.lastSnapResult {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Cannot resize this window")
                }
                .font(Theme.Typography.caption)
                .foregroundColor(.orange)
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Toggle(isOn: $sashStore.launchAtLogin) {
                Text("Launch at Login")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .onChange(of: sashStore.launchAtLogin) { newValue in
                SettingsStore.shared.setLaunchAtLogin(newValue)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func requestAccessibility() {
        WindowManager.shared.requestAccessibilityPermission()
        sashStore.showAccessibilityAlert = false
    }

    private func openSettings() {
        // R1: Stub - settings popover would open here
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - SnapResult Extension

extension SnapResult {
    var position: SnapPosition? {
        if case .success(let pos) = self {
            return pos
        }
        return nil
    }
}
