import Foundation

@MainActor
final class SashSyncManager: ObservableObject {
    static let shared = SashSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSynced: Date?

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case offline
        case error(String)
    }

    private let store = NSUbiquitousKeyValueStore.default
    private var observers: [NSObjectProtocol] = []

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        let notification = NSUbiquitousKeyValueStore.didChangeExternallyNotification
        let observer = NotificationCenter.default.addObserver(
            forName: notification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.handleExternalChange()
        }
        observers.append(observer)
    }

    // MARK: - Sync Data

    struct SyncPayload: Codable {
        var presets: [SnapPreset]
        var settings: SashSettings

        struct SashSettings: Codable {
            var launchAtLogin: Bool
            var showInMenuBar: Bool
            var animateWindows: Bool
        }
    }

    func sync() {
        guard isICloudAvailable else {
            syncStatus = .offline
            return
        }

        syncStatus = .syncing

        do {
            let payload = buildPayload()
            let data = try JSONEncoder().encode(payload)
            store.set(data, forKey: "sash.sync.data")
            store.synchronize()

            syncStatus = .synced
            lastSynced = Date()
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    func pullFromCloud() {
        guard isICloudAvailable else { return }

        guard let data = store.data(forKey: "sash.sync.data"),
              let payload = try? JSONDecoder().decode(SyncPayload.self, from: data) else {
            return
        }

        applyPayload(payload)
    }

    private func buildPayload() -> SyncPayload {
        let settings = SyncPayload.SashSettings(
            launchAtLogin: UserDefaults.standard.bool(forKey: "sash_launchAtLogin"),
            showInMenuBar: UserDefaults.standard.bool(forKey: "sash_showInMenuBar"),
            animateWindows: UserDefaults.standard.bool(forKey: "sash_animateWindows")
        )

        return SyncPayload(
            presets: SashState.shared.presets,
            settings: settings
        )
    }

    private func applyPayload(_ payload: SyncPayload) {
        SashState.shared.presets = payload.presets

        UserDefaults.standard.set(payload.settings.launchAtLogin, forKey: "sash_launchAtLogin")
        UserDefaults.standard.set(payload.settings.showInMenuBar, forKey: "sash_showInMenuBar")
        UserDefaults.standard.set(payload.settings.animateWindows, forKey: "sash_animateWindows")
    }

    private func handleExternalChange() {
        pullFromCloud()
        syncStatus = .synced
        lastSynced = Date()
    }

    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func syncNow() {
        sync()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
