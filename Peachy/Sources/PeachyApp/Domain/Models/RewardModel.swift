import Foundation
import RealmSwift

class RewardModel: Object {
    @Persisted var id: String = UUID().uuidString
    @Persisted var title: String = ""
    @Persisted var rewardDescription: String = ""
    @Persisted var pointCost: Int = 0
    @Persisted var category: String = RewardCategory.other.rawValue
    @Persisted var icon: String = ""
    @Persisted var validityDays: Int?
    @Persisted var maxRedemptionsPerWeek: Int?
    @Persisted var totalRedemptions: Int = 0
    @Persisted var isActive: Bool = true
    @Persisted var createdBy: String = ""
    @Persisted var createdByName: String = ""
    @Persisted var createdAt: Date = Date()
    @Persisted var expiresAt: Date?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(from reward: RewardCard) {
        self.init()
        self.id = reward.id
        self.title = reward.title
        self.rewardDescription = reward.description
        self.pointCost = reward.pointCost
        self.category = reward.category.rawValue
        self.icon = reward.icon
        self.validityDays = reward.validityDays
        self.maxRedemptionsPerWeek = reward.maxRedemptionsPerWeek
        self.totalRedemptions = reward.totalRedemptions
        self.isActive = reward.isActive
        self.createdBy = reward.createdBy
        self.createdByName = reward.createdByName
        self.createdAt = reward.createdAt
        self.expiresAt = reward.expiresAt
    }
    
    func toDomain() -> RewardCard {
        return RewardCard(
            id: id,
            title: title,
            description: rewardDescription,
            pointCost: pointCost,
            category: RewardCategory(rawValue: category) ?? .other,
            icon: icon,
            validityDays: validityDays,
            maxRedemptionsPerWeek: maxRedemptionsPerWeek,
            totalRedemptions: totalRedemptions,
            isActive: isActive,
            createdBy: createdBy,
            createdByName: createdByName,
            createdAt: createdAt,
            expiresAt: expiresAt
        )
    }
}