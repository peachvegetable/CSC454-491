import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let role: UserRole
    let createdAt: Date
    var profile: UserProfile?
    var circleId: String?
    
    enum UserRole: String, Codable, CaseIterable {
        case teen
        case parent
    }
}

struct UserProfile: Codable {
    var displayName: String
    var avatarEmoji: String
    var hobbies: [String]
    var preferences: UserPreferences
    
    init(displayName: String = "", avatarEmoji: String = "🙂", hobbies: [String] = [], preferences: UserPreferences = UserPreferences()) {
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.hobbies = hobbies
        self.preferences = preferences
    }
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool = true
    var defaultBufferMinutes: Int = 30
    var darkModeEnabled: Bool = false
    var hapticFeedbackEnabled: Bool = true
}

struct FamilyCircle: Identifiable, Codable {
    let id: String
    let code: String
    let parentId: String
    let teenId: String?
    let createdAt: Date
    var isActive: Bool
}