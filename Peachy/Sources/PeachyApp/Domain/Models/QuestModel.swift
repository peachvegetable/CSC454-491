import Foundation
import RealmSwift

public class QuestModel: Object {
    @Persisted(primaryKey: true) public var id = ObjectId.generate()
    @Persisted public var questType: String = "" // Quest.Kind.rawValue
    @Persisted public var userId: String = ""
    @Persisted public var hobbyId: ObjectId?
    @Persisted public var fact: String = ""
    @Persisted public var createdAt: Date = Date()
    @Persisted public var completedAt: Date?
    @Persisted public var pointsAwarded: Int = 0
    
    public convenience init(questType: String, userId: String, hobbyId: ObjectId? = nil, fact: String = "") {
        self.init()
        self.id = ObjectId.generate()  // Explicitly generate new ID
        self.questType = questType
        self.userId = userId
        self.hobbyId = hobbyId
        self.fact = fact
        self.createdAt = Date()
    }
}