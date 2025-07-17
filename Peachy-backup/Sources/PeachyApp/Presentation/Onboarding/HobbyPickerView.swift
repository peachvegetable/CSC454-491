import SwiftUI

struct HobbyPickerView: View {
    @Binding var currentStep: OnboardingStep
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appRouter: AppRouter
    @State private var searchText = ""
    @State private var selectedHobbies: Set<String> = []
    
    let maxHobbies = 3
    
    // Preset hobbies - would normally load from HobbyTags.json
    let presetHobbies = [
        "Gaming", "Reading", "Music", "Sports", "Art", "Cooking",
        "Photography", "Dancing", "Writing", "Coding", "Movies",
        "Anime", "Travel", "Fashion", "Fitness", "Yoga",
        "Swimming", "Basketball", "Soccer", "Tennis", "Running",
        "Drawing", "Painting", "Singing", "Guitar", "Piano",
        "Chess", "Board Games", "Hiking", "Camping", "Gardening",
        "Volunteering", "Drama", "Debate", "Science", "Math"
    ]
    
    var filteredHobbies: [String] {
        if searchText.isEmpty {
            return presetHobbies
        } else {
            return presetHobbies.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("What are you into?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(selectedHobbies.count)/\(maxHobbies)")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            ScrollView(.vertical) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(filteredHobbies, id: \.self) { hobby in
                        HobbyChip(
                            hobby: hobby,
                            isSelected: selectedHobbies.contains(hobby),
                            onTap: {
                                toggleHobby(hobby)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Button(action: saveHobbies) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedHobbies.isEmpty ? Color.gray : Color(hex: "#2BB3B3"))
                    .cornerRadius(12)
            }
            .disabled(selectedHobbies.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private func toggleHobby(_ hobby: String) {
        if selectedHobbies.contains(hobby) {
            selectedHobbies.remove(hobby)
        } else if selectedHobbies.count < maxHobbies {
            selectedHobbies.insert(hobby)
        }
    }
    
    private func saveHobbies() {
        Task {
            await viewModel.updateHobbies(Array(selectedHobbies))
            await MainActor.run {
                // Navigate to mood wheel after saving hobbies
                appRouter.currentRoute = .moodWheel
            }
        }
    }
}

struct HobbyChip: View {
    let hobby: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(hobby)
                .font(.footnote)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color(hex: "#2BB3B3") : Color.gray.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color(hex: "#2BB3B3") : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search hobbies...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    HobbyPickerView(currentStep: .constant(.hobbyPicker))
        .environmentObject(OnboardingViewModel())
}