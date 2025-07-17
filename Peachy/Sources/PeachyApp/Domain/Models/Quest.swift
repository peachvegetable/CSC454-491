import Foundation

public struct Quest: Identifiable, Hashable, Codable {
    public enum Kind: String, Codable { 
        case shareHobby, walk, playlist 
    }
    
    public let id: UUID
    public let title: String
    public let description: String
    public let kind: Kind
    
    public init(id: UUID = UUID(), title: String, description: String, kind: Kind) {
        self.id = id
        self.title = title
        self.description = description
        self.kind = kind
    }
}

extension Quest {
    public static let sample = Quest(
        id: UUID(),
        title: "Share a Hobby",
        description: "Pick one of your hobbies and share something interesting with your family.",
        kind: .shareHobby
    )
}