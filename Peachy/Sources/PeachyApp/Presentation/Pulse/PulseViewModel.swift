import Foundation

@MainActor
class PulseViewModel: ObservableObject {
    @Published var todayMoodLog: MoodLog?
    @Published var currentStreak = 0
    @Published var bufferEndTime: Date?
    @Published var todaysQuest: Quest? = .sample
    @Published var showEditMood = false
    @Published var activeQuest: Quest?
    
    private let authService = ServiceContainer.shared.authService
    private let streakService = ServiceContainer.shared.streakService
    private let realmManager = RealmManager.shared
    
    func loadData() {
        loadTodayMood()
        loadStreak()
    }
    
    private func loadTodayMood() {
        guard let userId = authService.currentUser?.id else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = NSPredicate(
            format: "userId == %@ AND createdAt >= %@ AND createdAt < %@",
            userId, startOfDay as NSDate, endOfDay as NSDate
        )
        
        todayMoodLog = realmManager.fetch(MoodLog.self, predicate: predicate)
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first
        
        // Check for active buffer
        if let log = todayMoodLog,
           let bufferMinutes = log.bufferMinutes,
           bufferMinutes > 0 {
            let bufferEnd = log.createdAt.addingTimeInterval(TimeInterval(bufferMinutes * 60))
            if bufferEnd > Date() {
                bufferEndTime = bufferEnd
            }
        }
    }
    
    private func loadStreak() {
        guard let userId = authService.currentUser?.id else { return }
        
        Task {
            currentStreak = await streakService.calculateStreak(for: userId)
        }
    }
    
    func showQuest(_ quest: Quest) {
        activeQuest = quest
    }
}