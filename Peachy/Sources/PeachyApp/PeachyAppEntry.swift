import SwiftUI
import RealmSwift

public struct PeachyAppEntry: View {
    @StateObject private var appState = AppState()
    @StateObject private var appRouter = AppRouter()
    @State private var showOnboarding = false
    @State private var isInitialized = false
    
    public init() {}
    
    public var body: some View {
        Group {
            if !isInitialized {
                // Show loading while checking auth status
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
            } else {
                switch determineRoute() {
                case .welcome:
                    OnboardingFlow()
                        .environmentObject(appState)
                        .environmentObject(appRouter)
                        .transition(.opacity)
                case .hobbyPicker:
                    HobbyPickerView(currentStep: .constant(.hobbyPicker))
                        .environmentObject(OnboardingViewModel())
                        .environmentObject(appRouter)
                        .transition(.opacity)
                case .moodWheel:
                    NavigationStack {
                        MoodLoggerView()
                            .environmentObject(appRouter)
                    }
                    .transition(.opacity)
                case .pulse:
                    TabBarView()
                        .environmentObject(appState)
                        .environmentObject(appRouter)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appRouter.currentRoute)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .environment(\.injected, ServiceContainer.shared)
        .onAppear {
            checkAuthStatus()
            setupSignOutHandler()
        }
        .onChange(of: appState.isAuthenticated) { newValue in
            showOnboarding = !newValue
            _ = determineRoute()  // Update route when auth changes
        }
        .onChange(of: appRouter.currentRoute) { _ in
            // Route changes will automatically trigger view updates
        }
    }
    
    private func checkAuthStatus() {
        let authService = ServiceContainer.shared.authService
        appState.isAuthenticated = authService.isSignedIn
        showOnboarding = !authService.isSignedIn
        
        // Initialize chat data if user is signed in
        if authService.isSignedIn {
            Task { @MainActor in
                ServiceContainer.shared.chatService.ensureInitialData()
            }
        }
        
        // Mark as initialized after a brief delay to ensure proper rendering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInitialized = true
        }
    }
    
    private func determineRoute() -> AppRoute {
        let authService = ServiceContainer.shared.authService
        
        // Not signed in → Welcome
        if !authService.isSignedIn {
            return .welcome
        }
        
        guard let user = authService.currentUser else { return .welcome }
        
        // No hobbies → HobbyPicker
        if user.hobbies.isEmpty {
            return .hobbyPicker
        }
        
        // Check if user has logged mood today
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let predicate = NSPredicate(
            format: "userId == %@ AND createdAt >= %@ AND createdAt < %@",
            user.id, startOfDay as NSDate, endOfDay as NSDate
        )
        
        let todayMoodCount = RealmManager.shared.fetch(MoodLog.self, predicate: predicate).count
        
        // No mood today → MoodWheel
        if todayMoodCount == 0 {
            return .moodWheel
        }
        
        // Otherwise → Pulse
        return .pulse
    }
    
    private func setupSignOutHandler() {
        var authService = ServiceContainer.shared.authService
        authService.signOutHandler = {
            // Navigate to welcome screen before deleting data
            self.appRouter.currentRoute = .welcome
            self.appState.isAuthenticated = false
        }
    }
}