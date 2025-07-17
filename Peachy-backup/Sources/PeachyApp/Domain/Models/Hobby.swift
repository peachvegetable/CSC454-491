import Foundation

public struct Hobby: Identifiable, Codable {
    public let id: String
    public let name: String
    public let category: HobbyCategory
    public let description: String
    public let emoji: String
    public var learnMoreUrl: String?
    
    public init(id: String, name: String, category: HobbyCategory, description: String, emoji: String, learnMoreUrl: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.emoji = emoji
        self.learnMoreUrl = learnMoreUrl
    }
    
    public enum HobbyCategory: String, Codable, CaseIterable {
        case sports = "Sports"
        case arts = "Arts"
        case music = "Music"
        case gaming = "Gaming"
        case technology = "Technology"
        case outdoors = "Outdoors"
        case reading = "Reading"
        case social = "Social"
        case creative = "Creative"
        case academic = "Academic"
        
        public var emoji: String {
            switch self {
            case .sports: return "⚽"
            case .arts: return "🎨"
            case .music: return "🎵"
            case .gaming: return "🎮"
            case .technology: return "💻"
            case .outdoors: return "🏕️"
            case .reading: return "📚"
            case .social: return "👥"
            case .creative: return "✨"
            case .academic: return "🎓"
            }
        }
    }
}

public struct HobbyIntroCard: Identifiable, Codable {
    public let id: String
    public let hobbyId: String
    public let userId: String
    public let title: String
    public let introText: String // 60-word AI-generated intro
    public let learnMoreUrl: String
    public let createdAt: Date
    public var isRead: Bool = false
    
    public init(id: String, hobbyId: String, userId: String, title: String, introText: String, learnMoreUrl: String, createdAt: Date, isRead: Bool = false) {
        self.id = id
        self.hobbyId = hobbyId
        self.userId = userId
        self.title = title
        self.introText = introText
        self.learnMoreUrl = learnMoreUrl
        self.createdAt = createdAt
        self.isRead = isRead
    }
}

public struct HobbyPreset {
    public static let presets: [Hobby] = [
        // Sports
        Hobby(id: "1", name: "Basketball", category: .sports, description: "Team sport with hoops", emoji: "🏀"),
        Hobby(id: "2", name: "Soccer", category: .sports, description: "World's most popular sport", emoji: "⚽"),
        Hobby(id: "3", name: "Swimming", category: .sports, description: "Water-based exercise", emoji: "🏊"),
        
        // Arts
        Hobby(id: "4", name: "Drawing", category: .arts, description: "Visual art with pencils", emoji: "✏️"),
        Hobby(id: "5", name: "Photography", category: .arts, description: "Capturing moments", emoji: "📷"),
        Hobby(id: "6", name: "Painting", category: .arts, description: "Art with colors", emoji: "🎨"),
        
        // Music
        Hobby(id: "7", name: "Guitar", category: .music, description: "String instrument", emoji: "🎸"),
        Hobby(id: "8", name: "Piano", category: .music, description: "Keyboard instrument", emoji: "🎹"),
        Hobby(id: "9", name: "Singing", category: .music, description: "Vocal performance", emoji: "🎤"),
        
        // Gaming
        Hobby(id: "10", name: "Video Games", category: .gaming, description: "Digital entertainment", emoji: "🎮"),
        Hobby(id: "11", name: "Board Games", category: .gaming, description: "Tabletop strategy", emoji: "🎲"),
        Hobby(id: "12", name: "Chess", category: .gaming, description: "Strategic board game", emoji: "♟️"),
        
        // Technology
        Hobby(id: "13", name: "Coding", category: .technology, description: "Computer programming", emoji: "💻"),
        Hobby(id: "14", name: "Robotics", category: .technology, description: "Building robots", emoji: "🤖"),
        Hobby(id: "15", name: "3D Printing", category: .technology, description: "Digital fabrication", emoji: "🖨️"),
        
        // Outdoors
        Hobby(id: "16", name: "Hiking", category: .outdoors, description: "Nature walks", emoji: "🥾"),
        Hobby(id: "17", name: "Camping", category: .outdoors, description: "Outdoor living", emoji: "⛺"),
        Hobby(id: "18", name: "Gardening", category: .outdoors, description: "Growing plants", emoji: "🌱"),
        
        // Reading
        Hobby(id: "19", name: "Fiction", category: .reading, description: "Story books", emoji: "📖"),
        Hobby(id: "20", name: "Comics", category: .reading, description: "Graphic novels", emoji: "💭"),
        Hobby(id: "21", name: "Poetry", category: .reading, description: "Verse writing", emoji: "📝"),
        
        // Social
        Hobby(id: "22", name: "Volunteering", category: .social, description: "Community service", emoji: "🤝"),
        Hobby(id: "23", name: "Drama Club", category: .social, description: "Theater performance", emoji: "🎭"),
        Hobby(id: "24", name: "Debate", category: .social, description: "Argumentative speaking", emoji: "💬"),
        
        // Creative
        Hobby(id: "25", name: "Writing", category: .creative, description: "Creative storytelling", emoji: "✍️"),
        Hobby(id: "26", name: "Crafts", category: .creative, description: "DIY projects", emoji: "🎨"),
        Hobby(id: "27", name: "Fashion", category: .creative, description: "Style and design", emoji: "👗"),
        
        // Academic
        Hobby(id: "28", name: "Science", category: .academic, description: "Scientific exploration", emoji: "🔬"),
        Hobby(id: "29", name: "Math", category: .academic, description: "Number puzzles", emoji: "🔢"),
        Hobby(id: "30", name: "Languages", category: .academic, description: "Learning new languages", emoji: "🗣️")
    ]
}