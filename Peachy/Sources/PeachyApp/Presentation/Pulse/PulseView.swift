import SwiftUI

public struct PulseView: View {
    @StateObject private var viewModel = PulseViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appRouter: AppRouter
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting Section
                    GreetingSection(userName: "there")
                    
                    // Family Members Status
                    if !viewModel.familyMemberStatuses.isEmpty {
                        FamilyMemberStatusSection(members: viewModel.familyMemberStatuses)
                    }
                    
                    // Streak Row - always visible
                    StreakRow(streak: viewModel.currentStreak)
                    
                    // Buffer Countdown Chip
                    if let bufferEndTime = viewModel.bufferEndTime {
                        BufferCountdownChip(endTime: bufferEndTime)
                    }
                    
                    // Quick Actions Section
                    QuickActionsSection(
                        showShareHobby: $viewModel.showShareHobby,
                        showFlashCards: $viewModel.showFlashCards
                    )
                    
                    // Suggested Quest Card - only show non-hobby quests
                    if let quest = viewModel.todaysQuest, quest.kind != .shareHobby {
                        SuggestedQuestCard(
                            quest: quest,
                            isCompleted: viewModel.isQuestCompleted,
                            onStartQuest: {
                                viewModel.showQuest(quest)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .accessibilityIdentifier("pulseRoot")
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(item: $viewModel.activeQuest) { quest in
            // Route to appropriate view based on quest type
            if quest.kind == .shareHobby {
                ShareHobbyView()
                    .environmentObject(appState)
                    .onDisappear {
                        viewModel.refreshQuestStatus()
                    }
            } else {
                // Generic quest view for other types
                Text("Quest: \(quest.title)")
                    .padding()
            }
        }
        .sheet(isPresented: $viewModel.showShareHobby) {
            ShareHobbyView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $viewModel.showFlashCards) {
            FlashCardQuizView()
                .environmentObject(appState)
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
    let isCompleted: Bool
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
                HStack(spacing: 4) {
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                    Text(isCompleted ? "Completed" : "Start Quest")
                }
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isCompleted ? Color.gray : Color(hex: "#2BB3B3"))
                .cornerRadius(20)
            }
            .disabled(isCompleted)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


struct GreetingSection: View {
    let userName: String
    @State private var greeting = "Good morning"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(greeting),")
                .font(.title2)
            Text(userName)
                .font(.largeTitle)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            updateGreeting()
        }
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            greeting = "Good morning"
        } else if hour < 17 {
            greeting = "Good afternoon"
        } else {
            greeting = "Good evening"
        }
    }
}

struct FamilyMemberStatusSection: View {
    let members: [FamilyMemberStatus]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Family Pulse")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(members) { member in
                        FamilyMemberStatusView(member: member)
                    }
                }
            }
        }
    }
}

struct FamilyMemberStatusView: View {
    let member: FamilyMemberStatus
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                // Profile picture or initial
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(member.initial)
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
                
                // Status indicator
                Circle()
                    .fill(member.statusColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            
            Text(member.name)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

struct EmptyMoodCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 40))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No mood logged today")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap the + button to share how you're feeling")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Model for family member status
struct FamilyMemberStatus: Identifiable {
    let id = UUID()
    let name: String
    let initial: String
    let simpleMoodColor: SimpleMoodColor
    let lastUpdate: Date
    
    var statusColor: Color {
        // Green, yellow, or red based on last update time
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        if timeSinceUpdate < 3600 { // Less than 1 hour
            return .green
        } else if timeSinceUpdate < 86400 { // Less than 24 hours
            return .yellow
        } else {
            return .red
        }
    }
}

struct QuickActionsSection: View {
    @Binding var showShareHobby: Bool
    @Binding var showFlashCards: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                QuickActionCard(
                    title: "Share a Hobby",
                    subtitle: "Earn 5 points",
                    icon: "star.fill",
                    color: Color(hex: "#FFC7B2"),
                    action: { showShareHobby = true }
                )
                
                QuickActionCard(
                    title: "Flash Cards",
                    subtitle: "Test knowledge",
                    icon: "rectangle.stack.fill",
                    color: Color(hex: "#2BB3B3"),
                    action: { showFlashCards = true }
                )
            }
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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