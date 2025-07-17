import XCTest
@testable import PeachyApp

final class ChatServiceTests: XCTestCase {
    var chatService: MockChatService!
    var authService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        chatService = MockChatService()
        authService = ServiceContainer.shared.authService as? MockAuthService
    }
    
    func testFetchThreads() async throws {
        // Create a test thread
        let thread = try await chatService.createThread(with: "test-user-id")
        
        // Fetch threads
        let threads = try await chatService.fetchThreads()
        
        XCTAssert(threads.contains { $0.id == thread.id })
    }
    
    func testSendMessage() async throws {
        // Create a thread first
        let thread = try await chatService.createThread(with: "test-user-id")
        
        // Send a message
        let message = try await chatService.sendMessage(
            threadID: thread.id,
            text: "Hello, test!"
        )
        
        XCTAssertEqual(message.text, "Hello, test!")
        XCTAssertEqual(message.threadID, thread.id)
    }
    
    func testFetchMessages() async throws {
        // Create a thread and send messages
        let thread = try await chatService.createThread(with: "test-user-id")
        
        _ = try await chatService.sendMessage(
            threadID: thread.id,
            text: "First message"
        )
        
        _ = try await chatService.sendMessage(
            threadID: thread.id,
            text: "Second message"
        )
        
        // Fetch messages
        let messages = try await chatService.fetchMessages(threadID: thread.id)
        
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].text, "First message")
        XCTAssertEqual(messages[1].text, "Second message")
    }
    
    func testMarkMessagesAsRead() async throws {
        // Create a thread and send a message
        let thread = try await chatService.createThread(with: "test-user-id")
        
        let message = try await chatService.sendMessage(
            threadID: thread.id,
            text: "Unread message"
        )
        
        // Initially message should be unread
        XCTAssertFalse(message.isRead)
        
        // Mark messages as read
        try await chatService.markMessagesAsRead(threadID: thread.id)
        
        // Verify messages are marked as read
        let messages = try await chatService.fetchMessages(threadID: thread.id)
        XCTAssertTrue(messages.allSatisfy { $0.isRead })
    }
}