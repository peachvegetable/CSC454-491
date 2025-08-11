import Foundation
import RealmSwift

// MARK: - Tip Enums

public enum TipCategory: String, CaseIterable {
    case immediateResponse = "immediate_response"
    case conversationStarter = "conversation_starter"
    case whatToAvoid = "what_to_avoid"
    case activitySuggestion = "activity_suggestion"
    case professionalResource = "professional_resource"
    
    public var displayName: String {
        switch self {
        case .immediateResponse: return "Immediate Response"
        case .conversationStarter: return "Conversation Starters"
        case .whatToAvoid: return "What to Avoid"
        case .activitySuggestion: return "Activity Ideas"
        case .professionalResource: return "Professional Resources"
        }
    }
    
    public var icon: String {
        switch self {
        case .immediateResponse: return "bolt.fill"
        case .conversationStarter: return "bubble.left.and.bubble.right.fill"
        case .whatToAvoid: return "exclamationmark.triangle.fill"
        case .activitySuggestion: return "star.fill"
        case .professionalResource: return "cross.circle.fill"
        }
    }
}

public enum UrgencyLevel: String, CaseIterable {
    case immediate = "immediate"  // Within 5-30 minutes
    case soon = "soon"            // Within 1-2 hours
    case awareness = "awareness"  // General awareness, no immediate action needed
    
    public var displayName: String {
        switch self {
        case .immediate: return "Check in now"
        case .soon: return "Check in soon"
        case .awareness: return "Be aware"
        }
    }
    
    public var color: String {
        switch self {
        case .immediate: return "#FF6B6B"  // Red
        case .soon: return "#FFB84D"       // Orange
        case .awareness: return "#4ECDC4"  // Teal
        }
    }
    
    public var notificationDelay: TimeInterval {
        switch self {
        case .immediate: return 0
        case .soon: return 300  // 5 minutes delay
        case .awareness: return 1800  // 30 minutes delay
        }
    }
}

public enum AgeRange: String, CaseIterable {
    case young = "8-12"
    case teen = "13-18"
    case all = "all"
    
    public func includes(age: Int) -> Bool {
        switch self {
        case .young: return age >= 8 && age <= 12
        case .teen: return age >= 13 && age <= 18
        case .all: return age >= 8 && age <= 18
        }
    }
}

public enum MoodPattern: String {
    case suddenDrop = "sudden_drop"
    case prolongedLow = "prolonged_low"
    case firstNegative = "first_negative"
    case lateNight = "late_night"
    case multipleBad = "multiple_bad"
    case improving = "improving"
    
    public var description: String {
        switch self {
        case .suddenDrop: return "Sudden mood drop detected"
        case .prolongedLow: return "Low mood for several days"
        case .firstNegative: return "First difficult mood after positive streak"
        case .lateNight: return "Late night mood entry"
        case .multipleBad: return "Multiple difficult moods today"
        case .improving: return "Mood seems to be improving"
        }
    }
}

// MARK: - Support Insight Model (formerly EmpathyTip)
// Note: Keeping class name as EmpathyTip for backward compatibility with Realm

public class EmpathyTip: Object {
    @Persisted public var id = ObjectId.generate()
    @Persisted public var categoryRaw: String = TipCategory.immediateResponse.rawValue
    @Persisted public var title: String = ""
    @Persisted public var content: String = ""
    @Persisted public var urgencyRaw: String = UrgencyLevel.awareness.rawValue
    @Persisted public var ageRangeRaw: String = AgeRange.all.rawValue
    @Persisted public var triggerColors = List<String>()  // SimpleMoodColor raw values
    @Persisted public var triggerPatterns = List<String>()  // MoodPattern raw values
    @Persisted public var childHobbies = List<String>()  // Optional: specific to child's hobbies
    @Persisted public var examplePhrases = List<String>()
    @Persisted public var whatToAvoid = List<String>()
    @Persisted public var followUpSuggestions = List<String>()
    @Persisted public var isActive: Bool = true
    @Persisted public var createdAt: Date = Date()
    
    public override static func primaryKey() -> String? {
        return "id"
    }
    
    // Computed properties
    public var category: TipCategory? {
        return TipCategory(rawValue: categoryRaw)
    }
    
    public var urgency: UrgencyLevel? {
        return UrgencyLevel(rawValue: urgencyRaw)
    }
    
    public var ageRange: AgeRange? {
        return AgeRange(rawValue: ageRangeRaw)
    }
    
    // Helper initializer
    public convenience init(
        category: TipCategory,
        title: String,
        content: String,
        urgency: UrgencyLevel,
        ageRange: AgeRange,
        triggerColors: [SimpleMoodColor] = [],
        triggerPatterns: [MoodPattern] = []
    ) {
        self.init()
        self.categoryRaw = category.rawValue
        self.title = title
        self.content = content
        self.urgencyRaw = urgency.rawValue
        self.ageRangeRaw = ageRange.rawValue
        
        self.triggerColors.removeAll()
        self.triggerColors.append(objectsIn: triggerColors.map { $0.rawValue })
        
        self.triggerPatterns.removeAll()
        self.triggerPatterns.append(objectsIn: triggerPatterns.map { $0.rawValue })
    }
}

// MARK: - Tip Delivery Record

public class TipDelivery: Object {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted public var tipId: ObjectId?
    @Persisted public var parentUserId: String = ""
    @Persisted public var childUserId: String = ""
    @Persisted public var childName: String = ""
    @Persisted public var deliveredAt: Date = Date()
    @Persisted public var viewedAt: Date?
    @Persisted public var wasHelpful: Bool?
    @Persisted public var parentNotes: String?
    @Persisted public var moodBeforeRaw: String?  // SimpleMoodColor before tip
    @Persisted public var moodAfterRaw: String?   // SimpleMoodColor after tip (if tracked)
    @Persisted public var patternRaw: String = ""  // MoodPattern that triggered it
    
    public var pattern: MoodPattern? {
        return MoodPattern(rawValue: patternRaw)
    }
}

// MARK: - Notification Record

public class EmpathyNotification: Object {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted public var tipDeliveryId: ObjectId?
    @Persisted public var scheduledFor: Date = Date()
    @Persisted public var sentAt: Date?
    @Persisted public var opened: Bool = false
    @Persisted public var childName: String = ""
    @Persisted public var moodContext: String = ""
    @Persisted public var primaryTip: String = ""
    @Persisted public var additionalTips = List<String>()
    @Persisted public var urgencyRaw: String = UrgencyLevel.awareness.rawValue
    
    public var urgency: UrgencyLevel? {
        return UrgencyLevel(rawValue: urgencyRaw)
    }
}

// MARK: - Support Insights Factory

public struct EmpathyTipFactory {
    public static func createDefaultInsights() -> [EmpathyTip] {
        var tips: [EmpathyTip] = []
        
        // Young Kids - Immediate Response
        tips.append(EmpathyTip(
            category: .immediateResponse,
            title: "Your child needs comfort",
            content: "When young children show distress, physical comfort often helps before words. Try a hug, sitting close, or offering their favorite stuffed animal.",
            urgency: .immediate,
            ageRange: .young,
            triggerColors: [.red],
            triggerPatterns: [.suddenDrop, .multipleBad]
        ))
        
        // Young Kids - Conversation Starters
        tips.append(EmpathyTip(
            category: .conversationStarter,
            title: "Opening up through play",
            content: "Try: 'Want to help me make cookies? We can chat while we bake.' or 'Should we take the dog for a walk together?'",
            urgency: .soon,
            ageRange: .young,
            triggerColors: [.yellow],
            triggerPatterns: [.firstNegative]
        ))
        
        // Teens - Immediate Response
        tips.append(EmpathyTip(
            category: .immediateResponse,
            title: "Give space, then connect",
            content: "Teens often need processing time. Wait 30 minutes, then try a low-key approach: knock gently and ask if they want a snack or drink.",
            urgency: .immediate,
            ageRange: .teen,
            triggerColors: [.red],
            triggerPatterns: [.suddenDrop]
        ))
        
        // Teens - Conversation Starters
        tips.append(EmpathyTip(
            category: .conversationStarter,
            title: "Side-by-side conversations",
            content: "Suggest: 'Want to grab ice cream?' or 'I'm running to the store, want to come?' Teens often open up during parallel activities like driving.",
            urgency: .soon,
            ageRange: .teen,
            triggerColors: [.yellow, .red],
            triggerPatterns: [.prolongedLow]
        ))
        
        // All Ages - What to Avoid
        tips.append(EmpathyTip(
            category: .whatToAvoid,
            title: "Phrases that shut down communication",
            content: "Avoid: 'It's not that bad', 'You're overreacting', 'When I was your age...'. Instead try: 'That sounds really hard', 'I'm here to listen'.",
            urgency: .awareness,
            ageRange: .all,
            triggerColors: [],
            triggerPatterns: [.multipleBad, .prolongedLow]
        ))
        
        // All Ages - Activity Suggestions
        tips.append(EmpathyTip(
            category: .activitySuggestion,
            title: "Mood-lifting activities",
            content: "Based on your child's interests, try: art projects, music time, outdoor activities, or watching their favorite show together.",
            urgency: .awareness,
            ageRange: .all,
            triggerColors: [.yellow],
            triggerPatterns: [.prolongedLow]
        ))
        
        // Late Night Pattern
        tips.append(EmpathyTip(
            category: .immediateResponse,
            title: "Late night worries",
            content: "Late night negative moods often relate to sleep anxiety or next-day worries. Offer warm milk or tea, and ask about tomorrow's schedule.",
            urgency: .immediate,
            ageRange: .all,
            triggerColors: [],
            triggerPatterns: [.lateNight]
        ))
        
        return tips
    }
}