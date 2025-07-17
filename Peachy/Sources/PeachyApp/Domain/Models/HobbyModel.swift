import Foundation
import RealmSwift

public class HobbyModel: Object {
    @Persisted(primaryKey: true) public var id: ObjectId = ObjectId()
    @Persisted public var name: String = ""
    @Persisted public var ownerId: String = ""  // teen or parent that created it
    @Persisted public var fact: String = ""      // interesting fact added when shared
    @Persisted public var createdAt: Date = Date()
    @Persisted public var seenBy = RealmSwift.List<String>() // track who has viewed for points
    
    public convenience init(name: String, ownerId: String, fact: String) {
        self.init()
        self.name = name
        self.ownerId = ownerId
        self.fact = fact
        self.createdAt = Date()
    }
}

public class FlashCard: Object {
    @Persisted(primaryKey: true) public var id: ObjectId = ObjectId()
    @Persisted public var question: String = ""
    @Persisted public var answer: String = ""
    @Persisted public var hobbyId: ObjectId?
    @Persisted public var createdAt: Date = Date()
    @Persisted public var answeredCorrectlyBy = RealmSwift.List<String>() // track who answered correctly
    
    public convenience init(question: String, answer: String, hobbyId: ObjectId) {
        self.init()
        self.question = question
        self.answer = answer
        self.hobbyId = hobbyId
        self.createdAt = Date()
    }
}

public class UserPoint: Object {
    @Persisted(primaryKey: true) public var id: ObjectId = ObjectId()
    @Persisted public var userId: String = ""
    @Persisted public var points: Int = 0
    @Persisted public var lastUpdated: Date = Date()
    
    public convenience init(userId: String, points: Int = 0) {
        self.init()
        self.userId = userId
        self.points = points
        self.lastUpdated = Date()
    }
}