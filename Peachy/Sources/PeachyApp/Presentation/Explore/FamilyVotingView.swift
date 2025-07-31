import SwiftUI

// MARK: - Models

enum PollCategory: String, CaseIterable {
    case dinner = "Dinner"
    case activity = "Activity"
    case decision = "Decision"
    case fun = "Fun"
    
    var icon: String {
        switch self {
        case .dinner: return "fork.knife"
        case .activity: return "figure.walk"
        case .decision: return "lightbulb.fill"
        case .fun: return "gamecontroller.fill"
        }
    }
}

struct Vote {
    let pollId: String
    let userId: String
    let selectedOptions: [Int]
    let timestamp: Date
}

struct Poll: Identifiable {
    let id: String
    let question: String
    let options: [String]
    let category: PollCategory
    let createdBy: String
    let deadline: Date
    let isAnonymous: Bool
    let allowMultiple: Bool
    var votes: [Vote]
    let totalMembers: Int
    var completedAt: Date?
    
    var hasUserVoted: Bool = false
    var userVoteIndices: Set<Int> = []
    
    var votedCount: Int {
        votes.count
    }
    
    var voteProgress: Double {
        Double(votedCount) / Double(totalMembers)
    }
    
    var timeLeftString: String? {
        let timeInterval = deadline.timeIntervalSinceNow
        if timeInterval <= 0 { return nil }
        
        if timeInterval < 3600 {
            return "\(Int(timeInterval / 60)) min left"
        } else if timeInterval < 86400 {
            return "\(Int(timeInterval / 3600)) hours left"
        } else {
            return "\(Int(timeInterval / 86400)) days left"
        }
    }
    
    var completedTimeAgo: String {
        guard let completedAt = completedAt else { return "" }
        let interval = Date().timeIntervalSince(completedAt)
        
        if interval < 3600 {
            return "\(Int(interval / 60)) minutes ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600)) hours ago"
        } else {
            return "\(Int(interval / 86400)) days ago"
        }
    }
    
    var winnerIndex: Int? {
        guard !votes.isEmpty else { return nil }
        
        var voteCounts = Array(repeating: 0, count: options.count)
        for vote in votes {
            for optionIndex in vote.selectedOptions {
                voteCounts[optionIndex] += 1
            }
        }
        
        if let maxVotes = voteCounts.max() {
            return voteCounts.firstIndex(of: maxVotes)
        }
        return nil
    }
    
    func getVoteCount(for optionIndex: Int) -> Int {
        votes.reduce(0) { count, vote in
            count + (vote.selectedOptions.contains(optionIndex) ? 1 : 0)
        }
    }
    
    var categoryIcon: String {
        category.icon
    }
}

// MARK: - View Model

class FamilyVotingViewModel: ObservableObject {
    @Published var activePolls: [Poll] = []
    @Published var completedPolls: [Poll] = []
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        // Mock active polls
        activePolls = [
            Poll(
                id: "1",
                question: "What should we have for family dinner tonight?",
                options: ["Pizza", "Chinese", "Mexican", "Home-cooked pasta"],
                category: .dinner,
                createdBy: "Dad",
                deadline: Date().addingTimeInterval(7200), // 2 hours
                isAnonymous: false,
                allowMultiple: false,
                votes: [
                    Vote(pollId: "1", userId: "dad", selectedOptions: [0], timestamp: Date()),
                    Vote(pollId: "1", userId: "mom", selectedOptions: [3], timestamp: Date())
                ],
                totalMembers: 4
            ),
            Poll(
                id: "2",
                question: "Where should we go for our weekend activity?",
                options: ["Beach", "Hiking", "Movies", "Stay home and play games"],
                category: .activity,
                createdBy: "Mom",
                deadline: Date().addingTimeInterval(172800), // 2 days
                isAnonymous: true,
                allowMultiple: false,
                votes: [],
                totalMembers: 4
            )
        ]
        
        // Mock completed polls
        completedPolls = [
            Poll(
                id: "3",
                question: "Which movie should we watch for family movie night?",
                options: ["Toy Story 4", "The Incredibles", "Frozen 2"],
                category: .fun,
                createdBy: "Teen",
                deadline: Date().addingTimeInterval(-86400), // Yesterday
                isAnonymous: false,
                allowMultiple: false,
                votes: [
                    Vote(pollId: "3", userId: "dad", selectedOptions: [1], timestamp: Date()),
                    Vote(pollId: "3", userId: "mom", selectedOptions: [1], timestamp: Date()),
                    Vote(pollId: "3", userId: "teen", selectedOptions: [0], timestamp: Date()),
                    Vote(pollId: "3", userId: "kid", selectedOptions: [1], timestamp: Date())
                ],
                totalMembers: 4,
                completedAt: Date().addingTimeInterval(-86400)
            )
        ]
    }
    
    func createPoll(question: String, options: [String], category: PollCategory, deadline: Date, isAnonymous: Bool, allowMultiple: Bool) {
        let newPoll = Poll(
            id: UUID().uuidString,
            question: question,
            options: options,
            category: category,
            createdBy: "You",
            deadline: deadline,
            isAnonymous: isAnonymous,
            allowMultiple: allowMultiple,
            votes: [],
            totalMembers: 4
        )
        activePolls.insert(newPoll, at: 0)
    }
    
    func submitVote(pollId: String, selectedOptions: [Int]) {
        guard let index = activePolls.firstIndex(where: { $0.id == pollId }) else { return }
        
        let vote = Vote(
            pollId: pollId,
            userId: "currentUser",
            selectedOptions: selectedOptions,
            timestamp: Date()
        )
        
        activePolls[index].votes.append(vote)
        activePolls[index].hasUserVoted = true
        activePolls[index].userVoteIndices = Set(selectedOptions)
        
        // Check if voting is complete
        if activePolls[index].votes.count == activePolls[index].totalMembers {
            var completedPoll = activePolls[index]
            completedPoll.completedAt = Date()
            completedPolls.insert(completedPoll, at: 0)
            activePolls.remove(at: index)
        }
    }
}

// MARK: - Main View

struct FamilyVotingView: View {
    @StateObject private var viewModel = FamilyVotingViewModel()
    @State private var showCreatePoll = false
    @State private var selectedTab = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(Color(hex: "#2BB3B3"))
                }
                
                Spacer()
                
                Button(action: { showCreatePoll = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "#2BB3B3"))
                }
            }
            .padding()
            
            VStack(alignment: .leading) {
                Text("Family Voting")
                    .font(.largeTitle)
                    .bold()
                Text("Make decisions together")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("Active").tag(0)
                Text("Completed").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom)
            
            // Content
            if selectedTab == 0 {
                activePolls
            } else {
                completedPolls
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreatePoll) {
            CreatePollView(viewModel: viewModel)
        }
    }
    
    var activePolls: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.activePolls.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.activePolls) { poll in
                        NavigationLink {
                            VotingDetailView(poll: poll, viewModel: viewModel)
                        } label: {
                            PollCard(poll: poll, isActive: true)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
    
    var completedPolls: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.completedPolls.isEmpty {
                    Text("No completed polls yet")
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                } else {
                    ForEach(viewModel.completedPolls) { poll in
                        NavigationLink {
                            PollResultsView(poll: poll, viewModel: viewModel)
                        } label: {
                            PollCard(poll: poll, isActive: false)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text("No active polls")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Create a poll to get your family's opinion!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create First Poll") {
                showCreatePoll = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#2BB3B3"))
        }
        .padding(.top, 50)
    }
}

struct PollCard: View {
    let poll: Poll
    let isActive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(poll.question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Image(systemName: poll.categoryIcon)
                            .font(.caption)
                        Text(poll.category.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isActive {
                    VStack(alignment: .trailing) {
                        Text(poll.votedCount == poll.totalMembers ? "All voted" : "\(poll.votedCount)/\(poll.totalMembers) voted")
                            .font(.caption)
                            .foregroundColor(poll.votedCount == poll.totalMembers ? .green : .orange)
                        
                        if let timeLeft = poll.timeLeftString {
                            Text(timeLeft)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            if isActive && poll.hasUserVoted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("You voted")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Create Poll View

struct CreatePollView: View {
    @ObservedObject var viewModel: FamilyVotingViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var question = ""
    @State private var options = ["", ""]
    @State private var category = PollCategory.fun
    @State private var deadline = Date().addingTimeInterval(86400) // 24 hours
    @State private var isAnonymous = true
    @State private var allowMultiple = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("What should we decide?", text: $question, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section("Options") {
                    ForEach(0..<options.count, id: \.self) { index in
                        HStack {
                            TextField("Option \(index + 1)", text: $options[index])
                            if options.count > 2 {
                                Button(action: { options.remove(at: index) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    if options.count < 6 {
                        Button(action: { options.append("") }) {
                            Label("Add Option", systemImage: "plus.circle.fill")
                                .foregroundColor(Color(hex: "#2BB3B3"))
                        }
                    }
                }
                
                Section("Settings") {
                    Picker("Category", selection: $category) {
                        ForEach(PollCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    
                    DatePicker("Deadline", selection: $deadline, in: Date()...)
                    
                    Toggle("Anonymous voting", isOn: $isAnonymous)
                    Toggle("Allow multiple choices", isOn: $allowMultiple)
                }
            }
            .navigationTitle("Create Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        viewModel.createPoll(
                            question: question,
                            options: options.filter { !$0.isEmpty },
                            category: category,
                            deadline: deadline,
                            isAnonymous: isAnonymous,
                            allowMultiple: allowMultiple
                        )
                        dismiss()
                    }
                    .disabled(question.isEmpty || options.filter { !$0.isEmpty }.count < 2)
                }
            }
        }
    }
}

// MARK: - Voting Detail View

struct VotingDetailView: View {
    let poll: Poll
    @ObservedObject var viewModel: FamilyVotingViewModel
    @State private var selectedOptions: Set<Int> = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(Color(hex: "#2BB3B3"))
                }
                Spacer()
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(poll.question)
                            .font(.title2)
                            .bold()
                        
                        HStack {
                            Image(systemName: poll.categoryIcon)
                            Text(poll.category.rawValue)
                            Text("•")
                            Text(poll.timeLeftString ?? "Ended")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                // Progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(poll.votedCount) of \(poll.totalMembers) voted")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(poll.voteProgress * 100))%")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    ProgressView(value: poll.voteProgress)
                        .tint(Color(hex: "#2BB3B3"))
                }
            }
            .padding()
            
            Divider()
            
            // Options
            ScrollView {
                VStack(spacing: 12) {
                    if poll.hasUserVoted {
                        // Show results preview
                        ForEach(0..<poll.options.count, id: \.self) { index in
                            VoteResultRow(
                                option: poll.options[index],
                                voteCount: poll.getVoteCount(for: index),
                                totalVotes: poll.votedCount,
                                isUserChoice: poll.userVoteIndices.contains(index)
                            )
                        }
                        
                        Text("Waiting for others to vote...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    } else {
                        // Show voting options
                        Text(poll.allowMultiple ? "Select all that apply:" : "Select one:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(0..<poll.options.count, id: \.self) { index in
                            OptionButton(
                                text: poll.options[index],
                                isSelected: selectedOptions.contains(index),
                                action: {
                                    if poll.allowMultiple {
                                        if selectedOptions.contains(index) {
                                            selectedOptions.remove(index)
                                        } else {
                                            selectedOptions.insert(index)
                                        }
                                    } else {
                                        selectedOptions = [index]
                                    }
                                }
                            )
                        }
                        
                        Button(action: submitVote) {
                            Text("Submit Vote")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#2BB3B3"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(selectedOptions.isEmpty)
                        .padding(.top)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func submitVote() {
        viewModel.submitVote(pollId: poll.id, selectedOptions: Array(selectedOptions))
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(hex: "#2BB3B3") : .gray)
            }
            .padding()
            .background(isSelected ? Color(hex: "#2BB3B3").opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Poll Results View

struct PollResultsView: View {
    let poll: Poll
    @ObservedObject var viewModel: FamilyVotingViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(Color(hex: "#2BB3B3"))
                }
                Spacer()
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(poll.question)
                            .font(.title2)
                            .bold()
                        
                        HStack {
                            Image(systemName: poll.categoryIcon)
                            Text(poll.category.rawValue)
                            Text("•")
                            Text("Completed \(poll.completedTimeAgo)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    // Winner announcement
                    if let winnerIndex = poll.winnerIndex {
                        VStack(spacing: 8) {
                            Image(systemName: "trophy.fill")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)
                            Text("Winner")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(poll.options[winnerIndex])
                                .font(.title3)
                                .bold()
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    
                    // Results
                    VStack(spacing: 12) {
                        ForEach(0..<poll.options.count, id: \.self) { index in
                            VoteResultRow(
                                option: poll.options[index],
                                voteCount: poll.getVoteCount(for: index),
                                totalVotes: poll.votedCount,
                                isUserChoice: poll.userVoteIndices.contains(index)
                            )
                        }
                    }
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voting Stats")
                            .font(.headline)
                        
                        HStack {
                            Label("\(poll.votedCount) votes", systemImage: "person.3.fill")
                            Spacer()
                            Label("\(Int(poll.voteProgress * 100))% participation", systemImage: "chart.pie.fill")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VoteResultRow: View {
    let option: String
    let voteCount: Int
    let totalVotes: Int
    let isUserChoice: Bool
    let showVoters: Bool = false
    
    var percentage: Double {
        totalVotes > 0 ? Double(voteCount) / Double(totalVotes) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(option)
                    .font(.body)
                Spacer()
                Text("\(voteCount) votes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 24)
                    
                    Rectangle()
                        .fill(isUserChoice ? Color(hex: "#2BB3B3") : Color.gray.opacity(0.5))
                        .frame(width: geometry.size.width * percentage, height: 24)
                    
                    Text("\(Int(percentage * 100))%")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                }
                .cornerRadius(12)
            }
            .frame(height: 24)
            
            if isUserChoice {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#2BB3B3"))
                    Text("Your choice")
                        .font(.caption)
                        .foregroundColor(Color(hex: "#2BB3B3"))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        FamilyVotingView()
    }
}