import Foundation

public class MockMoodService: MoodServiceProtocol {
    private var moodEntries: [MoodEntry] = []
    
    public init() {
        // Add some sample data
        generateSampleMoods()
    }
    
    public func logMood(_ entry: MoodEntry) async throws {
        moodEntries.append(entry)
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    public func getMoodHistory(for userId: String, days: Int) async throws -> [MoodEntry] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return moodEntries
            .filter { $0.userId == userId && $0.createdAt >= startDate }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    public func getLatestMood(for userId: String) async throws -> MoodEntry? {
        return moodEntries
            .filter { $0.userId == userId }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    public func scheduleMoodNotification(after minutes: Int) async throws {
        // Mock implementation - would use UNUserNotificationCenter in real app
        print("Scheduled mood notification after \(minutes) minutes")
    }
    
    private func generateSampleMoods() {
        let userId = "sample-user"
        let moods: [MoodEntry.MoodType] = [.happy, .calm, .excited, .tired, .anxious]
        
        for i in 0..<10 {
            let mood = MoodEntry(
                id: UUID().uuidString,
                userId: userId,
                moodType: moods.randomElement()!,
                intensity: Double.random(in: 0.5...1.0),
                bufferMinutes: [15, 30, 45, 60].randomElement()!,
                createdAt: Date().addingTimeInterval(TimeInterval(-i * 86400)),
                sentAt: Date().addingTimeInterval(TimeInterval(-i * 86400 + 1800))
            )
            moodEntries.append(mood)
        }
    }
}