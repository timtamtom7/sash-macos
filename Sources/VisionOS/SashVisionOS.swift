import SwiftUI
import WidgetKit

// MARK: - Sash Vision OS App (R20)

// MARK: - Spatial Sync View

struct SpatialSyncView: View {
    @StateObject private var syncStore = VisionSyncStore()

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 32) {
                // Header
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(.cyan)
                    Text("Sash Sync")
                        .font(.system(size: 28, weight: .semibold))
                    Spacer()
                    syncStatusBadge
                }
                .padding(.horizontal, 40)

                // Sync dashboard
                HStack(spacing: 24) {
                    // Folder list
                    FolderListPanel(folders: syncStore.folders)
                        .frame(width: 300)

                    // 3D Activity visualization
                    SpatialActivityView(changes: syncStore.recentChanges)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40)

                // Storage bar
                StorageBarView(
                    used: syncStore.storageUsed,
                    total: syncStore.storageQuota
                )
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 32)
        }
    }

    @ViewBuilder
    var syncStatusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(syncStore.isSyncing ? Color.green : Color.blue)
                .frame(width: 12, height: 12)
            Text(syncStore.isSyncing ? "Syncing" : "Synced")
                .font(.system(size: 16, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

// MARK: - Vision Sync Store

@MainActor
class VisionSyncStore: ObservableObject {
    @Published var folders: [VisionFolder] = []
    @Published var recentChanges: [VisionChange] = []
    @Published var isSyncing: Bool = false
    @Published var storageUsed: Double = 0
    @Published var storageQuota: Double = 10_000_000_000

    struct VisionFolder: Identifiable {
        let id: UUID
        let name: String
        let itemCount: Int
        let lastSync: Date
    }

    struct VisionChange: Identifiable {
        let id = UUID()
        let fileName: String
        let action: String
        let timestamp: Date
        let position: SIMD3<Float>
    }

    init() {
        loadData()
    }

    func loadData() {
        folders = [
            VisionFolder(id: UUID(), name: "Work Documents", itemCount: 234, lastSync: Date()),
            VisionFolder(id: UUID(), name: "Personal", itemCount: 89, lastSync: Date().addingTimeInterval(-3600)),
            VisionFolder(id: UUID(), name: "Photos", itemCount: 1247, lastSync: Date().addingTimeInterval(-7200))
        ]
        recentChanges = [
            VisionChange(fileName: "report.pdf", action: "uploaded", timestamp: Date(), position: SIMD3<Float>(0, 0, 0)),
            VisionChange(fileName: "image.png", action: "uploaded", timestamp: Date().addingTimeInterval(-300), position: SIMD3<Float>(1, 0, 0)),
            VisionChange(fileName: "notes.md", action: "downloaded", timestamp: Date().addingTimeInterval(-600), position: SIMD3<Float>(-1, 0, 0))
        ]
        isSyncing = false
        storageUsed = 2_500_000_000
    }
}

// MARK: - Folder List Panel

struct FolderListPanel: View {
    let folders: [VisionSyncStore.VisionFolder]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folders")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            ForEach(folders) { folder in
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.cyan)
                    VStack(alignment: .leading) {
                        Text(folder.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Text("\(folder.itemCount) items")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(folder.lastSync, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }

            Spacer()
        }
    }
}

// MARK: - Spatial Activity View

struct SpatialActivityView: View {
    let changes: [VisionSyncStore.VisionChange]

    var body: some View {
        ZStack {
            // Grid background
            ForEach(0..<10, id: \.self) { i in
                Rectangle()
                    .stroke(Color.cyan.opacity(0.1), lineWidth: 1)
                    .frame(width: 300, height: 300)
                    .rotationEffect(.degrees(Double(i) * 15))
                    .offset(y: -100)
            }

            // 3D-like floating items
            ForEach(changes) { change in
                VStack(spacing: 4) {
                    Image(systemName: change.action == "uploaded" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(change.action == "uploaded" ? .green : .blue)
                        .shadow(color: change.action == "uploaded" ? .green.opacity(0.5) : .blue.opacity(0.5), radius: 10)
                    Text(change.fileName)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .position(
                    x: 250 + CGFloat(change.position.x * 100),
                    y: 200 + CGFloat(change.position.z * 50)
                )
                .animation(.easeInOut, value: change.id)
            }
        }
    }
}

// MARK: - Storage Bar View

struct StorageBarView: View {
    let used: Double
    let total: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Storage")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                Text("\(formatBytes(used)) / \(formatBytes(total))")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 16)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(used / total), height: 16)
                }
            }
            .frame(height: 16)
        }
    }

    func formatBytes(_ bytes: Double) -> String {
        let gb = bytes / 1_000_000_000
        return String(format: "%.1f GB", gb)
    }
}

// MARK: - Vision OS App Export

@available(visionOS 1.0, *)
struct SashVisionOSApp: App {
    var body: some Scene {
        WindowGroup {
            SpatialSyncView()
                .preferredColorScheme(.dark)
        }
    }
}
