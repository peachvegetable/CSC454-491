import Foundation

public final class MockAIService: AIServiceProtocol {
    public init() {}
    
    public func generateHobbyIntro(hobby: String) async throws -> String {
        // Mock implementation
        return "Discover the joy of \(hobby)! This activity offers a great way to express yourself and connect with others who share your interests."
    }
    
    public func analyzeMoodPattern(_ entries: [MoodEntry]) async throws -> String {
        return "Your mood pattern shows consistency."
    }
    
    public func generateCBTTip(for mood: MoodEntry.MoodType) async throws -> String {
        return "Take a moment to reflect on your thoughts."
    }
    
    public func detectCrisisKeywords(in text: String) async throws -> Bool {
        return false
    }
}