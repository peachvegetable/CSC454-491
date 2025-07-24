import Foundation
import RealmSwift

@MainActor
public protocol QuestServiceProtocol {
    func getTodaysQuest() async -> Quest?
    func markDone(hobby: HobbyPresetItem, fact: String) async throws
    func getCompletedQuests(for userId: String) async -> [QuestModel]
    func isQuestCompleted(_ quest: Quest) async -> Bool
}