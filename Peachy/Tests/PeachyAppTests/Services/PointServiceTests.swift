import XCTest
@testable import PeachyApp
import RealmSwift

@MainActor
final class PointServiceTests: XCTestCase {
    var sut: MockPointService!
    var realm: Realm!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use in-memory Realm for testing
        let config = Realm.Configuration(
            inMemoryIdentifier: "PointServiceTests-\(UUID().uuidString)",
            schemaVersion: 1
        )
        realm = try Realm(configuration: config)
        RealmManager.shared.setRealm(realm)
        
        sut = MockPointService()
    }
    
    override func tearDown() async throws {
        sut = nil
        realm = nil
        try await super.tearDown()
    }
    
    func testAwardPointsNewUser() async throws {
        // Given
        let userId = "test-user-123"
        
        // When
        await sut.award(userId: userId, delta: 10)
        
        // Then
        let total = await sut.total(for: userId)
        XCTAssertEqual(total, 10)
        
        // Verify in Realm
        let userPoints = realm.objects(UserPoint.self).first(where: { $0.userId == userId })
        XCTAssertNotNil(userPoints)
        XCTAssertEqual(userPoints?.points, 10)
    }
    
    func testAwardPointsExistingUser() async throws {
        // Given
        let userId = "test-user-456"
        let existingPoints = UserPoint(userId: userId, points: 20)
        try realm.write {
            realm.add(existingPoints)
        }
        
        // When
        await sut.award(userId: userId, delta: 15)
        
        // Then
        let total = await sut.total(for: userId)
        XCTAssertEqual(total, 35)
        
        // Verify in Realm
        let userPoints = realm.objects(UserPoint.self).first(where: { $0.userId == userId })
        XCTAssertEqual(userPoints?.points, 35)
    }
    
    func testTotalPointsNoUser() async throws {
        // Given
        let userId = "non-existent-user"
        
        // When
        let total = await sut.total(for: userId)
        
        // Then
        XCTAssertEqual(total, 0)
    }
    
    func testMultipleAwards() async throws {
        // Given
        let userId = "test-user-789"
        
        // When
        await sut.award(userId: userId, delta: 5)
        await sut.award(userId: userId, delta: 3)
        await sut.award(userId: userId, delta: 7)
        
        // Then
        let total = await sut.total(for: userId)
        XCTAssertEqual(total, 15)
    }
    
    func testConcurrentAwards() async throws {
        // Given
        let userId = "test-user-concurrent"
        
        // When - Award points concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 1...5 {
                group.addTask {
                    await self.sut.award(userId: userId, delta: i)
                }
            }
        }
        
        // Then
        let total = await sut.total(for: userId)
        XCTAssertEqual(total, 15) // 1+2+3+4+5 = 15
    }
    
    func testAward() async throws {
        // Given
        let userId = "test-award-user"
        
        // When
        await sut.award(userId: userId, delta: 25)
        
        // Then
        let total = await sut.total(for: userId)
        XCTAssertEqual(total, 25)
        
        // Verify UserPoint object was created
        let userPoint = realm.objects(UserPoint.self).first(where: { $0.userId == userId })
        XCTAssertNotNil(userPoint)
        XCTAssertEqual(userPoint?.points, 25)
        XCTAssertNotNil(userPoint?.lastUpdated)
    }
}