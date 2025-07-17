import Foundation

class MockMoodService: MoodServiceProtocol {
    private var moodEntries: [MoodEntry] = []
    
    init() {
        // Add some sample data
        generateSampleMoods()
    }
    
    func logMood(_ entry: MoodEntry) async throws {
        moodEntries.append(entry)
        
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func getMoodHistory(for userId: String, days: Int) async throws -> [MoodEntry] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 300_000_000)
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return moodEntries
            .filter { $0.userId == userId && $0.createdAt >= startDate }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    func getLatestMood(for userId: String) async throws -> MoodEntry? {
        return moodEntries
            .filter { $0.userId == userId }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    func scheduleMoodNotification(after minutes: Int) async throws {
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

class MockHobbyService: HobbyServiceProtocol {
    private var userHobbies: [String: [Hobby]] = [:]
    private var hobbyCards: [HobbyIntroCard] = []
    
    func getAvailableHobbies() async throws -> [Hobby] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 200_000_000)
        return HobbyPreset.presets
    }
    
    func saveUserHobbies(_ hobbies: [Hobby], for userId: String) async throws {
        userHobbies[userId] = hobbies
        try await Task.sleep(nanoseconds: 300_000_000)
    }
    
    func generateHobbyIntro(for hobby: Hobby) async throws -> HobbyIntroCard {
        // Simulate AI generation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let introText = "Discover the exciting world of \(hobby.name)! This engaging activity offers endless opportunities for creativity and self-expression. Whether you're a beginner or looking to enhance your skills, \(hobby.name) provides a perfect outlet for passion and growth. Join millions who find joy in this rewarding pursuit."
        
        let card = HobbyIntroCard(
            id: UUID().uuidString,
            hobbyId: hobby.id,
            userId: "current-user",
            title: "Explore \(hobby.name)",
            introText: introText,
            learnMoreUrl: "https://example.com/hobbies/\(hobby.name.lowercased())",
            createdAt: Date()
        )
        
        hobbyCards.append(card)
        return card
    }
    
    func getHobbyCards(for userId: String) async throws -> [HobbyIntroCard] {
        return hobbyCards.filter { $0.userId == userId }
    }
    
    func markCardAsRead(_ cardId: String) async throws {
        if let index = hobbyCards.firstIndex(where: { $0.id == cardId }) {
            hobbyCards[index].isRead = true
        }
    }
}

class MockAIService: AIServiceProtocol {
    func generateHobbyIntro(hobby: String) async throws -> String {
        // Simulate AI processing time
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        return "Discover the amazing world of \(hobby)! This activity combines creativity with skill-building, offering both personal growth and enjoyment. Perfect for teens looking to explore new interests, \(hobby) provides opportunities to connect with like-minded peers while developing valuable abilities that last a lifetime."
    }
    
    func analyzeMoodPattern(_ entries: [MoodEntry]) async throws -> String {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return "Your mood patterns show a healthy variety of emotions. You tend to feel most positive in the mornings and experience some natural energy dips in the afternoon. Consider scheduling important activities during your peak mood times."
    }
    
    func generateCBTTip(for mood: MoodEntry.MoodType) async throws -> String {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        switch mood {
        case .anxious:
            return "Try the 5-4-3-2-1 grounding technique: Name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, and 1 you can taste."
        case .sad:
            return "Remember that feelings are temporary. Consider writing down three things you're grateful for today, no matter how small."
        case .angry:
            return "Take slow, deep breaths. Count to 10 before responding. Physical activity can help release tension safely."
        default:
            return "Keep nurturing positive emotions through activities you enjoy and connections with people who support you."
        }
    }
    
    func detectCrisisKeywords(in text: String) async throws -> Bool {
        // Simplified keyword detection - real implementation would be more sophisticated
        let crisisKeywords = ["harm", "hurt", "suicide", "die", "kill", "end it"]
        let lowercasedText = text.lowercased()
        
        return crisisKeywords.contains { keyword in
            lowercasedText.contains(keyword)
        }
    }
}

class MockNotificationService: NotificationServiceProtocol {
    private var hasPermission = false
    
    func requestPermission() async throws -> Bool {
        // Simulate permission request
        try await Task.sleep(nanoseconds: 500_000_000)
        hasPermission = true
        return true
    }
    
    func scheduleMoodReminder(after minutes: Int) async throws {
        guard hasPermission else {
            _ = try await requestPermission()
            return
        }
        
        print("Scheduled mood reminder after \(minutes) minutes")
    }
    
    func sendMoodUpdate(to userId: String, mood: MoodEntry) async throws {
        print("Sent mood update to user \(userId): \(mood.moodType.emoji)")
    }
    
    func cancelPendingNotifications() async throws {
        print("Cancelled all pending notifications")
    }
}