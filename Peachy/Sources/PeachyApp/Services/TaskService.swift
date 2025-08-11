import Foundation
import RealmSwift
import Combine

@MainActor
class TaskService: ObservableObject {
    private let realmManager = RealmManager.shared
    @Published var tasks: [FamilyTask] = []
    @Published var myTasks: [FamilyTask] = []
    @Published var availableTasks: [FamilyTask] = []
    
    var authService: AuthServiceProtocol?
    
    init() {}
    
    func loadTasks() {
        let realm = realmManager.realm
        let taskModels = realm.objects(TaskModel.self)
        self.tasks = Array(taskModels).map { $0.toDomain() }
        updateFilteredTasks()
    }
    
    func loadTasksForUser(_ userId: String) {
        let realm = realmManager.realm
        let myTaskModels = realm.objects(TaskModel.self).filter("assignedTo == %@", userId)
        self.myTasks = Array(myTaskModels).map { $0.toDomain() }
        
        let availableModels = realm.objects(TaskModel.self).filter("status == %@", TaskStatus.available.rawValue)
        self.availableTasks = Array(availableModels).map { $0.toDomain() }
    }
    
    private func updateFilteredTasks() {
        guard let currentUser = authService?.currentUser else { return }
        
        self.myTasks = tasks.filter { $0.assignedTo == currentUser.id }
        self.availableTasks = tasks.filter { $0.status == .available && $0.assignedTo == nil }
    }
    
    func createTask(_ task: FamilyTask) throws {
        let realm = realmManager.realm
        try realm.write {
            let model = TaskModel(from: task)
            realm.add(model, update: .modified)
        }
        loadTasks()
    }
    
    func updateTask(_ task: FamilyTask) throws {
        let realm = realmManager.realm
        try realm.write {
            let model = TaskModel(from: task)
            realm.add(model, update: .modified)
        }
        loadTasks()
    }
    
    func claimTask(_ taskId: String) throws {
        guard let currentUser = authService?.currentUser else {
            throw NSError(domain: "TaskService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        let realm = realmManager.realm
        guard let taskModel = realm.object(ofType: TaskModel.self, forPrimaryKey: taskId) else {
            throw NSError(domain: "TaskService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Task not found"])
        }
        
        try realm.write {
            taskModel.assignedTo = currentUser.id
            taskModel.assignedToName = currentUser.displayName
            taskModel.status = TaskStatus.claimed.rawValue
        }
        loadTasks()
    }
    
    func completeTask(_ taskId: String, proofImagePath: String? = nil) throws {
        guard let currentUser = authService?.currentUser else {
            throw NSError(domain: "TaskService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        let realm = realmManager.realm
        guard let taskModel = realm.object(ofType: TaskModel.self, forPrimaryKey: taskId) else {
            throw NSError(domain: "TaskService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Task not found"])
        }
        
        let task = taskModel.toDomain()
        
        try realm.write {
            if taskModel.requiresProof && proofImagePath == nil {
                taskModel.status = TaskStatus.pendingApproval.rawValue
            } else {
                taskModel.status = TaskStatus.completed.rawValue
                taskModel.completedAt = Date()
                taskModel.lastCompletedDate = Date()
            }
            
            if let proof = proofImagePath {
                taskModel.proofImagePath = proof
            }
        }
        
        // Award points if task is completed without needing approval
        if !task.requiresProof && taskModel.status == TaskStatus.completed.rawValue {
            if let assignedTo = task.assignedTo {
                UnifiedPointsService.shared.awardTaskCompletionPoints(
                    to: assignedTo,
                    taskTitle: task.title,
                    points: task.pointValue
                )
            }
        }
        
        // Handle recurring tasks
        if task.frequency != .once && taskModel.status == TaskStatus.completed.rawValue {
            try createRecurringTask(from: task)
        }
        
        loadTasks()
    }
    
    func approveTask(_ taskId: String) throws {
        let realm = realmManager.realm
        guard let taskModel = realm.object(ofType: TaskModel.self, forPrimaryKey: taskId) else {
            throw NSError(domain: "TaskService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Task not found"])
        }
        
        let task = taskModel.toDomain()
        
        try realm.write {
            taskModel.status = TaskStatus.completed.rawValue
            taskModel.completedAt = Date()
            taskModel.lastCompletedDate = Date()
        }
        
        // Award points after approval
        if let assignedTo = task.assignedTo {
            UnifiedPointsService.shared.awardTaskCompletionPoints(
                to: assignedTo,
                taskTitle: task.title,
                points: task.pointValue
            )
        }
        
        loadTasks()
    }
    
    func deleteTask(_ taskId: String) throws {
        let realm = realmManager.realm
        guard let taskModel = realm.object(ofType: TaskModel.self, forPrimaryKey: taskId) else {
            throw NSError(domain: "TaskService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Task not found"])
        }
        
        try realm.write {
            realm.delete(taskModel)
        }
        loadTasks()
    }
    
    private func createRecurringTask(from task: FamilyTask) throws {
        // Calculate next due date based on frequency
        var nextDueDate: Date?
        switch task.frequency {
        case .daily:
            nextDueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .weekly:
            nextDueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        case .monthly:
            nextDueDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        case .once:
            return // No recurring task for once frequency
        }
        
        let newTask = FamilyTask(
            id: UUID().uuidString,
            title: task.title,
            description: task.description,
            pointValue: task.pointValue,
            assignedTo: nil,
            assignedToName: nil,
            frequency: task.frequency,
            dueDate: nextDueDate,
            createdBy: task.createdBy,
            createdByName: task.createdByName,
            requiresProof: task.requiresProof,
            status: .available,
            completedAt: nil,
            proofImagePath: nil,
            createdAt: Date(),
            lastCompletedDate: nil
        )
        
        try createTask(newTask)
    }
    
    func getTasksForApproval() -> [FamilyTask] {
        return tasks.filter { $0.status == .pendingApproval }
    }
}