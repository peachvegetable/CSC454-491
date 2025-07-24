import SwiftUI

enum OnboardingStep {
    case welcome
    case auth
    case signUp
    case rolePicker
    case hobbyPicker
    case moodIntro
    case complete
}

struct OnboardingView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @EnvironmentObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome:
                WelcomeView(currentStep: $currentStep)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), 
                                          removal: .move(edge: .leading)))
                
            case .auth:
                AuthView(currentStep: $currentStep)
                    .environmentObject(viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), 
                                          removal: .move(edge: .leading)))
                
            case .signUp:
                SignUpView(currentStep: $currentStep)
                    .environmentObject(viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), 
                                          removal: .move(edge: .leading)))
                
            case .rolePicker:
                RolePickerView(currentStep: $currentStep)
                    .environmentObject(viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), 
                                          removal: .move(edge: .leading)))
                    
            case .hobbyPicker:
                HobbyPickerView(currentStep: $currentStep)
                    .environmentObject(viewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), 
                                          removal: .move(edge: .leading)))
                    
            case .moodIntro:
                // Skip mood intro, go directly to complete
                EmptyView()
                    .onAppear {
                        currentStep = .complete
                        onComplete()
                    }
                
            case .complete:
                // Show a loading state while transitioning
                VStack {
                    ProgressView()
                    Text("Setting up your experience...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
                .onAppear {
                    // Delay slightly to ensure state updates properly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onComplete()
                    }
                }
            }
        }
        .animation(.easeInOut, value: currentStep)
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environmentObject(OnboardingViewModel())
}