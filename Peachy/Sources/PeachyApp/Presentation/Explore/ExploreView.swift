import SwiftUI

struct ExploreView: View {
    @State private var selectedGame = 0
    @Binding var hideFloatingButton: Bool
    
    init(hideFloatingButton: Binding<Bool> = .constant(false)) {
        self._hideFloatingButton = hideFloatingButton
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Explore Activities")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Tree Garden Card
                        NavigationLink {
                            TreeGardenView()
                                .onAppear {
                                    hideFloatingButton = true
                                }
                                .onDisappear {
                                    hideFloatingButton = false
                                }
                        } label: {
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
                        NavigationLink {
                            FlashCardQuizView()
                        } label: {
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
                        
                        // Family Voting Card
                        NavigationLink {
                            FamilyVotingView()
                        } label: {
                            GameCard(
                                title: "Family Voting",
                                subtitle: "Make decisions together",
                                icon: "hand.raised.fill",
                                gradient: LinearGradient(
                                    colors: [Color.purple, Color.purple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Family Calendar Card
                        NavigationLink {
                            FamilyCalendarView()
                        } label: {
                            GameCard(
                                title: "Family Calendar",
                                subtitle: "Stay synchronized",
                                icon: "calendar",
                                gradient: LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Family Todo List Card
                        NavigationLink {
                            FamilyTodoListView()
                        } label: {
                            GameCard(
                                title: "Family Tasks",
                                subtitle: "Share responsibilities",
                                icon: "checklist",
                                gradient: LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Family Photos Card
                        NavigationLink {
                            FamilyPhotoView()
                        } label: {
                            GameCard(
                                title: "Family Photos",
                                subtitle: "Capture memories together",
                                icon: "camera.fill",
                                gradient: LinearGradient(
                                    colors: [Color.pink, Color.pink.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
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
    ExploreView(hideFloatingButton: .constant(false))
        .environmentObject(AppState())
}