import SwiftUI

struct MoodIntroView: View {
    @Binding var currentStep: OnboardingStep
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var appRouter: AppRouter
    @State private var selectedColor: SimpleMoodColor?
    @State private var selectedEmoji: String?
    
    var body: some View {
        ColorWheelView(
            selectedColor: $selectedColor,
            selectedEmoji: $selectedEmoji,
            onSave: {
                await saveMoodAndProceed()
            }
        )
    }
    
    private func saveMoodAndProceed() async {
        guard let color = selectedColor else { return }
        
        // Use the mood service directly
        let moodService = ServiceContainer.shared.moodService
        
        do {
            try await moodService.save(color: color, emoji: selectedEmoji)
            
            // Navigate to pulse after saving
            await MainActor.run {
                appRouter.currentRoute = .pulse
                currentStep = .complete
            }
        } catch {
            print("Error saving initial mood: \(error)")
        }
    }
}

#Preview {
    MoodIntroView(currentStep: .constant(.moodIntro))
        .environmentObject(OnboardingViewModel())
        .environmentObject(AppRouter())
}