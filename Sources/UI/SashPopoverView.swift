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
        .frame(width: 400, height: 340)
        .liquidGlassBackground()
    }
}

struct SnapPositionsTabView: View {
    @ObservedObject var sashStore: SashStore

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)

            GlassDivider()
                .padding(.horizontal, Theme.Spacing.md)

            if !WindowManager.shared.isAccessibilityEnabled() || sashStore.showAccessibilityAlert {
                accessibilityGuideView
            } else {
                snapPositionsView
            }

            GlassDivider()
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)

            statusLineView
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
        }
    }

    private var headerView: some View {
        HStack {
            Text("Sash")
                .font(Theme.Typography.title)
                .foregroundColor(.primary)
            Spacer()
            Text("Window Snapping")
                .font(Theme.Typography.caption)
                .foregroundColor(.secondary)
        }
    }

    private var snapPositionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SNAP POSITIONS")
                .font(Theme.Typography.sectionHeader)
                .foregroundColor(.secondary)
                .tracking(0.08)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)

            ForEach(SnapPosition.allCases) { position in
                SnapPositionRow(position: position)
                    .padding(.horizontal, Theme.Spacing.md)
                if position != SnapPosition.allCases.last {
                    GlassDivider()
                        .padding(.leading, 44 + Theme.Spacing.md)
                        .padding(.trailing, Theme.Spacing.md)
                }
            }

            Spacer()
        }
    }

    private var accessibilityGuideView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .glassIcon()
                .accessibilityLabel("Security shield")
            Text("Accessibility Access Required")
                .font(Theme.Typography.titleSmall)
                .foregroundColor(.primary)
                .accessibilityLabel("Accessibility access required")
            Text("Sash needs accessibility permission to move and resize windows.")
                .font(Theme.Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
                .accessibilityLabel("Sash needs accessibility permission to move and resize windows.")
            Button(action: requestAccessibility) {
                Label("Grant Access", systemImage: "checkmark.circle.fill")
                    .font(Theme.Typography.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.accentPrimary)
                    .cornerRadius(Theme.CornerRadius.medium)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Grant accessibility access")
            .accessibilityHint("Opens system preferences to grant accessibility permission")
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .accessibilityElement(children: .combine)
    }

    private var statusLineView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text("Focused:")
                        .foregroundColor(.secondary)
                    Text(sashStore.focusedAppName)
                        .foregroundColor(.primary)
                }
                .font(Theme.Typography.caption)

                if let position = sashStore.lastSnapResult.position {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Position:")
                            .foregroundColor(.secondary)
                        Text(position.rawValue)
                            .foregroundColor(Theme.Colors.accentPrimary)
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

struct MonitorsTabView: View {
    @ObservedObject var sashStore: SashStore
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Monitors")
                    .font(Theme.Typography.title)
                    .foregroundColor(.primary)
                Spacer()
                refreshButton
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)

            GlassDivider()
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(sashStore.monitors) { monitor in
                        monitorRow(monitor)
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
    }

    private var refreshButton: some View {
        Button(action: {
            isRefreshing = true
            sashStore.refreshMonitors()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isRefreshing = false
            }
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.accentPrimary)
                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                .animation(isRefreshing ? .linear(duration: 0.5).repeatForever(autoreverses: false) : .default, value: isRefreshing)
        }
        .buttonStyle(.plain)
    }

    private func monitorRow(_ monitor: MonitorInfo) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: monitor.isMain ? "display" : "rectangle")
                .font(.system(size: 20))
                .frame(width: 24, height: 24)
                .glassIcon(monitor.isMain ? Theme.Colors.accentPrimary : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(monitor.name)
                    .font(Theme.Typography.body)
                    .foregroundColor(.primary)
                Text("\(Int(monitor.width)) × \(Int(monitor.height))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if monitor.isMain {
                Text("Main")
                    .font(Theme.Typography.captionBold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.accentPrimary)
                    .cornerRadius(Theme.CornerRadius.small)
            }
        }
        .padding(Theme.Spacing.md)
        .liquidGlassCard()
    }
}

struct PresetsTabView: View {
    @ObservedObject var sashStore: SashStore
    @State private var showAddPreset = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Window Presets")
                    .font(Theme.Typography.title)
                    .foregroundColor(.primary)
                Spacer()
                addButton
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)

            GlassDivider()
                .padding(.horizontal, Theme.Spacing.md)

            if sashStore.snapPresets.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(sashStore.snapPresets) { preset in
                            presetRow(preset)
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
        }
    }

    private var addButton: some View {
        Button(action: { showAddPreset = true }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.accentPrimary)
        }
        .buttonStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 32))
                .glassIcon()
            Text("No presets yet")
                .font(Theme.Typography.body)
                .foregroundColor(.primary)
            Text("Create presets to arrange multiple windows")
                .font(Theme.Typography.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func presetRow(_ preset: SnapPreset) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(preset.name)
                    .font(Theme.Typography.body)
                    .foregroundColor(.primary)
                Text("\(preset.positions.count) windows")
                    .font(Theme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            deleteButton(for: preset)
        }
        .padding(Theme.Spacing.md)
        .liquidGlassCard()
    }

    private func deleteButton(for preset: SnapPreset) -> some View {
        Button(action: { sashStore.deletePreset(preset.id) }) {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.destructive)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsTabView: View {
    @ObservedObject var sashStore: SashStore

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                startupSection
                subscriptionSection
                aboutSection
            }
            .padding(Theme.Spacing.md)
        }
    }

    private var startupSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("STARTUP")
                .font(Theme.Typography.sectionHeader)
                .foregroundColor(.secondary)
                .tracking(0.08)

            Toggle(isOn: $sashStore.launchAtLogin) {
                Text("Launch at Login")
                    .font(Theme.Typography.body)
                    .foregroundColor(.primary)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .liquidGlassCard()
        }
    }

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("SUBSCRIPTION")
                .font(Theme.Typography.sectionHeader)
                .foregroundColor(.secondary)
                .tracking(0.08)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: SubscriptionManager.shared.hasActiveSubscription ? "checkmark.seal.fill" : "seal")
                        .font(.system(size: 16))
                        .foregroundColor(SubscriptionManager.shared.hasActiveSubscription ? Theme.Colors.success : .secondary)
                    Text(SubscriptionManager.shared.currentTier.displayName)
                        .font(Theme.Typography.body)
                        .foregroundColor(.primary)
                }

                if SubscriptionManager.shared.hasActiveSubscription {
                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.success)
                    }
                } else {
                    upgradeButton
                }
            }
            .padding(Theme.Spacing.md)
            .liquidGlassCard()
        }
    }

    private var upgradeButton: some View {
        Button(action: {}) {
            Text("Upgrade to Pro")
                .font(Theme.Typography.caption)
                .foregroundColor(.white)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Colors.accentPrimary)
                .cornerRadius(Theme.CornerRadius.small)
        }
        .buttonStyle(.plain)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("ABOUT")
                .font(Theme.Typography.sectionHeader)
                .foregroundColor(.secondary)
                .tracking(0.08)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "rectangle.split.2x1.fill")
                        .font(.system(size: 24))
                        .frame(width: 32, height: 32)
                        .glassIcon()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sash")
                            .font(Theme.Typography.body)
                            .foregroundColor(.primary)
                        Text("Version 1.0.0")
                            .font(Theme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .liquidGlassCard()
        }
    }
}
