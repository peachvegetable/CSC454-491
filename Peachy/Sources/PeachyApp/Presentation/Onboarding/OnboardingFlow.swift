import SwiftUI

public struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var isComplete = false
    
    public var body: some View {
        Group {
            if !isComplete {
                OnboardingView(onComplete: completeOnboarding)
                    .environmentObject(viewModel)
            } else {
                // Show nothing when complete - the parent view will switch
                EmptyView()
            }
        }
    }
    
    private func completeOnboarding() {
        // Ensure we have the latest user from auth service
        let authService = ServiceContainer.shared.authService
        if authService.isSignedIn {
            DispatchQueue.main.async {
                self.appState.isAuthenticated = true
                if let user = authService.currentUser {
                    self.appState.userRole = user.userRole
                }
                self.isComplete = true
            }
        }
    }
}

#Preview {
    OnboardingFlow()
        .environmentObject(AppState())
}