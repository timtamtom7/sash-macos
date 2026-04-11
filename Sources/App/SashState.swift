import Foundation

@MainActor
final class SashState {
    static let shared = SashState()

    var store: SashStore?
    var presets: [SnapPreset] {
        get { store?.snapPresets ?? [] }
        set {
            store?.snapPresets = newValue
        }
    }

    private init() {}

    func configure(store: SashStore) {
        self.store = store
    }
}
