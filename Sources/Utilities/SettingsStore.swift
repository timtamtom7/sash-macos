import Foundation
import SQLite

class SettingsStore {
    static let shared = SettingsStore()

    private var db: Connection?

    // Tables
    private let settings = Table("settings")
    private let keyColumn = Expression<String>("key")
    private let valueColumn = Expression<String>("value")

    // Keys
    enum SettingKey: String {
        case launchAtLogin = "launch_at_login"
        case lastSnapPosition = "last_snap_position"
        case customZones = "custom_zones"
    }

    private init() {
        setupDatabase()
    }

    // MARK: - Setup

    private func setupDatabase() {
        do {
            let path = getDBPath()
            db = try Connection(path)
            try createTables()
        } catch {
            print("Failed to setup database: \(error)")
        }
    }

    private func getDBPath() -> String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Sash", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        return appDir.appendingPathComponent("settings.sqlite3").path
    }

    private func createTables() throws {
        try db?.run(settings.create(ifNotExists: true) { t in
            t.column(keyColumn, primaryKey: true)
            t.column(valueColumn)
        })
    }

    // MARK: - CRUD

    func get(_ key: SettingKey) -> String? {
        do {
            let query = settings.filter(keyColumn == key.rawValue)
            if let row = try db?.pluck(query) {
                return row[valueColumn]
            }
        } catch {
            print("Failed to get setting: \(error)")
        }
        return nil
    }

    func set(_ key: SettingKey, value: String) {
        do {
            let insert = settings.upsert(
                keyColumn <- key.rawValue,
                valueColumn <- value,
                onConflictOf: keyColumn
            )
            try db?.run(insert)
        } catch {
            print("Failed to set setting: \(error)")
        }
    }

    func setBool(_ key: SettingKey, value: Bool) {
        set(key, value: value ? "true" : "false")
    }

    func getBool(_ key: SettingKey) -> Bool {
        return get(key) == "true"
    }

    func remove(_ key: SettingKey) {
        do {
            let query = settings.filter(keyColumn == key.rawValue)
            try db?.run(query.delete())
        } catch {
            print("Failed to remove setting: \(error)")
        }
    }

    // MARK: - Convenience

    var launchAtLogin: Bool {
        get { getBool(.launchAtLogin) }
        set { setBool(.launchAtLogin, value: newValue) }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        // Note: Actual launch at login implementation would use
        // SMAppService or LoginItems API
    }
}
