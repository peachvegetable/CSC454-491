// MARK: - ChatListView

import SwiftUI

public struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @State private var path = [ChatThread]()
    @Binding var hideFloatingButton: Bool
    
    public init(hideFloatingButton: Binding<Bool> = .constant(false)) {
        self._hideFloatingButton = hideFloatingButton
    }
    
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
                            hideFloatingButton = true
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
                    .toolbar(.hidden, for: .tabBar)
            }
            .onAppear {
                viewModel.loadThreads()
            }
            .onChange(of: path) { newPath in
                // Hide button when in chat, show when back to list
                hideFloatingButton = !newPath.isEmpty
            }
        }
    }
}