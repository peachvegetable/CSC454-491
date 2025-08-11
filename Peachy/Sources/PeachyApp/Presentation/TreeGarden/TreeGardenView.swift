import SwiftUI

public struct TreeGardenView: View {
    @StateObject private var viewModel = TreeGardenViewModel()
    @State private var showTreePicker = false
    @State private var waterAmount = 5
    @State private var showWateringAnimation = false
    @State private var selectedTip: TreeCareTip?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#A8E6CF").opacity(0.3),
                    Color(hex: "#7FD8BE").opacity(0.2),
                    Color(hex: "#B8E6D3").opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Enhanced Points Header
                    PointsHeaderView(
                        points: viewModel.userPoints,
                        onAddTestPoints: {
                            Task { await viewModel.addTestPoints(50) }
                        },
                        onShowCollection: { showTreePicker = true }
                    )
                    
                    // Main Tree Section
                    if let currentTree = viewModel.currentTree {
                        TreeDisplaySection(
                            tree: currentTree,
                            showWateringAnimation: $showWateringAnimation,
                            waterAmount: $waterAmount,
                            userPoints: viewModel.userPoints,
                            onWater: waterTree,
                            onPlantNew: plantNewTree
                        )
                    } else {
                        EmptyTreeSection(onPlantTree: plantNewTree)
                    }
                    
                    // Enhanced Tree Care Tips
                    TreeCareTipsSection(selectedTip: $selectedTip)
                }
                .padding()
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Tree Garden")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTreePicker) {
            TreeCollectionView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    private func waterTree() {
        showWateringAnimation = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        Task {
            await viewModel.waterTree(amount: waterAmount)
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    showWateringAnimation = false
                }
            }
        }
    }
    
    private func plantNewTree() {
        showTreePicker = true
    }
}

// MARK: - Points Header
struct PointsHeaderView: View {
    let points: Int
    let onAddTestPoints: () -> Void
    let onShowCollection: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Points Card
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(points)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                #if DEBUG
                Button(action: onAddTestPoints) {
                    Text("+50")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                }
                #endif
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
            )
            
            // Collection Button
            Button(action: onShowCollection) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#2BB3B3"), Color(hex: "#1FA3A3")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "tree.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                    
                    Text("Collection")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "#2BB3B3"))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
            )
        }
    }
}

// MARK: - Tree Display Section
struct TreeDisplaySection: View {
    let tree: Tree
    @Binding var showWateringAnimation: Bool
    @Binding var waterAmount: Int
    let userPoints: Int
    let onWater: () -> Void
    let onPlantNew: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Tree Visual Card
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#E8F5E9"),
                                Color(hex: "#C8E6C9")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 350)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
                
                VStack(spacing: 0) {
                    // Sky area
                    EnhancedTreeView(tree: tree, showWateringAnimation: $showWateringAnimation)
                        .frame(height: 280)
                        .padding()
                    
                    // Ground area with info
                    VStack(spacing: 8) {
                        Text(tree.type.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            Label(tree.growthStage.displayName, systemImage: "leaf.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Label("\(Int(tree.growthProgress * 100))%", systemImage: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom)
                }
            }
            
            // Growth Progress Card
            VStack(spacing: 12) {
                HStack {
                    Text("Growth Progress")
                        .font(.headline)
                    Spacer()
                    Text("\(tree.currentWater)/\(tree.type.waterRequired) 💧")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                // Custom Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 24)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#4CAF50"),
                                        Color(hex: "#8BC34A")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * tree.growthProgress, height: 24)
                        
                        // Animated water drops
                        if tree.growthProgress > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<min(5, Int(tree.growthProgress * 10)), id: \.self) { _ in
                                    Text("💧")
                                        .font(.caption2)
                                }
                            }
                            .offset(x: geometry.size.width * tree.growthProgress - 30)
                        }
                    }
                }
                .frame(height: 24)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
            )
            
            // Watering Controls
            if !tree.isFullyGrown {
                WateringCard(
                    waterAmount: $waterAmount,
                    userPoints: userPoints,
                    tree: tree,
                    onWater: onWater
                )
            } else {
                CelebrationCard(onPlantNew: onPlantNew)
            }
        }
    }
}

// MARK: - Watering Card
struct WateringCard: View {
    @Binding var waterAmount: Int
    let userPoints: Int
    let tree: Tree
    let onWater: () -> Void
    
    var maxDropsFromPoints: Int { userPoints * 5 }
    var remainingDropsNeeded: Int { max(0, tree.type.waterRequired - tree.currentWater) }
    var maxDrops: Int { min(maxDropsFromPoints, remainingDropsNeeded) }
    var pointCost: Int { max(1, waterAmount / 5) }
    
    var body: some View {
        VStack(spacing: 16) {
            if maxDrops >= 5 {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Water Your Tree")
                                .font(.headline)
                            Text("\(waterAmount) drops = \(pointCost) points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Water animation
                        Image(systemName: "drop.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(-15))
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: waterAmount
                            )
                    }
                    
                    if maxDrops > 5 {
                        Slider(value: Binding(
                            get: { Double(waterAmount) },
                            set: { waterAmount = Int($0) }
                        ), in: 5...Double(maxDrops), step: 5)
                        .accentColor(Color.blue)
                    }
                    
                    Button(action: onWater) {
                        HStack {
                            Image(systemName: "drop.fill")
                            Text("Water Tree")
                            Text("(\(pointCost) pts)")
                                .fontWeight(.regular)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                    }
                }
            } else {
                NeedPointsCard()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Need Points Card
struct NeedPointsCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.drop.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Need More Points")
                .font(.headline)
            
            Text("Complete tasks or update your mood to earn points!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Celebration Card
struct CelebrationCard: View {
    let onPlantNew: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🎉")
                    .font(.largeTitle)
                Text("Tree Fully Grown!")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("🎉")
                    .font(.largeTitle)
            }
            
            Button(action: onPlantNew) {
                Label("Plant New Tree", systemImage: "leaf.arrow.circlepath")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color(hex: "#4CAF50")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.green.opacity(0.1),
                            Color.yellow.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Empty Tree Section
struct EmptyTreeSection: View {
    let onPlantTree: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Illustration Card
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.1),
                                Color.green.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: "leaf.circle")
                    .font(.system(size: 100))
                    .foregroundColor(Color.green.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text("Start Your Garden")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Plant your first tree and watch it grow with care!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onPlantTree) {
                HStack {
                    Image(systemName: "tree")
                    Text("Plant Your First Tree")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.green, Color(hex: "#4CAF50")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
                .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding()
    }
}

// MARK: - Tree Care Tips Section
struct TreeCareTipsSection: View {
    @Binding var selectedTip: TreeCareTip?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tree Care Tips")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(Array(TreeCareTip.tips.enumerated()), id: \.element.title) { index, tip in
                    TreeCareTipCard(tip: tip, index: index, isExpanded: selectedTip?.title == tip.title) {
                        withAnimation(.spring()) {
                            selectedTip = selectedTip?.title == tip.title ? nil : tip
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Tree Care Tip Card
struct TreeCareTipCard: View {
    let tip: TreeCareTip
    let index: Int
    let isExpanded: Bool
    let onTap: () -> Void
    
    private var tipColor: Color {
        let colors = [
            Color(hex: "#4CAF50"), // Green
            Color(hex: "#2196F3"), // Blue
            Color(hex: "#FF9800"), // Orange
            Color(hex: "#9C27B0")  // Purple
        ]
        return colors[index % colors.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tipColor.opacity(0.8),
                                        tipColor
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: tip.icon)
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    }
                    
                    Text(tip.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(tip.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 52)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    NavigationView {
        TreeGardenView()
    }
}