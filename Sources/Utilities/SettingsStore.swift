import Foundation

class SettingsStore {
    static let shared = SettingsStore()

    private var values: [String: String] = [:]

    enum SettingKey: String {
        case launchAtLogin = "launch_at_login"
        case lastSnapPosition = "last_snap_position"
        case customZones = "custom_zones"
    }

    private init() {
        loadValues()
    }

    private var fileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Sash", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("settings.json")
    }

    private func loadValues() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            values = [:]
            return
        }
        values = decoded
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(values)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to persist settings: \(error)")
        }
    }

    func get(_ key: SettingKey) -> String? {
        values[key.rawValue]
    }

    func set(_ key: SettingKey, value: String) {
        values[key.rawValue] = value
        persist()
    }

    func setBool(_ key: SettingKey, value: Bool) {
        set(key, value: value ? "true" : "false")
    }

    func getBool(_ key: SettingKey) -> Bool {
        get(key) == "true"
    }

    func remove(_ key: SettingKey) {
        values.removeValue(forKey: key.rawValue)
        persist()
    }

    var launchAtLogin: Bool {
        get { getBool(.launchAtLogin) }
        set { setBool(.launchAtLogin, value: newValue) }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
    }
}
