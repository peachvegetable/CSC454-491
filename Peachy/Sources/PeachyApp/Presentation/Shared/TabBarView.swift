import SwiftUI

public struct TabBarView: View {
    @State private var selectedTab = 0
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            PulseView()
                .tabItem {
                    Label("Pulse", systemImage: "waveform.path.ecg")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "#2BB3B3"))
    }
}

#Preview {
    TabBarView()
        .environmentObject(AppState())
}