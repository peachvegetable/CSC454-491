import SwiftUI

public struct PulseView: View {
    @StateObject private var viewModel = PulseViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appRouter: AppRouter
    @State private var showProfile = false
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with greeting and date
                    HeaderSection(userName: viewModel.currentUserName, showProfile: $showProfile)
                    
                    // Today's Mood Status Card
                    TodayMoodStatusCard(
                        moodLog: viewModel.todayMoodLog,
                        onUpdateMood: { viewModel.showEditMood = true }
                    )
                    
                    // Stats Overview - Streak and Points
                    StatsOverviewSection(
                        streak: viewModel.currentStreak,
                        totalPoints: viewModel.totalPoints
                    )
                    
                    // Family Members Status - Enhanced
                    if !viewModel.familyMemberStatuses.isEmpty {
                        EnhancedFamilyStatusSection(members: viewModel.familyMemberStatuses)
                    } else {
                        EmptyFamilySection()
                    }
                    
                    // Buffer Countdown Chip
                    if let bufferEndTime = viewModel.bufferEndTime {
                        BufferCountdownChip(endTime: bufferEndTime)
                    }
                    
                    // Quick Actions Section - Enhanced
                    EnhancedQuickActionsSection(
                        showShareHobby: $viewModel.showShareHobby,
                        showFlashCards: $viewModel.showFlashCards
                    )
                    
                    // Daily Activities
                    DailyActivitiesSection(
                        quest: viewModel.todaysQuest,
                        isQuestCompleted: viewModel.isQuestCompleted,
                        onStartQuest: {
                            if let quest = viewModel.todaysQuest {
                                viewModel.showQuest(quest)
                            }
                        }
                    )
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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
        .sheet(isPresented: $showProfile) {
            ProfileView()
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


struct HeaderSection: View {
    let userName: String
    @Binding var showProfile: Bool
    @State private var greeting = "Good morning"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(greeting),")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text(userName.isEmpty ? "Friend" : userName)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Profile button and Date
                VStack(alignment: .trailing, spacing: 8) {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "#2BB3B3"))
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Date(), format: .dateTime.weekday(.abbreviated))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(Date(), format: .dateTime.day().month(.abbreviated))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.brandPeach)
                    }
                }
            }
        }
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

struct TodayMoodStatusCard: View {
    let moodLog: SimpleMoodLog?
    let onUpdateMood: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label("My Mood Today", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundColor(Color.brandPeach)
                Spacer()
            }
            
            if let log = moodLog {
                HStack(spacing: 20) {
                    // Mood color and emoji
                    ZStack {
                        Circle()
                            .fill(Color(hex: log.color.hex))
                            .frame(width: 70, height: 70)
                        
                        if let emoji = log.emoji {
                            Text(emoji)
                                .font(.system(size: 40))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(log.color.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(log.date, style: .time)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onUpdateMood) {
                        Text("Update")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.brandTeal)
                            .cornerRadius(20)
                    }
                }
            } else {
                // No mood logged
                VStack(spacing: 12) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("How are you feeling?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: onUpdateMood) {
                        Text("Share Mood")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(LinearGradient(
                                colors: [Color.brandPeach, Color.brandPeach.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .cornerRadius(20)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct StatsOverviewSection: View {
    let streak: Int
    let totalPoints: Int
    
    var body: some View {
        HStack(spacing: 12) {
            PulseStatCard(
                icon: "flame.fill",
                iconColor: .orange,
                value: "\(streak)",
                label: "Day Streak",
                gradient: LinearGradient(
                    colors: [.orange.opacity(0.2), .red.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            PulseStatCard(
                icon: "star.fill",
                iconColor: .yellow,
                value: "\(totalPoints)",
                label: "Total Points",
                gradient: LinearGradient(
                    colors: [.yellow.opacity(0.2), .orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

struct PulseStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(gradient)
        .cornerRadius(12)
    }
}

struct EnhancedFamilyStatusSection: View {
    let members: [FamilyMemberStatus]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Family Check-in", systemImage: "person.3.fill")
                    .font(.headline)
                    .foregroundColor(Color.brandTeal)
                Spacer()
                Text("\(members.count) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(members) { member in
                        EnhancedMemberCard(member: member)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct EnhancedMemberCard: View {
    let member: FamilyMemberStatus
    @State private var showMemberProfile = false
    
    var body: some View {
        Button(action: { showMemberProfile = true }) {
            VStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    // Mood color background
                    Circle()
                        .fill(Color(hex: member.simpleMoodColor.hex).opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    // Profile initial
                    Text(member.initial)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: member.simpleMoodColor.hex))
                        .frame(width: 70, height: 70)
                    
                    // Activity indicator
                    Circle()
                        .fill(member.statusColor)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                }
                
                VStack(spacing: 4) {
                    Text(member.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(timeAgoString(from: member.lastUpdate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 90)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showMemberProfile) {
            MemberProfileView(member: member)
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

struct EmptyFamilySection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No family members yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Invite family members to start sharing moods together")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct FamilyMemberStatusView: View {
    let member: FamilyMemberStatus
    @State private var showMemberProfile = false
    
    var body: some View {
        Button(action: { showMemberProfile = true }) {
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
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showMemberProfile) {
            MemberProfileView(member: member)
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

struct EnhancedQuickActionsSection: View {
    @Binding var showShareHobby: Bool
    @Binding var showFlashCards: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Actions", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundColor(.orange)
            
            HStack(spacing: 12) {
                EnhancedActionCard(
                    title: "Share Hobby",
                    subtitle: "+5 points",
                    icon: "star.fill",
                    primaryColor: Color.brandPeach,
                    action: { showShareHobby = true }
                )
                
                EnhancedActionCard(
                    title: "Quiz Time",
                    subtitle: "Test knowledge",
                    icon: "brain.head.profile",
                    primaryColor: Color.brandTeal,
                    action: { showFlashCards = true }
                )
            }
        }
    }
}

struct EnhancedActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(primaryColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [primaryColor.opacity(0.1), primaryColor.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(primaryColor.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DailyActivitiesSection: View {
    let quest: Quest?
    let isQuestCompleted: Bool
    let onStartQuest: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Today's Activities", systemImage: "sparkles")
                .font(.headline)
                .foregroundColor(.purple)
            
            if let quest = quest {
                QuestCard(
                    quest: quest,
                    isCompleted: isQuestCompleted,
                    onStart: onStartQuest
                )
            }
            
            // Additional activity suggestions
            ActivitySuggestionCard()
        }
    }
}

struct QuestCard: View {
    let quest: Quest
    let isCompleted: Bool
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isCompleted ? "checkmark.seal.fill" : "target")
                    .foregroundColor(isCompleted ? .green : .purple)
                
                Text(quest.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isCompleted {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            Text(quest.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !isCompleted {
                Button(action: onStart) {
                    Text("Start Quest")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActivitySuggestionCard: View {
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Try something new!")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Check out the Explore tab for more activities")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
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