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

struct SyncStatusEntry: TimelineEntry {
    let date: Date
    let folderCount: Int
    let syncStatus: SyncStatus
    let conflictCount: Int
    let recentChanges: [SyncChange]
    let storageUsed: Int64
    let storageQuota: Int64

    enum SyncStatus: String {
        case synced = "synced"
        case syncing = "syncing"
        case paused = "paused"
        case conflicts = "conflicts"
    }

    struct SyncChange: Identifiable {
        let id = UUID()
        let fileName: String
        let action: String
        let timestamp: Date
    }
}

struct SyncStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> SyncStatusEntry {
        SyncStatusEntry(
            date: Date(),
            folderCount: 3,
            syncStatus: .synced,
            conflictCount: 0,
            recentChanges: [
                SyncStatusEntry.SyncChange(fileName: "report.pdf", action: "uploaded", timestamp: Date())
            ],
            storageUsed: 2_500_000_000,
            storageQuota: 10_000_000_000
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SyncStatusEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SyncStatusEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> SyncStatusEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.sash.shared")

        let folderCount = userDefaults?.integer(forKey: "folderCount") ?? 1
        let statusRaw = userDefaults?.string(forKey: "syncStatus") ?? "synced"
        let status = SyncStatusEntry.SyncStatus(rawValue: statusRaw) ?? .synced
        let conflictCount = userDefaults?.integer(forKey: "conflictCount") ?? 0
        let storageUsed = Int64(userDefaults?.integer(forKey: "storageUsed") ?? 0)
        let storageQuota = Int64(userDefaults?.integer(forKey: "storageQuota") ?? 10_000_000_000)

        return SyncStatusEntry(
            date: Date(),
            folderCount: folderCount,
            syncStatus: status,
            conflictCount: conflictCount,
            recentChanges: [],
            storageUsed: storageUsed,
            storageQuota: storageQuota
        )
    }
}

struct SyncStatusWidgetView: View {
    var entry: SyncStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetSpacing.md) {
            headerRow
            WidgetDivider()
            statsRow
            WidgetDivider()
            storageSection
            syncButton
        }
        .padding(WidgetSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }

    private var headerRow: some View {
        HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Sash Sync")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            statusBadge
        }
        .foregroundStyle(.primary)
    }

    @ViewBuilder
    private var statusBadge: some View {
        HStack(spacing: WidgetSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(entry.syncStatus.rawValue.capitalized)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var statsRow: some View {
        HStack(spacing: WidgetSpacing.lg) {
            StatView(value: "\(entry.folderCount)", label: "Folders")
            StatView(value: "\(entry.conflictCount)", label: "Conflicts")
            StatView(value: formatStorage(entry.storageUsed), label: "Storage")
        }
    }

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: WidgetSpacing.xs) {
            HStack {
                Text("Storage")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(Double(entry.storageUsed) / Double(entry.storageQuota) * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(storageColor)
            }
            storageBar
        }
    }

    private var storageBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: WidgetRadius.small)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: WidgetRadius.small)
                    .fill(storageColor)
                    .frame(width: geo.size.width * storageFraction, height: 6)
            }
        }
        .frame(height: 6)
    }

    private var storageFraction: CGFloat {
        CGFloat(Double(entry.storageUsed) / Double(entry.storageQuota))
    }

    private var syncButton: some View {
        Link(destination: URL(string: "sash://toggle-sync")!) {
            HStack {
                Image(systemName: entry.syncStatus == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 12))
                Text(entry.syncStatus == .paused ? "Resume Sync" : "Pause Sync")
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, WidgetSpacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: WidgetRadius.medium))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
    }

    private var statusColor: Color {
        switch entry.syncStatus {
        case .synced: return .green
        case .syncing: return .blue
        case .paused: return .orange
        case .conflicts: return .red
        }
    }

    private var storageColor: Color {
        let pct = Double(entry.storageUsed) / Double(entry.storageQuota)
        if pct > 0.9 { return .red }
        if pct > 0.7 { return .orange }
        return .green
    }

    private func formatStorage(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_000_000_000
        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.0f MB", mb)
    }
}

private struct WidgetDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(height: 1)
    }
}

struct StatView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SyncActivityWidgetView: View {
    var entry: SyncStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetSpacing.sm) {
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("Recent Activity")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(entry.date, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)

            if entry.recentChanges.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No recent changes")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.recentChanges.prefix(5)) { change in
                    activityRow(change)
                }
            }
        }
        .padding(WidgetSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }

    private func activityRow(_ change: SyncStatusEntry.SyncChange) -> some View {
        HStack {
            Image(systemName: change.action == "uploaded" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 10))
                .foregroundStyle(change.action == "uploaded" ? .green : .blue)
            Text(change.fileName)
                .font(.system(size: 11))
                .lineLimit(1)
            Spacer()
            Text(change.timestamp, style: .relative)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}

struct ConflictWidgetView: View {
    var entry: SyncStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetSpacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
                Text("Conflicts")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("\(entry.conflictCount)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.orange)
            }
            .foregroundStyle(.primary)

            WidgetDivider()

            if entry.conflictCount == 0 {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: WidgetSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.green)
                        Text("No conflicts")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                Text("Tap to resolve")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                resolveButton
            }
        }
        .padding(WidgetSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
    }

    private var resolveButton: some View {
        Link(destination: URL(string: "sash://conflicts")!) {
            Text("View Conflicts")
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, WidgetSpacing.sm)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: WidgetRadius.medium))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.orange)
    }
}

struct SashSyncStatusWidgetR18: Widget {
    let kind: String = "SashSyncStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SyncStatusProvider()) { entry in
            SyncStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Sync Dashboard")
        .description("Full sync status with storage and controls.")
        .supportedFamilies([.systemLarge])
    }
}

struct SashSyncActivityWidget: Widget {
    let kind: String = "SashSyncActivityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SyncStatusProvider()) { entry in
            SyncActivityWidgetView(entry: entry)
        }
        .configurationDisplayName(" Sync Activity")
        .description("Recent sync activity across all folders.")
        .supportedFamilies([.systemMedium])
    }
}

struct SashConflictWidget: Widget {
    let kind: String = "SashConflictWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SyncStatusProvider()) { entry in
            ConflictWidgetView(entry: entry)
        }
        .configurationDisplayName("Sync Conflicts")
        .description("Active sync conflicts requiring resolution.")
        .supportedFamilies([.systemSmall])
    }
}
