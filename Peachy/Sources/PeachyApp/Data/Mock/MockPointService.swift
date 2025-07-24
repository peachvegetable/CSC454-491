import Foundation
import RealmSwift

@MainActor
public final class MockPointService: PointServiceProtocol {
    private let realmManager = RealmManager.shared
    
    public init() {}
    
    public func award(userId: String, delta: Int) async {
        do {
            let realm = realmManager.realm
            
            print("MockPointService.award - Awarding \(delta) points to user: \(userId)")
            
            // Find or create user points
            let userPoint = realm.objects(UserPoint.self).first(where: { $0.userId == userId })
            
            try realm.write {
                if let existing = userPoint {
                    print("MockPointService.award - Found existing UserPoint with ID: \(existing.id), current points: \(existing.points)")
                    existing.points += delta
                    existing.lastUpdated = Date()
                    print("MockPointService.award - Updated points to: \(existing.points)")
                } else {
                    let newUserPoint = UserPoint(userId: userId, points: delta)
                    print("MockPointService.award - Creating new UserPoint with ID: \(newUserPoint.id)")
                    realm.add(newUserPoint)
                    print("MockPointService.award - New UserPoint created successfully")
                }
            }
            print("MockPointService.award - Points awarded successfully")
        } catch {
            print("MockPointService.award - ERROR awarding points: \(error)")
            print("Error type: \(type(of: error))")
            print("Error localizedDescription: \(error.localizedDescription)")
            print("Realm configuration: \(Realm.Configuration.defaultConfiguration)")
        }
    }
    
    public func total(for userId: String) async -> Int {
        let realm = realmManager.realm
        let userPoint = realm.objects(UserPoint.self).first(where: { $0.userId == userId })
        return userPoint?.points ?? 0
    }
}