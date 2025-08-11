import Foundation
import Combine

@MainActor
class TaskListViewModel: ObservableObject {
    @Published var myTasks: [FamilyTask] = []
    @Published var availableTasks: [FamilyTask] = []
    @Published var pendingApprovalTasks: [FamilyTask] = []
    @Published var currentBalance: Int = 0
    @Published var isParent: Bool = false
    
    private let taskService = ServiceContainer.shared.taskService
    private let pointsService = ServiceContainer.shared.pointsService
    private let authService = ServiceContainer.shared.authService
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        taskService.$myTasks
            .assign(to: &$myTasks)
        
        taskService.$availableTasks
            .assign(to: &$availableTasks)
        
        pointsService.$currentBalance
            .assign(to: &$currentBalance)
    }
    
    func loadTasks() {
        guard let currentUser = authService.currentUser else { return }
        
        isParent = UserRole(rawValue: currentUser.role) == .admin
        
        taskService.loadTasksForUser(currentUser.id)
        
        // Use unified points service
        UnifiedPointsService.shared.loadUserPoints(for: currentUser.id)
        currentBalance = UnifiedPointsService.shared.getUserPoints(for: currentUser.id)
        
        if isParent {
            pendingApprovalTasks = taskService.getTasksForApproval()
        }
    }
    
    func claimTask(_ taskId: String) {
        do {
            try taskService.claimTask(taskId)
            loadTasks()
        } catch {
            print("Error claiming task: \(error)")
        }
    }
    
    func completeTask(_ taskId: String, proofImagePath: String? = nil) {
        do {
            try taskService.completeTask(taskId, proofImagePath: proofImagePath)
            
            // Points are now awarded automatically in TaskService using UnifiedPointsService
            
            loadTasks()
        } catch {
            print("Error completing task: \(error)")
        }
    }
    
    func approveTask(_ taskId: String) {
        guard isParent else { return }
        
        do {
            try taskService.approveTask(taskId)
            // Points are now awarded automatically in TaskService using UnifiedPointsService
            loadTasks()
        } catch {
            print("Error approving task: \(error)")
        }
    }
    
    func loadTasksWithSampleData() {
        // First load existing tasks
        loadTasks()
        
        // If no tasks exist, create sample data
        if taskService.tasks.isEmpty {
            createSampleTasks()
            loadTasks()
        }
    }
    
    private func createSampleTasks() {
        let sampleTasks = [
            FamilyTask(
                title: "Clean Your Room",
                description: "Make bed, vacuum floor, and organize desk",
                pointValue: 20,
                frequency: .weekly,
                dueDate: Date().addingTimeInterval(86400 * 3),
                createdBy: "parent",
                createdByName: "Mom",
                requiresProof: true
            ),
            FamilyTask(
                title: "Do Homework",
                description: "Complete all assignments before dinner",
                pointValue: 10,
                frequency: .daily,
                dueDate: Date().addingTimeInterval(3600 * 5),
                createdBy: "parent",
                createdByName: "Dad",
                requiresProof: false
            ),
            FamilyTask(
                title: "Take Out Trash",
                description: "Empty all trash cans and take bins to curb",
                pointValue: 15,
                frequency: .weekly,
                dueDate: Date().addingTimeInterval(86400 * 2),
                createdBy: "parent",
                createdByName: "Mom",
                requiresProof: false
            ),
            FamilyTask(
                title: "Walk the Dog",
                description: "30 minute walk around the neighborhood",
                pointValue: 15,
                frequency: .daily,
                createdBy: "parent",
                createdByName: "Dad",
                requiresProof: true
            )
        ]
        
        for task in sampleTasks {
            do {
                try taskService.createTask(task)
            } catch {
                print("Error creating sample task: \(error)")
            }
        }
    }
}