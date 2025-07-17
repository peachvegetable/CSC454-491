import Foundation
import Combine

@MainActor
class PulseViewModel: ObservableObject {
    @Published var todayMoodLog: SimpleMoodLog?
    @Published var currentStreak = 0
    @Published var bufferEndTime: Date?
    @Published var todaysQuest: Quest? = .sample
    @Published var showEditMood = false
    @Published var activeQuest: Quest?
    @Published var editingColor: SimpleMoodColor?
    @Published var editingEmoji: String?
    
    private let authService = ServiceContainer.shared.authService
    private let streakService = ServiceContainer.shared.streakService
    private let moodService = ServiceContainer.shared.moodService
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
    }
    
    private func loadTodayMood() {
        todayMoodLog = moodService.todaysLog
        updateBufferTime(from: todayMoodLog)
    }
    
    private func updateBufferTime(from log: SimpleMoodLog?) {
        // For now, we'll set a default buffer time
        // In a real app, this would be stored with the mood log
        bufferEndTime = nil
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
    
    func saveEditedMood() async {
        guard let color = editingColor else { return }
        
        do {
            try await moodService.save(color: color, emoji: editingEmoji)
            // Reset editing state
            editingColor = nil
            editingEmoji = nil
            showEditMood = false
        } catch {
            print("Error saving mood: \(error)")
        }
    }
}