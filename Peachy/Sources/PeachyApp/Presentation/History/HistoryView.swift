import SwiftUI
import RealmSwift

public struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    public var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.timelineEvents) { event in
                    TimelineEventRow(event: event)
                }
            }
            .navigationTitle("Timeline")
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

// Timeline Event Types
enum TimelineEventType {
    case mood(SimpleMoodLog)
    case hobby(HobbyModel)
    case quiz(points: Int, cardCount: Int, date: Date)
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let type: TimelineEventType
    let date: Date
    
    var sortDate: Date {
        switch type {
        case .mood(let log):
            return log.date
        case .hobby(let hobby):
            return hobby.createdAt
        case .quiz(_, _, let date):
            return date
        }
    }
}

struct TimelineEventRow: View {
    let event: TimelineEvent
    
    var body: some View {
        switch event.type {
        case .mood(let log):
            MoodEventRow(log: log)
        case .hobby(let hobby):
            HobbyEventRow(hobby: hobby)
        case .quiz(let points, let cardCount, let date):
            QuizEventRow(points: points, cardCount: cardCount, date: date)
        }
    }
}

struct MoodEventRow: View {
    let log: SimpleMoodLog
    
    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            Image(systemName: "waveform.path.ecg")
                .font(.title3)
                .foregroundColor(Color(hex: "#2BB3B3"))
                .frame(width: 30)
            
            // Mood circle
            Circle()
                .fill(Color(hex: log.color.hex))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(log.emoji ?? "")
                        .font(.title3)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Mood: \(log.color.displayName)")
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
}

struct HobbyEventRow: View {
    let hobby: HobbyModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Shared hobby: \(hobby.name)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(hobby.fact)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("+5")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                Text(relativeDateString(for: hobby.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuizEventRow: View {
    let points: Int
    let cardCount: Int
    let date: Date
    
    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            Image(systemName: "rectangle.stack.fill")
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Quiz completed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(cardCount) cards answered")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(points)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                Text(relativeDateString(for: date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
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

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var timelineEvents: [TimelineEvent] = []
    
    private let moodService = ServiceContainer.shared.moodService
    private let hobbyService = ServiceContainer.shared.hobbyService
    private let realmManager = RealmManager.shared
    
    func loadHistory() async {
        var events: [TimelineEvent] = []
        
        // Load mood logs
        do {
            let moodLogs = try await moodService.allLogs()
            for log in moodLogs {
                events.append(TimelineEvent(type: .mood(log), date: log.date))
            }
        } catch {
            print("Error loading mood history: \(error)")
        }
        
        // Load hobby shares
        let hobbies = await hobbyService.allHobbies()
        for hobby in hobbies {
            events.append(TimelineEvent(type: .hobby(hobby), date: hobby.createdAt))
        }
        
        // Load quiz events (mock data for now)
        // In a real app, you'd track quiz completions separately
        if !hobbies.isEmpty {
            // Add a sample quiz event
            let quizDate = Date().addingTimeInterval(-3600) // 1 hour ago
            events.append(TimelineEvent(
                type: .quiz(points: 6, cardCount: 3, date: quizDate), 
                date: quizDate
            ))
        }
        
        // Sort by date, newest first
        timelineEvents = events.sorted { $0.sortDate > $1.sortDate }
    }
}

#Preview {
    HistoryView()
}