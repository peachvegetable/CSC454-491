import SwiftUI
import RealmSwift

public struct FlashCardQuizView: View {
    @StateObject private var viewModel = FlashCardQuizViewModel()
    @State private var showAnswer = false
    @State private var currentIndex = 0
    @State private var showPointsToast = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                ProgressView("Loading flash cards...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.flashCards.isEmpty {
                EmptyStateView()
            } else {
                VStack(spacing: 20) {
                    // Progress indicator
                    HStack {
                        Text("\(currentIndex + 1) / \(viewModel.flashCards.count)")
                            .font(.headline)
                        Spacer()
                        Label("\(viewModel.totalPoints) pts", systemImage: "star.fill")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal)
                    
                    // Flash card
                    if currentIndex < viewModel.flashCards.count {
                        let card = viewModel.flashCards[currentIndex]
                        
                        FlashCardView(
                            card: card,
                            showAnswer: $showAnswer,
                            onCorrect: {
                                Task {
                                    let awarded = await viewModel.markCorrect(card: card)
                                    if awarded {
                                        withAnimation {
                                            showPointsToast = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            showPointsToast = false
                                            nextCard()
                                        }
                                    } else {
                                        nextCard()
                                    }
                                }
                            }
                        )
                    }
                    
                    Spacer()
                }
                .navigationTitle("Flash Cards")
                .navigationBarTitleDisplayMode(.large)
                .overlay(alignment: .top) {
                    if showPointsToast {
                        ToastView(message: "+2 pts!", icon: "star.fill")
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                    }
                }
            }
        }
        .task {
            await viewModel.loadFlashCards()
        }
    }
    
    private func nextCard() {
        showAnswer = false
        if currentIndex < viewModel.flashCards.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            // Quiz completed
            currentIndex = 0
        }
    }
}

struct FlashCardView: View {
    let card: FlashCard
    @Binding var showAnswer: Bool
    let onCorrect: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Question side
            VStack(spacing: 20) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#2BB3B3"))
                
                Text(card.question)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if !showAnswer {
                    Button("Reveal Answer") {
                        withAnimation(.spring()) {
                            showAnswer = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .opacity(showAnswer ? 0 : 1)
            
            // Answer side
            if showAnswer {
                VStack(spacing: 20) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text(card.answer)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: onCorrect) {
                        HStack {
                            Image(systemName: "hand.thumbsup.fill")
                            Text("Got it!")
                        }
                        .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(radius: 5)
        )
        .padding()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Flash Cards Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete quests and share hobby facts to create flash cards!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

@MainActor
class FlashCardQuizViewModel: ObservableObject {
    @Published var flashCards: [FlashCard] = []
    @Published var isLoading = true
    @Published var totalPoints = 0
    
    private let realmManager = RealmManager.shared
    private let authService = ServiceContainer.shared.authService
    private let pointService = ServiceContainer.shared.pointService
    
    func loadFlashCards() async {
        isLoading = true
        
        // Load flash cards
        let cards = realmManager.fetch(FlashCard.self)
            .sorted(byKeyPath: "createdAt", ascending: false)
        flashCards = Array(cards)
        
        // Load total points
        if let userId = authService.currentUser?.id {
            totalPoints = await pointService.total(for: userId)
        }
        
        isLoading = false
    }
    
    func markCorrect(card: FlashCard) async -> Bool {
        guard let userId = authService.currentUser?.id else { return false }
        
        // Check if user already answered this card correctly
        if card.answeredCorrectlyBy.contains(where: { $0 == userId }) {
            return false
        }
        
        // Mark as answered
        do {
            try realmManager.realm.write {
                card.answeredCorrectlyBy.append(userId)
            }
        } catch {
            print("Error marking card as answered: \(error)")
            return false
        }
        
        // Award points
        await pointService.award(userId: userId, delta: 2)
        totalPoints += 2
        
        return true
    }
}

#Preview {
    FlashCardQuizView()
}