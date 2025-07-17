import SwiftUI

struct PeachyApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            PeachyAppEntry()
                .environmentObject(appState)
                .environment(\.injected, ServiceContainer.shared)
        }
    }
    
    private func setupAppearance() {
        let peachColor = UIColor(red: 255/255, green: 199/255, blue: 178/255, alpha: 1.0)
        let tealColor = UIColor(red: 43/255, green: 179/255, blue: 179/255, alpha: 1.0)
        
        UINavigationBar.appearance().tintColor = tealColor
        UITabBar.appearance().tintColor = tealColor
    }
}

public class AppState: ObservableObject {
    @Published public var isAuthenticated = false
    @Published public var userRole: UserRole?
    @Published public var isPaired = false
    
    public init() {}
}

struct InjectedKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = ServiceContainer.shared
}

public extension EnvironmentValues {
    var injected: ServiceContainer {
        get { self[InjectedKey.self] }
        set { self[InjectedKey.self] = newValue }
    }
}