import Foundation
import RealmSwift

class TaskModel: Object {
    @Persisted var id: String = UUID().uuidString
    @Persisted var title: String = ""
    @Persisted var taskDescription: String?
    @Persisted var pointValue: Int = 0
    @Persisted var assignedTo: String?
    @Persisted var assignedToName: String?
    @Persisted var frequency: String = TaskFrequency.once.rawValue
    @Persisted var dueDate: Date?
    @Persisted var createdBy: String = ""
    @Persisted var createdByName: String = ""
    @Persisted var requiresProof: Bool = false
    @Persisted var status: String = TaskStatus.available.rawValue
    @Persisted var completedAt: Date?
    @Persisted var proofImagePath: String?
    @Persisted var createdAt: Date = Date()
    @Persisted var lastCompletedDate: Date?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(from task: FamilyTask) {
        self.init()
        self.id = task.id
        self.title = task.title
        self.taskDescription = task.description
        self.pointValue = task.pointValue
        self.assignedTo = task.assignedTo
        self.assignedToName = task.assignedToName
        self.frequency = task.frequency.rawValue
        self.dueDate = task.dueDate
        self.createdBy = task.createdBy
        self.createdByName = task.createdByName
        self.requiresProof = task.requiresProof
        self.status = task.status.rawValue
        self.completedAt = task.completedAt
        self.proofImagePath = task.proofImagePath
        self.createdAt = task.createdAt
        self.lastCompletedDate = task.lastCompletedDate
    }
    
    func toDomain() -> FamilyTask {
        return FamilyTask(
            id: id,
            title: title,
            description: taskDescription,
            pointValue: pointValue,
            assignedTo: assignedTo,
            assignedToName: assignedToName,
            frequency: TaskFrequency(rawValue: frequency) ?? .once,
            dueDate: dueDate,
            createdBy: createdBy,
            createdByName: createdByName,
            requiresProof: requiresProof,
            status: TaskStatus(rawValue: status) ?? .available,
            completedAt: completedAt,
            proofImagePath: proofImagePath,
            createdAt: createdAt,
            lastCompletedDate: lastCompletedDate
        )
    }
}