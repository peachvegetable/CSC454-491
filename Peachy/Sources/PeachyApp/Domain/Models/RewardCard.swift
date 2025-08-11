import Foundation

enum RewardCategory: String, CaseIterable, Codable {
    case screenTime = "Screen Time"
    case privileges = "Privileges"
    case money = "Money"
    case experiences = "Experiences"
    case food = "Food & Treats"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .screenTime: return "tv"
        case .privileges: return "star.circle"
        case .money: return "dollarsign.circle"
        case .experiences: return "ticket"
        case .food: return "fork.knife"
        case .other: return "gift"
        }
    }
}

struct RewardCard: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var pointCost: Int
    var category: RewardCategory
    var icon: String
    var validityDays: Int?
    var maxRedemptionsPerWeek: Int?
    var totalRedemptions: Int
    var isActive: Bool
    var createdBy: String
    var createdByName: String
    var createdAt: Date
    var expiresAt: Date?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        pointCost: Int,
        category: RewardCategory = .other,
        icon: String? = nil,
        validityDays: Int? = nil,
        maxRedemptionsPerWeek: Int? = nil,
        totalRedemptions: Int = 0,
        isActive: Bool = true,
        createdBy: String,
        createdByName: String,
        createdAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.pointCost = pointCost
        self.category = category
        self.icon = icon ?? category.icon
        self.validityDays = validityDays
        self.maxRedemptionsPerWeek = maxRedemptionsPerWeek
        self.totalRedemptions = totalRedemptions
        self.isActive = isActive
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    var pointsDisplay: String {
        "\(pointCost) pts"
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt < Date()
    }
}