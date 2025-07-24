import SwiftUI

// MARK: - Achievement System
struct TreeAchievementView: View {
    let achievement: TreeAchievement
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [achievement.color.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(showAnimation ? 1.2 : 0.8)
                
                // Medal
                Circle()
                    .fill(achievement.color)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(achievement.icon)
                            .font(.system(size: 40))
                    )
                    .scaleEffect(showAnimation ? 1.0 : 0)
                    .rotationEffect(.degrees(showAnimation ? 0 : -180))
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showAnimation ? 1 : 0)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showAnimation = true
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Achievement Models
struct TreeAchievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let requirement: AchievementRequirement
}

enum AchievementRequirement {
    case firstTree
    case treeCount(Int)
    case waterAmount(Int)
    case treeType(TreeType)
    case streak(Int)
    case allTreeTypes
    case speedGrowth(minutes: Int)
}

// MARK: - Achievement Manager
class TreeAchievementManager: ObservableObject {
    @Published var unlockedAchievements: Set<String> = []
    @Published var showingAchievement: TreeAchievement?
    
    static let achievements: [TreeAchievement] = [
        TreeAchievement(
            title: "First Seed",
            description: "Plant your first tree",
            icon: "🌱",
            color: .green,
            requirement: .firstTree
        ),
        TreeAchievement(
            title: "Green Thumb",
            description: "Grow 5 trees",
            icon: "👍",
            color: .green,
            requirement: .treeCount(5)
        ),
        TreeAchievement(
            title: "Forest Guardian",
            description: "Grow 10 trees",
            icon: "🌲",
            color: .green,
            requirement: .treeCount(10)
        ),
        TreeAchievement(
            title: "Water Master",
            description: "Use 1000 water drops",
            icon: "💧",
            color: .blue,
            requirement: .waterAmount(1000)
        ),
        TreeAchievement(
            title: "Cherry Blossom",
            description: "Grow your first cherry tree",
            icon: "🌸",
            color: .pink,
            requirement: .treeType(.cherry)
        ),
        TreeAchievement(
            title: "Collector",
            description: "Grow all tree types",
            icon: "🏆",
            color: .yellow,
            requirement: .allTreeTypes
        ),
        TreeAchievement(
            title: "Speed Grower",
            description: "Grow a tree in under 5 minutes",
            icon: "⚡",
            color: .orange,
            requirement: .speedGrowth(minutes: 5)
        )
    ]
    
    @MainActor
    func checkAchievements(for userId: String, treeService: TreeServiceProtocol) {
        let collection = treeService.getTreeCollection(for: userId)
        
        // Check each achievement
        for achievement in Self.achievements {
            if !unlockedAchievements.contains(achievement.title) {
                if isAchievementUnlocked(achievement, collection: collection) {
                    unlockAchievement(achievement)
                }
            }
        }
    }
    
    private func isAchievementUnlocked(_ achievement: TreeAchievement, collection: TreeCollection) -> Bool {
        switch achievement.requirement {
        case .firstTree:
            return collection.totalTreesGrown >= 1
        case .treeCount(let count):
            return collection.totalTreesGrown >= count
        case .waterAmount(_):
            // Would need to track total water used
            return false
        case .treeType(let type):
            return collection.hasCollected(type: type)
        case .streak(_):
            // Would need to track daily streaks
            return false
        case .allTreeTypes:
            return TreeType.allCases.allSatisfy { collection.hasCollected(type: $0) }
        case .speedGrowth(_):
            // Would need to track growth time
            return false
        }
    }
    
    private func unlockAchievement(_ achievement: TreeAchievement) {
        unlockedAchievements.insert(achievement.title)
        showingAchievement = achievement
        
        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.showingAchievement?.id == achievement.id {
                self.showingAchievement = nil
            }
        }
    }
}

// MARK: - Tree Care Tips
struct TreeCareTipView: View {
    let tip: TreeCareTip
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tip.icon)
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text(tip.title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                Text(tip.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                
                if let funFact = tip.funFact {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(funFact)
                            .font(.caption)
                            .italic()
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TreeCareTip {
    let title: String
    let description: String
    let icon: String
    let funFact: String?
    
    static let tips: [TreeCareTip] = [
        TreeCareTip(
            title: "Water Wisely",
            description: "Trees need consistent watering to grow strong. Try to water your tree regularly rather than all at once.",
            icon: "drop.circle",
            funFact: "A large tree can drink up to 100 gallons of water per day!"
        ),
        TreeCareTip(
            title: "Growth Stages",
            description: "Your tree goes through 5 stages: seed, sprout, sapling, young tree, and fully grown. Each stage is special!",
            icon: "leaf.circle",
            funFact: "The oldest tree in the world is over 5,000 years old!"
        ),
        TreeCareTip(
            title: "Tree Types",
            description: "Different trees need different amounts of water. Cherry trees are delicate, while oak trees are hardy.",
            icon: "tree.circle",
            funFact: "Cherry blossoms only bloom for about two weeks each year!"
        ),
        TreeCareTip(
            title: "Earn More Points",
            description: "Share hobbies, complete quests, and answer quiz questions to earn more points for watering.",
            icon: "star.circle",
            funFact: "Trees can communicate with each other through underground networks!"
        )
    ]
}

// MARK: - Progress Milestone View
struct TreeMilestoneView: View {
    let milestone: TreeMilestone
    let isAchieved: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isAchieved ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Image(systemName: milestone.icon)
                    .foregroundColor(.white)
                    .font(.title3)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.headline)
                    .foregroundColor(isAchieved ? .primary : .secondary)
                
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Reward
            if isAchieved {
                VStack {
                    Text("+\(milestone.pointReward)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("points")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isAchieved ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
}

struct TreeMilestone {
    let title: String
    let description: String
    let icon: String
    let pointReward: Int
    let requirement: Int // Water amount needed
    
    static func milestones(for treeType: TreeType) -> [TreeMilestone] {
        let total = treeType.waterRequired
        return [
            TreeMilestone(
                title: "Planted",
                description: "Your seed is in the soil",
                icon: "circle.fill",
                pointReward: 5,
                requirement: 0
            ),
            TreeMilestone(
                title: "Sprouted",
                description: "First signs of life!",
                icon: "leaf",
                pointReward: 10,
                requirement: Int(Double(total) * 0.25)
            ),
            TreeMilestone(
                title: "Growing Strong",
                description: "Your tree is taking shape",
                icon: "tree",
                pointReward: 15,
                requirement: Int(Double(total) * 0.5)
            ),
            TreeMilestone(
                title: "Almost There",
                description: "Just a bit more water!",
                icon: "sparkles",
                pointReward: 20,
                requirement: Int(Double(total) * 0.75)
            ),
            TreeMilestone(
                title: "Fully Grown",
                description: "A magnificent tree!",
                icon: "star.fill",
                pointReward: 50,
                requirement: total
            )
        ]
    }
}