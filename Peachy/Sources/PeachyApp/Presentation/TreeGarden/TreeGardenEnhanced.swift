import SwiftUI
import Foundation

// MARK: - Particle Models
struct WaterDrop: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
}

struct Sparkle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    var color: Color = .yellow
}

struct LeafParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    var position: CGPoint
    var rotation: Double = 0
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    
    init(startX: CGFloat, startY: CGFloat) {
        self.startX = startX
        self.startY = startY
        self.position = CGPoint(x: startX, y: startY)
    }
}

// MARK: - Time of Day
enum TimeOfDay {
    case day, sunset, night
    
    var skyColors: [Color] {
        switch self {
        case .day:
            return [Color(hex: "#87CEEB"), Color(hex: "#98FB98")]
        case .sunset:
            return [Color(hex: "#FF6B6B"), Color(hex: "#FFE66D")]
        case .night:
            return [Color(hex: "#0F0C29"), Color(hex: "#302B63")]
        }
    }
}

// MARK: - Enhanced Tree View with Particle Effects
public struct EnhancedTreeView: View {
    let tree: Tree
    @Binding var showWateringAnimation: Bool
    @State private var treeScale: CGFloat = 1.0
    @State private var waterDrops: [WaterDrop] = []
    @State private var sparkles: [Sparkle] = []
    @State private var leafParticles: [LeafParticle] = []
    @State private var showGrowthBurst = false
    @State private var windOffset: CGFloat = 0
    @State private var previousProgress: Double = 0
    
    // Day/Night cycle
    @State private var timeOfDay: TimeOfDay = .day
    @State private var sunMoonRotation: Double = 0
    @State private var dayNightTimer: Timer?
    @State private var leafFallTimer: Timer?
    
    // Watering can animation
    @State private var wateringCanPosition: CGPoint = .zero
    @State private var wateringCanRotation: Double = 0
    @State private var showWateringCan = false
    
    // MARK: - Helper Functions
    
    private func calculateTreeOffset(for progress: Double) -> CGFloat {
        let stage = TreeGrowthStage.from(progress: progress)
        switch stage {
        case .seed:
            return 10 // Seeds are partially in soil
        case .sprout:
            return -10
        case .seedling:
            return -30
        case .sapling:
            return -50
        case .mature:
            return -70
        }
    }
    
    private func getStage(for progress: Double) -> Int {
        switch progress {
        case 0..<0.25: return 0
        case 0.25..<0.5: return 1
        case 0.5..<0.75: return 2
        case 0.75..<1.0: return 3
        default: return 4
        }
    }
    
    private func createSplashEffect(at point: CGPoint) {
        for _ in 0..<5 {
            let sparkle = Sparkle(
                position: point,
                scale: 1.0,
                opacity: 1.0,
                color: .blue.opacity(0.6)
            )
            sparkles.append(sparkle)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                sparkles.removeAll { $0.id == sparkle.id }
            }
        }
    }
    
    private func createSparkles() {
        for _ in 0..<8 {
            let sparkle = Sparkle(
                position: CGPoint(
                    x: CGFloat.random(in: 150...250),
                    y: CGFloat.random(in: 200...300)
                ),
                scale: 1.0,
                opacity: 1.0,
                color: .yellow
            )
            sparkles.append(sparkle)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                sparkles.removeAll { $0.id == sparkle.id }
            }
        }
    }
    
    private func createFallingLeaf() {
        let leaf = LeafParticle(
            startX: CGFloat.random(in: 150...250),
            startY: 150
        )
        leafParticles.append(leaf)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            leafParticles.removeAll { $0.id == leaf.id }
        }
    }
    
    private func checkMilestone(oldProgress: Double, newProgress: Double) {
        // Check if crossed a growth stage
        let oldStage = getStage(for: oldProgress)
        let newStage = getStage(for: newProgress)
        
        if oldStage != newStage {
            // Show growth burst
            showGrowthBurst = true
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Stage transition animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                treeScale = 1.2
            }
            
            // Create celebration particles
            for _ in 0..<20 {
                let sparkle = Sparkle(
                    position: CGPoint(x: 200, y: 250),
                    scale: 1.5,
                    opacity: 1.0,
                    color: [.yellow, .green, .orange].randomElement()!
                )
                sparkles.append(sparkle)
            }
            
            // Clean up after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring()) {
                    treeScale = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showGrowthBurst = false
                sparkles.removeAll()
            }
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky gradient based on time
                LinearGradient(
                    colors: timeOfDay.skyColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Sun/Moon
                SunMoonView(timeOfDay: timeOfDay, rotation: sunMoonRotation)
                    .position(x: geometry.size.width * 0.8, y: 50)
                
                // Clouds
                CloudsView()
                
                // Ground with enhanced grass
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Enhanced grass with wind effect
                    EnhancedGrassView(windOffset: windOffset)
                        .frame(height: 80)
                    
                    // Rich soil with texture
                    ZStack {
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "#6B4423"), Color(hex: "#8B5A2B")],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 180, height: 60)
                            .overlay(
                                // Soil texture
                                ForEach(0..<5) { _ in
                                    Circle()
                                        .fill(Color.black.opacity(0.1))
                                        .frame(width: CGFloat.random(in: 5...15))
                                        .offset(
                                            x: CGFloat.random(in: -70...70),
                                            y: CGFloat.random(in: -20...20)
                                        )
                                }
                            )
                    }
                    .offset(y: -30)
                }
                
                // Tree with enhanced animations
                ZStack {
                    // Shadow
                    Ellipse()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 100 * tree.growthProgress, height: 20 * tree.growthProgress)
                        .offset(y: 10)
                        .blur(radius: 5)
                    
                    // Tree with wind sway and proper positioning
                    TreeVisualization(type: tree.type, progress: tree.growthProgress)
                        .scaleEffect(treeScale)
                        .rotationEffect(.degrees(Foundation.sin(windOffset) * 2))
                        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: tree.growthProgress)
                        .offset(y: calculateTreeOffset(for: tree.growthProgress))
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
                
                // Particle effects
                ForEach(waterDrops) { drop in
                    EnhancedWaterDropView(drop: drop)
                }
                
                ForEach(sparkles) { sparkle in
                    SparkleView(sparkle: sparkle)
                }
                
                // Watering can
                if showWateringCan {
                    WateringCanView()
                        .rotationEffect(.degrees(wateringCanRotation), anchor: .center)
                        .position(wateringCanPosition)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), 
                                               removal: .move(edge: .trailing).combined(with: .opacity)))
                }
                
                ForEach(leafParticles) { leaf in
                    LeafParticleView(leaf: leaf)
                }
                
                // Growth burst effect
                if showGrowthBurst {
                    GrowthBurstEffect()
                        .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
                }
            }
            .onChange(of: showWateringAnimation) { isWatering in
                if isWatering {
                    animateWatering(in: geometry)
                }
            }
            .onChange(of: tree.growthProgress) { newProgress in
                checkMilestone(oldProgress: previousProgress, newProgress: newProgress)
                previousProgress = newProgress
            }
            .onAppear {
                startAmbientAnimations()
                previousProgress = tree.growthProgress
            }
            .onDisappear {
                // Clean up timers to prevent memory leaks
                dayNightTimer?.invalidate()
                dayNightTimer = nil
                leafFallTimer?.invalidate()
                leafFallTimer = nil
            }
        }
    }
    
    private func startAmbientAnimations() {
        // Wind animation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            windOffset = Double.pi * 2
        }
        
        // Day/night cycle - invalidate old timer first
        dayNightTimer?.invalidate()
        dayNightTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2)) {
                timeOfDay = timeOfDay == .day ? .sunset : (timeOfDay == .sunset ? .night : .day)
                sunMoonRotation += 120
            }
        }
        
        // Occasional falling leaves for grown trees
        if tree.growthProgress > 0.7 {
            leafFallTimer?.invalidate()
            leafFallTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                createFallingLeaf()
            }
        }
    }
    
    private func animateWatering(in geometry: GeometryProxy) {
        // Show watering can - start from right side, higher up
        showWateringCan = true
        wateringCanPosition = CGPoint(x: geometry.size.width + 100, y: geometry.size.height * 0.3)
        
        // Animate watering can tilt and move to watering position
        withAnimation(.easeInOut(duration: 0.8)) {
            wateringCanRotation = -35
            wateringCanPosition.x = geometry.size.width / 2 + 70 // Position to the right of tree
            wateringCanPosition.y = geometry.size.height * 0.4 // Higher position
        }
        
        // Create water stream from watering can
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            for i in 0..<30 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                    // Calculate water drop path from watering can spout (rose position)
                    // Account for rotation of the watering can
                    let rotationRadians = wateringCanRotation * Double.pi / 180
                    
                    // Original rose position relative to can center
                    let roseOffsetX: CGFloat = -60
                    let roseOffsetY: CGFloat = 15
                    
                    // Apply rotation transformation
                    let rotatedX = roseOffsetX * Foundation.cos(rotationRadians) - roseOffsetY * Foundation.sin(rotationRadians)
                    let rotatedY = roseOffsetX * Foundation.sin(rotationRadians) + roseOffsetY * Foundation.cos(rotationRadians)
                    
                    // Final spout position
                    let canSpoutX = wateringCanPosition.x + rotatedX
                    let canSpoutY = wateringCanPosition.y + rotatedY
                    
                    let drop = WaterDrop(
                        startX: canSpoutX + CGFloat.random(in: -4...4),
                        startY: canSpoutY,
                        endX: geometry.size.width / 2 + CGFloat.random(in: -30...30),
                        endY: geometry.size.height - 140 // Target the tree base
                    )
                    waterDrops.append(drop)
                
                // Create splash effect when drop lands
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    createSplashEffect(at: CGPoint(x: drop.endX, y: drop.endY))
                }
                
                // Remove drop
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    waterDrops.removeAll { $0.id == drop.id }
                }
            }
        }
        
        // Hide watering can after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                wateringCanRotation = 0
                wateringCanPosition.x = geometry.size.width + 150
                wateringCanPosition.y = geometry.size.height * 0.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                showWateringCan = false
            }
        }
        
        // Tree reaction
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            treeScale = 1.08
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                treeScale = 1.0
            }
        }
        
        // Create sparkles
        createSparkles()
    }
}

// MARK: - Tree Growth Stages
enum TreeGrowthStage {
    case seed       // 0-10%
    case sprout     // 10-25%
    case seedling   // 25-50%
    case sapling    // 50-80%
    case mature     // 80-100%
    
    static func from(progress: Double) -> TreeGrowthStage {
        switch progress {
        case 0..<0.1:
            return .seed
        case 0.1..<0.25:
            return .sprout
        case 0.25..<0.5:
            return .seedling
        case 0.5..<0.8:
            return .sapling
        default:
            return .mature
        }
    }
}

// MARK: - Tree Visualization
struct TreeVisualization: View {
    let type: TreeType
    let progress: Double
    @State private var leafAnimation = false
    
    var growthStage: TreeGrowthStage {
        TreeGrowthStage.from(progress: progress)
    }
    
    var body: some View {
        Group {
            switch type {
            case .oak:
                OakTreeStages(stage: growthStage, leafAnimation: $leafAnimation)
            case .pine:
                PineTreeStages(stage: growthStage, leafAnimation: $leafAnimation)
            case .cherry:
                CherryTreeStages(stage: growthStage, leafAnimation: $leafAnimation)
            case .maple:
                MapleTreeStages(stage: growthStage, leafAnimation: $leafAnimation)
            case .willow:
                WillowTreeStages(stage: growthStage, leafAnimation: $leafAnimation)
            case .bamboo:
                BambooTreeStages(stage: growthStage, leafAnimation: $leafAnimation)
            }
        }
        .onAppear {
            leafAnimation = true
        }
    }
}

// MARK: - Oak Tree Stages
struct OakTreeStages: View {
    let stage: TreeGrowthStage
    @Binding var leafAnimation: Bool
    
    var body: some View {
        ZStack {
            switch stage {
            case .seed:
                // Acorn
                ZStack {
                    Ellipse()
                        .fill(Color(hex: "#8B4513"))
                        .frame(width: 25, height: 30)
                    Ellipse()
                        .fill(Color(hex: "#654321"))
                        .frame(width: 25, height: 12)
                        .offset(y: -12)
                }
                
            case .sprout:
                // Split acorn with shoot
                VStack(spacing: -5) {
                    HStack(spacing: 5) {
                        Leaf(color: .green.opacity(0.8), size: 15, rotation: -30)
                        Leaf(color: .green.opacity(0.8), size: 15, rotation: 30)
                    }
                    Rectangle()
                        .fill(Color(hex: "#90EE90"))
                        .frame(width: 3, height: 20)
                    ZStack {
                        Ellipse()
                            .fill(Color(hex: "#8B4513").opacity(0.6))
                            .frame(width: 20, height: 25)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 1, height: 25)
                            .rotationEffect(.degrees(15))
                    }
                }
                
            case .seedling:
                // Young oak with simple leaves
                VStack(spacing: -5) {
                    ZStack {
                        ForEach(0..<6, id: \.self) { index in
                            OakLeaf(size: 25)
                                .foregroundColor(.green)
                                .rotationEffect(.degrees(Double(index) * 60))
                                .offset(y: -15)
                                .scaleEffect(leafAnimation ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(index) * 0.1), value: leafAnimation)
                        }
                    }
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#8B7355"), Color(hex: "#654321")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 8, height: 40)
                }
                
            case .sapling:
                // Young tree with branches
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#654321"), Color(hex: "#4B3621")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 15, height: 80)
                        .offset(y: 20)
                    ForEach(0..<3, id: \.self) { level in
                        HStack(spacing: 30) {
                            OakBranch(leafAnimation: $leafAnimation)
                                .rotationEffect(.degrees(-20))
                            OakBranch(leafAnimation: $leafAnimation)
                                .rotationEffect(.degrees(20))
                                .scaleEffect(x: -1, y: 1)
                        }
                        .offset(y: CGFloat(level * -20) - 10)
                    }
                }
                
            case .mature:
                // Full oak tree
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#4B3621"), Color(hex: "#3B2611")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 30, height: 100)
                        .overlay(
                            VStack(spacing: 5) {
                                ForEach(0..<8, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.1))
                                        .frame(height: 2)
                                        .offset(x: CGFloat.random(in: -5...5))
                                }
                            }
                        )
                        .offset(y: 40)
                    ZStack {
                        ForEach(0..<3, id: \.self) { layer in
                            Circle()
                                .fill(RadialGradient(colors: [Color(hex: "#228B22"), Color(hex: "#006400")], center: .center, startRadius: 5, endRadius: 60))
                                .frame(width: 120 - CGFloat(layer * 20), height: 120 - CGFloat(layer * 20))
                                .offset(y: CGFloat(layer * -10) - 40)
                                .opacity(0.8)
                                .scaleEffect(leafAnimation ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(layer) * 0.3), value: leafAnimation)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Pine Tree Stages
struct PineTreeStages: View {
    let stage: TreeGrowthStage
    @Binding var leafAnimation: Bool
    
    var body: some View {
        ZStack {
            switch stage {
            case .seed:
                // Pine cone with seed
                ZStack {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<(3 - row), id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: "#8B4513"))
                                    .frame(width: 8, height: 6)
                            }
                        }
                        .offset(y: CGFloat(row * 5) - 10)
                    }
                    Ellipse()
                        .fill(Color(hex: "#D2691E").opacity(0.6))
                        .frame(width: 15, height: 8)
                        .rotationEffect(.degrees(45))
                        .offset(x: 10, y: 5)
                }
                
            case .sprout:
                // Tiny pine seedling
                VStack(spacing: 0) {
                    ZStack {
                        ForEach(0..<8, id: \.self) { index in
                            Rectangle()
                                .fill(Color(hex: "#00FF00"))
                                .frame(width: 2, height: 15)
                                .rotationEffect(.degrees(Double(index) * 45))
                        }
                    }
                    Rectangle()
                        .fill(Color(hex: "#90EE90"))
                        .frame(width: 2, height: 15)
                }
                
            case .seedling:
                // Young pine with needle clusters
                VStack(spacing: -5) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    ForEach(0..<3, id: \.self) { level in
                        PineNeedleWhorl(size: 30 - CGFloat(level * 5))
                            .offset(y: CGFloat(level * 10))
                    }
                    Rectangle()
                        .fill(Color(hex: "#8B7355"))
                        .frame(width: 4, height: 30)
                }
                
            case .sapling:
                // Classic pyramid shape
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#8B4513"), Color(hex: "#654321")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 10, height: 80)
                        .offset(y: 20)
                    VStack(spacing: -10) {
                        ForEach(0..<5, id: \.self) { tier in
                            Triangle()
                                .fill(LinearGradient(colors: [Color(hex: "#228B22"), Color(hex: "#006400")], startPoint: .top, endPoint: .bottom))
                                .frame(width: CGFloat(60 + tier * 15), height: CGFloat(25 + tier * 5))
                                .scaleEffect(leafAnimation ? 1.05 : 1.0)
                                .offset(y: CGFloat(tier * 10) - 30)
                        }
                    }
                }
                
            case .mature:
                // Majestic pine tree
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#654321"), Color(hex: "#4B3621")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 25, height: 100)
                        .overlay(
                            VStack(spacing: 3) {
                                ForEach(0..<10, id: \.self) { _ in
                                    HStack(spacing: 2) {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.1))
                                            .frame(width: CGFloat.random(in: 5...15), height: 3)
                                        Rectangle()
                                            .fill(Color.black.opacity(0.1))
                                            .frame(width: CGFloat.random(in: 5...15), height: 3)
                                    }
                                }
                            }
                        )
                        .offset(y: 40)
                    VStack(spacing: -20) {
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: "#006400"))
                            .scaleEffect(leafAnimation ? 1.1 : 1.0)
                        ForEach(0..<4, id: \.self) { layer in
                            Triangle()
                                .fill(LinearGradient(colors: [Color(hex: "#228B22"), Color(hex: "#006400")], startPoint: .top, endPoint: .bottom))
                                .frame(width: 60 + CGFloat(layer * 25), height: 40 + CGFloat(layer * 10))
                                .scaleEffect(leafAnimation ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(Double(layer) * 0.2), value: leafAnimation)
                        }
                    }
                    .offset(y: -30)
                }
            }
        }
    }
}

// MARK: - Cherry Tree Stages
struct CherryTreeStages: View {
    let stage: TreeGrowthStage
    @Binding var leafAnimation: Bool
    @State private var blossomAnimation = false
    
    var body: some View {
        ZStack {
            switch stage {
            case .seed:
                // Cherry pit
                Ellipse()
                    .fill(LinearGradient(colors: [Color(hex: "#D2691E"), Color(hex: "#8B4513")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 15, height: 20)
                
            case .sprout:
                // Delicate cherry sprout
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        Leaf(color: Color(hex: "#90EE90"), size: 20, rotation: -40)
                        Leaf(color: Color(hex: "#90EE90"), size: 20, rotation: 40)
                    }
                    Rectangle()
                        .fill(Color(hex: "#90EE90"))
                        .frame(width: 2, height: 25)
                }
                
            case .seedling:
                // Young cherry with serrated leaves
                VStack(spacing: -5) {
                    ZStack {
                        ForEach(0..<4, id: \.self) { index in
                            HStack {
                                CherryLeaf()
                                    .frame(width: 25, height: 30)
                                    .rotationEffect(.degrees(Double(index) * 90 - 45))
                                    .offset(x: index % 2 == 0 ? -15 : 15, y: CGFloat(index * -10))
                            }
                        }
                    }
                    Rectangle()
                        .fill(Color(hex: "#CD853F"))
                        .frame(width: 5, height: 40)
                }
                
            case .sapling:
                // Graceful young cherry tree
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#A0522D"), Color(hex: "#8B4513")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 12, height: 70)
                        .overlay(
                            VStack(spacing: 8) {
                                ForEach(0..<5, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: CGFloat.random(in: 6...10), height: 1)
                                }
                            }
                        )
                        .offset(y: 25)
                    ForEach(0..<3, id: \.self) { level in
                        HStack(spacing: 40) {
                            CherryBranch(hasBlossoms: false, leafAnimation: $leafAnimation)
                                .rotationEffect(.degrees(-25))
                            CherryBranch(hasBlossoms: false, leafAnimation: $leafAnimation)
                                .rotationEffect(.degrees(25))
                                .scaleEffect(x: -1, y: 1)
                        }
                        .offset(y: CGFloat(level * -20) - 10)
                    }
                }
                
            case .mature:
                // Blooming cherry tree
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#8B4513"), Color(hex: "#654321")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 25, height: 90)
                        .overlay(
                            HStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.1))
                                        .frame(width: 2, height: 80)
                                        .offset(y: CGFloat.random(in: -5...5))
                                }
                            }
                        )
                        .offset(y: 35)
                    ZStack {
                        Ellipse()
                            .fill(RadialGradient(colors: [Color(hex: "#90EE90").opacity(0.8), Color(hex: "#228B22").opacity(0.6)], center: .center, startRadius: 10, endRadius: 60))
                            .frame(width: 140, height: 100)
                            .offset(y: -40)
                        ForEach(0..<15, id: \.self) { index in
                            CherryBlossom()
                                .frame(width: 20, height: 20)
                                .position(
                                    x: 70 + CGFloat.random(in: -50...50),
                                    y: 60 + CGFloat.random(in: -30...30)
                                )
                                .rotationEffect(.degrees(Double.random(in: 0...360)))
                                .scaleEffect(blossomAnimation ? 1.1 : 0.9)
                                .opacity(blossomAnimation ? 1.0 : 0.8)
                                .animation(
                                    .easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.1),
                                    value: blossomAnimation
                                )
                        }
                    }
                    .offset(y: -20)
                }
                .onAppear {
                    blossomAnimation = true
                }
            }
        }
    }
}

// MARK: - Maple Tree Stages
struct MapleTreeStages: View {
    let stage: TreeGrowthStage
    @Binding var leafAnimation: Bool
    @State private var fallAnimation = false
    
    var body: some View {
        ZStack {
            switch stage {
            case .seed:
                // Maple seed (samara/helicopter seed)
                ZStack {
                    // Wing
                    Ellipse()
                        .fill(Color(hex: "#D2691E").opacity(0.7))
                        .frame(width: 30, height: 12)
                        .rotationEffect(.degrees(45))
                        .offset(x: 10, y: -5)
                    // Seed body
                    Circle()
                        .fill(Color(hex: "#8B4513"))
                        .frame(width: 10, height: 10)
                }
                .rotationEffect(.degrees(fallAnimation ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        fallAnimation = true
                    }
                }
                
            case .sprout:
                // Young maple sprout with characteristic leaves
                VStack(spacing: 0) {
                    HStack(spacing: 5) {
                        MapleLeaf(size: 20, color: .green.opacity(0.8))
                            .rotationEffect(.degrees(-30))
                        MapleLeaf(size: 20, color: .green.opacity(0.8))
                            .rotationEffect(.degrees(30))
                    }
                    Rectangle()
                        .fill(Color(hex: "#90EE90"))
                        .frame(width: 3, height: 25)
                }
                
            case .seedling:
                // Young maple with distinctive leaves
                VStack(spacing: -5) {
                    ZStack {
                        ForEach(0..<5, id: \.self) { index in
                            MapleLeaf(size: 30, color: .green)
                                .rotationEffect(.degrees(Double(index) * 72))
                                .offset(y: -20)
                                .scaleEffect(leafAnimation ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(Double(index) * 0.1), value: leafAnimation)
                        }
                    }
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#8B7355"), Color(hex: "#654321")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 6, height: 45)
                }
                
            case .sapling:
                // Young maple tree with branches
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#8B7355"), Color(hex: "#654321")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 12, height: 70)
                        .offset(y: 25)
                    
                    ForEach(0..<3, id: \.self) { level in
                        HStack(spacing: 35) {
                            MapleBranch(leafAnimation: $leafAnimation, autumnColors: false)
                                .rotationEffect(.degrees(-25))
                            MapleBranch(leafAnimation: $leafAnimation, autumnColors: false)
                                .rotationEffect(.degrees(25))
                                .scaleEffect(x: -1, y: 1)
                        }
                        .offset(y: CGFloat(level * -20) - 10)
                    }
                }
                
            case .mature:
                // Mature maple with fall colors
                ZStack {
                    // Trunk
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#654321"), Color(hex: "#4B3621")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 25, height: 90)
                        .overlay(
                            VStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.1))
                                        .frame(height: 2)
                                        .offset(x: CGFloat.random(in: -3...3))
                                }
                            }
                        )
                        .offset(y: 35)
                    
                    // Crown with autumn colors
                    ZStack {
                        ForEach(0..<3, id: \.self) { layer in
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(hex: ["#FF6B35", "#FFA500", "#DC143C", "#FF8C00"][layer % 4]),
                                            Color(hex: ["#FF4500", "#FF6347", "#B22222", "#D2691E"][layer % 4])
                                        ],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 120 - CGFloat(layer * 20), height: 120 - CGFloat(layer * 20))
                                .offset(y: CGFloat(layer * -10) - 40)
                                .opacity(0.9)
                                .scaleEffect(leafAnimation ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(Double(layer) * 0.3), value: leafAnimation)
                        }
                        
                        // Falling maple leaves
                        ForEach(0..<6, id: \.self) { index in
                            MapleLeaf(size: 15, color: Color(hex: ["#FF6B35", "#FFA500", "#DC143C"][index % 3]))
                                .rotationEffect(.degrees(Double.random(in: 0...360)))
                                .offset(
                                    x: CGFloat.random(in: -50...50),
                                    y: leafAnimation ? 100 : -60
                                )
                                .opacity(leafAnimation ? 0 : 1)
                                .animation(
                                    .easeIn(duration: 3.0)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.5),
                                    value: leafAnimation
                                )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Willow Tree Stages
struct WillowTreeStages: View {
    let stage: TreeGrowthStage
    @Binding var leafAnimation: Bool
    @State private var droopAnimation = false
    
    var body: some View {
        ZStack {
            switch stage {
            case .seed:
                // Willow catkin seed
                ZStack {
                    Capsule()
                        .fill(Color(hex: "#F0E68C"))
                        .frame(width: 20, height: 8)
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 6, height: 6)
                            .offset(x: CGFloat(i - 1) * 6)
                    }
                }
                
            case .sprout:
                // Willow sprout with narrow leaves
                VStack(spacing: 0) {
                    ZStack {
                        ForEach(0..<4, id: \.self) { index in
                            WillowLeaf(size: 20)
                                .rotationEffect(.degrees(Double(index) * 90 - 45))
                                .offset(y: -10)
                        }
                    }
                    Rectangle()
                        .fill(Color(hex: "#90EE90"))
                        .frame(width: 2, height: 20)
                }
                
            case .seedling:
                // Young willow with drooping branches starting to form
                VStack(spacing: -5) {
                    ZStack {
                        ForEach(0..<6, id: \.self) { index in
                            WillowBranch(size: 30, droopAnimation: $droopAnimation)
                                .rotationEffect(.degrees(Double(index) * 60))
                                .offset(y: -20)
                        }
                    }
                    Rectangle()
                        .fill(Color(hex: "#8B7355"))
                        .frame(width: 5, height: 40)
                }
                .onAppear {
                    droopAnimation = true
                }
                
            case .sapling:
                // Young willow with characteristic drooping branches
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#8B7355"), Color(hex: "#654321")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 12, height: 70)
                        .offset(y: 25)
                    
                    // Drooping branches
                    ForEach(0..<4, id: \.self) { level in
                        ZStack {
                            DroopingWillowBranch(leafAnimation: $leafAnimation, isLeft: true)
                                .offset(x: -20, y: CGFloat(level * -15) - 10)
                            DroopingWillowBranch(leafAnimation: $leafAnimation, isLeft: false)
                                .offset(x: 20, y: CGFloat(level * -15) - 10)
                        }
                    }
                }
                
            case .mature:
                // Mature weeping willow
                ZStack {
                    // Trunk
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#696969"), Color(hex: "#4B4B4B")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 30, height: 100)
                        .overlay(
                            // Rough bark texture
                            VStack(spacing: 3) {
                                ForEach(0..<12, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.black.opacity(0.2))
                                        .frame(height: 3)
                                        .offset(x: CGFloat.random(in: -5...5))
                                }
                            }
                        )
                        .offset(y: 40)
                    
                    // Weeping canopy
                    ZStack {
                        // Main canopy
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "#9ACD32"), Color(hex: "#6B8E23")],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 150, height: 100)
                            .offset(y: -40)
                        
                        // Hanging branches
                        ForEach(0..<12, id: \.self) { index in
                            WillowHangingBranch()
                                .offset(
                                    x: CGFloat(index - 6) * 12,
                                    y: -30
                                )
                                .scaleEffect(leafAnimation ? 1.05 : 0.95)
                                .animation(
                                    .easeInOut(duration: 3.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                    value: leafAnimation
                                )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Bamboo Tree Stages
struct BambooTreeStages: View {
    let stage: TreeGrowthStage
    @Binding var leafAnimation: Bool
    @State private var swayAnimation = false
    
    var body: some View {
        ZStack {
            switch stage {
            case .seed:
                // Bamboo shoot underground
                ZStack {
                    // Underground rhizome
                    Capsule()
                        .fill(Color(hex: "#8B4513"))
                        .frame(width: 25, height: 10)
                    // Emerging shoot tip
                    Triangle()
                        .fill(Color(hex: "#9ACD32"))
                        .frame(width: 15, height: 20)
                        .offset(y: -10)
                }
                
            case .sprout:
                // Bamboo shoot emerging
                VStack(spacing: -5) {
                    // Shoot tip with layers
                    ForEach(0..<3, id: \.self) { layer in
                        Triangle()
                            .fill(Color(hex: "#9ACD32").opacity(Double(3 - layer) / 3))
                            .frame(width: 20 - CGFloat(layer * 3), height: 15)
                            .offset(y: CGFloat(layer * -5))
                    }
                    // Base
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "#9ACD32"), Color(hex: "#556B2F")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 8, height: 20)
                }
                
            case .seedling:
                // Young bamboo culm with segments
                VStack(spacing: -2) {
                    // Top leaves
                    ZStack {
                        ForEach(0..<4, id: \.self) { index in
                            BambooLeaf()
                                .rotationEffect(.degrees(Double(index) * 90))
                                .offset(y: -10)
                        }
                    }
                    // Segmented culm
                    ForEach(0..<4, id: \.self) { segment in
                        BambooSegment(width: 8 + CGFloat(segment), height: 12)
                    }
                }
                
            case .sapling:
                // Multiple bamboo culms
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { culm in
                        VStack(spacing: -2) {
                            // Leaves at top
                            ZStack {
                                ForEach(0..<3, id: \.self) { index in
                                    BambooLeaf()
                                        .rotationEffect(.degrees(Double(index) * 120))
                                        .scaleEffect(leafAnimation ? 1.1 : 0.9)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(culm) * 0.3), value: leafAnimation)
                                }
                            }
                            .offset(y: -10)
                            
                            // Culm segments
                            ForEach(0..<6, id: \.self) { segment in
                                BambooSegment(width: 10, height: 12 - CGFloat(segment))
                            }
                        }
                        .rotationEffect(.degrees(swayAnimation ? 2 : -2), anchor: .bottom)
                        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(Double(culm) * 0.2), value: swayAnimation)
                        .offset(y: CGFloat(culm) * -10)
                    }
                }
                .onAppear {
                    swayAnimation = true
                }
                
            case .mature:
                // Bamboo grove
                ZStack {
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { culm in
                            VStack(spacing: -2) {
                                // Leaf clusters
                                ZStack {
                                    ForEach(0..<5, id: \.self) { leaf in
                                        BambooLeaf()
                                            .rotationEffect(.degrees(Double(leaf) * 72))
                                            .scaleEffect(1.2)
                                            .offset(y: -5)
                                    }
                                }
                                
                                // Tall culm with many segments
                                ForEach(0..<10, id: \.self) { segment in
                                    BambooSegment(
                                        width: 15 - CGFloat(segment) * 0.5,
                                        height: 10,
                                        color: segment % 2 == 0 ? Color(hex: "#9ACD32") : Color(hex: "#8FBC8F")
                                    )
                                }
                            }
                            .rotationEffect(
                                .degrees(Foundation.sin(swayAnimation ? Double.pi : 0 + Double(culm) * 0.5) * 3),
                                anchor: .bottom
                            )
                            .offset(y: CGFloat(culm % 3) * -20)
                        }
                    }
                }
            }
            }
        }
    }
}

// MARK: - Additional Helper Views
struct MapleLeaf: View {
    let size: CGFloat
    let color: Color
    
    var body: some View {
        // Classic maple leaf shape with 5 points
        ZStack {
            ForEach(0..<5, id: \.self) { point in
                Triangle()
                    .fill(color)
                    .frame(width: size * 0.4, height: size * 0.7)
                    .rotationEffect(.degrees(Double(point) * 72))
                    .offset(y: -size * 0.3)
            }
            Circle()
                .fill(color)
                .frame(width: size * 0.5, height: size * 0.5)
        }
    }
}

struct MapleBranch: View {
    @Binding var leafAnimation: Bool
    let autumnColors: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "#654321"))
                .frame(width: 35, height: 3)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    MapleLeaf(
                        size: 25,
                        color: autumnColors ? 
                            Color(hex: ["#FF6B35", "#FFA500", "#DC143C"][index]) :
                            Color.green
                    )
                    .rotationEffect(.degrees(Double(index - 1) * 25))
                    .scaleEffect(leafAnimation ? 1.1 : 1.0)
                }
            }
        }
    }
}

struct WillowLeaf: View {
    let size: CGFloat
    
    var body: some View {
        Ellipse()
            .fill(Color(hex: "#9ACD32"))
            .frame(width: size * 0.3, height: size)
    }
}

struct WillowBranch: View {
    let size: CGFloat
    @Binding var droopAnimation: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { leaf in
                WillowLeaf(size: size * 0.7)
                    .rotationEffect(.degrees(Double(leaf - 2) * 15))
                    .offset(y: CGFloat(leaf) * 3)
            }
        }
        .rotationEffect(.degrees(droopAnimation ? 15 : 0), anchor: .top)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: droopAnimation)
    }
}

struct DroopingWillowBranch: View {
    @Binding var leafAnimation: Bool
    let isLeft: Bool
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addCurve(
                to: CGPoint(x: isLeft ? -30 : 30, y: 40),
                control1: CGPoint(x: 0, y: 10),
                control2: CGPoint(x: isLeft ? -20 : 20, y: 20)
            )
        }
        .stroke(Color(hex: "#556B2F"), lineWidth: 2)
        .overlay(
            // Leaves along the branch
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    WillowLeaf(size: 15)
                        .position(
                            x: CGFloat(index) * (isLeft ? -4 : 4),
                            y: CGFloat(index) * 5
                        )
                        .rotationEffect(.degrees(Double(index) * 10 * (isLeft ? 1 : -1)))
                        .opacity(leafAnimation ? 1.0 : 0.7)
                }
            }
        )
    }
}

struct WillowHangingBranch: View {
    var body: some View {
        VStack(spacing: -5) {
            ForEach(0..<15, id: \.self) { segment in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#9ACD32"), Color(hex: "#6B8E23")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2 - CGFloat(segment) * 0.05, height: 8)
                    .overlay(
                        HStack(spacing: 2) {
                            WillowLeaf(size: 8)
                                .offset(x: -5)
                            WillowLeaf(size: 8)
                                .offset(x: 5)
                        }
                        .opacity(segment % 2 == 0 ? 1 : 0)
                    )
            }
        }
    }
}

struct BambooLeaf: View {
    var body: some View {
        Ellipse()
            .fill(Color(hex: "#228B22"))
            .frame(width: 25, height: 8)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "#006400"))
                    .frame(width: 20, height: 0.5)
            )
    }
}

struct BambooSegment: View {
    let width: CGFloat
    let height: CGFloat
    var color: Color = Color(hex: "#9ACD32")
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(color)
                .frame(width: width, height: height)
            
            // Node ring
            Rectangle()
                .fill(Color(hex: "#556B2F"))
                .frame(width: width + 2, height: 2)
                .offset(y: height / 2)
        }
    }
}

// MARK: - Watering Can View
struct WateringCanView: View {
    var body: some View {
        ZStack {
            // Can body (base layer)
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#5B9EE6"), Color(hex: "#4169E1")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, height: 50)
                .overlay(
                    // Shiny highlight
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(width: 60, height: 20)
                        .offset(y: -10)
                )
                .overlay(
                    // Water level
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#87CEEB").opacity(0.6), Color(hex: "#4682B4").opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 55, height: 28)
                        .offset(y: 6)
                )
            
            // Spout with integrated connection to body
            Path { path in
                // Start from body connection point
                path.move(to: CGPoint(x: -35, y: -5))
                // Top edge of spout
                path.addLine(to: CGPoint(x: -50, y: 0))
                path.addLine(to: CGPoint(x: -60, y: 10))
                // Bottom edge of spout
                path.addLine(to: CGPoint(x: -60, y: 20))
                path.addLine(to: CGPoint(x: -50, y: 18))
                path.addLine(to: CGPoint(x: -35, y: 10))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#5B9EE6"), Color(hex: "#4169E1")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Handle
            Path { path in
                path.move(to: CGPoint(x: 12, y: -20))
                path.addCurve(
                    to: CGPoint(x: 32, y: -20),
                    control1: CGPoint(x: 17, y: -35),
                    control2: CGPoint(x: 27, y: -35)
                )
                path.addLine(to: CGPoint(x: 32, y: -17))
                path.addCurve(
                    to: CGPoint(x: 12, y: -17),
                    control1: CGPoint(x: 27, y: -32),
                    control2: CGPoint(x: 17, y: -32)
                )
                path.closeSubpath()
            }
            .fill(Color(hex: "#3A5FCD"))
            
            // Rose (water spreader) with better integration
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#D3D3D3"), Color(hex: "#A9A9A9")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .fill(Color(hex: "#808080"))
                        .frame(width: 18, height: 18)
                )
                .overlay(
                    // Holes pattern
                    ZStack {
                        ForEach(0..<6, id: \.self) { i in
                            Circle()
                                .fill(Color.black.opacity(0.8))
                                .frame(width: 3, height: 3)
                                .offset(
                                    x: Foundation.cos(Double(i) * Double.pi / 3.0) * 6.0,
                                    y: Foundation.sin(Double(i) * Double.pi / 3.0) * 6.0
                                )
                        }
                        Circle()
                            .fill(Color.black.opacity(0.8))
                            .frame(width: 3, height: 3)
                    }
                )
                .offset(x: -60, y: 15)
        }
        .frame(width: 160, height: 80)
    }
}

// MARK: - Helper Views
struct Leaf: View {
    let color: Color
    let size: CGFloat
    let rotation: Double
    
    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: size * 0.7, height: size)
            .rotationEffect(.degrees(rotation))
    }
}

struct OakLeaf: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.green)
                .frame(width: size * 0.8, height: size)
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.green)
                    .frame(width: size * 0.4)
                    .offset(x: CGFloat(index - 1) * size * 0.3, y: -size * 0.2)
            }
        }
    }
}

struct OakBranch: View {
    @Binding var leafAnimation: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "#654321"))
                .frame(width: 40, height: 3)
            HStack {
                ForEach(0..<3, id: \.self) { index in
                    OakLeaf(size: 20)
                        .rotationEffect(.degrees(Double(index - 1) * 30))
                        .scaleEffect(leafAnimation ? 1.1 : 1.0)
                }
            }
        }
    }
}

struct PineNeedleWhorl: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Rectangle()
                    .fill(Color(hex: "#006400"))
                    .frame(width: 2, height: size)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
        }
    }
}

struct CherryLeaf: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: "#228B22"))
                .overlay(
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Triangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 3, height: 5)
                        }
                    }
                    .mask(Ellipse())
                )
        }
    }
}

struct CherryBranch: View {
    let hasBlossoms: Bool
    @Binding var leafAnimation: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(hex: "#A0522D"))
                .frame(width: 35, height: 3)
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    if hasBlossoms && index == 1 {
                        CherryBlossom()
                            .frame(width: 15, height: 15)
                    } else {
                        CherryLeaf()
                            .frame(width: 20, height: 25)
                            .rotationEffect(.degrees(Double(index - 1) * 20))
                            .scaleEffect(leafAnimation ? 1.05 : 1.0)
                    }
                }
            }
        }
    }
}

struct CherryBlossom: View {
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { petal in
                Ellipse()
                    .fill(LinearGradient(colors: [Color.pink.opacity(0.8), Color.white], startPoint: .bottom, endPoint: .top))
                    .frame(width: 8, height: 12)
                    .rotationEffect(.degrees(Double(petal) * 72))
                    .offset(y: -4)
            }
            Circle()
                .fill(Color.yellow.opacity(0.8))
                .frame(width: 4, height: 4)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Supporting Views
struct SunMoonView: View {
    let timeOfDay: TimeOfDay
    let rotation: Double
    
    var body: some View {
        ZStack {
            if timeOfDay == .day {
                // Sun
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .fill(Color.yellow.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .blur(radius: 10)
                    )
            } else {
                // Moon
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 35, height: 35)
                    .overlay(
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .offset(x: 5, y: -5)
                    )
            }
        }
        .rotationEffect(.degrees(rotation))
    }
}

struct CloudsView: View {
    @State private var cloudOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Cloud()
                    .offset(x: cloudOffset + CGFloat(i * 150), y: CGFloat(i * 30))
                    .opacity(0.6)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                cloudOffset = 400
            }
        }
    }
}

struct Cloud: View {
    var body: some View {
        ZStack {
            ForEach(0..<5) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: 30...50))
                    .offset(x: CGFloat(i * 15), y: CGFloat.random(in: -10...10))
            }
        }
    }
}

struct EnhancedGrassView: View {
    let windOffset: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#4CAF50"), Color(hex: "#388E3C")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Animated grass blades
            HStack(spacing: 2) {
                ForEach(0..<40) { i in
                    GrassBlade(
                        height: CGFloat.random(in: 20...35),
                        delay: Double(i) * 0.05,
                        windOffset: windOffset
                    )
                }
            }
            .padding(.horizontal, 10)
        }
    }
}

struct GrassBlade: View {
    let height: CGFloat
    let delay: Double
    let windOffset: CGFloat
    
    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.7)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3, height: height)
            .rotationEffect(
                .degrees(Foundation.sin(windOffset + delay) * 5),
                anchor: .bottom
            )
    }
}

// MARK: - Particle Views
struct EnhancedWaterDropView: View {
    let drop: WaterDrop
    @State private var position: CGPoint
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    
    init(drop: WaterDrop) {
        self.drop = drop
        self._position = State(initialValue: CGPoint(x: drop.startX, y: drop.startY))
    }
    
    var body: some View {
        ZStack {
            Image(systemName: "drop.fill")
                .foregroundColor(.blue.opacity(0.7))
                .blur(radius: 0.5)
            Image(systemName: "drop.fill")
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#87CEEB"), Color(hex: "#4682B4")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
            .font(.system(size: 14))
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .opacity(opacity)
            .shadow(color: .blue.opacity(0.3), radius: 2)
            .onAppear {
                // Animate with a parabolic arc
                withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.9)) {
                    position = CGPoint(x: drop.endX, y: drop.endY)
                    rotation = 180
                    scale = 1.2
                }
                withAnimation(.easeIn(duration: 0.9).delay(0.7)) {
                    opacity = 0.2
                }
            }
    }
}

struct SparkleView: View {
    let sparkle: Sparkle
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Image(systemName: "sparkle")
            .foregroundColor(sparkle.color)
            .font(.system(size: 20))
            .scaleEffect(scale)
            .opacity(opacity)
            .position(sparkle.position)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    scale = 1.5
                    opacity = 0
                }
            }
    }
}

struct LeafParticleView: View {
    let leaf: LeafParticle
    @State private var position: CGPoint
    @State private var rotation: Double = 0
    
    init(leaf: LeafParticle) {
        self.leaf = leaf
        self._position = State(initialValue: CGPoint(x: leaf.startX, y: leaf.startY))
    }
    
    var body: some View {
        Text("🍃")
            .font(.system(size: 20))
            .rotationEffect(.degrees(rotation))
            .position(position)
            .onAppear {
                withAnimation(.linear(duration: 3)) {
                    position = CGPoint(
                        x: leaf.startX + CGFloat.random(in: -50...50),
                        y: 350
                    )
                    rotation = 720
                }
            }
    }
}

struct GrowthBurstEffect: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .rotationEffect(.degrees(Double(i * 45)))
            }
            
            Text("✨")
                .font(.system(size: 60))
                .scaleEffect(scale * 1.5)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                scale = 3.0
                opacity = 0
            }
        }
    }
}