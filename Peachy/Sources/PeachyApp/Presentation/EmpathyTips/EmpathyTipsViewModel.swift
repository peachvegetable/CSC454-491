import Foundation
import Combine
import RealmSwift

@MainActor
class EmpathyTipsViewModel: ObservableObject {
    @Published var childMoodStatuses: [ChildMoodStatus] = []
    @Published var pendingNotifications: [EmpathyNotification] = []
    @Published var recentDeliveries: [TipDelivery] = []
    @Published var allTips: [EmpathyTip] = []
    @Published var isFeatureAvailable = false
    
    private let empathyService = ServiceContainer.shared.empathyTipService
    private let authService = ServiceContainer.shared.authService
    private let subscriptionService = ServiceContainer.shared.subscriptionService
    private let realmManager = RealmManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Subscribe to service updates
        empathyService.$pendingNotifications
            .assign(to: &$pendingNotifications)
        
        empathyService.$recentDeliveries
            .assign(to: &$recentDeliveries)
        
        empathyService.$activeTips
            .assign(to: &$allTips)
        
        // Check feature availability
        subscriptionService.$currentSubscription
            .sink { [weak self] _ in
                self?.checkFeatureAvailability()
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        checkFeatureAvailability()
        
        if isFeatureAvailable {
            empathyService.initialize()
            loadChildMoodStatuses()
        }
    }
    
    private func checkFeatureAvailability() {
        isFeatureAvailable = empathyService.isFeatureAvailable()
    }
    
    private func loadChildMoodStatuses() {
        guard let currentUser = authService.currentUser,
              currentUser.userRole == .admin else { return }
        
        // Get family members
        var statuses: [ChildMoodStatus] = []
        
        if let pairedId = currentUser.pairedWithUserId,
           let pairedUser = realmManager.realm.object(ofType: UserProfile.self, forPrimaryKey: pairedId) {
            
            // Get their most recent mood
            let recentMood = getMostRecentMood(for: pairedUser.id)
            let pattern = empathyService.currentChildMoodPatterns[pairedUser.id]
            
            statuses.append(ChildMoodStatus(
                childName: pairedUser.displayName,
                currentMoodColor: recentMood?.color,
                currentMoodEmoji: recentMood?.emoji,
                detectedPattern: pattern,
                lastUpdate: recentMood?.date ?? Date()
            ))
        }
        
        childMoodStatuses = statuses
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
    
    // MARK: - Tip Management
    
    func filteredTips(by category: TipCategory?) -> [EmpathyTip] {
        guard let category = category else { return allTips }
        return allTips.filter { $0.categoryRaw == category.rawValue }
    }
    
    func getTipForDelivery(_ delivery: TipDelivery) -> EmpathyTip? {
        guard let tipId = delivery.tipId else { return nil }
        return realmManager.realm.object(ofType: EmpathyTip.self, forPrimaryKey: tipId)
    }
    
    func getTipForNotification(_ notification: EmpathyNotification) -> EmpathyTip? {
        guard let deliveryId = notification.tipDeliveryId,
              let delivery = realmManager.realm.object(ofType: TipDelivery.self, forPrimaryKey: deliveryId),
              let tipId = delivery.tipId else { return nil }
        
        return realmManager.realm.object(ofType: EmpathyTip.self, forPrimaryKey: tipId)
    }
    
    // MARK: - User Actions
    
    func markNotificationAsViewed(_ notification: EmpathyNotification) {
        do {
            try realmManager.realm.write {
                notification.opened = true
                notification.sentAt = Date()
            }
            
            // Mark the associated delivery as viewed
            if let deliveryId = notification.tipDeliveryId {
                empathyService.markTipAsViewed(deliveryId)
            }
        } catch {
            print("Error marking notification as viewed: \(error)")
        }
    }
    
    func recordFeedback(for delivery: TipDelivery, wasHelpful: Bool) {
        empathyService.recordTipFeedback(delivery.id, wasHelpful: wasHelpful)
        
        // Reload data to reflect changes
        loadData()
    }
    
    func saveTip(_ tip: EmpathyTip) {
        // This could be used to save tips for later reference
        // For now, we'll just print
        print("Tip saved: \(tip.title)")
    }
}