import XCTest
@testable import PeachyApp
import RealmSwift

@MainActor
final class HobbyServiceTests: XCTestCase {
    var sut: MockHobbyService!
    var mockPointService: MockPointService!
    var realm: Realm!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use in-memory Realm for testing
        let config = Realm.Configuration(
            inMemoryIdentifier: "HobbyServiceTests-\(UUID().uuidString)",
            schemaVersion: 1
        )
        realm = try Realm(configuration: config)
        RealmManager.shared.setRealm(realm)
        
        // Create services
        mockPointService = MockPointService()
        sut = MockHobbyService()
        sut.setPointService(mockPointService)
        
        // Create mock user
        let mockAuth = ServiceContainer.shared.authService as? MockAuthService
        mockAuth?.currentUser = UserProfile()
        mockAuth?.currentUser?.id = "test-user-123"
    }
    
    override func tearDown() async throws {
        sut = nil
        mockPointService = nil
        realm = nil
        try await super.tearDown()
    }
    
    func testSaveHobby() async throws {
        // Given
        let hobbyName = "Basketball"
        let fact = "Basketball was invented in 1891"
        
        // When
        try await sut.saveHobby(name: hobbyName, fact: fact)
        
        // Then
        let hobbies = await sut.allHobbies()
        XCTAssertEqual(hobbies.count, 1)
        XCTAssertEqual(hobbies.first?.name, hobbyName)
        XCTAssertEqual(hobbies.first?.fact, fact)
        XCTAssertEqual(hobbies.first?.ownerId, "test-user-123")
        
        // Verify flash card was created
        let flashCards = realm.objects(FlashCard.self)
        XCTAssertEqual(flashCards.count, 1)
        XCTAssertTrue(flashCards.first?.question.contains(hobbyName) ?? false)
        XCTAssertEqual(flashCards.first?.answer, fact)
        
        // Verify points were awarded
        let points = await mockPointService.total(for: "test-user-123")
        XCTAssertEqual(points, 5)
    }
    
    func testMarkHobbyAsSeen() async throws {
        // Given
        let hobby = HobbyModel()
        hobby.name = "Guitar"
        hobby.fact = "Guitars have 6 strings"
        hobby.ownerId = "other-user"
        
        try realm.write {
            realm.add(hobby)
        }
        
        // When
        let wasNew = try await sut.markHobbyAsSeen(hobbyId: hobby.id, by: "test-user-123")
        
        // Then
        XCTAssertTrue(wasNew)
        XCTAssertTrue(hobby.seenBy.contains(where: { $0 == "test-user-123" }))
        
        // Mark again - should return false
        let wasNewAgain = try await sut.markHobbyAsSeen(hobbyId: hobby.id, by: "test-user-123")
        XCTAssertFalse(wasNewAgain)
    }
    
    func testAllHobbies() async throws {
        // Given
        let hobby1 = HobbyModel()
        hobby1.name = "Swimming"
        hobby1.fact = "Swimming is great exercise"
        hobby1.ownerId = "user1"
        hobby1.createdAt = Date().addingTimeInterval(-3600) // 1 hour ago
        
        let hobby2 = HobbyModel()
        hobby2.name = "Reading"
        hobby2.fact = "Reading improves vocabulary"
        hobby2.ownerId = "user2"
        hobby2.createdAt = Date() // now
        
        try realm.write {
            realm.add([hobby1, hobby2])
        }
        
        // When
        let hobbies = await sut.allHobbies()
        
        // Then
        XCTAssertEqual(hobbies.count, 2)
        XCTAssertEqual(hobbies.first?.name, "Reading") // Most recent first
        XCTAssertEqual(hobbies.last?.name, "Swimming")
    }
    
    func testSaveHobbyCreatesFlashCard() async throws {
        // Given
        let hobbyName = "Chess"
        let fact = "Chess originated in India around the 6th century"
        
        // When
        try await sut.saveHobby(name: hobbyName, fact: fact)
        
        // Then
        // Verify hobby was created
        let hobbies = await sut.allHobbies()
        XCTAssertEqual(hobbies.count, 1)
        let hobby = hobbies.first!
        XCTAssertEqual(hobby.name, hobbyName)
        XCTAssertEqual(hobby.fact, fact)
        
        // Verify flash card was created
        let flashCards = realm.objects(FlashCard.self)
        XCTAssertEqual(flashCards.count, 1)
        let flashCard = flashCards.first!
        XCTAssertTrue(flashCard.question.contains(hobbyName))
        XCTAssertEqual(flashCard.answer, fact)
        XCTAssertEqual(flashCard.hobbyId, hobby.id)
        
        // Verify points were awarded
        let points = await mockPointService.total(for: "test-user-123")
        XCTAssertEqual(points, 5)
    }
    
    func testGetHobbies() async throws {
        // When
        let hobbies = try await sut.getHobbies()
        
        // Then
        XCTAssertFalse(hobbies.isEmpty)
        XCTAssertEqual(hobbies.count, HobbyPreset.presets.count)
        
        // Verify some expected hobbies are present
        XCTAssertTrue(hobbies.contains(where: { $0.name == "Basketball" }))
        XCTAssertTrue(hobbies.contains(where: { $0.name == "Chess" }))
        XCTAssertTrue(hobbies.contains(where: { $0.name == "Reading" }))
        
        // Verify hobby structure
        if let basketball = hobbies.first(where: { $0.name == "Basketball" }) {
            XCTAssertEqual(basketball.category, .sports)
            XCTAssertEqual(basketball.emoji, "🏀")
            XCTAssertFalse(basketball.description.isEmpty)
        }
    }
}