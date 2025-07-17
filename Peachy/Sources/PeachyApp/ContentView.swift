import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.injected) var container: ServiceContainer
    
    var body: some View {
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
        if appState.userRole == .teen {
            TeenTabView()
        } else {
            ParentTabView()
        }
    }
}

// MARK: - Teen Tab View
struct TeenTabView: View {
    var body: some View {
        TabView {
            MoodSignalView()
                .tabItem {
                    Label("Mood", systemImage: "face.smiling")
                }
            
            HobbyExplorerView()
                .tabItem {
                    Label("Hobbies", systemImage: "sparkles")
                }
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

// MARK: - Parent Tab View
struct ParentTabView: View {
    var body: some View {
        TabView {
            ParentDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }
            
            HobbyLearningView()
                .tabItem {
                    Label("Learn", systemImage: "book")
                }
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}