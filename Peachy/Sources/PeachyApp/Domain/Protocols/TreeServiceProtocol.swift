import Foundation

@MainActor
public protocol TreeServiceProtocol {
    func getCurrentTree(for userId: String) -> Tree?
    func waterTree(userId: String, points: Int) async throws -> WaterResult
    func getTreeCollection(for userId: String) -> TreeCollection
    func plantNewTree(userId: String, type: TreeType) async throws -> Tree
    func getAvailableTreeTypes(for userId: String) -> [TreeType]
}

public struct WaterResult {
    public let tree: Tree
    public let pointsUsed: Int
    public let didGrowFully: Bool
    public let newTreeUnlocked: TreeType?
    
    public init(tree: Tree, pointsUsed: Int, didGrowFully: Bool, newTreeUnlocked: TreeType? = nil) {
        self.tree = tree
        self.pointsUsed = pointsUsed
        self.didGrowFully = didGrowFully
        self.newTreeUnlocked = newTreeUnlocked
    }
}