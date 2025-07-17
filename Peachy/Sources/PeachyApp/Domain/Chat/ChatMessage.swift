// MARK: - ChatMessage

import Foundation

public struct ChatMessage: Identifiable, Codable {
    public let id: String
    public let threadID: String
    public let senderID: String
    public let text: String
    public let timestamp: Date
    public var isRead: Bool
    
    public init(
        id: String = UUID().uuidString,
        threadID: String,
        senderID: String,
        text: String,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.threadID = threadID
        self.senderID = senderID
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
    }
}