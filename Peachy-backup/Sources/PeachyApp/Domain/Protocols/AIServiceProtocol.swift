import Foundation

public protocol AIServiceProtocol {
    func generateHobbyIntro(hobby: String) async throws -> String
    func analyzeMoodPattern(_ entries: [MoodEntry]) async throws -> String
    func generateCBTTip(for mood: MoodEntry.MoodType) async throws -> String
    func detectCrisisKeywords(in text: String) async throws -> Bool
}