import Foundation
import RealmSwift

// MARK: - Tree Type Enum
public enum TreeType: String, CaseIterable {
    case oak = "oak"
    case cherry = "cherry"
    case maple = "maple"
    case pine = "pine"
    case willow = "willow"
    case bamboo = "bamboo"
    
    public var displayName: String {
        switch self {
        case .oak: return "Oak Tree"
        case .cherry: return "Cherry Blossom"
        case .maple: return "Maple Tree"
        case .pine: return "Pine Tree"
        case .willow: return "Willow Tree"
        case .bamboo: return "Bamboo"
        }
    }
    
    public var emoji: String {
        switch self {
        case .oak: return "🌳"
        case .cherry: return "🌸"
        case .maple: return "🍁"
        case .pine: return "🌲"
        case .willow: return "🌿"
        case .bamboo: return "🎋"
        }
    }
    
    public var waterRequired: Int {
        switch self {
        case .oak: return 100
        case .cherry: return 150
        case .maple: return 200
        case .pine: return 250
        case .willow: return 300
        case .bamboo: return 400
        }
    }
    
    public var unlockLevel: Int {
        switch self {
        case .oak: return 1
        case .cherry: return 2
        case .maple: return 3
        case .pine: return 4
        case .willow: return 5
        case .bamboo: return 6
        }
    }
}

// MARK: - Tree Model
public class Tree: Object, Identifiable {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted public var userId: String = ""
    @Persisted private var typeRaw: String = TreeType.oak.rawValue
    @Persisted public var currentWater: Int = 0
    @Persisted public var isFullyGrown: Bool = false
    @Persisted public var plantedAt: Date = Date()
    @Persisted public var grownAt: Date?
    
    public var type: TreeType {
        get { TreeType(rawValue: typeRaw) ?? .oak }
        set { typeRaw = newValue.rawValue }
    }
    
    public var growthProgress: Double {
        let progress = Double(currentWater) / Double(type.waterRequired)
        return min(progress, 1.0)
    }
    
    public var growthStage: GrowthStage {
        let progress = growthProgress
        switch progress {
        case 0..<0.25: return .seed
        case 0.25..<0.5: return .sprout
        case 0.5..<0.75: return .sapling
        case 0.75..<1.0: return .youngTree
        default: return .fullGrown
        }
    }
    
    public convenience init(userId: String, type: TreeType) {
        self.init()
        self.id = ObjectId.generate()
        self.userId = userId
        self.type = type
    }
}

// MARK: - Growth Stage
public enum GrowthStage: String, CaseIterable {
    case seed = "seed"
    case sprout = "sprout"
    case sapling = "sapling"
    case youngTree = "young_tree"
    case fullGrown = "full_grown"
    
    public var displayName: String {
        switch self {
        case .seed: return "Seed"
        case .sprout: return "Sprout"
        case .sapling: return "Sapling"
        case .youngTree: return "Young Tree"
        case .fullGrown: return "Fully Grown"
        }
    }
    
    public var heightMultiplier: Double {
        switch self {
        case .seed: return 0.1
        case .sprout: return 0.25
        case .sapling: return 0.5
        case .youngTree: return 0.75
        case .fullGrown: return 1.0
        }
    }
}

// MARK: - Tree Collection
public class TreeCollection: Object {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted public var userId: String = ""
    @Persisted public var collectedTrees = List<CollectedTree>()
    @Persisted public var currentLevel: Int = 1
    @Persisted public var totalTreesGrown: Int = 0
    
    public convenience init(userId: String) {
        self.init()
        self.id = ObjectId.generate()
        self.userId = userId
    }
    
    public func hasCollected(type: TreeType) -> Bool {
        return collectedTrees.contains(where: { $0.treeType == type })
    }
    
    public func canUnlock(type: TreeType) -> Bool {
        return currentLevel >= type.unlockLevel
    }
}

// MARK: - Collected Tree Entry
public class CollectedTree: Object {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted private var treeTypeRaw: String = TreeType.oak.rawValue
    @Persisted public var collectedAt: Date = Date()
    @Persisted public var timesGrown: Int = 1
    
    public var treeType: TreeType {
        get { TreeType(rawValue: treeTypeRaw) ?? .oak }
        set { treeTypeRaw = newValue.rawValue }
    }
}