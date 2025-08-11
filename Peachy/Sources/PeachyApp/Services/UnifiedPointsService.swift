import Foundation
import RealmSwift

@MainActor
class UnifiedPointsService: ObservableObject {
    static let shared = UnifiedPointsService()
    private let realmManager = RealmManager.shared
    
    @Published var currentUserPoints: Int = 0
    
    private init() {}
    
    // MARK: - Core Point Management
    
    func loadUserPoints(for userId: String) {
        let realm = realmManager.realm
        if let userPoint = realm.objects(UserPoint.self).filter("userId == %@", userId).first {
            currentUserPoints = userPoint.points
        } else {
            // Create initial points record for new user
            createUserPoints(for: userId)
        }
    }
    
    private func createUserPoints(for userId: String) {
        let realm = realmManager.realm
        try? realm.write {
            let userPoint = UserPoint(userId: userId, points: 0)
            realm.add(userPoint, update: .modified)
        }
        currentUserPoints = 0
    }
    
    func addPoints(to userId: String, amount: Int, reason: String) {
        let realm = realmManager.realm
        
        guard let userPoint = realm.objects(UserPoint.self).filter("userId == %@", userId).first else {
            createUserPoints(for: userId)
            addPoints(to: userId, amount: amount, reason: reason)
            return
        }
        
        try? realm.write {
            userPoint.points += amount
            userPoint.lastUpdated = Date()
            
            // Also create a transaction record for history
            let transaction = TransactionModel()
            transaction.userId = userId
            transaction.userName = userPoint.userId // We should get the actual name
            transaction.type = TransactionType.earned.rawValue
            transaction.amount = amount
            transaction.balance = userPoint.points
            transaction.transactionDescription = reason
            transaction.createdAt = Date()
            realm.add(transaction)
        }
        
        currentUserPoints = userPoint.points
        print("✅ Added \(amount) points to user \(userId). New balance: \(userPoint.points). Reason: \(reason)")
    }
    
    func spendPoints(from userId: String, amount: Int, reason: String) -> Bool {
        let realm = realmManager.realm
        
        guard let userPoint = realm.objects(UserPoint.self).filter("userId == %@", userId).first else {
            return false
        }
        
        guard userPoint.points >= amount else {
            print("❌ Insufficient points. User has \(userPoint.points), needs \(amount)")
            return false
        }
        
        try? realm.write {
            userPoint.points -= amount
            userPoint.lastUpdated = Date()
            
            // Create transaction record
            let transaction = TransactionModel()
            transaction.userId = userId
            transaction.userName = userPoint.userId
            transaction.type = TransactionType.spent.rawValue
            transaction.amount = amount
            transaction.balance = userPoint.points
            transaction.transactionDescription = reason
            transaction.createdAt = Date()
            realm.add(transaction)
        }
        
        currentUserPoints = userPoint.points
        print("✅ Spent \(amount) points from user \(userId). New balance: \(userPoint.points). Reason: \(reason)")
        return true
    }
    
    func getUserPoints(for userId: String) -> Int {
        let realm = realmManager.realm
        return realm.objects(UserPoint.self).filter("userId == %@", userId).first?.points ?? 0
    }
    
    // MARK: - Specific Point Awards
    
    func awardMoodUpdatePoints(to userId: String) {
        addPoints(to: userId, amount: 5, reason: "Mood status update")
    }
    
    func awardTaskCompletionPoints(to userId: String, taskTitle: String, points: Int) {
        addPoints(to: userId, amount: points, reason: "Completed task: \(taskTitle)")
    }
    
    func awardHobbySharePoints(to userId: String) {
        addPoints(to: userId, amount: 5, reason: "Shared a hobby")
    }
    
    func awardQuizCorrectPoints(to userId: String) {
        addPoints(to: userId, amount: 2, reason: "Correct quiz answer")
    }
    
    // MARK: - Tree Watering Exchange
    
    func exchangePointsForWater(userId: String, points: Int) -> Int {
        let waterDrops = points * 5 // 1 point = 5 drops of water
        
        if spendPoints(from: userId, amount: points, reason: "Bought \(waterDrops) water drops for tree") {
            return waterDrops
        }
        return 0
    }
    
    // MARK: - Reward Redemption
    
    func redeemReward(userId: String, rewardTitle: String, cost: Int) -> Bool {
        return spendPoints(from: userId, amount: cost, reason: "Redeemed: \(rewardTitle)")
    }
}