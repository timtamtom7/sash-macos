import Foundation

struct DisplayProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var screenCount: Int
    var resolutions: [String: String]
    var createdAt: Date
}

final class DisplayProfileManager {
    static let shared = DisplayProfileManager()

    private let profilesKey = "displayProfiles"

    private init() {}

    func saveProfile(name: String, resolutions: [String: String]) {
        let profile = DisplayProfile(
            id: UUID(),
            name: name,
            screenCount: resolutions.count,
            resolutions: resolutions,
            createdAt: Date()
        )

        var profiles = fetchProfiles()
        profiles.append(profile)
        saveProfiles(profiles)
    }

    func fetchProfiles() -> [DisplayProfile] {
        guard let data = UserDefaults.standard.data(forKey: profilesKey) else { return [] }
        do {
            return try JSONDecoder().decode([DisplayProfile].self, from: data)
        } catch {
            return []
        }
    }

    func deleteProfile(_ id: UUID) {
        var profiles = fetchProfiles()
        profiles.removeAll { $0.id == id }
        saveProfiles(profiles)
    }

    private func saveProfiles(_ profiles: [DisplayProfile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            UserDefaults.standard.set(data, forKey: profilesKey)
        } catch {
            print("Failed to save display profiles: \(error)")
        }
    }
}
