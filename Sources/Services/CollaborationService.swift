import Foundation

// MARK: - Sash R12: Collaboration & Team Sync

/// Service for managing team shared folders and collaboration features
final class CollaborationService: ObservableObject {
    static let shared = CollaborationService()

    @Published var teamFolders: [TeamFolder] = []
    @Published var activityFeed: [ActivityItem] = []
    @Published var guestAccesses: [GuestAccess] = []
    @Published var fileLocks: [FileLock] = []

    private init() {
        loadState()
    }

    // MARK: - Team Folders

    func createTeamFolder(name: String, admin: TeamMember) -> TeamFolder {
        let folder = TeamFolder(
            id: UUID(),
            name: name,
            members: [admin],
            permissions: [:],
            createdAt: Date()
        )
        teamFolders.append(folder)
        saveState()
        return folder
    }

    func inviteMember(to folder: UUID, email: String, role: TeamRole) {
        guard let idx = teamFolders.firstIndex(where: { $0.id == folder }) else { return }
        let member = TeamMember(id: UUID(), name: email, email: email, role: role)
        teamFolders[idx].members.append(member)
        saveState()
    }

    func setPermission(folder: UUID, member: UUID, permission: FolderPermission) {
        guard let idx = teamFolders.firstIndex(where: { $0.id == folder }) else { return }
        teamFolders[idx].permissions[member] = permission
        saveState()
    }

    // MARK: - Guest Access

    func createGuestAccess(folder: UUID, email: String, accessLevel: GuestAccessLevel, daysValid: Int) -> GuestAccess {
        let guest = GuestAccess(
            id: UUID(),
            folderId: folder,
            email: email,
            accessLevel: accessLevel,
            expiresAt: Calendar.current.date(byAdding: .day, value: daysValid, to: Date()),
            createdAt: Date()
        )
        guestAccesses.append(guest)
        saveState()
        return guest
    }

    // MARK: - File Locking

    func lockFile(path: String, by user: String) -> FileLock? {
        guard !fileLocks.contains(where: { $0.path == path && !$0.isExpired }) else { return nil }
        let lock = FileLock(id: UUID(), path: path, lockedBy: user, lockedAt: Date())
        fileLocks.append(lock)
        saveState()
        return lock
    }

    func unlockFile(path: String) {
        fileLocks.removeAll { $0.path == path }
        saveState()
    }

    // MARK: - Activity Feed

    func logActivity(type: ActivityType, folderId: UUID, user: String, detail: String) {
        let item = ActivityItem(id: UUID(), type: type, folderId: folderId, user: user, detail: detail, timestamp: Date())
        activityFeed.insert(item, at: 0)
        saveState()
    }

    // MARK: - Persistence

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sash/collaboration.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = CollaborationState(teamFolders: teamFolders, activityFeed: activityFeed, guestAccesses: guestAccesses, fileLocks: fileLocks)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(CollaborationState.self, from: data) else { return }
        teamFolders = state.teamFolders
        activityFeed = state.activityFeed
        guestAccesses = state.guestAccesses
        fileLocks = state.fileLocks
    }
}

// MARK: - Models

struct TeamFolder: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [TeamMember]
    var permissions: [UUID: FolderPermission]
    var createdAt: Date
}

struct TeamMember: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var role: TeamRole
}

enum TeamRole: String, Codable {
    case admin, editor, viewer
}

enum FolderPermission: String, Codable {
    case read, write, admin
}

struct GuestAccess: Identifiable, Codable {
    let id: UUID
    let folderId: UUID
    var email: String
    var accessLevel: GuestAccessLevel
    var expiresAt: Date?
    var createdAt: Date
}

enum GuestAccessLevel: String, Codable {
    case readOnly, contributor
}

struct FileLock: Identifiable, Codable {
    let id: UUID
    let path: String
    let lockedBy: String
    let lockedAt: Date

    var isExpired: Bool {
        lockedAt + 3600 < Date() // auto-unlock after 1 hour
    }
}

struct ActivityItem: Identifiable, Codable {
    let id: UUID
    let type: ActivityType
    let folderId: UUID
    let user: String
    let detail: String
    let timestamp: Date
}

enum ActivityType: String, Codable {
    case fileChanged, fileShared, memberInvited, guestAccessed, conflictDetected, lockAcquired
}

struct CollaborationState: Codable {
    var teamFolders: [TeamFolder]
    var activityFeed: [ActivityItem]
    var guestAccesses: [GuestAccess]
    var fileLocks: [FileLock]
}
