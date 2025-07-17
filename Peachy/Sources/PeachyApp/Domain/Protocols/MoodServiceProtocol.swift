import Foundation

public protocol MoodServiceProtocol {
    func logMood(_ entry: MoodEntry) async throws
    func getMoodHistory(for userId: String, days: Int) async throws -> [MoodEntry]
    func getLatestMood(for userId: String) async throws -> MoodEntry?
    func scheduleMoodNotification(after minutes: Int) async throws
    func getLatestMoodLog(for userId: String) -> MoodLog?
}