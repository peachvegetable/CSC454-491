import Foundation
import RealmSwift

public class MoodLog: Object, Identifiable {
    @Persisted public var id: String = UUID().uuidString
    @Persisted public var userId: String = ""
    @Persisted public var colorHex: String = ""
    @Persisted public var colorName: String = ""  // Store SimpleMoodColor name
    @Persisted public var moodLabel: String = ""
    @Persisted public var emoji: String = ""
    @Persisted public var createdAt: Date = Date()
    @Persisted public var bufferMinutes: Int?
    
    public override static func primaryKey() -> String? {
        return "id"
    }
    
    public convenience init(color: SimpleMoodColor, emoji: String?) {
        self.init()
        self.id = UUID().uuidString
        self.userId = "current-user" // In real app, get from auth service
        self.colorHex = color.hex
        self.colorName = color.rawValue
        self.moodLabel = color.displayName
        self.emoji = emoji ?? ""
        self.createdAt = Date()
    }
    
    var moodColor: MoodColor? {
        return MoodColor.allCases.first { $0.hex == colorHex }
    }
}

enum MoodColor: String, CaseIterable {
    case good = "Good"
    case okay = "Okay"
    case tough = "Tough"
    
    var hex: String {
        switch self {
        case .good: return "#34C759"
        case .okay: return "#FFCC00"
        case .tough: return "#FF3B30"
        }
    }
    
    var color: String {
        return hex
    }
}