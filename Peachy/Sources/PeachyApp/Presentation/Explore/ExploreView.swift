import SwiftUI

struct ExploreView: View {
    @State private var selectedGame = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Explore Activities")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Tree Garden Card
                        NavigationLink(destination: TreeGardenView()) {
                            GameCard(
                                title: "Tree Garden",
                                subtitle: "Grow your mood tree",
                                icon: "tree.fill",
                                gradient: LinearGradient(
                                    colors: [Color(hex: "#2BB3B3"), Color(hex: "#1FA3A3")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        
                        // Flash Cards Card
                        NavigationLink(destination: FlashCardQuizView()) {
                            GameCard(
                                title: "Flash Cards",
                                subtitle: "Test your knowledge",
                                icon: "rectangle.stack.fill",
                                gradient: LinearGradient(
                                    colors: [Color(hex: "#FFC7B2"), Color(hex: "#FFB7A2")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        
                        // Coming Soon Cards
                        GameCard(
                            title: "Mood Patterns",
                            subtitle: "Coming soon",
                            icon: "chart.line.uptrend.xyaxis",
                            gradient: LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            disabled: true
                        )
                        
                        GameCard(
                            title: "Family Challenges",
                            subtitle: "Coming soon",
                            icon: "person.3.fill",
                            gradient: LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            disabled: true
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct GameCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    var disabled: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.white)
        }
        .padding()
        .frame(height: 100)
        .background(gradient)
        .cornerRadius(16)
        .opacity(disabled ? 0.6 : 1.0)
    }
}

#Preview {
    ExploreView()
        .environmentObject(AppState())
}