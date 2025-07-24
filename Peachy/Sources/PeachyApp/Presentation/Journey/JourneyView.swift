import SwiftUI

struct JourneyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = JourneyViewModel()
    @State private var selectedTimeRange = TimeRange.week
    
    enum TimeRange: String, CaseIterable {
        case day = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Your Journey")
                        .font(.largeTitle)
                        .bold()
                    
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Mood History
                if viewModel.moodLogs.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 60))
                            .foregroundColor(Color.gray.opacity(0.5))
                        
                        Text("No mood entries yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Tap the + button to log your first mood")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredMoodLogs) { mood in
                                MoodHistoryCard(mood: mood)
                                    .transition(.slide)
                            }
                        }
                        .padding(.horizontal)
                        .animation(.spring(), value: selectedTimeRange)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadMoodHistory()
            }
        }
    }
    
    private var filteredMoodLogs: [MoodLog] {
        let now = Date()
        let calendar = Calendar.current
        
        return viewModel.moodLogs.filter { mood in
            switch selectedTimeRange {
            case .day:
                return calendar.isDateInToday(mood.createdAt)
            case .week:
                return mood.createdAt > calendar.date(byAdding: .day, value: -7, to: now)!
            case .month:
                return mood.createdAt > calendar.date(byAdding: .month, value: -1, to: now)!
            case .all:
                return true
            }
        }
    }
}

struct MoodHistoryCard: View {
    let mood: MoodLog
    
    var body: some View {
        HStack(spacing: 16) {
            // Mood Color and Emoji
            ZStack {
                Circle()
                    .fill(Color(hex: mood.colorHex))
                    .frame(width: 50, height: 50)
                
                Text(mood.emoji)
                    .font(.title2)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(mood.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(mood.moodLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let bufferMinutes = mood.bufferMinutes, bufferMinutes > 0 {
                    Label("\(bufferMinutes)m buffer", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// ViewModel
@MainActor
class JourneyViewModel: ObservableObject {
    @Published var moodLogs: [MoodLog] = []
    private let moodService = ServiceContainer.shared.moodService
    private let authService = ServiceContainer.shared.authService
    
    func loadMoodHistory() {
        guard let userId = authService.currentUser?.id else { return }
        
        Task {
            do {
                // Get mood logs from service
                let logs = try await moodService.allLogs()
                
                // Convert SimpleMoodLog to MoodLog for display
                moodLogs = logs.map { simplelog in
                    let log = MoodLog()
                    log.userId = simplelog.userId
                    log.colorHex = simplelog.color.hex
                    log.colorName = simplelog.color.rawValue
                    log.moodLabel = simplelog.color.displayName
                    log.emoji = simplelog.emoji ?? ""
                    log.createdAt = simplelog.date
                    log.bufferMinutes = simplelog.bufferMinutes
                    return log
                }
            } catch {
                print("Error loading mood history: \(error)")
                moodLogs = []
            }
        }
    }
}

#Preview {
    JourneyView()
        .environmentObject(AppState())
}