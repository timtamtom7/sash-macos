import Foundation

struct SnapPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var positions: [PresetPosition]

    struct PresetPosition: Codable {
        var bundleIdentifier: String
        var snapPosition: String
    }

    init(id: UUID = UUID(), name: String, positions: [PresetPosition] = []) {
        self.id = id
        self.name = name
        self.positions = positions
    }
}
