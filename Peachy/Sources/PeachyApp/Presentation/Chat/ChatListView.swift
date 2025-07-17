// MARK: - ChatListView

import SwiftUI

public struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @State private var path = [ChatThread]()
    
    public init() {}
    
    public var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.threads) { thread in
                        ChatRow(
                            thread: thread,
                            unread: viewModel.unreadCounts[thread.id] ?? 0,
                            latestMood: viewModel.getMoodLog(for: thread)
                        )
                        .onTapGesture {
                            path.append(thread)
                        }
                        
                        Divider()
                    }
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ChatThread.self) { thread in
                ChatView(thread: thread)
            }
            .onAppear {
                viewModel.loadThreads()
            }
        }
    }
}