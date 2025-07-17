import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var todayMoodCount = 0
    
    private let authService = ServiceContainer.shared.authService
    private let realmManager = RealmManager.shared
    
    init() {
        loadTodayMoodCount()
    }
    
    func saveMood(_ mood: MoodColor, emoji: String?) async {
        guard let user = authService.currentUser else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let moodLog = MoodLog()
        moodLog.userId = user.id
        moodLog.colorHex = mood.hex
        moodLog.moodLabel = mood.rawValue
        moodLog.emoji = emoji
        
        do {
            try realmManager.save(moodLog)
            todayMoodCount += 1
        } catch {
            print("Error saving mood: \(error)")
        }
    }
    
    private func loadTodayMoodCount() {
        guard let user = authService.currentUser else { return }
        
        Task { @MainActor in
            let count = await ServiceContainer.shared.streakService.getTodayMoodCount(for: user.id)
            todayMoodCount = count
        }
    }
}