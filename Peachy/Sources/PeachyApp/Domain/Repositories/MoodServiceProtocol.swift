import Foundation

protocol MoodServiceProtocol {
    func logMood(_ entry: MoodEntry) async throws
    func getMoodHistory(for userId: String, days: Int) async throws -> [MoodEntry]
    func getLatestMood(for userId: String) async throws -> MoodEntry?
    func scheduleMoodNotification(after minutes: Int) async throws
}

protocol HobbyServiceProtocol {
    func getAvailableHobbies() async throws -> [Hobby]
    func saveUserHobbies(_ hobbies: [Hobby], for userId: String) async throws
    func generateHobbyIntro(for hobby: Hobby) async throws -> HobbyIntroCard
    func getHobbyCards(for userId: String) async throws -> [HobbyIntroCard]
    func markCardAsRead(_ cardId: String) async throws
}

protocol AIServiceProtocol {
    func generateHobbyIntro(hobby: String) async throws -> String
    func analyzeMoodPattern(_ entries: [MoodEntry]) async throws -> String
    func generateCBTTip(for mood: MoodEntry.MoodType) async throws -> String
    func detectCrisisKeywords(in text: String) async throws -> Bool
}

protocol NotificationServiceProtocol {
    func requestPermission() async throws -> Bool
    func scheduleMoodReminder(after minutes: Int) async throws
    func sendMoodUpdate(to userId: String, mood: MoodEntry) async throws
    func cancelPendingNotifications() async throws
}