import SwiftUI

public struct QuestDetailView: View {
    let quest: Quest
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = QuestViewModel()
    
    public init(quest: Quest) {
        self.quest = quest
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Quest Header
                VStack(spacing: 12) {
                    Text(quest.title)
                        .font(.largeTitle)
                        .bold()
                    
                    Text(quest.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Hobbies Section
                if viewModel.isLoading {
                    ProgressView("Loading hobbies...")
                        .padding()
                } else if viewModel.hobbies.isEmpty {
                    Text("No hobbies found")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(viewModel.hobbies) { hobby in
                                QuestHobbyChip(
                                    hobby: hobby,
                                    isSelected: viewModel.selectedHobbyIds.contains(hobby.id)
                                ) {
                                    viewModel.toggleHobby(hobby.id)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Mark Done Button
                Button(action: {
                    viewModel.markQuestComplete()
                    dismiss()
                }) {
                    Text("Mark Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.selectedHobbyIds.isEmpty ? Color.gray : Color(hex: "#2BB3B3"))
                        .cornerRadius(12)
                }
                .disabled(viewModel.selectedHobbyIds.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadHobbies()
        }
    }
}

struct QuestHobbyChip: View {
    let hobby: Hobby
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(hobby.name)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color(hex: "#2BB3B3") : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    QuestDetailView(
        quest: Quest(
            id: UUID(),
            title: "Share a Hobby",
            description: "Pick one of your hobbies and share something interesting with your family.",
            kind: .shareHobby
        )
    )
}