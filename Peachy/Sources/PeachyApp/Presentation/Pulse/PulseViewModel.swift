import Foundation
import Combine

@MainActor
class PulseViewModel: ObservableObject {
    @Published var todayMoodLog: SimpleMoodLog?
    @Published var currentStreak = 0
    @Published var bufferEndTime: Date?
    @Published var todaysQuest: Quest? = .sample
    @Published var isQuestCompleted = false
    @Published var showEditMood = false
    @Published var activeQuest: Quest?
    @Published var editingColor: SimpleMoodColor?
    @Published var editingEmoji: String?
    @Published var familyMemberStatuses: [FamilyMemberStatus] = []
    @Published var showShareHobby = false
    @Published var showFlashCards = false
    @Published var currentUserName: String = ""
    @Published var totalPoints: Int = 0
    
    private let authService = ServiceContainer.shared.authService
    private let streakService = ServiceContainer.shared.streakService
    private let moodService = ServiceContainer.shared.moodService
    private let questService = ServiceContainer.shared.questService
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to mood service updates
        moodService.todaysLogPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] log in
                self?.todayMoodLog = log
                self?.updateBufferTime(from: log)
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        loadTodayMood()
        loadStreak()
        loadFamilyMemberStatuses()
        loadUserInfo()
        Task {
            await loadTodaysQuest()
        }
    }
    
    private func loadUserInfo() {
        if let user = authService.currentUser {
            currentUserName = user.displayName
            // Load points from unified points service
            UnifiedPointsService.shared.loadUserPoints(for: user.id)
            totalPoints = UnifiedPointsService.shared.currentUserPoints
            
            // Subscribe to point changes
            UnifiedPointsService.shared.$currentUserPoints
                .receive(on: DispatchQueue.main)
                .sink { [weak self] points in
                    self?.totalPoints = points
                }
                .store(in: &cancellables)
        }
    }
    
    private func loadTodayMood() {
        todayMoodLog = moodService.todaysLog
        updateBufferTime(from: todayMoodLog)
    }
    
    private func updateBufferTime(from log: SimpleMoodLog?) {
        guard let log = log,
              let bufferMinutes = log.bufferMinutes,
              bufferMinutes > 0 else {
            bufferEndTime = nil
            return
        }
        
        // Calculate buffer end time
        let bufferSeconds = TimeInterval(bufferMinutes * 60)
        let endTime = log.date.addingTimeInterval(bufferSeconds)
        
        // Only show buffer if it hasn't expired yet
        if endTime > Date() {
            bufferEndTime = endTime
        } else {
            bufferEndTime = nil
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
    
    func refreshQuestStatus() {
        Task {
            await loadTodaysQuest()
        }
    }
    
    func saveEditedMood() async {
        guard let color = editingColor else { return }
        
        do {
            try await moodService.save(color: color, emoji: editingEmoji, bufferMinutes: nil)
            // Reset editing state
            editingColor = nil
            editingEmoji = nil
            showEditMood = false
        } catch {
            print("Error saving mood: \(error)")
        }
    }
    
    private func loadTodaysQuest() async {
        todaysQuest = await questService.getTodaysQuest()
        if let quest = todaysQuest {
            isQuestCompleted = await questService.isQuestCompleted(quest)
        }
    }
    
    private func loadFamilyMemberStatuses() {
        // Mock data for now - in production this would come from a service
        // that fetches family members and their latest mood logs
        familyMemberStatuses = [
            FamilyMemberStatus(
                name: "Mom",
                initial: "M",
                simpleMoodColor: .green,
                lastUpdate: Date().addingTimeInterval(-1800) // 30 minutes ago
            ),
            FamilyMemberStatus(
                name: "Dad",
                initial: "D",
                simpleMoodColor: .red,
                lastUpdate: Date().addingTimeInterval(-7200) // 2 hours ago
            ),
            FamilyMemberStatus(
                name: "Sister",
                initial: "S",
                simpleMoodColor: .yellow,
                lastUpdate: Date().addingTimeInterval(-172800) // 2 days ago
            )
        ]
    }
}