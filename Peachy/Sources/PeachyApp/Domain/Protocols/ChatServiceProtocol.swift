// MARK: - ChatServiceProtocol

import Foundation

public protocol ChatServiceProtocol {
    func fetchThreads() async throws -> [ChatThread]
    func fetchMessages(threadID: String) async throws -> [ChatMessage]
    func sendMessage(threadID: String, text: String) async throws -> ChatMessage
    func createThread(with userID: String) async throws -> ChatThread
    func markMessagesAsRead(threadID: String) async throws
    func ensureInitialData()
}