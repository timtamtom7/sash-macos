import SwiftUI
import AppKit

struct SashPopoverView: View {
    @ObservedObject var sashStore: SashStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SnapPositionsTabView(sashStore: sashStore)
                .tabItem {
                    Label("Snap", systemImage: "rectangle.split.2x1")
                }
                .tag(0)

            MonitorsTabView(sashStore: sashStore)
                .tabItem {
                    Label("Monitors", systemImage: "display")
                }
                .tag(1)

            PresetsTabView(sashStore: sashStore)
                .tabItem {
                    Label("Presets", systemImage: "square.grid.2x2")
                }
                .tag(2)

            SettingsTabView(sashStore: sashStore)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .frame(width: 400, height: 380)
        .background(Theme.Colors.background)
    }
}

// MARK: - Snap Positions Tab

struct SnapPositionsTabView: View {
    @ObservedObject var sashStore: SashStore

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)

            Divider()
                .background(Theme.Colors.border)

            if !WindowManager.shared.isAccessibilityEnabled() || sashStore.showAccessibilityAlert {
                accessibilityGuideView
            } else {
                snapPositionsView
            }

            Divider()
                .background(Theme.Colors.border)
                .padding(.top, Theme.Spacing.sm)

            statusLineView
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
        }
    }

    private var headerView: some View {
        HStack {
            Text("Sash")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
            Spacer()
        }
    }

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
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
    }

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
        }
    }

    private func requestAccessibility() {
        WindowManager.shared.requestAccessibilityPermission()
        sashStore.showAccessibilityAlert = false
    }
}

// MARK: - Monitors Tab

struct MonitorsTabView: View {
    @ObservedObject var sashStore: SashStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Monitors")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                Spacer()
                Button(action: { sashStore.refreshMonitors() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            Divider()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(sashStore.monitors) { monitor in
                        monitorRow(monitor)
                    }
                }
                .padding(12)
            }
        }
    }

    private func monitorRow(_ monitor: MonitorInfo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: monitor.isMain ? "display" : "rectangle")
                .font(.system(size: 20))
                .foregroundColor(monitor.isMain ? Theme.Colors.accent : Theme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(monitor.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("\(Int(monitor.width)) × \(Int(monitor.height))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            if monitor.isMain {
                Text("Main")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.accent)
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(Theme.Colors.surface)
        .cornerRadius(8)
    }
}

// MARK: - Presets Tab

struct PresetsTabView: View {
    @ObservedObject var sashStore: SashStore
    @State private var showAddPreset = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Window Presets")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                Spacer()
                Button(action: { showAddPreset = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            Divider()

            if sashStore.snapPresets.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("No presets yet")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textSecondary)
                    Text("Create presets to arrange multiple windows")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.textTertiary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(sashStore.snapPresets) { preset in
                            presetRow(preset)
                        }
                    }
                    .padding(12)
                }
            }
        }
    }

    private func presetRow(_ preset: SnapPreset) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("\(preset.positions.count) windows")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            Spacer()
            Button(action: { sashStore.deletePreset(preset.id) }) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Theme.Colors.surface)
        .cornerRadius(8)
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    @ObservedObject var sashStore: SashStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Startup
                VStack(alignment: .leading, spacing: 8) {
                    Text("STARTUP")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .tracking(0.05)

                    Toggle(isOn: $sashStore.launchAtLogin) {
                        Text("Launch at Login")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .padding(12)
                    .background(Theme.Colors.surface)
                    .cornerRadius(8)
                }

                // About
                VStack(alignment: .leading, spacing: 8) {
                    Text("ABOUT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .tracking(0.05)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("Window snapping utility for macOS")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(12)
                    .background(Theme.Colors.surface)
                    .cornerRadius(8)
                }
            }
            .padding(12)
        }
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
