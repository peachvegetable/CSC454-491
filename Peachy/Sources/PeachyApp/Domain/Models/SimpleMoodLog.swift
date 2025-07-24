import Foundation

public struct SimpleMoodLog: Identifiable, Codable, Hashable {
    public let id: String
    public let userId: String
    public let date: Date
    public let color: SimpleMoodColor
    public let emoji: String?
    public let bufferMinutes: Int?
    
    public init(id: String = UUID().uuidString, userId: String = "current-user", date: Date = Date(), color: SimpleMoodColor, emoji: String? = nil, bufferMinutes: Int? = nil) {
        self.id = id
        self.userId = userId
        self.date = date
        self.color = color
        self.emoji = emoji
        self.bufferMinutes = bufferMinutes
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