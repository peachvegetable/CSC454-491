import Foundation
import RealmSwift

@MainActor
public final class MockQuestService: QuestServiceProtocol {
    private let realmManager = RealmManager.shared
    private var authService: AuthServiceProtocol?
    private var pointService: PointServiceProtocol?
    private var hobbyService: HobbyServiceProtocol?
    
    public init() {}
    
    // Set services after initialization to avoid circular dependency
    public func setServices(authService: AuthServiceProtocol, pointService: PointServiceProtocol, hobbyService: HobbyServiceProtocol) {
        self.authService = authService
        self.pointService = pointService
        self.hobbyService = hobbyService
    }
    
    public func markDone(hobby: HobbyPresetItem, fact: String) async throws {
        guard let authService = authService,
              let hobbyService = hobbyService,
              let pointService = pointService,
              let currentUserId = authService.currentUser?.id else {
            throw NSError(domain: "QuestService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user or services not initialized"])
        }
        
        // Save the hobby fact
        try await hobbyService.saveHobby(name: hobby.name, fact: fact)
        
        // Get the created hobby model to get its ID
        let hobbies = await hobbyService.allHobbies()
        guard let hobbyModel = hobbies.first(where: { $0.name == hobby.name && $0.fact == fact }) else {
            throw NSError(domain: "QuestService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to find created hobby"])
        }
        
        // Create quest completion record
        let questModel = QuestModel(
            questType: Quest.Kind.shareHobby.rawValue,
            userId: currentUserId,
            hobbyId: hobbyModel.id,
            fact: fact
        )
        questModel.completedAt = Date()
        questModel.pointsAwarded = 5
        
        try realmManager.save(questModel)
        
        // Award points to all family members (in real app, would look up paired users)
        await pointService.award(userId: currentUserId, delta: 1)
        
        // If user has a paired user, award them points too
        if let pairedUserId = authService.currentUser?.pairedWithUserId {
            await pointService.award(userId: pairedUserId, delta: 1)
        }
    }
    
    public func getCompletedQuests(for userId: String) async -> [QuestModel] {
        let quests = realmManager.fetch(QuestModel.self)
            .filter("userId == %@", userId)
            .sorted(byKeyPath: "completedAt", ascending: false)
        return Array(quests)
    }
}