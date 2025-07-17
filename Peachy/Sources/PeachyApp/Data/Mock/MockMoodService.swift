import Foundation
import Combine

@MainActor
public class MockMoodService: MoodServiceProtocol {
    private var moodEntries: [MoodEntry] = []
    private var simpleLogs: [SimpleMoodLog] = []
    
    @Published private var _todaysLog: SimpleMoodLog?
    public var todaysLog: SimpleMoodLog? { _todaysLog }
    public var todaysLogPublisher: AnyPublisher<SimpleMoodLog?, Never> {
        $_todaysLog.eraseToAnyPublisher()
    }
    
    public init() {
        // Add some sample data
        generateSampleMoods()
        updateTodaysLog()
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
    
    public func getLatestMoodLog(for userId: String) -> MoodLog? {
        let predicate = NSPredicate(format: "userId == %@", userId)
        return RealmManager.shared.fetch(MoodLog.self, predicate: predicate)
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first
    }
    
    // MARK: - New SimpleMoodLog methods
    
    public func save(color: SimpleMoodColor, emoji: String?) async throws {
        // Always append a new log entry
        let newLog = SimpleMoodLog(
            date: Date(),
            color: color,
            emoji: emoji
        )
        simpleLogs.append(newLog)
        
        // Sort logs by date (newest first)
        simpleLogs.sort { $0.date > $1.date }
        
        // Update today's log to the most recent one
        updateTodaysLog()
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    
    public func allLogs() async throws -> [SimpleMoodLog] {
        // Return logs sorted by date (newest first)
        return simpleLogs.sorted { $0.date > $1.date }
    }
    
    public func deleteLog(_ log: SimpleMoodLog) async throws {
        simpleLogs.removeAll { $0.id == log.id }
        updateTodaysLog()
    }
    
    private func updateTodaysLog() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get the most recent log from today
        _todaysLog = simpleLogs
            .filter { log in calendar.isDate(log.date, inSameDayAs: today) }
            .sorted { $0.date > $1.date }
            .first
    }
}