import SwiftUI

public struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    public var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.groupedMoodLogs, id: \.key) { date, logs in
                    Section(header: Text(date, style: .date)) {
                        ForEach(logs) { log in
                            MoodHistoryRow(log: log)
                        }
                    }
                }
            }
            .navigationTitle("Mood History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.loadHistory()
            }
        }
    }
}

struct MoodHistoryRow: View {
    let log: MoodLog
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: log.colorHex))
                .frame(width: 40, height: 40)
            
            if let emoji = log.emoji {
                Text(emoji)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.moodLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(log.createdAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var groupedMoodLogs: [(key: Date, value: [MoodLog])] = []
    
    private let authService = ServiceContainer.shared.authService
    private let realmManager = RealmManager.shared
    
    func loadHistory() {
        guard let userId = authService.currentUser?.id else { return }
        
        let predicate = NSPredicate(format: "userId == %@", userId)
        let logs = realmManager.fetch(MoodLog.self, predicate: predicate)
            .sorted(byKeyPath: "createdAt", ascending: false)
        
        // Group by date
        let grouped = Dictionary(grouping: Array(logs)) { log in
            Calendar.current.startOfDay(for: log.createdAt)
        }
        
        groupedMoodLogs = grouped.sorted { $0.key > $1.key }
    }
}

#Preview {
    HistoryView()
}