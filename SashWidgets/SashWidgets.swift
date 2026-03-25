import WidgetKit
import SwiftUI

// MARK: - Layout Summary

struct LayoutSummary: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let windowCount: Int
}

// MARK: - Widget Entry

struct SashWidgetEntry: TimelineEntry {
    let date: Date
    let currentLayout: LayoutSummary?
    let layouts: [LayoutSummary]
    let recentLayouts: [String]
}

// MARK: - Provider

struct SashProvider: TimelineProvider {
    func placeholder(in context: Context) -> SashWidgetEntry {
        SashWidgetEntry(
            date: Date(),
            currentLayout: LayoutSummary(id: "1", name: "Code + Docs", icon: "📐", windowCount: 3),
            layouts: [
                LayoutSummary(id: "1", name: "Code + Docs", icon: "📐", windowCount: 3),
                LayoutSummary(id: "2", name: "Email", icon: "📧", windowCount: 2),
                LayoutSummary(id: "3", name: "Music", icon: "🎵", windowCount: 1),
                LayoutSummary(id: "4", name: "Presentation", icon: "📊", windowCount: 4)
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

// MARK: - Current Layout View

struct CurrentLayoutView: View {
    var entry: SashWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "rectangle.split.2x1")
                    .foregroundColor(.accentColor)
                Text("Sash")
                    .font(.system(size: 12, weight: .semibold))
            }

            Spacer()

            if let layout = entry.currentLayout {
                Text("Current:")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                HStack {
                    Text(layout.icon)
                        .font(.system(size: 16))
                    Text(layout.name)
                        .font(.system(size: 12, weight: .medium))
                }
                Text("\(layout.windowCount) windows")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                Text("No active layout")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .widgetURL(URL(string: "sash://open")!)
    }
}

// MARK: - Layout Switcher View

struct LayoutSwitcherView: View {
    var entry: SashWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "rectangle.split.2x1")
                    .foregroundColor(.accentColor)
                Text("Sash")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("Quick Layout")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if entry.layouts.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No layouts")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(entry.layouts.prefix(4)) { layout in
                        Link(destination: URL(string: "sash://apply/\(layout.id)")!) {
                            HStack {
                                Text(layout.icon)
                                    .font(.system(size: 14))
                                Text(layout.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(6)
                        }
                    }
                }
            }

            Spacer()

            Text("Tap any layout to apply it")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Quick Snap View

struct QuickSnapView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "rectangle.split.2x1")
                    .foregroundColor(.accentColor)
                Text("Sash")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(["left", "right"], id: \.self) { pos in
                    Link(destination: URL(string: "sash://snap/\(pos)")!) {
                        Image(systemName: pos == "left" ? "arrow.left.square" : "arrow.right.square")
                            .font(.system(size: 16))
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                ForEach(["top", "bottom"], id: \.self) { pos in
                    Link(destination: URL(string: "sash://snap/\(pos)")!) {
                        Image(systemName: pos == "top" ? "arrow.up.square" : "arrow.down.square")
                            .font(.system(size: 16))
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
            }

            HStack(spacing: 8) {
                Link(destination: URL(string: "sash://snap/center")!) {
                    Image(systemName: "rectangle.center.inset.filled")
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(6)
                }
                Link(destination: URL(string: "sash://snap/fill")!) {
                    Image(systemName: "rectangle.fill")
                        .font(.system(size: 16))
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(6)
                }
            }

            Spacer()

            Text("Tap to snap")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding()
        .widgetURL(URL(string: "sash://open")!)
    }
}

// MARK: - Widget Bundle

@main
struct SashWidgetBundle: WidgetBundle {
    var body: some Widget {
        SashCurrentLayoutWidget()
        SashLayoutSwitcherWidget()
        SashQuickSnapWidget()
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
