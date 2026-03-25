import Foundation

struct CustomShortcut: Identifiable, Codable {
    let id: UUID
    var keyCode: UInt16
    var modifiers: UInt
    var action: String
}

final class ShortcutManager {
    static let shared = ShortcutManager()

    private let shortcutsKey = "customShortcuts"

    private init() {}

    func fetchShortcuts() -> [CustomShortcut] {
        guard let data = UserDefaults.standard.data(forKey: shortcutsKey) else { return [] }
        do {
            return try JSONDecoder().decode([CustomShortcut].self, from: data)
        } catch {
            return []
        }
    }

    func saveShortcut(_ shortcut: CustomShortcut) {
        var shortcuts = fetchShortcuts()
        if let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            shortcuts[index] = shortcut
        } else {
            shortcuts.append(shortcut)
        }
        saveShortcuts(shortcuts)
    }

    func deleteShortcut(_ id: UUID) {
        var shortcuts = fetchShortcuts()
        shortcuts.removeAll { $0.id == id }
        saveShortcuts(shortcuts)
    }

    private func saveShortcuts(_ shortcuts: [CustomShortcut]) {
        do {
            let data = try JSONEncoder().encode(shortcuts)
            UserDefaults.standard.set(data, forKey: shortcutsKey)
        } catch {
            print("Failed to save shortcuts: \(error)")
        }
    }
}
