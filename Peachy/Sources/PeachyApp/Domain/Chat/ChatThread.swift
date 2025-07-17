// MARK: - ChatThread

import Foundation

public struct ChatThread: Identifiable, Codable, Hashable {
    public let id: String
    public let participantIDs: [String]
    public let createdAt: Date
    public var lastMessageDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        participantIDs: [String],
        createdAt: Date = Date(),
        lastMessageDate: Date? = nil
    ) {
        self.id = id
        self.participantIDs = participantIDs
        self.createdAt = createdAt
        self.lastMessageDate = lastMessageDate
    }
    
    // Computed property to expose participantIDs as participants
    public var participants: [String] {
        participantIDs
    }
    
    // Helper method to get the other participant
    public func otherParticipant(for userID: String) -> String {
        participantIDs.first { $0 != userID } ?? ""
    }
}