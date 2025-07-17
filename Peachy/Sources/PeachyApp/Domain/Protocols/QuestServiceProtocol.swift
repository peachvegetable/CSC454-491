import Foundation
import RealmSwift

@MainActor
public protocol QuestServiceProtocol {
    func markDone(hobby: HobbyPresetItem, fact: String) async throws
    func getCompletedQuests(for userId: String) async -> [QuestModel]
}