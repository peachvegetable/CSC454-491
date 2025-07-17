import XCTest
@testable import PeachyApp
import RealmSwift

@MainActor
final class QuestServiceTests: XCTestCase {
    var sut: MockQuestService!
    var realm: Realm!
    var mockAuth: MockAuthService!
    var mockHobbyService: MockHobbyService!
    var mockPointService: MockPointService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use in-memory Realm for testing
        let config = Realm.Configuration(
            inMemoryIdentifier: "QuestServiceTests-\(UUID().uuidString)",
            schemaVersion: 2
        )
        realm = try Realm(configuration: config)
        RealmManager.shared.setRealm(realm)
        
        // Create mock services
        mockAuth = MockAuthService()
        mockHobbyService = MockHobbyService()
        mockPointService = MockPointService()
        
        // Create test user
        mockAuth.currentUser = UserProfile()
        mockAuth.currentUser?.id = "test-user-123"
        mockAuth.currentUser?.pairedWithUserId = "paired-user-456"
        
        // Override services in container
        ServiceContainer.shared.authService = mockAuth
        mockHobbyService.setPointService(mockPointService)
        
        sut = MockQuestService()
    }
    
    override func tearDown() async throws {
        sut = nil
        realm = nil
        mockAuth = nil
        mockHobbyService = nil
        mockPointService = nil
        try await super.tearDown()
    }
    
    func testMarkDoneCreatesFlashCard() async throws {
        // Given
        let hobby = HobbyPresetItem(
            id: "chess-id",
            name: "Chess",
            category: .gaming,
            description: "Strategic board game",
            emoji: "♟️"
        )
        let fact = "Chess was invented in India"
        
        // When
        try await sut.markDone(hobby: hobby, fact: fact)
        
        // Then
        // Verify flash card was created
        let flashCards = realm.objects(FlashCard.self)
        XCTAssertEqual(flashCards.count, 1)
        let flashCard = flashCards.first!
        XCTAssertTrue(flashCard.question.contains("Chess"))
        XCTAssertEqual(flashCard.answer, fact)
        
        // Verify quest was recorded
        let quests = await sut.getCompletedQuests(for: "test-user-123")
        XCTAssertEqual(quests.count, 1)
        let quest = quests.first!
        XCTAssertEqual(quest.questType, Quest.Kind.shareHobby.rawValue)
        XCTAssertEqual(quest.fact, fact)
        XCTAssertNotNil(quest.completedAt)
        XCTAssertEqual(quest.pointsAwarded, 5)
        
        // Verify points were awarded to both users
        let userPoints = await mockPointService.total(for: "test-user-123")
        XCTAssertEqual(userPoints, 6) // 5 for hobby + 1 for quest
        
        let pairedUserPoints = await mockPointService.total(for: "paired-user-456")
        XCTAssertEqual(pairedUserPoints, 1) // 1 for quest completion
    }
    
    func testGetCompletedQuests() async throws {
        // Given - create multiple quest completions
        let hobby1 = HobbyPresetItem(id: "1", name: "Swimming", category: .sports, description: "Water sport", emoji: "🏊")
        let hobby2 = HobbyPresetItem(id: "2", name: "Reading", category: .reading, description: "Books", emoji: "📚")
        
        try await sut.markDone(hobby: hobby1, fact: "Swimming is great exercise")
        
        // Wait a bit to ensure different timestamps
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        try await sut.markDone(hobby: hobby2, fact: "Reading improves vocabulary")
        
        // When
        let quests = await sut.getCompletedQuests(for: "test-user-123")
        
        // Then
        XCTAssertEqual(quests.count, 2)
        XCTAssertEqual(quests.first?.fact, "Reading improves vocabulary") // Most recent first
        XCTAssertEqual(quests.last?.fact, "Swimming is great exercise")
    }
}