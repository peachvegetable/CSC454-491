import Foundation
import Combine
import RealmSwift

@MainActor
public class MockMoodService: MoodServiceProtocol {
    private var moodEntries: [MoodEntry] = []
    private let realmManager = RealmManager.shared
    
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
    
    public func save(color: SimpleMoodColor, emoji: String?, bufferMinutes: Int? = nil) async throws {
        // Create new mood log
        let moodLog = MoodLog(color: color, emoji: emoji)
        moodLog.bufferMinutes = bufferMinutes
        
        // Save to Realm for persistence
        try realmManager.save(moodLog)
        
        // Create SimpleMoodLog for immediate UI update
        let newLog = SimpleMoodLog(
            id: moodLog.id,
            userId: "current-user", // In real app, get from auth service
            date: moodLog.createdAt,
            color: color,
            emoji: emoji,
            bufferMinutes: bufferMinutes
        )
        
        // Update today's log
        _todaysLog = newLog
        
        print("Mood saved to Realm: \(color.rawValue) with emoji: \(emoji ?? "none") and buffer: \(bufferMinutes ?? 0) minutes")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    
    public func allLogs() async throws -> [SimpleMoodLog] {
        // Fetch from Realm for persistence
        let realmLogs = realmManager.fetch(MoodLog.self)
            .sorted(byKeyPath: "createdAt", ascending: false)
        
        // Convert to SimpleMoodLog
        let logs = realmLogs.map { log in
            SimpleMoodLog(
                id: log.id,
                userId: log.userId,
                date: log.createdAt,
                color: SimpleMoodColor(rawValue: log.colorName) ?? .green,
                emoji: log.emoji.isEmpty ? nil : log.emoji,
                bufferMinutes: log.bufferMinutes
            )
        }
        
        return Array(logs)
    }
    
    public func deleteLog(_ log: SimpleMoodLog) async throws {
        // Find and delete from Realm
        if let realmLog = realmManager.realm.object(ofType: MoodLog.self, forPrimaryKey: log.id) {
            try realmManager.delete(realmLog)
        }
        updateTodaysLog()
    }
    
    private func updateTodaysLog() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get the most recent log from today from Realm
        let todayLogs = realmManager.fetch(MoodLog.self)
            .filter("createdAt >= %@", today)
            .sorted(byKeyPath: "createdAt", ascending: false)
        
        if let latestLog = todayLogs.first {
            _todaysLog = SimpleMoodLog(
                id: latestLog.id,
                userId: latestLog.userId,
                date: latestLog.createdAt,
                color: SimpleMoodColor(rawValue: latestLog.colorName) ?? .green,
                emoji: latestLog.emoji.isEmpty ? nil : latestLog.emoji,
                bufferMinutes: latestLog.bufferMinutes
            )
        } else {
            _todaysLog = nil
        }
    }
}