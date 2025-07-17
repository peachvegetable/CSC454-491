import Foundation
import RealmSwift

@MainActor
public protocol HobbyServiceProtocol {
    func getHobbies() async throws -> [HobbyPresetItem]
    func saveHobby(name: String, fact: String) async throws
    func allHobbies() async -> [HobbyModel]
    func markHobbyAsSeen(hobbyId: ObjectId, by userId: String) async throws -> Bool // Returns true if first time viewing
}

@MainActor  
public protocol PointServiceProtocol {
    func award(userId: String, delta: Int) async
    func total(for userId: String) async -> Int
}