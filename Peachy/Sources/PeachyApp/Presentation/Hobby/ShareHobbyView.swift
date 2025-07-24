import SwiftUI

struct ShareHobbyView: View {
    @StateObject private var viewModel = ShareHobbyViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var hobbyFact = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#FFC7B2"))
                    
                    Text("Share a Hobby Fact")
                        .font(.title2)
                        .bold()
                    
                    Text("Tell your family something interesting about your hobbies")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Hobby selection
                if !viewModel.userHobbies.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.userHobbies, id: \.id) { hobby in
                                HobbySelectionChip(
                                    hobby: hobby,
                                    isSelected: viewModel.selectedHobby?.id == hobby.id,
                                    action: { viewModel.selectedHobby = hobby }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Fact input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Hobby Fact")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $hobbyFact)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .frame(minHeight: 100)
                        .padding(.horizontal)
                        .focused($isTextFieldFocused)
                }
                
                // Points indicator
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("Earn 5 points for sharing!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Share button
                Button(action: {
                    Task {
                        await viewModel.shareHobbyFact(hobbyFact)
                        dismiss()
                    }
                }) {
                    Text("Share Fact")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (viewModel.selectedHobby != nil && !hobbyFact.isEmpty) ?
                            Color(hex: "#2BB3B3") : Color.gray
                        )
                        .cornerRadius(12)
                }
                .disabled(viewModel.selectedHobby == nil || hobbyFact.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
            .onAppear {
                Task {
                    await viewModel.loadUserHobbies()
                }
            }
        }
    }
}

struct HobbySelectionChip: View {
    let hobby: HobbyModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(hobby.name)
                .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "#FFC7B2") : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// ViewModel for ShareHobbyView
@MainActor
class ShareHobbyViewModel: ObservableObject {
    @Published var userHobbies: [HobbyModel] = []
    @Published var selectedHobby: HobbyModel?
    @Published var isLoading = false
    
    private let hobbyService = ServiceContainer.shared.hobbyService
    private let authService = ServiceContainer.shared.authService
    
    func loadUserHobbies() async {
        guard let userId = authService.currentUser?.id else { return }
        
        // For now, create some sample hobbies
        // In production, this would fetch from the database
        userHobbies = [
            HobbyModel(name: "Photography", ownerId: userId, fact: ""),
            HobbyModel(name: "Gaming", ownerId: userId, fact: ""),
            HobbyModel(name: "Reading", ownerId: userId, fact: ""),
            HobbyModel(name: "Cooking", ownerId: userId, fact: "")
        ]
        
        if !userHobbies.isEmpty {
            selectedHobby = userHobbies.first
        }
    }
    
    func shareHobbyFact(_ fact: String) async {
        guard let hobby = selectedHobby,
              let userId = authService.currentUser?.id else { return }
        
        // Update the hobby with the fact
        hobby.fact = fact
        
        // In production, this would:
        // 1. Save to database
        // 2. Award 5 points
        // 3. Create flash cards for family members
        // 4. Notify other family members
        
        print("Shared hobby fact: \(fact) for hobby: \(hobby.name)")
    }
}

#Preview {
    ShareHobbyView()
        .environmentObject(AppState())
}