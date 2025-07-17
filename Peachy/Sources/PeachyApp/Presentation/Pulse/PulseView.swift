import SwiftUI

public struct PulseView: View {
    @StateObject private var viewModel = PulseViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appRouter: AppRouter
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's Mood Card
                    TodayCard(
                        moodLog: viewModel.todayMoodLog,
                        streak: viewModel.currentStreak
                    )
                    
                    // Buffer Countdown Chip
                    if let bufferEndTime = viewModel.bufferEndTime {
                        BufferCountdownChip(endTime: bufferEndTime)
                    }
                    
                    // Suggested Quest Card
                    if let quest = viewModel.suggestedQuest {
                        SuggestedQuestCard(quest: quest)
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
    }
}

struct TodayCard: View {
    let moodLog: MoodLog?
    let streak: Int
    @EnvironmentObject var appRouter: AppRouter
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today")
                    .font(.headline)
                Spacer()
                Label("\(streak) day streak", systemImage: "flame.fill")
                    .font(.footnote)
                    .foregroundColor(.orange)
            }
            
            if let log = moodLog {
                HStack(spacing: 20) {
                    Circle()
                        .fill(Color(hex: log.colorHex))
                        .frame(width: 60, height: 60)
                    
                    if let emoji = log.emoji {
                        Text(emoji)
                            .font(.system(size: 50))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(log.moodLabel)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(log.createdAt, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            // Navigate to MoodWheel for editing
                            appRouter.currentRoute = .moodWheel
                        }) {
                            Text("Edit")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#2BB3B3"))
                        }
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
            
            Button(action: {
                // Start quest
            }) {
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

// Quest model
struct Quest: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
}

#Preview {
    PulseView()
        .environmentObject(AppState())
}