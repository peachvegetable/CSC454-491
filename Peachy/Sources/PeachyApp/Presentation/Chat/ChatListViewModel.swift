// MARK: - ChatListViewModel

import Foundation
import SwiftUI

@MainActor
public class ChatListViewModel: ObservableObject {
    @Published var threads: [ChatThread] = []
    @Published var unreadCounts: [String: Int] = [:]
    
    private let chatService = ServiceContainer.shared.chatService
    private let authService = ServiceContainer.shared.authService
    private let moodService = MockMoodService()
    
    func loadThreads() {
        Task { @MainActor in
            do {
                threads = try await chatService.fetchThreads()
                await loadUnreadCounts()
            } catch {
                print("Error loading threads: \(error)")
            }
        }
    }
    
    @MainActor
    func getOtherUser(in thread: ChatThread) -> UserProfile? {
        let currentUserID = authService.currentUser?.id ?? ""
        let otherUserID = thread.participantIDs.first { $0 != currentUserID }
        
        guard let otherUserID = otherUserID else { return nil }
        
        let predicate = NSPredicate(format: "id == %@", otherUserID)
        return RealmManager.shared.fetch(UserProfile.self, predicate: predicate).first
    }
    
    @MainActor
    func getMoodLog(for thread: ChatThread) -> MoodLog? {
        let otherUser = getOtherUser(in: thread)
        guard let userId = otherUser?.id else { return nil }
        
        return moodService.getLatestMoodLog(for: userId)
    }
    
    private func loadUnreadCounts() async {
        var newUnreadCounts: [String: Int] = [:]
        
        for thread in threads {
            do {
                let messages = try await chatService.fetchMessages(threadID: thread.id)
                let currentUserID = authService.currentUser?.id ?? ""
                let unreadCount = messages.filter { 
                    !$0.isRead && $0.senderID != currentUserID 
                }.count
                
                newUnreadCounts[thread.id] = unreadCount
            } catch {
                print("Error loading unread count for thread \(thread.id): \(error)")
            }
        }
        
        await MainActor.run {
            self.unreadCounts = newUnreadCounts
        }
    }
}