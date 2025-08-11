import Foundation

enum TransactionType: String, Codable {
    case earned = "Earned"
    case spent = "Spent"
    case gifted = "Gifted"
    case bonus = "Bonus"
    case adjustment = "Adjustment"
}

struct PointTransaction: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let type: TransactionType
    let amount: Int
    let balance: Int
    let description: String
    let relatedTaskId: String?
    let relatedRewardId: String?
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        userName: String,
        type: TransactionType,
        amount: Int,
        balance: Int,
        description: String,
        relatedTaskId: String? = nil,
        relatedRewardId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.type = type
        self.amount = amount
        self.balance = balance
        self.description = description
        self.relatedTaskId = relatedTaskId
        self.relatedRewardId = relatedRewardId
        self.createdAt = createdAt
    }
    
    var amountDisplay: String {
        switch type {
        case .earned, .gifted, .bonus:
            return "+\(amount) pts"
        case .spent:
            return "-\(amount) pts"
        case .adjustment:
            return amount >= 0 ? "+\(amount) pts" : "\(amount) pts"
        }
    }
    
    var icon: String {
        switch type {
        case .earned: return "checkmark.circle.fill"
        case .spent: return "cart.fill"
        case .gifted: return "gift.fill"
        case .bonus: return "star.fill"
        case .adjustment: return "slider.horizontal.3"
        }
    }
}

struct RedeemedReward: Identifiable, Codable {
    let id: String
    let rewardCard: RewardCard
    let redeemedBy: String
    let redeemedByName: String
    let redeemedAt: Date
    let expiresAt: Date?
    var usedAt: Date?
    var isUsed: Bool
    
    init(
        id: String = UUID().uuidString,
        rewardCard: RewardCard,
        redeemedBy: String,
        redeemedByName: String,
        redeemedAt: Date = Date(),
        expiresAt: Date? = nil,
        usedAt: Date? = nil,
        isUsed: Bool = false
    ) {
        self.id = id
        self.rewardCard = rewardCard
        self.redeemedBy = redeemedBy
        self.redeemedByName = redeemedByName
        self.redeemedAt = redeemedAt
        self.expiresAt = expiresAt ?? (rewardCard.validityDays != nil ? Date().addingTimeInterval(TimeInterval(rewardCard.validityDays! * 24 * 3600)) : nil)
        self.usedAt = usedAt
        self.isUsed = isUsed
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt < Date()
    }
    
    var isValid: Bool {
        !isUsed && !isExpired
    }
}