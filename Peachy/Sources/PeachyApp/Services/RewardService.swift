import Foundation
import RealmSwift
import Combine

@MainActor
class RewardService: ObservableObject {
    private let realmManager = RealmManager.shared
    @Published var rewards: [RewardCard] = []
    @Published var activeRewards: [RewardCard] = []
    @Published var myRedeemedRewards: [RedeemedReward] = []
    
    var authService: AuthServiceProtocol?
    
    init() {}
    
    func loadRewards() {
        let realm = realmManager.realm
        let rewardModels = realm.objects(RewardModel.self)
        self.rewards = Array(rewardModels).map { $0.toDomain() }
        self.activeRewards = rewards.filter { $0.isActive && !$0.isExpired }
    }
    
    func loadRedeemedRewards(for userId: String) {
        let realm = realmManager.realm
        let redeemedModels = realm.objects(RedeemedRewardModel.self).filter("redeemedBy == %@", userId)
        self.myRedeemedRewards = Array(redeemedModels).map { $0.toDomain() }
    }
    
    func createReward(_ reward: RewardCard) throws {
        let realm = realmManager.realm
        try realm.write {
            let model = RewardModel(from: reward)
            realm.add(model, update: .modified)
        }
        loadRewards()
    }
    
    func updateReward(_ reward: RewardCard) throws {
        let realm = realmManager.realm
        try realm.write {
            let model = RewardModel(from: reward)
            realm.add(model, update: .modified)
        }
        loadRewards()
    }
    
    func redeemReward(_ rewardId: String, userId: String, userName: String, currentBalance: Int) throws -> RedeemedReward {
        let realm = realmManager.realm
        
        guard let rewardModel = realm.object(ofType: RewardModel.self, forPrimaryKey: rewardId) else {
            throw NSError(domain: "RewardService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Reward not found"])
        }
        
        let reward = rewardModel.toDomain()
        
        guard currentBalance >= reward.pointCost else {
            throw NSError(domain: "RewardService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Insufficient points"])
        }
        
        // Check weekly redemption limit
        if let maxPerWeek = reward.maxRedemptionsPerWeek {
            let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
            let recentRedemptions = realm.objects(RedeemedRewardModel.self)
                .filter("redeemedBy == %@ AND rewardCardId == %@ AND redeemedAt >= %@", userId, rewardId, weekAgo)
            
            if recentRedemptions.count >= maxPerWeek {
                throw NSError(domain: "RewardService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Weekly redemption limit reached"])
            }
        }
        
        let redeemedReward = RedeemedReward(
            rewardCard: reward,
            redeemedBy: userId,
            redeemedByName: userName
        )
        
        try realm.write {
            let redeemedModel = RedeemedRewardModel(from: redeemedReward)
            realm.add(redeemedModel)
            
            // Update total redemptions count
            rewardModel.totalRedemptions += 1
        }
        
        loadRewards()
        loadRedeemedRewards(for: userId)
        
        return redeemedReward
    }
    
    func useRedeemedReward(_ redeemedRewardId: String) throws {
        let realm = realmManager.realm
        
        guard let redeemedModel = realm.object(ofType: RedeemedRewardModel.self, forPrimaryKey: redeemedRewardId) else {
            throw NSError(domain: "RewardService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Redeemed reward not found"])
        }
        
        try realm.write {
            redeemedModel.usedAt = Date()
            redeemedModel.isUsed = true
        }
        
        if let userId = authService?.currentUser?.id {
            loadRedeemedRewards(for: userId)
        }
    }
    
    func deleteReward(_ rewardId: String) throws {
        let realm = realmManager.realm
        
        guard let rewardModel = realm.object(ofType: RewardModel.self, forPrimaryKey: rewardId) else {
            throw NSError(domain: "RewardService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Reward not found"])
        }
        
        try realm.write {
            // Soft delete - just mark as inactive
            rewardModel.isActive = false
        }
        
        loadRewards()
    }
    
    func getRewardsByCategory(_ category: RewardCategory) -> [RewardCard] {
        return activeRewards.filter { $0.category == category }
    }
    
    func getValidRedeemedRewards(for userId: String) -> [RedeemedReward] {
        loadRedeemedRewards(for: userId)
        return myRedeemedRewards.filter { $0.isValid }
    }
}