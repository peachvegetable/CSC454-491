import SwiftUI
import Combine

struct JourneyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = JourneyViewModel()
    @State private var selectedTimeRange = TimeRange.week
    @State private var showPlotView = false
    
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
                        Text("Your Journey")
                            .font(.largeTitle)
                            .bold()
                        
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
                    MoodPlotView(
                        moodLogs: filteredMoodLogs,
                        timeRange: selectedTimeRange
                    )
                    .padding(.horizontal)
                } else {
                    // List View
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
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadMoodHistory()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                viewModel.loadMoodHistory()
            }
            .task {
                // Reload when view becomes visible
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

// MARK: - Mood Plot View
struct MoodPlotView: View {
    let moodLogs: [MoodLog]
    let timeRange: JourneyView.TimeRange
    
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
                if !moodLogs.isEmpty {
                    MoodLineChart(
                        moodLogs: moodLogs,
                        size: geometry.size
                    )
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

// MARK: - Mood Line Chart
struct MoodLineChart: View {
    let moodLogs: [MoodLog]
    let size: CGSize
    
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
    
    private func xPosition(for index: Int) -> CGFloat {
        guard sortedLogs.count > 1 else { return size.width / 2 }
        return CGFloat(index) * (size.width / CGFloat(sortedLogs.count - 1))
    }
    
    private func yPosition(for mood: MoodLog) -> CGFloat {
        let value = moodValue(for: mood.colorName)
        return size.height - (value * size.height * 0.8) - 20
    }
    
    var body: some View {
        ZStack {
            // Grid lines
            ForEach(0..<4) { i in
                Path { path in
                    let y = CGFloat(i) * size.height / 3
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            }
            
            // Line
            Path { path in
                guard !sortedLogs.isEmpty else { return }
                
                path.move(to: CGPoint(
                    x: xPosition(for: 0),
                    y: yPosition(for: sortedLogs[0])
                ))
                
                for (index, mood) in sortedLogs.enumerated() {
                    if index > 0 {
                        path.addLine(to: CGPoint(
                            x: xPosition(for: index),
                            y: yPosition(for: mood)
                        ))
                    }
                }
            }
            .stroke(Color(hex: "#2BB3B3"), lineWidth: 2)
            
            // Points
            ForEach(Array(sortedLogs.enumerated()), id: \.element.id) { index, mood in
                ZStack {
                    Circle()
                        .fill(Color(hex: mood.colorHex))
                        .frame(width: 12, height: 12)
                    
                    if !mood.emoji.isEmpty {
                        Text(mood.emoji)
                            .font(.caption2)
                    }
                }
                .position(
                    x: xPosition(for: index),
                    y: yPosition(for: mood)
                )
            }
        }
    }
}

// ViewModel
@MainActor
class JourneyViewModel: ObservableObject {
    @Published var moodLogs: [MoodLog] = []
    private let moodService = ServiceContainer.shared.moodService
    private let authService = ServiceContainer.shared.authService
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to mood updates
        moodService.todaysLogPublisher
            .sink { [weak self] _ in
                self?.loadMoodHistory()
            }
            .store(in: &cancellables)
    }
    
    func loadMoodHistory() {
        guard let userId = authService.currentUser?.id else { return }
        
        Task {
            do {
                // Get mood logs from service
                let logs = try await moodService.allLogs()
                
                // Filter logs for the current user
                let userLogs = logs.filter { $0.userId == userId }
                
                print("JourneyView: Found \(logs.count) total logs")
                print("JourneyView: Current user ID: \(userId)")
                print("JourneyView: Found \(userLogs.count) logs for current user")
                
                // Convert SimpleMoodLog to MoodLog for display
                moodLogs = userLogs.map { simplelog in
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