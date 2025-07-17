import Foundation

public class MockStreakService: StreakServiceProtocol {
    private let realmManager = RealmManager.shared
    
    public init() {}
    
    public func calculateStreak(for userId: String) async -> Int {
        return await MainActor.run {
            let predicate = NSPredicate(format: "userId == %@", userId)
            let moodLogs = realmManager.fetch(MoodLog.self, predicate: predicate)
                .sorted(byKeyPath: "createdAt", ascending: false)
            
            guard !moodLogs.isEmpty else { return 0 }
            
            var streak = 0
            var currentDate = Date()
            let calendar = Calendar.current
            
            for log in moodLogs {
                let logDate = calendar.startOfDay(for: log.createdAt)
                let checkDate = calendar.startOfDay(for: currentDate)
                
                if logDate == checkDate {
                    streak += 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                } else if logDate < checkDate {
                    break
                }
            }
            
            return streak
        }
    }
    
    public func getTodayMoodCount(for userId: String) async -> Int {
        return await MainActor.run {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            let predicate = NSPredicate(format: "userId == %@ AND createdAt >= %@ AND createdAt < %@", 
                                      userId, startOfDay as NSDate, endOfDay as NSDate)
            
            return realmManager.fetch(MoodLog.self, predicate: predicate).count
        }
    }
}