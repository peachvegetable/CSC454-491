import SwiftUI

struct ExploreView: View {
    @State private var selectedGame = 0
    @State private var navigationPath = NavigationPath()
    @Binding var hideFloatingButton: Bool
    
    init(hideFloatingButton: Binding<Bool> = .constant(false)) {
        self._hideFloatingButton = hideFloatingButton
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 20) {
                Text("Explore Activities")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Tree Garden Card
                        Button(action: {
                            hideFloatingButton = true
                            navigationPath.append("treeGarden")
                        }) {
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
                        .buttonStyle(PlainButtonStyle())
                        
                        // Flash Cards Card
                        Button(action: {
                            navigationPath.append("flashCards")
                        }) {
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
                        .buttonStyle(PlainButtonStyle())
                        
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
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "treeGarden":
                    TreeGardenView()
                        .onDisappear {
                            hideFloatingButton = false
                        }
                case "flashCards":
                    FlashCardQuizView()
                default:
                    EmptyView()
                }
            }
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
    ExploreView(hideFloatingButton: .constant(false))
        .environmentObject(AppState())
}