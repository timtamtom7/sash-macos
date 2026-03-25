import Foundation

struct WindowLayout: Identifiable, Codable {
    let id: UUID
    var name: String
    var windows: [WindowInfo]
    var createdAt: Date
}

struct WindowInfo: Codable {
    let appBundleId: String
    let appName: String
    let snapPosition: String
}

final class LayoutManager {
    static let shared = LayoutManager()

    private let layoutsKey = "savedLayouts"

    private init() {}

    func saveLayout(name: String, windows: [WindowInfo]) {
        let layout = WindowLayout(
            id: UUID(),
            name: name,
            windows: windows,
            createdAt: Date()
        )

        var layouts = fetchLayouts()
        layouts.append(layout)
        saveLayouts(layouts)
    }

    func fetchLayouts() -> [WindowLayout] {
        guard let data = UserDefaults.standard.data(forKey: layoutsKey) else { return [] }
        do {
            return try JSONDecoder().decode([WindowLayout].self, from: data)
        } catch {
            return []
        }
    }

    func deleteLayout(_ id: UUID) {
        var layouts = fetchLayouts()
        layouts.removeAll { $0.id == id }
        saveLayouts(layouts)
    }

    private func saveLayouts(_ layouts: [WindowLayout]) {
        do {
            let data = try JSONEncoder().encode(layouts)
            UserDefaults.standard.set(data, forKey: layoutsKey)
        } catch {
            print("Failed to save layouts: \(error)")
        }
    }
}
