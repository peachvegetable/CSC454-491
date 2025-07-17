import SwiftUI

public struct PulseView: View {
    @StateObject private var viewModel = PulseViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appRouter: AppRouter
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Row - always visible
                    StreakRow(streak: viewModel.currentStreak)
                    
                    // Today's Mood Card or Log Mood Row
                    if let todayLog = viewModel.todayMoodLog {
                        TodayCard(
                            moodLog: todayLog,
                            showEditMood: $viewModel.showEditMood
                        )
                    } else {
                        LogMoodRow {
                            viewModel.showEditMood = true
                        }
                    }
                    
                    // Buffer Countdown Chip
                    if let bufferEndTime = viewModel.bufferEndTime {
                        BufferCountdownChip(endTime: bufferEndTime)
                    }
                    
                    // Suggested Quest Card
                    if let quest = viewModel.todaysQuest {
                        SuggestedQuestCard(quest: quest, onStartQuest: {
                            viewModel.showQuest(quest)
                        })
                    }
                }
                .padding()
            }
            .navigationTitle("Pulse")
            .navigationBarTitleDisplayMode(.large)
            .accessibilityIdentifier("pulseRoot")
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showEditMood) {
            MoodSignalView()
        }
        .sheet(item: $viewModel.activeQuest) { quest in
            QuestDetailView(quest: quest)
        }
    }
}

struct StreakRow: View {
    let streak: Int
    
    var body: some View {
        HStack {
            Label("\(streak) day streak", systemImage: "flame.fill")
                .font(.headline)
                .foregroundColor(.orange)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct TodayCard: View {
    let moodLog: SimpleMoodLog
    @EnvironmentObject var appRouter: AppRouter
    @Binding var showEditMood: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Mood")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 20) {
                Circle()
                    .fill(Color(hex: moodLog.color.hex))
                    .frame(width: 60, height: 60)
                
                if let emoji = moodLog.emoji {
                    Text(emoji)
                        .font(.system(size: 50))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(moodLog.color.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(moodLog.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showEditMood = true
                    }) {
                        Text("Edit")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "#2BB3B3"))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct BufferCountdownChip: View {
    let endTime: Date
    @State private var timeRemaining = ""
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            Image(systemName: "timer")
            Text("Buffer ends in \(timeRemaining)")
                .font(.footnote)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.2))
        .foregroundColor(.orange)
        .cornerRadius(20)
        .onReceive(timer) { _ in
            updateTimeRemaining()
        }
        .onAppear {
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        let remaining = endTime.timeIntervalSince(Date())
        if remaining > 0 {
            let minutes = Int(remaining) / 60
            let seconds = Int(remaining) % 60
            timeRemaining = String(format: "%d:%02d", minutes, seconds)
        } else {
            timeRemaining = "0:00"
        }
    }
}

struct SuggestedQuestCard: View {
    let quest: Quest
    let onStartQuest: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color(hex: "#FFC7B2"))
                Text("Suggested Quest")
                    .font(.headline)
                Spacer()
            }
            
            Text(quest.title)
                .font(.title3)
                .fontWeight(.medium)
            
            Text(quest.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Button(action: onStartQuest) {
                Text("Start Quest")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#2BB3B3"))
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


struct LogMoodRow: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(Color(hex: "#2BB3B3"))
                
                Text("Log your mood")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PulseView()
        .environmentObject(AppState())
}