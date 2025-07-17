import Foundation

public struct HobbyPresetItem: Identifiable, Codable {
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
    public static let presets: [HobbyPresetItem] = [
        // Sports
        HobbyPresetItem(id: "1", name: "Basketball", category: .sports, description: "Team sport with hoops", emoji: "🏀"),
        HobbyPresetItem(id: "2", name: "Soccer", category: .sports, description: "World's most popular sport", emoji: "⚽"),
        HobbyPresetItem(id: "3", name: "Swimming", category: .sports, description: "Water-based exercise", emoji: "🏊"),
        
        // Arts
        HobbyPresetItem(id: "4", name: "Drawing", category: .arts, description: "Visual art with pencils", emoji: "✏️"),
        HobbyPresetItem(id: "5", name: "Photography", category: .arts, description: "Capturing moments", emoji: "📷"),
        HobbyPresetItem(id: "6", name: "Painting", category: .arts, description: "Art with colors", emoji: "🎨"),
        
        // Music
        HobbyPresetItem(id: "7", name: "Guitar", category: .music, description: "String instrument", emoji: "🎸"),
        HobbyPresetItem(id: "8", name: "Piano", category: .music, description: "Keyboard instrument", emoji: "🎹"),
        HobbyPresetItem(id: "9", name: "Singing", category: .music, description: "Vocal performance", emoji: "🎤"),
        
        // Gaming
        HobbyPresetItem(id: "10", name: "Video Games", category: .gaming, description: "Digital entertainment", emoji: "🎮"),
        HobbyPresetItem(id: "11", name: "Board Games", category: .gaming, description: "Tabletop strategy", emoji: "🎲"),
        HobbyPresetItem(id: "12", name: "Chess", category: .gaming, description: "Strategic board game", emoji: "♟️"),
        
        // Technology
        HobbyPresetItem(id: "13", name: "Coding", category: .technology, description: "Computer programming", emoji: "💻"),
        HobbyPresetItem(id: "14", name: "Robotics", category: .technology, description: "Building robots", emoji: "🤖"),
        HobbyPresetItem(id: "15", name: "3D Printing", category: .technology, description: "Digital fabrication", emoji: "🖨️"),
        
        // Outdoors
        HobbyPresetItem(id: "16", name: "Hiking", category: .outdoors, description: "Nature walks", emoji: "🥾"),
        HobbyPresetItem(id: "17", name: "Camping", category: .outdoors, description: "Outdoor living", emoji: "⛺"),
        HobbyPresetItem(id: "18", name: "Gardening", category: .outdoors, description: "Growing plants", emoji: "🌱"),
        
        // Reading
        HobbyPresetItem(id: "19", name: "Fiction", category: .reading, description: "Story books", emoji: "📖"),
        HobbyPresetItem(id: "20", name: "Comics", category: .reading, description: "Graphic novels", emoji: "💭"),
        HobbyPresetItem(id: "21", name: "Poetry", category: .reading, description: "Verse writing", emoji: "📝"),
        
        // Social
        HobbyPresetItem(id: "22", name: "Volunteering", category: .social, description: "Community service", emoji: "🤝"),
        HobbyPresetItem(id: "23", name: "Drama Club", category: .social, description: "Theater performance", emoji: "🎭"),
        HobbyPresetItem(id: "24", name: "Debate", category: .social, description: "Argumentative speaking", emoji: "💬"),
        
        // Creative
        HobbyPresetItem(id: "25", name: "Writing", category: .creative, description: "Creative storytelling", emoji: "✍️"),
        HobbyPresetItem(id: "26", name: "Crafts", category: .creative, description: "DIY projects", emoji: "🎨"),
        HobbyPresetItem(id: "27", name: "Fashion", category: .creative, description: "Style and design", emoji: "👗"),
        
        // Academic
        HobbyPresetItem(id: "28", name: "Science", category: .academic, description: "Scientific exploration", emoji: "🔬"),
        HobbyPresetItem(id: "29", name: "Math", category: .academic, description: "Number puzzles", emoji: "🔢"),
        HobbyPresetItem(id: "30", name: "Languages", category: .academic, description: "Learning new languages", emoji: "🗣️")
    ]
}