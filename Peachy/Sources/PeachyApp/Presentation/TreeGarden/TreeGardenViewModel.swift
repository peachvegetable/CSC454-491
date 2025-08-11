import Foundation
import Combine

@MainActor
class TreeGardenViewModel: ObservableObject {
    @Published var currentTree: Tree?
    @Published var userPoints = 0
    @Published var treeCollection: TreeCollection?
    @Published var availableTreeTypes: [TreeType] = []
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    private let authService = ServiceContainer.shared.authService
    private let treeService = ServiceContainer.shared.treeService
    private let pointService = ServiceContainer.shared.pointService
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    func loadData() {
        guard let userId = authService.currentUser?.id else { return }
        
        // Load current tree
        currentTree = treeService.getCurrentTree(for: userId)
        
        // Load tree collection
        treeCollection = treeService.getTreeCollection(for: userId)
        
        // Load available tree types
        availableTreeTypes = treeService.getAvailableTreeTypes(for: userId)
        
        // Load user points
        Task {
            userPoints = await pointService.total(for: userId)
        }
    }
    
    func waterTree(amount: Int) async {
        guard let userId = authService.currentUser?.id else { return }
        
        // Convert water drops to points (1 point = 5 drops)
        let pointsToSpend = max(1, amount / 5)
        
        // Check if user has enough points
        let currentPoints = UnifiedPointsService.shared.getUserPoints(for: userId)
        guard currentPoints >= pointsToSpend else {
            await MainActor.run {
                self.successMessage = "Not enough points! You need \(pointsToSpend) points."
                self.showSuccess = true
            }
            return
        }
        
        // Spend points for water
        guard UnifiedPointsService.shared.spendPoints(from: userId, amount: pointsToSpend, reason: "Watered tree with \(amount) drops") else {
            return
        }
        
        do {
            // Water the tree with the drops (not points)
            let result = try await treeService.waterTree(userId: userId, points: amount)
            
            // Get updated points from unified service
            let updatedPoints = UnifiedPointsService.shared.getUserPoints(for: userId)
            
            await MainActor.run {
                // Update current tree
                self.currentTree = result.tree
                
                // Update points display
                self.userPoints = updatedPoints
                
                // Show success message
                if result.didGrowFully {
                    self.successMessage = "🎉 Your \(result.tree.type.displayName) is fully grown!"
                    self.showSuccess = true
                    
                    // Reload data to update collection
                    self.loadData()
                    
                    if let newTree = result.newTreeUnlocked {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.successMessage = "🌟 New tree unlocked: \(newTree.displayName)!"
                            self.showSuccess = true
                        }
                    }
                }
            }
        } catch {
            print("Error watering tree: \(error)")
        }
    }
    
    func plantTree(type: TreeType) async {
        guard let userId = authService.currentUser?.id else { return }
        
        do {
            let newTree = try await treeService.plantNewTree(userId: userId, type: type)
            
            await MainActor.run {
                self.currentTree = newTree
                self.successMessage = "🌱 Planted a new \(type.displayName)!"
                self.showSuccess = true
            }
        } catch {
            print("Error planting tree: \(error)")
        }
    }
    
    private func setupSubscriptions() {
        // Listen for point updates
        NotificationCenter.default.publisher(for: NSNotification.Name("PointsUpdated"))
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    // DEBUG: Method to add test points
    func addTestPoints(_ amount: Int) async {
        guard let userId = authService.currentUser?.id else { return }
        
        await pointService.award(userId: userId, delta: amount)
        
        // Update points synchronously
        let updatedPoints = await pointService.total(for: userId)
        await MainActor.run {
            self.userPoints = updatedPoints
        }
    }
}