import Foundation
import RealmSwift
import Combine

@MainActor
public class SubscriptionService: ObservableObject {
    @Published public var currentSubscription: FamilySubscription?
    @Published public var familyGroup: FamilyGroup?
    @Published public var isAdmin = false
    @Published public var availableFeatures: Set<AppFeature> = []
    
    private let realmManager = RealmManager.shared
    private var notificationToken: NotificationToken?
    
    // MARK: - Test Mode
    #if DEBUG
    private let TEST_MODE_ENABLED = true
    #else
    private let TEST_MODE_ENABLED = false
    #endif
    
    public init() {
        // Initialize will be called by views when ready
    }
    
    deinit {
        notificationToken?.invalidate()
    }
    
    // MARK: - Initialization
    
    public func initialize() {
        loadFamilyGroup()
        loadSubscription()
        updateAvailableFeatures()
    }
    
    // MARK: - Family Group Management
    
    public func loadFamilyGroup() {
        guard let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        // Find family group that contains this user
        // Use ANY for Realm List properties
        let predicate = NSPredicate(format: "ANY members == %@", currentUser.id)
        
        if let group = realmManager.fetch(FamilyGroup.self, predicate: predicate).first {
            familyGroup = group
            isAdmin = group.isAdmin(currentUser.id)
        }
    }
    
    public func createFamilyGroup(name: String) {
        guard let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        let group = FamilyGroup(
            groupName: name.isEmpty ? "\(currentUser.displayName)'s Family" : name,
            createdBy: currentUser.id,
            createdByName: currentUser.displayName
        )
        
        do {
            try realmManager.save(group)
            familyGroup = group
            isAdmin = true
            
            // Update user role to admin
            try realmManager.realm.write {
                currentUser.userRole = .admin
            }
            
            // Create default subscription for the group
            createDefaultSubscription(for: group.id.stringValue)
        } catch {
            print("Error creating family group: \(error)")
        }
    }
    
    public func joinFamilyGroup(inviteCode: String) {
        guard let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        let predicate = NSPredicate(format: "inviteCode == %@", inviteCode)
        
        guard let group = realmManager.fetch(FamilyGroup.self, predicate: predicate).first else {
            print("Invalid invite code")
            return
        }
        
        do {
            try realmManager.realm.write {
                group.addMember(currentUser.id)
                // New members are regular users, not admins
                currentUser.userRole = .user
            }
            
            familyGroup = group
            isAdmin = false
            loadSubscription()
        } catch {
            print("Error joining family group: \(error)")
        }
    }
    
    public func promoteToAdmin(userId: String) {
        guard isAdmin,
              let group = familyGroup else { return }
        
        do {
            try realmManager.realm.write {
                group.makeAdmin(userId)
                
                // Update user's role
                if let user = realmManager.realm.object(ofType: UserProfile.self, forPrimaryKey: userId) {
                    user.userRole = .admin
                }
            }
        } catch {
            print("Error promoting to admin: \(error)")
        }
    }
    
    // MARK: - Subscription Management
    
    public func loadSubscription() {
        guard let group = familyGroup else { return }
        
        let predicate = NSPredicate(format: "familyId == %@", group.id.stringValue)
        
        if let subscription = realmManager.fetch(FamilySubscription.self, predicate: predicate).first {
            currentSubscription = subscription
        } else {
            createDefaultSubscription(for: group.id.stringValue)
        }
        
        updateAvailableFeatures()
    }
    
    private func createDefaultSubscription(for familyId: String) {
        let subscription = FamilySubscription(familyId: familyId)
        
        // Enable test mode by default in DEBUG
        if TEST_MODE_ENABLED {
            subscription.enableTestMode()
        }
        
        do {
            try realmManager.save(subscription)
            currentSubscription = subscription
        } catch {
            print("Error creating subscription: \(error)")
        }
    }
    
    public func subscribe(to feature: SubscriptionFeature) {
        guard isAdmin,
              let subscription = currentSubscription,
              let currentUser = ServiceContainer.shared.authService.currentUser else { return }
        
        do {
            try realmManager.realm.write {
                subscription.subscribe(
                    to: feature,
                    userId: currentUser.id,
                    userName: currentUser.displayName
                )
            }
            updateAvailableFeatures()
        } catch {
            print("Error subscribing to feature: \(error)")
        }
    }
    
    public func cancelSubscription(for feature: SubscriptionFeature) {
        guard isAdmin,
              let subscription = currentSubscription else { return }
        
        do {
            try realmManager.realm.write {
                subscription.cancel(feature: feature)
            }
            updateAvailableFeatures()
        } catch {
            print("Error canceling subscription: \(error)")
        }
    }
    
    public func toggleTestMode() {
        // If no subscription exists, create one for test mode
        if currentSubscription == nil {
            // Create a default family group if none exists
            if familyGroup == nil {
                guard let currentUser = ServiceContainer.shared.authService.currentUser else { return }
                createFamilyGroup(name: "\(currentUser.displayName)'s Test Group")
            }
            
            // After creating group, try to get the subscription again
            if let group = familyGroup {
                loadSubscription()
            }
        }
        
        guard let subscription = currentSubscription else { 
            print("Error: Could not create or load subscription for test mode")
            return 
        }
        
        do {
            try realmManager.realm.write {
                if subscription.isTestMode {
                    subscription.disableTestMode()
                } else {
                    subscription.enableTestMode()
                }
            }
            updateAvailableFeatures()
            objectWillChange.send()
        } catch {
            print("Error toggling test mode: \(error)")
        }
    }
    
    // MARK: - Feature Access
    
    public func isFeatureAvailable(_ feature: AppFeature) -> Bool {
        // Core free features are always available
        if FreeFeatures.isFreature(feature) {
            return true
        }
        
        return availableFeatures.contains(feature)
    }
    
    private func updateAvailableFeatures() {
        availableFeatures.removeAll()
        
        // Add all free features
        availableFeatures.formUnion(FreeFeatures.features)
        
        guard let subscription = currentSubscription else { return }
        
        // Check each subscription
        for subscriptionFeature in SubscriptionFeature.allCases {
            if subscription.hasActiveSubscription(for: subscriptionFeature) {
                availableFeatures.formUnion(subscriptionFeature.unlockedFeatures)
            }
        }
    }
    
    // MARK: - Pricing Information
    
    public func getActiveSubscriptions() -> [SubscriptionFeature] {
        guard let subscription = currentSubscription else { return [] }
        
        return SubscriptionFeature.allCases.filter { feature in
            subscription.hasActiveSubscription(for: feature)
        }
    }
    
    public func getTotalMonthlyPrice() -> Double {
        let activeSubscriptions = getActiveSubscriptions()
        
        // If Peachy Plus is active, return its price only
        if activeSubscriptions.contains(.peachyPlus) {
            return SubscriptionFeature.peachyPlus.monthlyPrice
        }
        
        // Otherwise sum individual subscriptions
        return activeSubscriptions.reduce(0) { $0 + $1.monthlyPrice }
    }
    
    public func getSavingsWithPeachyPlus() -> Double {
        let individualTotal = SubscriptionFeature.rewardSystem.monthlyPrice +
                            SubscriptionFeature.familyPhotoWall.monthlyPrice +
                            SubscriptionFeature.miniGames.monthlyPrice
        
        return individualTotal - SubscriptionFeature.peachyPlus.monthlyPrice
    }
}