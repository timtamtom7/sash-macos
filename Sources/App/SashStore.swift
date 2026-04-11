import Foundation
import AppKit

class SashStore: ObservableObject {
    @Published var focusedAppName: String = "No focused app"
    @Published var focusedWindowTitle: String = ""
    @Published var lastSnapPosition: SnapPosition?
    @Published var lastSnapResult: SnapResult = .success(nil)
    @Published var showAccessibilityAlert: Bool = false
    @Published var launchAtLogin: Bool = false
    @Published var snapPresets: [SnapPreset] = []
    @Published var monitors: [MonitorInfo] = []

    private let windowManager = WindowManager.shared
    private let presetsKey = "sash_presets"

    init() {
        loadPresets()
        refreshMonitors()
    }

    func refreshFocusedWindow() {
        if let app = NSWorkspace.shared.frontmostApplication {
            focusedAppName = app.localizedName ?? "Unknown"
        } else {
            focusedAppName = "No focused app"
        }
    }

    func refreshMonitors() {
        monitors = MonitorManager.shared.getMonitors()
    }

    func addPreset(_ preset: SnapPreset) {
        snapPresets.append(preset)
        savePresets()
    }

    func deletePreset(_ id: UUID) {
        snapPresets.removeAll { $0.id == id }
        savePresets()
    }

    private func savePresets() {
        do {
            let data = try JSONEncoder().encode(snapPresets)
            UserDefaults.standard.set(data, forKey: presetsKey)
        } catch {
            print("Failed to save presets: \(error)")
        }
    }

    private func loadPresets() {
        guard let data = UserDefaults.standard.data(forKey: presetsKey) else { return }
        do {
            snapPresets = try JSONDecoder().decode([SnapPreset].self, from: data)
        } catch {
            print("Failed to load presets: \(error)")
        }
    }
}
