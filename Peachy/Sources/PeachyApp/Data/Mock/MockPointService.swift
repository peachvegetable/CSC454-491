import Foundation
import RealmSwift

@MainActor
public final class MockPointService: PointServiceProtocol {
    private let realmManager = RealmManager.shared
    
    public init() {}
    
    public func award(userId: String, delta: Int) async {
        let realm = realmManager.realm
        
        // Find or create user points
        let userPoint = realm.objects(UserPoint.self).first(where: { $0.userId == userId })
        
        do {
            try realm.write {
                if let existing = userPoint {
                    existing.points += delta
                    existing.lastUpdated = Date()
                } else {
                    let newUserPoint = UserPoint(userId: userId, points: delta)
                    realm.add(newUserPoint)
                }
            }
        } catch {
            print("Error awarding points: \(error)")
        }
    }
    
    public func total(for userId: String) async -> Int {
        let realm = realmManager.realm
        let userPoint = realm.objects(UserPoint.self).first(where: { $0.userId == userId })
        return userPoint?.points ?? 0
    }
}