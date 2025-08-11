import Foundation
import RealmSwift

// MARK: - Subscription Features
public enum SubscriptionFeature: String, CaseIterable, Identifiable {
    public var id: String { rawValue }
    case rewardSystem = "reward_system"
    case familyPhotoWall = "family_photo_wall"
    case miniGames = "mini_games"
    case peachyPlus = "peachy_plus"
    
    public var displayName: String {
        switch self {
        case .rewardSystem: return "Reward System"
        case .familyPhotoWall: return "Family Photo Wall"
        case .miniGames: return "Mini-Games"
        case .peachyPlus: return "Peachy Plus"
        }
    }
    
    public var description: String {
        switch self {
        case .rewardSystem: 
            return "Create tasks, earn points, and redeem rewards"
        case .familyPhotoWall: 
            return "Share and cherish family memories together"
        case .miniGames: 
            return "Fun games including Tree Garden and more"
        case .peachyPlus: 
            return "All premium features included"
        }
    }
    
    public var price: String {
        switch self {
        case .rewardSystem: return "$1.99/month"
        case .familyPhotoWall: return "$2.99/month"
        case .miniGames: return "$0.99/month"
        case .peachyPlus: return "$4.99/month"
        }
    }
    
    public var monthlyPrice: Double {
        switch self {
        case .rewardSystem: return 1.99
        case .familyPhotoWall: return 2.99
        case .miniGames: return 0.99
        case .peachyPlus: return 4.99
        }
    }
    
    public var icon: String {
        switch self {
        case .rewardSystem: return "gift.fill"
        case .familyPhotoWall: return "photo.stack"
        case .miniGames: return "gamecontroller.fill"
        case .peachyPlus: return "star.circle.fill"
        }
    }
    
    // Which app features this subscription unlocks
    public var unlockedFeatures: [AppFeature] {
        switch self {
        case .rewardSystem:
            return [.taskRewards]
        case .familyPhotoWall:
            return [.familyPhotos]
        case .miniGames:
            return [.treeGarden]
        case .peachyPlus:
            return [.taskRewards, .familyPhotos, .treeGarden, .aiAssistant]
        }
    }
}

// MARK: - Family Subscription Model
public class FamilySubscription: Object {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted public var familyId: String = ""
    @Persisted public var activeSubscriptions = List<String>() // SubscriptionFeature raw values
    @Persisted public var subscribedBy: String = "" // User ID who subscribed
    @Persisted public var subscribedByName: String = ""
    @Persisted public var expirationDates = Map<String, Date>() // Feature -> Expiration
    @Persisted public var isTestMode: Bool = false // For development/testing
    @Persisted public var createdAt: Date = Date()
    @Persisted public var updatedAt: Date = Date()
    
    public convenience init(familyId: String) {
        self.init()
        self.id = ObjectId.generate()
        self.familyId = familyId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public func hasActiveSubscription(for feature: SubscriptionFeature) -> Bool {
        // Test mode has access to everything
        if isTestMode {
            return true
        }
        
        // Check if Peachy Plus is active (includes all features)
        if activeSubscriptions.contains(SubscriptionFeature.peachyPlus.rawValue) {
            if let expiration = expirationDates[SubscriptionFeature.peachyPlus.rawValue] {
                return expiration > Date()
            }
        }
        
        // Check specific subscription
        if activeSubscriptions.contains(feature.rawValue) {
            if let expiration = expirationDates[feature.rawValue] {
                return expiration > Date()
            }
        }
        
        return false
    }
    
    public func subscribe(to feature: SubscriptionFeature, userId: String, userName: String) {
        if !activeSubscriptions.contains(feature.rawValue) {
            activeSubscriptions.append(feature.rawValue)
        }
        
        // Set expiration to 30 days from now (for demo purposes)
        let expiration = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        expirationDates[feature.rawValue] = expiration
        
        subscribedBy = userId
        subscribedByName = userName
        updatedAt = Date()
    }
    
    public func cancel(feature: SubscriptionFeature) {
        if let index = activeSubscriptions.firstIndex(of: feature.rawValue) {
            activeSubscriptions.remove(at: index)
        }
        expirationDates.removeObject(for: feature.rawValue)
        updatedAt = Date()
    }
    
    public func enableTestMode() {
        isTestMode = true
        updatedAt = Date()
    }
    
    public func disableTestMode() {
        isTestMode = false
        updatedAt = Date()
    }
}

// MARK: - Free Features (Always Available)
public struct FreeFeatures {
    public static let features: [AppFeature] = [
        .moodTracking,
        .moodHistory,
        .chat,
        .hobbySharing
        // Voting, calendar, and todo are also free but not in the current AppFeature enum
    ]
    
    public static func isFreature(_ feature: AppFeature) -> Bool {
        return features.contains(feature)
    }
}

// MARK: - Family Group Model (replaces pairing)
public class FamilyGroup: Object {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted public var groupName: String = ""
    @Persisted public var inviteCode: String = ""
    @Persisted public var createdBy: String = "" // User ID of creator (first admin)
    @Persisted public var createdByName: String = ""
    @Persisted public var members = List<String>() // User IDs
    @Persisted public var admins = List<String>() // User IDs with admin privileges
    @Persisted public var createdAt: Date = Date()
    
    public convenience init(groupName: String, createdBy: String, createdByName: String) {
        self.init()
        self.id = ObjectId.generate()
        self.groupName = groupName
        self.inviteCode = generateInviteCode()
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.members.append(createdBy)
        self.admins.append(createdBy) // Creator is automatically admin
        self.createdAt = Date()
    }
    
    private func generateInviteCode() -> String {
        return String((100000...999999).randomElement() ?? 123456)
    }
    
    public func addMember(_ userId: String) {
        if !members.contains(userId) {
            members.append(userId)
        }
    }
    
    public func removeMember(_ userId: String) {
        if let index = members.firstIndex(of: userId) {
            members.remove(at: index)
        }
        // Also remove from admins if they were one
        if let adminIndex = admins.firstIndex(of: userId) {
            admins.remove(at: adminIndex)
        }
    }
    
    public func makeAdmin(_ userId: String) {
        if members.contains(userId) && !admins.contains(userId) {
            admins.append(userId)
        }
    }
    
    public func removeAdmin(_ userId: String) {
        // Can't remove the creator as admin
        if userId != createdBy {
            if let index = admins.firstIndex(of: userId) {
                admins.remove(at: index)
            }
        }
    }
    
    public func isAdmin(_ userId: String) -> Bool {
        return admins.contains(userId)
    }
}