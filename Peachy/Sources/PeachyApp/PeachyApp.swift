import SwiftUI

@main
struct PeachyApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(\.injected, ServiceContainer.shared)
        }
    }
    
    private func setupAppearance() {
        // Configure global appearance
        let peachColor = UIColor(red: 255/255, green: 199/255, blue: 178/255, alpha: 1.0)
        let tealColor = UIColor(red: 43/255, green: 179/255, blue: 179/255, alpha: 1.0)
        
        UINavigationBar.appearance().tintColor = tealColor
        UITabBar.appearance().tintColor = tealColor
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userRole: UserRole?
    @Published var isPaired = false
    
    enum UserRole: String, CaseIterable {
        case teen = "Teen"
        case parent = "Parent"
    }
}

// MARK: - Dependency Injection
struct InjectedKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = ServiceContainer.shared
}

extension EnvironmentValues {
    var injected: ServiceContainer {
        get { self[InjectedKey.self] }
        set { self[InjectedKey.self] = newValue }
    }
}

// MARK: - Service Container
class ServiceContainer {
    static let shared = ServiceContainer()
    
    lazy var authService: AuthServiceProtocol = MockAuthService()
    lazy var moodService: MoodServiceProtocol = MockMoodService()
    lazy var hobbyService: HobbyServiceProtocol = MockHobbyService()
    lazy var aiService: AIServiceProtocol = MockAIService()
    lazy var notificationService: NotificationServiceProtocol = MockNotificationService()
    
    private init() {}
}