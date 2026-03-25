import Foundation

struct WindowHistory: Codable {
    var entries: [WindowHistoryEntry]
}

struct WindowHistoryEntry: Identifiable, Codable {
    let id: UUID
    let windowId: Int
    let appName: String
    let appBundleId: String
    let snapPosition: String
    let timestamp: Date
}

final class WindowHistoryManager {
    static let shared = WindowHistoryManager()

    private let historyKey = "windowHistory"
    private let maxEntries = 100

    private init() {}

    func recordSnap(windowId: Int, appName: String, appBundleId: String, position: String) {
        let entry = WindowHistoryEntry(
            id: UUID(),
            windowId: windowId,
            appName: appName,
            appBundleId: appBundleId,
            snapPosition: position,
            timestamp: Date()
        )

        var history = fetchHistory()
        history.append(entry)

        if history.count > maxEntries {
            history = Array(history.suffix(maxEntries))
        }

        saveHistory(history)
    }

    func fetchHistory() -> [WindowHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([WindowHistoryEntry].self, from: data)
        } catch {
            return []
        }
    }

    func getLastPosition(for appBundleId: String) -> String? {
        fetchHistory()
            .filter { $0.appBundleId == appBundleId }
            .last?
            .snapPosition
    }

    private func saveHistory(_ history: [WindowHistoryEntry]) {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save window history: \(error)")
        }
    }
}
