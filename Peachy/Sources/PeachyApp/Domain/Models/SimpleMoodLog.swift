import Foundation

public struct SimpleMoodLog: Identifiable, Codable, Hashable {
    public let id: UUID
    public let date: Date
    public let color: SimpleMoodColor
    public let emoji: String?
    
    public init(id: UUID = UUID(), date: Date = Date(), color: SimpleMoodColor, emoji: String? = nil) {
        self.id = id
        self.date = date
        self.color = color
        self.emoji = emoji
    }
}

public enum SimpleMoodColor: String, Codable, CaseIterable {
    case green
    case yellow
    case red
    
    public var displayName: String {
        switch self {
        case .green: return "Good"
        case .yellow: return "Okay"
        case .red: return "Tough"
        }
    }
    
    public var hex: String {
        switch self {
        case .green: return "#34C759"
        case .yellow: return "#FFCC00"
        case .red: return "#FF3B30"
        }
    }
}