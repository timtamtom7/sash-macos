import WidgetKit
import SwiftUI

private enum WidgetSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
}

private enum WidgetRadius {
    static let small: CGFloat = 6
    static let medium: CGFloat = 8
    static let large: CGFloat = 12
}

struct LayoutSummary: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let windowCount: Int
}

struct SashWidgetEntry: TimelineEntry {
    let date: Date
    let currentLayout: LayoutSummary?
    let layouts: [LayoutSummary]
    let recentLayouts: [String]
}

struct SashProvider: TimelineProvider {
    func placeholder(in context: Context) -> SashWidgetEntry {
        SashWidgetEntry(
            date: Date(),
            currentLayout: LayoutSummary(id: "1", name: "Code + Docs", icon: "rectangle.split.2x1", windowCount: 3),
            layouts: [
                LayoutSummary(id: "1", name: "Code + Docs", icon: "rectangle.split.2x1", windowCount: 3),
                LayoutSummary(id: "2", name: "Email", icon: "envelope", windowCount: 2),
                LayoutSummary(id: "3", name: "Music", icon: "music.note", windowCount: 1),
                LayoutSummary(id: "4", name: "Presentation", icon: "chart.bar", windowCount: 4)
            ],
            recentLayouts: ["1", "2", "3", "4"]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SashWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SashWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func loadEntry() -> SashWidgetEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.sash.shared")

        var currentLayout: LayoutSummary?
        var layouts: [LayoutSummary] = []
        var recentLayouts: [String] = []

        if let currentData = userDefaults?.data(forKey: "currentLayout"),
           let layout = try? JSONDecoder().decode(LayoutSummary.self, from: currentData) {
            currentLayout = layout
        }

        if let layoutsData = userDefaults?.data(forKey: "layouts"),
           let decoded = try? JSONDecoder().decode([LayoutSummary].self, from: layoutsData) {
            layouts = decoded
        }

        recentLayouts = userDefaults?.stringArray(forKey: "recentLayoutIds") ?? []

        return SashWidgetEntry(date: Date(), currentLayout: currentLayout, layouts: layouts, recentLayouts: recentLayouts)
    }
}

struct CurrentLayoutView: View {
    var entry: SashWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetSpacing.sm) {
            HStack {
                Image(systemName: "rectangle.split.2x1")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("Sash")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.primary)

            Spacer()

            if let layout = entry.currentLayout {
                Text("Current:")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName: layout.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.tint)
                    Text(layout.name)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                }
                Text("\(layout.windowCount) windows")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            } else {
                Text("No active layout")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(WidgetSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .widgetURL(URL(string: "sash://open")!)
    }
}

struct LayoutSwitcherView: View {
    var entry: SashWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetSpacing.sm) {
            HStack {
                Image(systemName: "rectangle.split.2x1")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("Sash")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("Quick Layout")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)

            if entry.layouts.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No layouts")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: WidgetSpacing.sm) {
                    ForEach(entry.layouts.prefix(4)) { layout in
                        Link(destination: URL(string: "sash://apply/\(layout.id)")!) {
                            HStack {
                                Image(systemName: layout.icon)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.tint)
                                Text(layout.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, WidgetSpacing.sm)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: WidgetRadius.small))
                        }
                    }
                }
            }

            Spacer()

            Text("Tap any layout to apply it")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(WidgetSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }
}

struct QuickSnapView: View {
    var body: some View {
        VStack(spacing: WidgetSpacing.sm) {
            HStack {
                Image(systemName: "rectangle.split.2x1")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("Sash")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.primary)

            snapButtonGrid

            Spacer()

            Text("Tap to snap")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(WidgetSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .widgetURL(URL(string: "sash://open")!)
    }

    private var snapButtonGrid: some View {
        VStack(spacing: WidgetSpacing.sm) {
            HStack(spacing: WidgetSpacing.sm) {
                snapButton(icon: "arrow.left.square", url: "sash://snap/left")
                snapButton(icon: "arrow.right.square", url: "sash://snap/right")
                snapButton(icon: "arrow.up.square", url: "sash://snap/top")
                snapButton(icon: "arrow.down.square", url: "sash://snap/bottom")
            }
            HStack(spacing: WidgetSpacing.sm) {
                snapButton(icon: "rectangle.center.inset.filled", url: "sash://snap/center")
                snapButton(icon: "rectangle.fill", url: "sash://snap/fill")
                Spacer()
                Spacer()
            }
        }
    }

    private func snapButton(icon: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 28, height: 28)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: WidgetRadius.small))
        }
        .foregroundStyle(.tint)
    }
}

@main
struct SashWidgetBundle: WidgetBundle {
    var body: some Widget {
        SashCurrentLayoutWidget()
        SashLayoutSwitcherWidget()
        SashQuickSnapWidget()
        SashSyncStatusWidgetR18()
        SashSyncActivityWidget()
        SashConflictWidget()
    }
}

struct SashCurrentLayoutWidget: Widget {
    let kind: String = "SashCurrentLayoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SashProvider()) { entry in
            CurrentLayoutView(entry: entry)
        }
        .configurationDisplayName("Current Layout")
        .description("Shows the currently active window layout.")
        .supportedFamilies([.systemSmall])
    }
}

struct SashLayoutSwitcherWidget: Widget {
    let kind: String = "SashLayoutSwitcherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SashProvider()) { entry in
            LayoutSwitcherView(entry: entry)
        }
        .configurationDisplayName("Layout Switcher")
        .description("Quick layout switching with one tap.")
        .supportedFamilies([.systemMedium])
    }
}

struct SashQuickSnapWidget: Widget {
    let kind: String = "SashQuickSnapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SashProvider()) { entry in
            QuickSnapView()
        }
        .configurationDisplayName("Quick Snap")
        .description("Quick window snapping positions.")
        .supportedFamilies([.systemSmall])
    }
}
