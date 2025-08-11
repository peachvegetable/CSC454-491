import Foundation
import RealmSwift

// MARK: - Feature Flags
public enum AppFeature: String, CaseIterable {
    case moodTracking = "mood_tracking"
    case chat = "chat"
    case hobbySharing = "hobby_sharing"
    case taskRewards = "task_rewards"
    case treeGarden = "tree_garden"
    case familyPhotos = "family_photos"
    case aiAssistant = "ai_assistant"
    case moodHistory = "mood_history"
    
    public var displayName: String {
        switch self {
        case .moodTracking: return "Mood Tracking"
        case .chat: return "Family Chat"
        case .hobbySharing: return "Hobby Sharing & Quiz"
        case .taskRewards: return "Tasks & Rewards"
        case .treeGarden: return "Tree Garden Game"
        case .familyPhotos: return "Family Photo Wall"
        case .aiAssistant: return "AI Coach"
        case .moodHistory: return "Mood History"
        }
    }
    
    public var description: String {
        switch self {
        case .moodTracking: 
            return "Core feature for sharing emotions with color and emoji selections"
        case .chat: 
            return "Real-time messaging between family members"
        case .hobbySharing: 
            return "Share interests and learn about each other through fun quizzes"
        case .taskRewards: 
            return "Assign tasks, earn points, and redeem rewards"
        case .treeGarden: 
            return "Grow virtual trees using earned points"
        case .familyPhotos: 
            return "Share and view family memories together"
        case .aiAssistant: 
            return "Get personalized mental health tips and support"
        case .moodHistory: 
            return "View past mood entries and patterns"
        }
    }
    
    public var icon: String {
        switch self {
        case .moodTracking: return "face.smiling"
        case .chat: return "message.fill"
        case .hobbySharing: return "sparkles"
        case .taskRewards: return "checkmark.circle.fill"
        case .treeGarden: return "tree.fill"
        case .familyPhotos: return "photo.stack"
        case .aiAssistant: return "brain.head.profile"
        case .moodHistory: return "chart.line.uptrend.xyaxis"
        }
    }
    
    public var isCore: Bool {
        // Mood tracking is always enabled as it's the core feature
        return self == .moodTracking
    }
    
    public var category: FeatureCategory {
        switch self {
        case .moodTracking, .moodHistory:
            return .emotional
        case .chat, .hobbySharing, .familyPhotos:
            return .communication
        case .taskRewards, .treeGarden:
            return .gamification
        case .aiAssistant:
            return .support
        }
    }
    
    // Dependencies - features that must be enabled for this to work
    public var dependencies: [AppFeature] {
        switch self {
        case .moodHistory:
            return [.moodTracking]
        case .taskRewards:
            return [] // Independent now with unified points
        case .treeGarden:
            return [] // Can work with any point source
        default:
            return []
        }
    }
}

public enum FeatureCategory: String, CaseIterable {
    case emotional = "Emotional Wellness"
    case communication = "Communication"
    case gamification = "Gamification & Rewards"
    case support = "Support Tools"
    
    public var icon: String {
        switch self {
        case .emotional: return "heart.fill"
        case .communication: return "bubble.left.and.bubble.right.fill"
        case .gamification: return "gamecontroller.fill"
        case .support: return "lifepreserver.fill"
        }
    }
}

// MARK: - Feature Settings Model
public class FeatureSettings: Object {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted public var familyId: String = ""
    @Persisted public var enabledFeatures = List<String>() // AppFeature raw values
    @Persisted public var featureConfigs = Map<String, String>() // JSON configs for advanced settings
    @Persisted public var lastModifiedBy: String = ""
    @Persisted public var lastModifiedByName: String = ""
    @Persisted public var lastModifiedAt: Date = Date()
    @Persisted public var createdAt: Date = Date()
    
    // Preset configurations
    @Persisted public var presetType: String = FeaturePreset.full.rawValue
    
    public convenience init(familyId: String, preset: FeaturePreset = .full) {
        self.init()
        self.id = ObjectId.generate()
        self.familyId = familyId
        self.presetType = preset.rawValue
        self.createdAt = Date()
        self.lastModifiedAt = Date()
        
        // Don't apply preset in init - do it after saving to Realm
        // to avoid modifying Lists/Maps outside of a write transaction
    }
    
    public func applyPreset(_ preset: FeaturePreset) {
        enabledFeatures.removeAll()
        enabledFeatures.append(objectsIn: preset.enabledFeatures.map { $0.rawValue })
        presetType = preset.rawValue
    }
    
    public func isEnabled(_ feature: AppFeature) -> Bool {
        if feature.isCore {
            return true
        }
        return enabledFeatures.contains(feature.rawValue)
    }
    
    public func toggle(_ feature: AppFeature) {
        guard !feature.isCore else { return }
        
        // This method should only be called within a Realm write transaction
        // The caller is responsible for wrapping this in a write block
        
        if let index = enabledFeatures.firstIndex(of: feature.rawValue) {
            enabledFeatures.remove(at: index)
            // Also disable features that depend on this
            for depFeature in AppFeature.allCases {
                if depFeature.dependencies.contains(feature) {
                    if let depIndex = enabledFeatures.firstIndex(of: depFeature.rawValue) {
                        enabledFeatures.remove(at: depIndex)
                    }
                }
            }
        } else {
            // First enable dependencies
            for dep in feature.dependencies {
                if !enabledFeatures.contains(dep.rawValue) {
                    enabledFeatures.append(dep.rawValue)
                }
            }
            enabledFeatures.append(feature.rawValue)
        }
    }
    
    public func enabledFeaturesSet() -> Set<AppFeature> {
        var features = Set(enabledFeatures.compactMap { AppFeature(rawValue: $0) })
        // Always include core features
        for feature in AppFeature.allCases where feature.isCore {
            features.insert(feature)
        }
        return features
    }
}

// MARK: - Feature Presets
public enum FeaturePreset: String, CaseIterable {
    case essential = "Essential"
    case balanced = "Balanced"
    case full = "Full Experience"
    
    public var description: String {
        switch self {
        case .essential:
            return "Core features only - mood tracking and chat"
        case .balanced:
            return "Core features plus educational content"
        case .full:
            return "All features enabled for the complete experience"
        }
    }
    
    public var enabledFeatures: [AppFeature] {
        switch self {
        case .essential:
            return [.moodTracking, .chat, .moodHistory]
        case .balanced:
            return [.moodTracking, .chat, .hobbySharing, .moodHistory, .familyPhotos]
        case .full:
            return AppFeature.allCases
        }
    }
}

// MARK: - Feature Request
public class FeatureRequest: Object {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted public var requesterId: String = ""
    @Persisted public var requesterName: String = ""
    @Persisted public var featureRaw: String = ""
    @Persisted public var reason: String = ""
    @Persisted public var status: String = "pending" // pending, approved, denied
    @Persisted public var requestedAt: Date = Date()
    @Persisted public var respondedAt: Date?
    @Persisted public var respondedBy: String?
    
    public var feature: AppFeature? {
        AppFeature(rawValue: featureRaw)
    }
    
    public convenience init(requesterId: String, requesterName: String, feature: AppFeature, reason: String = "") {
        self.init()
        self.id = ObjectId.generate()
        self.requesterId = requesterId
        self.requesterName = requesterName
        self.featureRaw = feature.rawValue
        self.reason = reason
        self.requestedAt = Date()
    }
}