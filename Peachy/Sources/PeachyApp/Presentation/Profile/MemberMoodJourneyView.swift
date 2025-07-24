import SwiftUI
import PeachyApp

struct MemberMoodJourneyView: View {
    let member: FamilyMemberStatus
    @StateObject private var viewModel = MemberMoodJourneyViewModel()
    @State private var selectedTimeRange = TimeRange.week
    @State private var showPlotView = false
    @Environment(\.dismiss) private var dismiss
    
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
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(member.name)'s Mood Journey")
                                .font(.largeTitle)
                                .bold()
                            
                            HStack {
                                Circle()
                                    .fill(member.statusColor)
                                    .frame(width: 8, height: 8)
                                
                                Text("Last update: \(member.lastUpdate.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Toggle between list and plot view
                        Button(action: { showPlotView.toggle() }) {
                            Image(systemName: showPlotView ? "list.bullet" : "chart.line.uptrend.xyaxis")
                                .font(.title2)
                                .foregroundColor(Color(hex: "#2BB3B3"))
                        }
                    }
                    .padding(.horizontal)
                    
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
                if showPlotView {
                    // Plot View
                    if viewModel.moodLogs.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 60))
                                .foregroundColor(Color.gray.opacity(0.5))
                            
                            Text("No mood data to display")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            SimpleMoodPlotView(moodLogs: filteredMoodLogs)
                                .padding()
                        }
                    }
                } else {
                    // List View
                    if viewModel.moodLogs.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 60))
                                .foregroundColor(Color.gray.opacity(0.5))
                            
                            Text("No mood entries found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(member.name) hasn't shared any moods yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredMoodLogs) { mood in
                                    SimpleMoodCard(mood: mood)
                                        .transition(.slide)
                                }
                            }
                            .padding(.horizontal)
                            .animation(.spring(), value: selectedTimeRange)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                viewModel.loadMoodHistory(for: member)
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

// MARK: - View Model
@MainActor
class MemberMoodJourneyViewModel: ObservableObject {
    @Published var moodLogs: [MoodLog] = []
    private let moodService = ServiceContainer.shared.moodService
    
    func loadMoodHistory(for member: FamilyMemberStatus) {
        // In a real app, we'd map member name to user ID through a service
        let memberUserId = member.name == "Mom" ? "mom-user-id" : "dad-user-id"
        
        Task {
            do {
                // Get all mood logs from service
                let logs = try await moodService.allLogs()
                
                // Filter logs for the selected member
                let memberLogs = logs.filter { $0.userId == memberUserId }
                
                // Convert SimpleMoodLog to MoodLog for display
                moodLogs = memberLogs.map { simplelog in
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
                print("Error loading member mood history: \(error)")
                moodLogs = []
            }
        }
    }
}

// MARK: - Simple Mood Card
struct SimpleMoodCard: View {
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

// MARK: - Simple Mood Plot View
struct SimpleMoodPlotView: View {
    let moodLogs: [MoodLog]
    
    private var sortedLogs: [MoodLog] {
        moodLogs.sorted { $0.createdAt < $1.createdAt }
    }
    
    private func moodValue(for color: String) -> CGFloat {
        switch color {
        case "green": return 1.0
        case "yellow": return 0.5
        case "red": return 0.0
        default: return 0.5
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Legend
            HStack(spacing: 20) {
                ForEach(SimpleMoodColor.allCases, id: \.self) { color in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: color.hex))
                            .frame(width: 12, height: 12)
                        Text(color.displayName)
                            .font(.caption2)
                    }
                }
            }
            .padding(.horizontal)
            
            // Plot
            GeometryReader { geometry in
                if !sortedLogs.isEmpty {
                    ZStack {
                        // Grid lines
                        ForEach(0..<4) { i in
                            Path { path in
                                let y = CGFloat(i) * geometry.size.height / 3
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                            }
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        }
                        
                        // Line
                        Path { path in
                            guard !sortedLogs.isEmpty else { return }
                            
                            let width = geometry.size.width
                            let height = geometry.size.height
                            
                            for (index, mood) in sortedLogs.enumerated() {
                                let x = sortedLogs.count > 1 ? CGFloat(index) * (width / CGFloat(sortedLogs.count - 1)) : width / 2
                                let value = moodValue(for: mood.colorName)
                                let y = height - (value * height * 0.8) - 20
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color(hex: "#2BB3B3"), lineWidth: 2)
                        
                        // Points
                        ForEach(Array(sortedLogs.enumerated()), id: \.element.id) { index, mood in
                            let x = sortedLogs.count > 1 ? CGFloat(index) * (geometry.size.width / CGFloat(sortedLogs.count - 1)) : geometry.size.width / 2
                            let value = moodValue(for: mood.colorName)
                            let y = geometry.size.height - (value * geometry.size.height * 0.8) - 20
                            
                            ZStack {
                                Circle()
                                    .fill(Color(hex: mood.colorHex))
                                    .frame(width: 12, height: 12)
                                
                                if !mood.emoji.isEmpty {
                                    Text(mood.emoji)
                                        .font(.caption2)
                                }
                            }
                            .position(x: x, y: y)
                        }
                    }
                } else {
                    Text("No data to display")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 300)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

#Preview {
    MemberMoodJourneyView(
        member: FamilyMemberStatus(
            name: "Mom",
            initial: "M",
            simpleMoodColor: .green,
            lastUpdate: Date()
        )
    )
}