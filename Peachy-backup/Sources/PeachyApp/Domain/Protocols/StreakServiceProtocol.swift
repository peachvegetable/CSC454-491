import Foundation

public protocol StreakServiceProtocol {
    func calculateStreak(for userId: String) async -> Int
    func getTodayMoodCount(for userId: String) async -> Int
}