import Foundation
import RealmSwift

public class UserProfile: Object, Identifiable {
    @Persisted public var id: String = UUID().uuidString
    @Persisted public var email: String = ""
    @Persisted public var displayName: String = ""
    @Persisted public var role: String = ""
    @Persisted public var pairingCode: String?
    @Persisted public var pairedWithUserId: String?
    @Persisted public var createdAt: Date = Date()
    @Persisted public var hobbies = List<String>()
    
    public override static func primaryKey() -> String? {
        return "id"
    }
    
    public var userRole: UserRole? {
        get { UserRole(rawValue: role) }
        set { role = newValue?.rawValue ?? "" }
    }
    
    public var hobbiesArray: [String] {
        get { Array(hobbies) }
        set { 
            hobbies.removeAll()
            hobbies.append(objectsIn: newValue)
        }
    }
}

public enum UserRole: String, CaseIterable {
    case teen = "Teen"
    case parent = "Parent"
}