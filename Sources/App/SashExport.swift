import Foundation

struct SashExport: Codable {
    let version: String
    let exportDate: Date
    let layouts: [WindowLayout]
    let shortcuts: [CustomShortcut]
}

final class SashExportManager {
    static let shared = SashExportManager()

    private init() {}

    func exportAll() -> Data? {
        let export = SashExport(
            version: "R10",
            exportDate: Date(),
            layouts: LayoutManager.shared.fetchLayouts(),
            shortcuts: ShortcutManager.shared.fetchShortcuts()
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(export)
        } catch {
            print("Failed to encode export: \(error)")
            return nil
        }
    }

    func importFrom(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(SashExport.self, from: data)

            // Import layouts
            for layout in export.layouts {
                LayoutManager.shared.saveLayout(name: layout.name, windows: layout.windows)
            }

            // Import shortcuts
            for shortcut in export.shortcuts {
                ShortcutManager.shared.saveShortcut(shortcut)
            }

            return true
        } catch {
            print("Failed to import: \(error)")
            return false
        }
    }

    func saveExportToFile() -> URL? {
        guard let data = exportAll() else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "Sash-Backup-\(dateFormatter.string(from: Date())).json"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write export file: \(error)")
            return nil
        }
    }
}
