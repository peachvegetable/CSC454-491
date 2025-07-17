import Foundation

public protocol NotificationServiceProtocol {
    func requestPermission() async throws -> Bool
    func scheduleMoodReminder(after minutes: Int) async throws
    func sendMoodUpdate(to userId: String, mood: MoodEntry) async throws
    func cancelPendingNotifications() async throws
}