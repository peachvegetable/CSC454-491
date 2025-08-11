import SwiftUI

struct ExploreView: View {
    @State private var selectedGame = 0
    @Binding var hideFloatingButton: Bool
    @StateObject private var subscriptionService = ServiceContainer.shared.subscriptionService
    @State private var showRequestFeature: AppFeature?
    
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
                        featureCard(
                            feature: .treeGarden,
                            destination: AnyView(TreeGardenView()
                                .onAppear { hideFloatingButton = true }
                                .onDisappear { hideFloatingButton = false }),
                            title: "Tree Garden",
                            subtitle: "Grow your mood tree",
                            icon: "tree.fill",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#2BB3B3"), Color(hex: "#1FA3A3")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        
                        // Flash Cards Card (part of hobby sharing)
                        featureCard(
                            feature: .hobbySharing,
                            destination: AnyView(FlashCardQuizView()),
                            title: "Flash Cards",
                            subtitle: "Test your knowledge",
                            icon: "rectangle.stack.fill",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#FFC7B2"), Color(hex: "#FFB7A2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        
                        // Family Photos Card
                        featureCard(
                            feature: .familyPhotos,
                            destination: AnyView(FamilyPhotoView()),
                            title: "Family Photos",
                            subtitle: "Capture memories together",
                            icon: "camera.fill",
                            gradient: LinearGradient(
                                colors: [Color.pink, Color.pink.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        
                        // Task Rewards Card
                        featureCard(
                            feature: .taskRewards,
                            destination: AnyView(TaskListView()),
                            title: "Task Rewards",
                            subtitle: "Earn points for chores",
                            icon: "checkmark.circle.fill",
                            gradient: LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        
                        // Reward Shop Card
                        featureCard(
                            feature: .taskRewards,
                            destination: AnyView(RewardShopView()),
                            title: "Reward Shop",
                            subtitle: "Redeem your points",
                            icon: "gift.fill",
                            gradient: LinearGradient(
                                colors: [Color.indigo, Color.indigo.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        
                        // Support Insights Card (Admin only, Premium feature)
                        if ServiceContainer.shared.authService.currentUser?.userRole == .admin {
                            NavigationLink {
                                EmpathyTipsDashboard()
                            } label: {
                                GameCard(
                                    title: "Support Insights",
                                    subtitle: "Guidance for emotional moments",
                                    icon: "heart.text.square.fill",
                                    gradient: LinearGradient(
                                        colors: [Color.red.opacity(0.8), Color.pink.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    // Premium badge
                                    Text("PREMIUM")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.yellow)
                                        .cornerRadius(8)
                                        .offset(x: -10, y: -10),
                                    alignment: .topTrailing
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Family Voting Card (always available for now)
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
                        
                        // Family Calendar Card (always available for now)
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
                        
                        // Family Todo List Card (always available for now)
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
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $showRequestFeature) { feature in
            RequestFeatureView(feature: feature)
        }
        .onAppear {
            subscriptionService.initialize()
        }
    }
    
    @ViewBuilder
    private func featureCard(
        feature: AppFeature,
        destination: AnyView,
        title: String,
        subtitle: String,
        icon: String,
        gradient: LinearGradient
    ) -> some View {
        if subscriptionService.isFeatureAvailable(feature) {
            NavigationLink {
                destination
            } label: {
                GameCard(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    gradient: gradient
                )
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // Show locked card for teens
            Button(action: {
                showRequestFeature = feature
            }) {
                LockedGameCard(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    feature: feature
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct GameCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
            
            Spacer()
            
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.9))
                .padding(.trailing)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(gradient)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
    }
}

struct LockedGameCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let feature: AppFeature
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .background(Circle().fill(Color.white).frame(width: 20, height: 20))
                        .offset(x: 15, y: -15)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Ask parent to unlock")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding()
            
            Spacer()
            
            Image(systemName: "lock.circle.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .padding(.trailing)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(16)
    }
}

// Extension to make AppFeature Identifiable for sheet presentation
extension AppFeature: Identifiable {
    public var id: String { rawValue }
}

#Preview {
    ExploreView()
}