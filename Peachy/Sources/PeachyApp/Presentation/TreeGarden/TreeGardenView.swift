import SwiftUI

public struct TreeGardenView: View {
    @StateObject private var viewModel = TreeGardenViewModel()
    @State private var showTreePicker = false
    @State private var waterAmount = 10
    @State private var showWateringAnimation = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#87CEEB"), Color(hex: "#98FB98")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                    VStack(spacing: 20) {
                        // Points display
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                            Text("\(viewModel.userPoints) Points")
                                .font(.headline)
                            
                            // DEBUG: Add test points button
                            #if DEBUG
                            Button(action: {
                                Task {
                                    await viewModel.addTestPoints(50)
                                }
                            }) {
                                Text("+50")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .cornerRadius(8)
                            }
                            #endif
                            
                            Spacer()
                            
                            Button(action: { showTreePicker = true }) {
                                Image(systemName: "tree.fill")
                                    .foregroundColor(.green)
                                Text("Collection")
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        
                        // Tree display
                        if let currentTree = viewModel.currentTree {
                        VStack(spacing: 20) {
                            // Tree visualization
                            EnhancedTreeView(tree: currentTree, showWateringAnimation: $showWateringAnimation)
                                .frame(height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 10)
                            
                            // Growth progress
                            VStack(spacing: 12) {
                                HStack {
                                    Text(currentTree.type.displayName)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text(currentTree.growthStage.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(12)
                                }
                                
                                ProgressView(value: currentTree.growthProgress)
                                    .progressViewStyle(GrowthProgressStyle())
                                
                                HStack {
                                    Text("\(currentTree.currentWater) / \(currentTree.type.waterRequired) 💧")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(currentTree.growthProgress * 100))%")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                        }
                        
                        // Water controls
                        if !currentTree.isFullyGrown {
                            WaterControlsView(
                                waterAmount: $waterAmount,
                                maxAmount: min(viewModel.userPoints, currentTree.type.waterRequired - currentTree.currentWater),
                                onWater: waterTree
                            )
                        } else {
                            // Tree is fully grown
                            VStack(spacing: 12) {
                                Text("🎉 Tree Fully Grown! 🎉")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Button(action: plantNewTree) {
                                    Label("Plant New Tree", systemImage: "leaf.arrow.circlepath")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.green)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                    } else {
                        // No tree planted
                        VStack(spacing: 20) {
                            Image(systemName: "leaf.circle")
                                .font(.system(size: 80))
                                .foregroundColor(.green.opacity(0.5))
                            
                            Text("No tree planted yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button(action: plantNewTree) {
                                Label("Plant Your First Tree", systemImage: "tree")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Tree Care Tips Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tree Care Tips")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(TreeCareTip.tips.prefix(2), id: \.title) { tip in
                            TreeCareTipView(tip: tip)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding()
                .padding(.bottom, 20) // Extra padding to avoid tab bar
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Tree Garden")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTreePicker) {
            TreeCollectionView(viewModel: viewModel)
        }
        .onAppear {
            print("TreeGardenView: View appeared")
            viewModel.loadData()
        }
    }
    
    private func waterTree() {
        // Start watering animation
        showWateringAnimation = true
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        Task {
            await viewModel.waterTree(amount: waterAmount)
            
            await MainActor.run {
                // Hide animation after delay
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


// MARK: - Water Controls
struct WaterControlsView: View {
    @Binding var waterAmount: Int
    let maxAmount: Int
    let onWater: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Water Amount: \(waterAmount) 💧")
                .font(.headline)
            
            Slider(value: Binding(
                get: { Double(waterAmount) },
                set: { waterAmount = Int($0) }
            ), in: 1...Double(max(maxAmount, 1)))
            .accentColor(.blue)
            
            Button(action: onWater) {
                HStack {
                    Image(systemName: "drop.fill")
                    Text("Water Tree")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(maxAmount == 0)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
    }
}


// MARK: - Growth Progress Style
struct GrowthProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.6), Color.green],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0), height: 20)
            }
        }
        .frame(height: 20)
    }
}

#Preview {
    TreeGardenView()
}