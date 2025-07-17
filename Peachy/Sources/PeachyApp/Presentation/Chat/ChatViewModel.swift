// MARK: - ChatViewModel

import Foundation
import SwiftUI
import RealmSwift

@MainActor
public class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var otherUserName: String = "Chat"
    
    let thread: ChatThread
    let currentUserID: String
    
    private let chatService = ServiceContainer.shared.chatService
    private let authService = ServiceContainer.shared.authService
    
    public init(thread: ChatThread) {
        self.thread = thread
        self.currentUserID = authService.currentUser?.id ?? ""
        loadOtherUserName()
    }
    
    func loadMessages() {
        Task {
            do {
                messages = try await chatService.fetchMessages(threadID: thread.id)
            } catch {
                print("Error loading messages: \(error)")
            }
        }
    }
    
    func sendMessage(text: String) async {
        do {
            let message = try await chatService.sendMessage(
                threadID: thread.id,
                text: text
            )
            messages.append(message)
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    func markMessagesAsRead() {
        Task {
            do {
                try await chatService.markMessagesAsRead(threadID: thread.id)
            } catch {
                print("Error marking messages as read: \(error)")
            }
        }
    }
    
    private func loadOtherUserName() {
        let otherUserID = thread.participantIDs.first { $0 != currentUserID }
        
        guard let otherUserID = otherUserID else { return }
        
        let predicate = NSPredicate(format: "id == %@", otherUserID)
        if let otherUser = RealmManager.shared.fetch(UserProfile.self, predicate: predicate).first {
            otherUserName = otherUser.displayName
        }
    }
}