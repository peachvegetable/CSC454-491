import SwiftUI

public struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appRouter: AppRouter
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
        print("OnboardingFlow - completeOnboarding: isSignedIn = \(authService.isSignedIn)")
        
        if authService.isSignedIn {
            DispatchQueue.main.async {
                self.appState.isAuthenticated = true
                if let user = authService.currentUser {
                    self.appState.userRole = user.userRole
                    print("OnboardingFlow - completeOnboarding: User role set to \(user.userRole)")
                }
                self.isComplete = true
                
                // Update the route to move past onboarding
                self.appRouter.currentRoute = self.determineNextRoute()
            }
        }
    }
    
    private func determineNextRoute() -> AppRoute {
        let authService = ServiceContainer.shared.authService
        guard let user = authService.currentUser else { return .welcome }
        
        if user.hobbies.isEmpty {
            return .hobbyPicker
        }
        
        // Go directly to Pulse (main app)
        return .pulse
    }
}

#Preview {
    OnboardingFlow()
        .environmentObject(AppState())
        .environmentObject(AppRouter())
}