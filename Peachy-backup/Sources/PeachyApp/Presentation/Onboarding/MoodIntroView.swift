import SwiftUI

struct MoodIntroView: View {
    @Binding var currentStep: OnboardingStep
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var selectedMood: MoodColor?
    @State private var showEmojiPicker = false
    @State private var selectedEmoji: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("How are you feeling right now?")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top, 40)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            MoodWheel(selectedMood: $selectedMood)
                .frame(height: 300)
                .padding(.horizontal)
            
            if let mood = selectedMood {
                VStack(spacing: 20) {
                    Text("You selected: \(mood.rawValue)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if let emoji = selectedEmoji {
                        Text(emoji)
                            .font(.system(size: 60))
                    } else {
                        Button(action: {
                            showEmojiPicker = true
                        }) {
                            Label("Add Emoji", systemImage: "face.smiling")
                                .font(.headline)
                                .foregroundColor(Color(hex: "#2BB3B3"))
                        }
                    }
                    
                    Button(action: saveMood) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save Mood")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#2BB3B3"))
                    .cornerRadius(12)
                    .disabled(isLoading)
                    .padding(.horizontal)
                }
                .transition(.opacity)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerSheet(selectedEmoji: $selectedEmoji)
        }
        .onChange(of: selectedMood) { _ in
            selectedEmoji = nil
        }
    }
    
    private func saveMood() {
        guard let mood = selectedMood else { return }
        isLoading = true
        
        Task {
            await viewModel.saveMood(mood, emoji: selectedEmoji)
            await MainActor.run {
                currentStep = .complete
            }
        }
    }
}

#Preview {
    MoodIntroView(currentStep: .constant(.moodIntro))
        .environmentObject(OnboardingViewModel())
}