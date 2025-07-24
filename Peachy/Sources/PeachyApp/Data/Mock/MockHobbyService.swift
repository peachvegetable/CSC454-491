import Foundation
import RealmSwift

@MainActor
public final class MockHobbyService: HobbyServiceProtocol {
    private let realmManager = RealmManager.shared
    private var authService: AuthServiceProtocol?
    private var pointService: PointServiceProtocol?
    
    public init() {}
    
    // Set services after initialization to avoid circular dependency
    public func setAuthService(_ service: AuthServiceProtocol) {
        self.authService = service
    }
    
    public func setPointService(_ service: PointServiceProtocol) {
        self.pointService = service
    }
    
    public func getHobbies() async throws -> [HobbyPresetItem] {
        return HobbyPreset.presets
    }
    
    public func saveHobby(name: String, fact: String) async throws {
        guard let authService = authService, 
              let currentUserId = authService.currentUser?.id else {
            throw NSError(domain: "HobbyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        print("MockHobbyService.saveHobby - Starting save for hobby: \(name), user: \(currentUserId)")
        
        // Create and save hobby
        let hobby = HobbyModel(name: name, ownerId: currentUserId, fact: fact)
        try realmManager.save(hobby)
        print("MockHobbyService.saveHobby - Hobby saved with ID: \(hobby.id)")
        
        // Create flash card
        let question = "What's something interesting about \(name)?"
        let flashCard = FlashCard(question: question, answer: fact, hobbyId: hobby.id)
        try realmManager.save(flashCard)
        print("MockHobbyService.saveHobby - Flash card created with ID: \(flashCard.id)")
        
        // Award points to creator
        if let pointService = pointService {
            print("MockHobbyService.saveHobby - Awarding 5 points to user: \(currentUserId)")
            await pointService.award(userId: currentUserId, delta: 5)
            print("MockHobbyService.saveHobby - Points awarded successfully")
        }
    }
    
    public func allHobbies() async -> [HobbyModel] {
        let hobbies = realmManager.fetch(HobbyModel.self)
            .sorted(byKeyPath: "createdAt", ascending: false)
        return Array(hobbies)
    }
    
    public func markHobbyAsSeen(hobbyId: ObjectId, by userId: String) async throws -> Bool {
        guard let hobby = realmManager.realm.object(ofType: HobbyModel.self, forPrimaryKey: hobbyId) else {
            return false
        }
        
        // Check if user has already seen this hobby
        if hobby.seenBy.contains(where: { $0 == userId }) {
            return false
        }
        
        // Mark as seen
        try realmManager.realm.write {
            hobby.seenBy.append(userId)
        }
        
        // Award point for viewing
        if let pointService = pointService {
            await pointService.award(userId: userId, delta: 1)
        }
        
        return true
    }
}