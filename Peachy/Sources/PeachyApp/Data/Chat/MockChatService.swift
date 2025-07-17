// MARK: - MockChatService

import Foundation

@MainActor
public final class MockChatService: ChatServiceProtocol {
    // In-memory storage for mock data
    private var threads: [ChatThread] = []
    private var messages: [ChatMessage] = []
    private var isInitialized = false
    
    public init() {
        // Sample data will be created on first access
    }
    
    private func ensureInitialized() {
        guard !isInitialized else { return }
        isInitialized = true
        createSampleData()
    }
    
    public func fetchThreads() async throws -> [ChatThread] {
        ensureInitialized()
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        return threads
    }
    
    public func fetchMessages(threadID: String) async throws -> [ChatMessage] {
        ensureInitialized()
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)
        return messages
            .filter { $0.threadID == threadID }
            .sorted { $0.timestamp < $1.timestamp }
    }
    
    public func sendMessage(threadID: String, text: String) async throws -> ChatMessage {
        ensureInitialized()
        let currentUserID = ServiceContainer.shared.authService.currentUser?.id ?? ""
        
        let message = ChatMessage(
            threadID: threadID,
            senderID: currentUserID,
            text: text
        )
        
        messages.append(message)
        
        // Update thread's last message date
        if let index = threads.firstIndex(where: { $0.id == threadID }) {
            threads[index].lastMessageDate = Date()
        }
        
        // Simulate bot reply after delay
        Task {
            try await Task.sleep(nanoseconds: 600_000_000)
            await sendBotReply(to: threadID, originalMessage: text)
        }
        
        return message
    }
    
    public func createThread(with userID: String) async throws -> ChatThread {
        ensureInitialized()
        let currentUserID = ServiceContainer.shared.authService.currentUser?.id ?? ""
        
        let thread = ChatThread(
            participantIDs: [currentUserID, userID]
        )
        
        threads.append(thread)
        return thread
    }
    
    public func markMessagesAsRead(threadID: String) async throws {
        ensureInitialized()
        let currentUserID = ServiceContainer.shared.authService.currentUser?.id ?? ""
        
        for index in messages.indices {
            if messages[index].threadID == threadID && 
               messages[index].senderID != currentUserID {
                messages[index].isRead = true
            }
        }
    }
    
    private func sendBotReply(to threadID: String, originalMessage: String) async {
        let botMessage = ChatMessage(
            threadID: threadID,
            senderID: "bot",
            text: generateBotReply(to: originalMessage)
        )
        
        messages.append(botMessage)
        
        // Update thread's last message date
        if let index = threads.firstIndex(where: { $0.id == threadID }) {
            threads[index].lastMessageDate = Date()
        }
    }
    
    private func generateBotReply(to message: String) -> String {
        let replies = [
            "That's interesting! Tell me more.",
            "I understand how you feel.",
            "Thanks for sharing that with me.",
            "How does that make you feel?",
            "I'm here to listen."
        ]
        return replies.randomElement() ?? "I hear you."
    }
    
    // Public method to ensure initial data is seeded
    public func ensureInitialData() {
        ensureInitialized()
    }
    
    private func createSampleData() {
        // Create a sample thread with the current user's parent/teen
        let currentUserID = ServiceContainer.shared.authService.currentUser?.id ?? ""
        let otherUserID = "mom-user-id"
        
        var thread = ChatThread(
            id: "momThread",
            participantIDs: [currentUserID, otherUserID]
        )
        
        // Add some sample messages
        let sampleMessages = [
            ChatMessage(
                threadID: thread.id,
                senderID: otherUserID,
                text: "Hey! How was your day?",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: true
            ),
            ChatMessage(
                threadID: thread.id,
                senderID: currentUserID,
                text: "It was good! Just finished homework.",
                timestamp: Date().addingTimeInterval(-3000),
                isRead: true
            ),
            ChatMessage(
                threadID: thread.id,
                senderID: otherUserID,
                text: "That's great! Want to talk about anything?",
                timestamp: Date().addingTimeInterval(-1800),
                isRead: false
            ),
            // Add 4 more unread messages to make 5 total
            ChatMessage(
                threadID: thread.id,
                senderID: otherUserID,
                text: "I noticed you've been doing great with your moods lately!",
                timestamp: Date().addingTimeInterval(-1200),
                isRead: false
            ),
            ChatMessage(
                threadID: thread.id,
                senderID: otherUserID,
                text: "Keep up the good work!",
                timestamp: Date().addingTimeInterval(-900),
                isRead: false
            ),
            ChatMessage(
                threadID: thread.id,
                senderID: otherUserID,
                text: "Would you like to do a quest together?",
                timestamp: Date().addingTimeInterval(-600),
                isRead: false
            ),
            ChatMessage(
                threadID: thread.id,
                senderID: otherUserID,
                text: "Let me know when you're free!",
                timestamp: Date().addingTimeInterval(-300),
                isRead: false
            )
        ]
        
        messages.append(contentsOf: sampleMessages)
        thread.lastMessageDate = sampleMessages.last?.timestamp
        threads.append(thread)
    }
}