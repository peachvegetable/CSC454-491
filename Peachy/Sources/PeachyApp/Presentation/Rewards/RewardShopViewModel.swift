import Foundation
import Combine

@MainActor
class RewardShopViewModel: ObservableObject {
    @Published var rewards: [RewardCard] = []
    @Published var myRedeemedRewards: [RedeemedReward] = []
    @Published var currentBalance: Int = 0
    @Published var isParent: Bool = false
    
    private let rewardService = ServiceContainer.shared.rewardService
    private let pointsService = ServiceContainer.shared.pointsService
    private let authService = ServiceContainer.shared.authService
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        rewardService.$activeRewards
            .assign(to: &$rewards)
        
        rewardService.$myRedeemedRewards
            .assign(to: &$myRedeemedRewards)
        
        pointsService.$currentBalance
            .assign(to: &$currentBalance)
    }
    
    func loadRewards() {
        guard let currentUser = authService.currentUser else { return }
        
        isParent = UserRole(rawValue: currentUser.role) == .admin
        
        rewardService.loadRewards()
        rewardService.loadRedeemedRewards(for: currentUser.id)
        
        // Use unified points service
        UnifiedPointsService.shared.loadUserPoints(for: currentUser.id)
        currentBalance = UnifiedPointsService.shared.getUserPoints(for: currentUser.id)
    }
    
    func filteredRewards(for category: RewardCategory?) -> [RewardCard] {
        guard let category = category else {
            return rewards
        }
        return rewards.filter { $0.category == category }
    }
    
    func redeemReward(_ reward: RewardCard) {
        guard let currentUser = authService.currentUser else { return }
        
        // Use unified points to redeem
        if UnifiedPointsService.shared.redeemReward(userId: currentUser.id, rewardTitle: reward.title, cost: reward.pointCost) {
            do {
                // Record the redemption
                let _ = try rewardService.redeemReward(
                    reward.id,
                    userId: currentUser.id,
                    userName: currentUser.displayName,
                    currentBalance: UnifiedPointsService.shared.getUserPoints(for: currentUser.id) + reward.pointCost
                )
                loadRewards()
            } catch {
                print("Error recording reward redemption: \(error)")
            }
        } else {
            print("Insufficient points to redeem reward")
        }
    }
    
    func createReward(_ reward: RewardCard) {
        do {
            try rewardService.createReward(reward)
            loadRewards()
        } catch {
            print("Error creating reward: \(error)")
        }
    }
    
    func updateReward(_ reward: RewardCard) {
        do {
            try rewardService.updateReward(reward)
            loadRewards()
        } catch {
            print("Error updating reward: \(error)")
        }
    }
    
    func deleteReward(_ rewardId: String) {
        do {
            try rewardService.deleteReward(rewardId)
            loadRewards()
        } catch {
            print("Error deleting reward: \(error)")
        }
    }
    
    func loadRewardsWithSampleData() {
        // First load existing rewards
        loadRewards()
        
        // If no rewards exist, create sample data
        if rewardService.rewards.isEmpty {
            createSampleRewards()
            loadRewards()
        }
    }
    
    private func createSampleRewards() {
        let sampleRewards = [
            RewardCard(
                title: "1 Hour Extra Screen Time",
                description: "Get an extra hour of gaming or TV time today",
                pointCost: 30,
                category: .screenTime,
                icon: "tv",
                validityDays: 1,
                maxRedemptionsPerWeek: 3,
                createdBy: "parent",
                createdByName: "Mom"
            ),
            RewardCard(
                title: "Stay Up 30 Min Later",
                description: "Extend bedtime by 30 minutes tonight",
                pointCost: 25,
                category: .privileges,
                icon: "moon.stars",
                validityDays: 1,
                maxRedemptionsPerWeek: 2,
                createdBy: "parent",
                createdByName: "Dad"
            ),
            RewardCard(
                title: "$5 iTunes Card",
                description: "Get $5 credit for App Store purchases",
                pointCost: 50,
                category: .money,
                icon: "dollarsign.circle",
                createdBy: "parent",
                createdByName: "Mom"
            ),
            RewardCard(
                title: "Choose Movie Night Film",
                description: "Pick the movie for family movie night",
                pointCost: 40,
                category: .experiences,
                icon: "film",
                validityDays: 7,
                maxRedemptionsPerWeek: 1,
                createdBy: "parent",
                createdByName: "Dad"
            ),
            RewardCard(
                title: "Pizza for Dinner",
                description: "Choose pizza toppings for Friday night",
                pointCost: 60,
                category: .food,
                icon: "fork.knife",
                validityDays: 7,
                maxRedemptionsPerWeek: 1,
                createdBy: "parent",
                createdByName: "Mom"
            ),
            RewardCard(
                title: "Friend Sleepover",
                description: "Have a friend stay over this weekend",
                pointCost: 100,
                category: .experiences,
                icon: "person.2",
                validityDays: 14,
                maxRedemptionsPerWeek: 1,
                createdBy: "parent",
                createdByName: "Dad"
            )
        ]
        
        for reward in sampleRewards {
            do {
                try rewardService.createReward(reward)
            } catch {
                print("Error creating sample reward: \(error)")
            }
        }
    }
}