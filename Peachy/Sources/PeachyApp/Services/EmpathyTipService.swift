import Foundation
import RealmSwift
import Combine

@MainActor
public class EmpathyTipService: ObservableObject {
    @Published public var activeTips: [EmpathyTip] = []
    @Published public var recentDeliveries: [TipDelivery] = []
    @Published public var pendingNotifications: [EmpathyNotification] = []
    @Published public var currentChildMoodPatterns: [String: MoodPattern] = [:]  // childId: pattern
    
    private let realmManager = RealmManager.shared
    private var moodService: MoodServiceProtocol?
    private var authService: AuthServiceProtocol?
    private var subscriptionService: SubscriptionService?
    private var notificationTokens: [NotificationToken] = []
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Services will be injected via setter
    }
    
    deinit {
        notificationTokens.forEach { $0.invalidate() }
    }
    
    // MARK: - Service Injection
    
    public func setServices(
        moodService: MoodServiceProtocol,
        authService: AuthServiceProtocol,
        subscriptionService: SubscriptionService
    ) {
        self.moodService = moodService
        self.authService = authService
        self.subscriptionService = subscriptionService
    }
    
    // MARK: - Initialization
    
    public func initialize() {
        loadDefaultTipsIfNeeded()
        observeMoodChanges()
        loadRecentDeliveries()
    }
    
    private func loadDefaultTipsIfNeeded() {
        let tips = realmManager.fetch(EmpathyTip.self)
        
        if tips.isEmpty {
            // Load default support insights
            let defaultTips = EmpathyTipFactory.createDefaultInsights()
            for tip in defaultTips {
                do {
                    try realmManager.save(tip)
                } catch {
                    print("Error saving default tip: \(error)")
                }
            }
        }
        
        activeTips = Array(realmManager.fetch(EmpathyTip.self).filter("isActive == true"))
    }
    
    // MARK: - Mood Pattern Detection
    
    private func observeMoodChanges() {
        guard let moodService = moodService else { return }
        
        // Subscribe to mood updates if available
        if let mockMoodService = moodService as? MockMoodService {
            mockMoodService.todaysLogPublisher
                .sink { [weak self] _ in
                    self?.checkForMoodPatterns()
                }
                .store(in: &cancellables)
        }
    }
    
    private func checkForMoodPatterns() {
        guard let currentUser = authService?.currentUser,
              currentUser.userRole == .admin else { return }
        
        // Get family members who are children (non-admins)
        let familyMembers = getFamilyMembers()
        
        for member in familyMembers where member.userRole == .user {
            if let pattern = detectMoodPattern(for: member) {
                currentChildMoodPatterns[member.id] = pattern
                generateAndDeliverTip(for: member, pattern: pattern)
            }
        }
    }
    
    private func detectMoodPattern(for child: UserProfile) -> MoodPattern? {
        let recentLogs = getMoodLogs(for: child.id, days: 7)
        guard !recentLogs.isEmpty else { return nil }
        
        let now = Date()
        let todayLogs = recentLogs.filter { Calendar.current.isDateInToday($0.date) }
        
        // Check for multiple bad moods today
        let negativeTodayCount = todayLogs.filter { mood in
            mood.color == SimpleMoodColor.red
        }.count
        
        if negativeTodayCount >= 2 {
            return .multipleBad
        }
        
        // Check for late night mood
        if let latestLog = todayLogs.first {
            let hour = Calendar.current.component(.hour, from: latestLog.date)
            if hour >= 22 || hour <= 2 {
                if latestLog.color == SimpleMoodColor.red || latestLog.color == SimpleMoodColor.yellow {
                    return .lateNight
                }
            }
        }
        
        // Check for sudden drop
        if recentLogs.count >= 2 {
            let previousMood = recentLogs[1].color
            let currentMood = recentLogs[0].color
            
            if isPositiveMood(previousMood) && isNegativeMood(currentMood) {
                return .suddenDrop
            }
        }
        
        // Check for prolonged low mood (3+ days)
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now
        let recentNegativeCount = recentLogs.filter { log in
            log.date >= threeDaysAgo && isNegativeMood(log.color)
        }.count
        
        if recentNegativeCount >= 3 {
            return .prolongedLow
        }
        
        // Check for first negative after positive streak
        let positiveStreak = recentLogs.dropFirst().prefix(5).allSatisfy { isPositiveMood($0.color) }
        if positiveStreak && !recentLogs.isEmpty && isNegativeMood(recentLogs[0].color) {
            return .firstNegative
        }
        
        return nil
    }
    
    // MARK: - Tip Generation
    
    public func generateAndDeliverTip(for child: UserProfile, pattern: MoodPattern) {
        // Check if we've already sent a tip recently (within 2 hours)
        let twoHoursAgo = Date().addingTimeInterval(-7200)
        let recentDelivery = realmManager.fetch(TipDelivery.self)
            .filter("childUserId == %@ AND deliveredAt > %@", child.id, twoHoursAgo)
            .first
        
        if recentDelivery != nil {
            return // Don't spam parents with tips
        }
        
        // Find appropriate tips
        let appropriateTips = findAppropriateTips(
            for: child,
            pattern: pattern,
            moodColor: getMostRecentMood(for: child.id)?.color
        )
        
        guard let selectedTip = appropriateTips.first else { return }
        
        // Create delivery record
        let delivery = TipDelivery()
        delivery.tipId = selectedTip.id
        delivery.parentUserId = authService?.currentUser?.id ?? ""
        delivery.childUserId = child.id
        delivery.childName = child.displayName
        delivery.patternRaw = pattern.rawValue
        delivery.moodBeforeRaw = getMostRecentMood(for: child.id)?.color.rawValue
        
        do {
            try realmManager.save(delivery)
            
            // Schedule notification
            scheduleNotification(for: selectedTip, delivery: delivery, child: child, pattern: pattern)
            
        } catch {
            print("Error delivering tip: \(error)")
        }
    }
    
    private func findAppropriateTips(
        for child: UserProfile,
        pattern: MoodPattern,
        moodColor: SimpleMoodColor?
    ) -> [EmpathyTip] {
        // Default to teen age since we don't track birthdate
        let childAge = 14
        
        return activeTips.filter { tip in
            // Check age range
            guard let ageRange = tip.ageRange,
                  ageRange.includes(age: childAge) else { return false }
            
            // Check if pattern matches
            if tip.triggerPatterns.contains(pattern.rawValue) {
                return true
            }
            
            // Check if mood color matches
            if let color = moodColor,
               tip.triggerColors.contains(color.rawValue) {
                return true
            }
            
            return false
        }.sorted { tip1, tip2 in
            // Prioritize by urgency
            let urgency1 = tip1.urgency ?? .awareness
            let urgency2 = tip2.urgency ?? .awareness
            
            if urgency1 == .immediate && urgency2 != .immediate { return true }
            if urgency1 == .soon && urgency2 == .awareness { return true }
            
            return false
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleNotification(
        for tip: EmpathyTip,
        delivery: TipDelivery,
        child: UserProfile,
        pattern: MoodPattern
    ) {
        let notification = EmpathyNotification()
        notification.tipDeliveryId = delivery.id
        notification.childName = child.displayName
        notification.moodContext = pattern.description
        notification.primaryTip = tip.content
        notification.urgencyRaw = tip.urgencyRaw
        
        // Add additional tips if available
        if !tip.examplePhrases.isEmpty {
            notification.additionalTips.append(objectsIn: Array(tip.examplePhrases.prefix(3)))
        }
        
        // Schedule based on urgency
        let delay = tip.urgency?.notificationDelay ?? 0
        notification.scheduledFor = Date().addingTimeInterval(delay)
        
        do {
            try realmManager.save(notification)
            
            // In a real app, this would schedule a local notification
            // For now, just update the pending list
            loadPendingNotifications()
            
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    // MARK: - Tip Effectiveness
    
    public func markTipAsViewed(_ deliveryId: ObjectId) {
        guard let delivery = realmManager.realm.object(ofType: TipDelivery.self, forPrimaryKey: deliveryId) else { return }
        
        do {
            try realmManager.realm.write {
                delivery.viewedAt = Date()
            }
        } catch {
            print("Error marking tip as viewed: \(error)")
        }
    }
    
    public func recordTipFeedback(_ deliveryId: ObjectId, wasHelpful: Bool, notes: String? = nil) {
        guard let delivery = realmManager.realm.object(ofType: TipDelivery.self, forPrimaryKey: deliveryId) else { return }
        
        do {
            try realmManager.realm.write {
                delivery.wasHelpful = wasHelpful
                delivery.parentNotes = notes
                
                // Check if child's mood improved
                if let childId = delivery.childUserId as String? {
                    if let recentMood = getMostRecentMood(for: childId) {
                        delivery.moodAfterRaw = recentMood.color.rawValue
                    }
                }
            }
        } catch {
            print("Error recording feedback: \(error)")
        }
    }
    
    // MARK: - Data Loading
    
    private func loadRecentDeliveries() {
        guard let userId = authService?.currentUser?.id else { return }
        
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let deliveries = realmManager.fetch(TipDelivery.self)
            .filter("parentUserId == %@ AND deliveredAt > %@", userId, oneWeekAgo)
            .sorted(byKeyPath: "deliveredAt", ascending: false)
        
        recentDeliveries = Array(deliveries)
    }
    
    private func loadPendingNotifications() {
        let pending = realmManager.fetch(EmpathyNotification.self)
            .filter("sentAt == nil AND scheduledFor <= %@", Date().addingTimeInterval(3600))
            .sorted(byKeyPath: "scheduledFor", ascending: true)
        
        pendingNotifications = Array(pending)
    }
    
    // MARK: - Helper Methods
    
    private func getFamilyMembers() -> [UserProfile] {
        guard let currentUser = authService?.currentUser,
              let pairedId = currentUser.pairedWithUserId else { return [] }
        
        // Get paired user
        if let pairedUser = realmManager.realm.object(ofType: UserProfile.self, forPrimaryKey: pairedId) {
            return [pairedUser]
        }
        
        return []
    }
    
    private func getMoodLogs(for userId: String, days: Int) -> [SimpleMoodLog] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let logs = realmManager.fetch(MoodLog.self)
            .filter("userId == %@ AND createdAt >= %@", userId, startDate)
            .sorted(byKeyPath: "createdAt", ascending: false)
        
        // Convert MoodLog to SimpleMoodLog
        return logs.compactMap { log in
            guard let color = SimpleMoodColor(rawValue: log.colorName) else { return nil }
            return SimpleMoodLog(
                id: log.id,
                userId: log.userId,
                date: log.createdAt,
                color: color,
                emoji: log.emoji.isEmpty ? nil : log.emoji,
                bufferMinutes: log.bufferMinutes
            )
        }
    }
    
    private func getMostRecentMood(for userId: String) -> SimpleMoodLog? {
        guard let log = realmManager.fetch(MoodLog.self)
            .filter("userId == %@", userId)
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first,
              let color = SimpleMoodColor(rawValue: log.colorName) else { return nil }
        
        return SimpleMoodLog(
            id: log.id,
            userId: log.userId,
            date: log.createdAt,
            color: color,
            emoji: log.emoji.isEmpty ? nil : log.emoji,
            bufferMinutes: log.bufferMinutes
        )
    }
    
    private func isPositiveMood(_ color: SimpleMoodColor) -> Bool {
        return color == .green
    }
    
    private func isNegativeMood(_ color: SimpleMoodColor) -> Bool {
        return color == .red
    }
    
    // Age calculation removed - using default age since UserProfile doesn't have birthDate
    
    // MARK: - Feature Access Check
    
    public func isFeatureAvailable() -> Bool {
        // Check if user has Peachy Plus subscription
        guard let subscription = subscriptionService else { return false }
        
        // This is a premium feature, part of Peachy Plus
        return subscription.currentSubscription?.hasActiveSubscription(for: .peachyPlus) ?? false ||
               subscription.currentSubscription?.isTestMode ?? false
    }
}