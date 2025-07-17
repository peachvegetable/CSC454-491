import Foundation
import Combine

@MainActor
public protocol MoodServiceProtocol {
    var todaysLog: SimpleMoodLog? { get }
    var todaysLogPublisher: AnyPublisher<SimpleMoodLog?, Never> { get }
    
    func save(color: SimpleMoodColor, emoji: String?) async throws
    func allLogs() async throws -> [SimpleMoodLog]
    func deleteLog(_ log: SimpleMoodLog) async throws
    
    // Legacy methods - keep for compatibility
    func logMood(_ entry: MoodEntry) async throws
    func getMoodHistory(for userId: String, days: Int) async throws -> [MoodEntry]
    func getLatestMood(for userId: String) async throws -> MoodEntry?
    func scheduleMoodNotification(after minutes: Int) async throws
    func getLatestMoodLog(for userId: String) -> MoodLog?
}