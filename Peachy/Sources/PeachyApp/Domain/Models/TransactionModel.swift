import Foundation
import RealmSwift

class TransactionModel: Object {
    @Persisted var id: String = UUID().uuidString
    @Persisted var userId: String = ""
    @Persisted var userName: String = ""
    @Persisted var type: String = TransactionType.earned.rawValue
    @Persisted var amount: Int = 0
    @Persisted var balance: Int = 0
    @Persisted var transactionDescription: String = ""
    @Persisted var relatedTaskId: String?
    @Persisted var relatedRewardId: String?
    @Persisted var createdAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(from transaction: PointTransaction) {
        self.init()
        self.id = transaction.id
        self.userId = transaction.userId
        self.userName = transaction.userName
        self.type = transaction.type.rawValue
        self.amount = transaction.amount
        self.balance = transaction.balance
        self.transactionDescription = transaction.description
        self.relatedTaskId = transaction.relatedTaskId
        self.relatedRewardId = transaction.relatedRewardId
        self.createdAt = transaction.createdAt
    }
    
    func toDomain() -> PointTransaction {
        return PointTransaction(
            id: id,
            userId: userId,
            userName: userName,
            type: TransactionType(rawValue: type) ?? .earned,
            amount: amount,
            balance: balance,
            description: transactionDescription,
            relatedTaskId: relatedTaskId,
            relatedRewardId: relatedRewardId,
            createdAt: createdAt
        )
    }
}

class RedeemedRewardModel: Object {
    @Persisted var id: String = UUID().uuidString
    @Persisted var rewardCardId: String = ""
    @Persisted var rewardTitle: String = ""
    @Persisted var rewardDescription: String = ""
    @Persisted var pointCost: Int = 0
    @Persisted var category: String = ""
    @Persisted var icon: String = ""
    @Persisted var redeemedBy: String = ""
    @Persisted var redeemedByName: String = ""
    @Persisted var redeemedAt: Date = Date()
    @Persisted var expiresAt: Date?
    @Persisted var usedAt: Date?
    @Persisted var isUsed: Bool = false
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(from redeemed: RedeemedReward) {
        self.init()
        self.id = redeemed.id
        self.rewardCardId = redeemed.rewardCard.id
        self.rewardTitle = redeemed.rewardCard.title
        self.rewardDescription = redeemed.rewardCard.description
        self.pointCost = redeemed.rewardCard.pointCost
        self.category = redeemed.rewardCard.category.rawValue
        self.icon = redeemed.rewardCard.icon
        self.redeemedBy = redeemed.redeemedBy
        self.redeemedByName = redeemed.redeemedByName
        self.redeemedAt = redeemed.redeemedAt
        self.expiresAt = redeemed.expiresAt
        self.usedAt = redeemed.usedAt
        self.isUsed = redeemed.isUsed
    }
    
    func toDomain() -> RedeemedReward {
        let card = RewardCard(
            id: rewardCardId,
            title: rewardTitle,
            description: rewardDescription,
            pointCost: pointCost,
            category: RewardCategory(rawValue: category) ?? .other,
            icon: icon,
            createdBy: "",
            createdByName: ""
        )
        
        return RedeemedReward(
            id: id,
            rewardCard: card,
            redeemedBy: redeemedBy,
            redeemedByName: redeemedByName,
            redeemedAt: redeemedAt,
            expiresAt: expiresAt,
            usedAt: usedAt,
            isUsed: isUsed
        )
    }
}