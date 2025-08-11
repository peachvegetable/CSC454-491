import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.injected) var container: ServiceContainer
    
    public init() {}
    
    public var body: some View {
        Group {
            if !appState.isAuthenticated {
                OnboardingFlow()
            } else if !appState.isPaired {
                PairingView()
            } else {
                mainTabView
            }
        }
        .animation(.easeInOut, value: appState.isAuthenticated)
        .animation(.easeInOut, value: appState.isPaired)
    }
    
    @ViewBuilder
    private var mainTabView: some View {
        // All users now use the same tab view
        TabBarView()
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}