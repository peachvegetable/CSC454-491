import SwiftUI

public struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    public var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.moodLogs) { log in
                    MoodHistoryRow(log: log)
                }
                .onDelete(perform: viewModel.deleteLogs)
            }
            .navigationTitle("Mood History")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadHistory()
            }
            .task {
                await viewModel.loadHistory()
            }
        }
    }
}

struct MoodHistoryRow: View {
    let log: SimpleMoodLog
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: log.color.hex))
                .frame(width: 40, height: 40)
            
            if let emoji = log.emoji {
                Text(emoji)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.color.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(log.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(relativeDateString(for: log.date))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func relativeDateString(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var moodLogs: [SimpleMoodLog] = []
    
    private let moodService = ServiceContainer.shared.moodService
    
    func loadHistory() async {
        do {
            moodLogs = try await moodService.allLogs()
        } catch {
            print("Error loading mood history: \(error)")
        }
    }
    
    func deleteLogs(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let log = moodLogs[index]
                do {
                    try await moodService.deleteLog(log)
                    // Reload to get updated list
                    await loadHistory()
                } catch {
                    print("Error deleting log: \(error)")
                }
            }
        }
    }
}

#Preview {
    HistoryView()
}