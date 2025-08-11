import Foundation
import RealmSwift
import Combine

@MainActor
class PointsService: ObservableObject {
    private let realmManager = RealmManager.shared
    @Published var currentBalance: Int = 0
    @Published var transactions: [PointTransaction] = []
    @Published var familyBalances: [(userId: String, userName: String, balance: Int)] = []
    
    var authService: AuthServiceProtocol?
    var taskService: TaskService?
    var rewardService: RewardService?
    
    init() {}
    
    func loadBalance(for userId: String) {
        let realm = realmManager.realm
        let userTransactions = realm.objects(TransactionModel.self)
            .filter("userId == %@", userId)
            .sorted(byKeyPath: "createdAt", ascending: false)
        
        self.transactions = Array(userTransactions).map { $0.toDomain() }
        self.currentBalance = transactions.first?.balance ?? 0
    }
    
    func loadFamilyBalances() {
        let realm = realmManager.realm
        let allTransactions = realm.objects(TransactionModel.self)
        
        var balanceMap: [String: (userName: String, balance: Int, date: Date)] = [:]
        
        for transaction in allTransactions {
            let userId = transaction.userId
            let userName = transaction.userName
            let balance = transaction.balance
            
            if let existing = balanceMap[userId] {
                if transaction.createdAt > existing.date {
                    balanceMap[userId] = (userName, balance, transaction.createdAt)
                }
            } else {
                balanceMap[userId] = (userName, balance, transaction.createdAt)
            }
        }
        
        self.familyBalances = balanceMap.map { ($0.key, $0.value.userName, $0.value.balance) }
            .sorted { $0.2 > $1.2 } // Sort by balance descending
    }
    
    func earnPoints(userId: String, userName: String, amount: Int, description: String, taskId: String? = nil) throws {
        let realm = realmManager.realm
        
        let newBalance = currentBalance + amount
        let transaction = PointTransaction(
            userId: userId,
            userName: userName,
            type: .earned,
            amount: amount,
            balance: newBalance,
            description: description,
            relatedTaskId: taskId
        )
        
        try realm.write {
            let model = TransactionModel(from: transaction)
            realm.add(model)
        }
        
        currentBalance = newBalance
        loadBalance(for: userId)
    }
    
    func spendPoints(userId: String, userName: String, amount: Int, description: String, rewardId: String? = nil) throws {
        let realm = realmManager.realm
        
        guard currentBalance >= amount else {
            throw NSError(domain: "PointsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Insufficient points"])
        }
        
        let newBalance = currentBalance - amount
        let transaction = PointTransaction(
            userId: userId,
            userName: userName,
            type: .spent,
            amount: amount,
            balance: newBalance,
            description: description,
            relatedRewardId: rewardId
        )
        
        try realm.write {
            let model = TransactionModel(from: transaction)
            realm.add(model)
        }
        
        currentBalance = newBalance
        loadBalance(for: userId)
    }
    
    func giftPoints(fromUserId: String, fromUserName: String, toUserId: String, toUserName: String, amount: Int) throws {
        let realm = realmManager.realm
        
        // Load sender's balance
        loadBalance(for: fromUserId)
        guard currentBalance >= amount else {
            throw NSError(domain: "PointsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Insufficient points to gift"])
        }
        
        try realm.write {
            // Deduct from sender
            let senderNewBalance = currentBalance - amount
            let senderTransaction = PointTransaction(
                userId: fromUserId,
                userName: fromUserName,
                type: .gifted,
                amount: amount,
                balance: senderNewBalance,
                description: "Gifted to \(toUserName)"
            )
            realm.add(TransactionModel(from: senderTransaction))
            
            // Add to recipient
            let recipientTransactions = realm.objects(TransactionModel.self)
                .filter("userId == %@", toUserId)
                .sorted(byKeyPath: "createdAt", ascending: false)
            let recipientBalance = recipientTransactions.first?.balance ?? 0
            let recipientNewBalance = recipientBalance + amount
            
            let recipientTransaction = PointTransaction(
                userId: toUserId,
                userName: toUserName,
                type: .gifted,
                amount: amount,
                balance: recipientNewBalance,
                description: "Received from \(fromUserName)"
            )
            realm.add(TransactionModel(from: recipientTransaction))
        }
        
        loadBalance(for: fromUserId)
        loadFamilyBalances()
    }
    
    func awardBonusPoints(userId: String, userName: String, amount: Int, reason: String) throws {
        let realm = realmManager.realm
        
        loadBalance(for: userId)
        let newBalance = currentBalance + amount
        let transaction = PointTransaction(
            userId: userId,
            userName: userName,
            type: .bonus,
            amount: amount,
            balance: newBalance,
            description: reason
        )
        
        try realm.write {
            let model = TransactionModel(from: transaction)
            realm.add(model)
        }
        
        currentBalance = newBalance
        loadBalance(for: userId)
    }
    
    func completeTaskAndEarnPoints(_ taskId: String) throws {
        guard let currentUser = authService?.currentUser else {
            throw NSError(domain: "PointsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Get task details
        guard let task = taskService?.tasks.first(where: { $0.id == taskId }) else {
            throw NSError(domain: "PointsService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Task not found"])
        }
        
        // Award points
        try earnPoints(
            userId: currentUser.id,
            userName: currentUser.displayName,
            amount: task.pointValue,
            description: "Completed: \(task.title)",
            taskId: taskId
        )
    }
    
    func redeemRewardAndSpendPoints(_ rewardId: String) throws -> RedeemedReward {
        guard let currentUser = authService?.currentUser else {
            throw NSError(domain: "PointsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Get reward details
        guard let reward = rewardService?.rewards.first(where: { $0.id == rewardId }) else {
            throw NSError(domain: "PointsService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Reward not found"])
        }
        
        // Check balance
        loadBalance(for: currentUser.id)
        
        // Redeem reward (this also checks balance)
        let redeemedReward = try rewardService?.redeemReward(
            rewardId,
            userId: currentUser.id,
            userName: currentUser.displayName,
            currentBalance: currentBalance
        )
        
        // Spend points
        try spendPoints(
            userId: currentUser.id,
            userName: currentUser.displayName,
            amount: reward.pointCost,
            description: "Redeemed: \(reward.title)",
            rewardId: rewardId
        )
        
        return redeemedReward!
    }
    
    func getTransactionHistory(for userId: String, limit: Int = 50) -> [PointTransaction] {
        let realm = realmManager.realm
        let userTransactions = realm.objects(TransactionModel.self)
            .filter("userId == %@", userId)
            .sorted(byKeyPath: "createdAt", ascending: false)
        
        return Array(userTransactions.prefix(limit)).map { $0.toDomain() }
    }
}