import SwiftUI

public struct TabBarView: View {
    @State private var selectedTab = 0
    @State private var showMoodSignal = false
    @State private var showProfile = false
    @State private var hideFloatingButton = false
    @EnvironmentObject var appState: AppState
    @StateObject private var featureSettings = ServiceContainer.shared.featureSettingsService
    
    public var body: some View {
        ZStack {
            // Main Tab Content
            TabView(selection: $selectedTab) {
                    PulseView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Pulse")
                        }
                        .tag(0)
                    
                    ExploreView(hideFloatingButton: $hideFloatingButton)
                        .tabItem {
                            Image(systemName: "safari")
                            Text("Explore")
                        }
                        .tag(1)
                    
                    // Empty view for center plus button
                    Color.clear
                        .tabItem {
                            Image(systemName: "plus")
                                .opacity(0)
                            Text(" ")
                        }
                        .tag(2)
                        .disabled(true)
                    
                    JourneyView()
                        .tabItem {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Journey")
                        }
                        .tag(3)
                    
                    if featureSettings.isFeatureEnabled(.chat) {
                        ChatListView(hideFloatingButton: $hideFloatingButton)
                            .tabItem {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Chat")
                            }
                            .tag(4)
                    }
                }
                .accentColor(Color(hex: "#2BB3B3"))
            
            // Floating Plus Button - positioned in center of tab bar
            if !hideFloatingButton {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showMoodSignal = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                        Spacer()
                    }
                    .padding(.bottom, 12) // Position right on the tab bar
                }
            }
        }
        .sheet(isPresented: $showMoodSignal) {
            NavigationView {
                MoodLoggerView()
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(appState)
        }
        .onAppear {
            featureSettings.loadSettings()
            featureSettings.startObservingRequests()
        }
    }
}

#Preview {
    TabBarView()
        .environmentObject(AppState())
}