import Foundation
import RealmSwift

@MainActor
public class MockTreeService: TreeServiceProtocol {
    private let realmManager = RealmManager.shared
    
    public init() {}
    
    public func getCurrentTree(for userId: String) -> Tree? {
        let predicate = NSPredicate(format: "userId == %@ AND isFullyGrown == false", userId)
        return realmManager.fetch(Tree.self, predicate: predicate)
            .sorted(byKeyPath: "plantedAt", ascending: false)
            .first
    }
    
    public func waterTree(userId: String, points: Int) async throws -> WaterResult {
        // Validate input
        guard points > 0 else {
            throw TreeError.invalidPointAmount
        }
        
        // Get or create current tree
        var currentTree = getCurrentTree(for: userId)
        if currentTree == nil {
            currentTree = try await plantNewTree(userId: userId, type: .oak)
        }
        
        guard let tree = currentTree else {
            throw TreeError.noActiveTree
        }
        
        // Get user's available points
        guard let userPoints = realmManager.fetch(UserPoint.self, predicate: NSPredicate(format: "userId == %@", userId)).first else {
            throw TreeError.insufficientPoints
        }
        
        // Calculate points to use
        let pointsToUse = min(points, userPoints.points)
        let waterNeeded = tree.type.waterRequired - tree.currentWater
        let actualPointsUsed = min(pointsToUse, waterNeeded)
        
        if actualPointsUsed <= 0 {
            throw TreeError.treeAlreadyFullyGrown
        }
        
        // Update tree and user points
        try realmManager.realm.write {
            tree.currentWater += actualPointsUsed
            userPoints.points -= actualPointsUsed
            
            // Check if tree is fully grown
            if tree.currentWater >= tree.type.waterRequired {
                tree.isFullyGrown = true
                tree.grownAt = Date()
                
                // Update collection (we're already in a write transaction)
                updateTreeCollection(userId: userId, grownTree: tree, inWriteTransaction: true)
            }
        }
        
        // Check for newly unlocked trees
        let newUnlock = checkForNewUnlock(userId: userId)
        
        return WaterResult(
            tree: tree,
            pointsUsed: actualPointsUsed,
            didGrowFully: tree.isFullyGrown,
            newTreeUnlocked: newUnlock
        )
    }
    
    public func getTreeCollection(for userId: String) -> TreeCollection {
        let predicate = NSPredicate(format: "userId == %@", userId)
        if let collection = realmManager.fetch(TreeCollection.self, predicate: predicate).first {
            return collection
        }
        
        // Create new collection if doesn't exist
        let newCollection = TreeCollection(userId: userId)
        do {
            try realmManager.save(newCollection)
        } catch {
            print("Error creating tree collection: \(error)")
        }
        return newCollection
    }
    
    public func plantNewTree(userId: String, type: TreeType) async throws -> Tree {
        // Check if user can plant this tree type
        let collection = getTreeCollection(for: userId)
        guard collection.canUnlock(type: type) else {
            throw TreeError.treeTypeLocked
        }
        
        // Check if there's already an active tree
        if let existingTree = getCurrentTree(for: userId), !existingTree.isFullyGrown {
            throw TreeError.activeTreeExists
        }
        
        // Create new tree
        let newTree = Tree(userId: userId, type: type)
        try realmManager.save(newTree)
        
        return newTree
    }
    
    public func getAvailableTreeTypes(for userId: String) -> [TreeType] {
        let collection = getTreeCollection(for: userId)
        return TreeType.allCases.filter { collection.canUnlock(type: $0) }
    }
    
    // MARK: - Private Helpers
    
    private func updateTreeCollection(userId: String, grownTree: Tree, inWriteTransaction: Bool = false) {
        let collection = getTreeCollection(for: userId)
        
        let updateBlock = {
            collection.totalTreesGrown += 1
            
            // Check if this tree type was already collected
            if let existingEntry = collection.collectedTrees.first(where: { $0.treeType == grownTree.type }) {
                existingEntry.timesGrown += 1
            } else {
                let newEntry = CollectedTree()
                newEntry.id = ObjectId.generate()
                newEntry.treeType = grownTree.type
                collection.collectedTrees.append(newEntry)
                
                // Level up if collected all trees of current level
                let currentLevelTrees = TreeType.allCases.filter { $0.unlockLevel <= collection.currentLevel }
                let collectedTypes = Set(collection.collectedTrees.map { $0.treeType })
                
                if Set(currentLevelTrees).isSubset(of: collectedTypes) {
                    collection.currentLevel += 1
                }
            }
        }
        
        // Execute update in write transaction if needed
        if inWriteTransaction {
            updateBlock()
        } else {
            do {
                try realmManager.realm.write {
                    updateBlock()
                }
            } catch {
                print("Error updating tree collection: \(error)")
            }
        }
    }
    
    private func checkForNewUnlock(userId: String) -> TreeType? {
        let collection = getTreeCollection(for: userId)
        let availableTypes = getAvailableTreeTypes(for: userId)
        
        // Find the first unlocked but not yet grown tree
        return availableTypes.first { !collection.hasCollected(type: $0) }
    }
}

// MARK: - Tree Errors
enum TreeError: LocalizedError {
    case noActiveTree
    case insufficientPoints
    case treeAlreadyFullyGrown
    case treeTypeLocked
    case activeTreeExists
    case invalidPointAmount
    
    var errorDescription: String? {
        switch self {
        case .noActiveTree:
            return "No active tree to water"
        case .insufficientPoints:
            return "Not enough points to water the tree"
        case .treeAlreadyFullyGrown:
            return "This tree is already fully grown"
        case .treeTypeLocked:
            return "This tree type is not yet unlocked"
        case .activeTreeExists:
            return "You already have an active tree to grow"
        case .invalidPointAmount:
            return "Water amount must be greater than zero"
        }
    }
}