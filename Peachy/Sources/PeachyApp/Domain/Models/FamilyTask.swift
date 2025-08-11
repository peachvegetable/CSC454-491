import Foundation

enum TaskFrequency: String, CaseIterable, Codable {
    case once = "Once"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum TaskStatus: String, CaseIterable, Codable {
    case available = "Available"
    case claimed = "Claimed"
    case pendingApproval = "Pending Approval"
    case completed = "Completed"
    case expired = "Expired"
}

struct FamilyTask: Identifiable, Codable {
    let id: String
    var title: String
    var description: String?
    var pointValue: Int
    var assignedTo: String?
    var assignedToName: String?
    var frequency: TaskFrequency
    var dueDate: Date?
    var createdBy: String
    var createdByName: String
    var requiresProof: Bool
    var status: TaskStatus
    var completedAt: Date?
    var proofImagePath: String?
    var createdAt: Date
    var lastCompletedDate: Date?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        pointValue: Int,
        assignedTo: String? = nil,
        assignedToName: String? = nil,
        frequency: TaskFrequency = .once,
        dueDate: Date? = nil,
        createdBy: String,
        createdByName: String,
        requiresProof: Bool = false,
        status: TaskStatus = .available,
        completedAt: Date? = nil,
        proofImagePath: String? = nil,
        createdAt: Date = Date(),
        lastCompletedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.pointValue = pointValue
        self.assignedTo = assignedTo
        self.assignedToName = assignedToName
        self.frequency = frequency
        self.dueDate = dueDate
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.requiresProof = requiresProof
        self.status = status
        self.completedAt = completedAt
        self.proofImagePath = proofImagePath
        self.createdAt = createdAt
        self.lastCompletedDate = lastCompletedDate
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != .completed
    }
    
    var canBeClaimed: Bool {
        return status == .available && assignedTo == nil
    }
    
    var pointsDisplay: String {
        "\(pointValue) pts"
    }
}