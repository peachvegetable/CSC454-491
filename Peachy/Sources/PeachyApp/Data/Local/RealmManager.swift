import Foundation
import RealmSwift

@MainActor
public class RealmManager {
    public static let shared = RealmManager()
    
    private var _realm: Realm?
    
    public var realm: Realm {
        if let realm = _realm {
            return realm
        }
        
        do {
            let config = Realm.Configuration(
                inMemoryIdentifier: ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ? "test" : nil,
                schemaVersion: 5, // Increment version for Tree models
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 3 {
                        // Migrate MoodLog objects
                        migration.enumerateObjects(ofType: MoodLog.className()) { oldObject, newObject in
                            // Set default values for new required properties
                            if newObject!["emoji"] == nil {
                                newObject!["emoji"] = ""
                            }
                            if newObject!["colorName"] == nil {
                                // Try to infer colorName from existing data
                                if let colorHex = oldObject!["colorHex"] as? String {
                                    switch colorHex {
                                    case "#34C759": newObject!["colorName"] = "green"
                                    case "#FFCC00": newObject!["colorName"] = "yellow"
                                    case "#FF3B30": newObject!["colorName"] = "red"
                                    default: newObject!["colorName"] = "green"
                                    }
                                } else {
                                    newObject!["colorName"] = "green"
                                }
                            }
                        }
                    }
                    if oldSchemaVersion < 4 {
                        // bufferMinutes is optional, no migration needed
                    }
                    if oldSchemaVersion < 5 {
                        // Tree models are new, no migration needed
                    }
                },
                deleteRealmIfMigrationNeeded: false,
                objectTypes: [MoodLog.self, UserProfile.self, HobbyModel.self, FlashCard.self, UserPoint.self, QuestModel.self, Tree.self, TreeCollection.self, CollectedTree.self]
            )
            Realm.Configuration.defaultConfiguration = config
            let realm = try Realm()
            _realm = realm
            print("Realm initialized successfully with path: \(realm.configuration.fileURL?.path ?? "in-memory")")
            return realm
        } catch {
            print("Failed to initialize Realm: \(error)")
            // Return a default in-memory Realm as fallback
            let fallbackConfig = Realm.Configuration(
                inMemoryIdentifier: "fallback",
                schemaVersion: 5,
                objectTypes: [MoodLog.self, UserProfile.self, HobbyModel.self, FlashCard.self, UserPoint.self, QuestModel.self, Tree.self, TreeCollection.self, CollectedTree.self]
            )
            // swiftlint:disable force_try
            return try! Realm(configuration: fallbackConfig)
            // swiftlint:enable force_try
        }
    }
    
    private init() {}
    
    public func save<T: Object>(_ object: T) throws {
        try realm.write {
            realm.add(object, update: .modified)
        }
    }
    
    public func fetch<T: Object>(_ type: T.Type, predicate: NSPredicate? = nil) -> Results<T> {
        if let predicate = predicate {
            return realm.objects(type).filter(predicate)
        }
        return realm.objects(type)
    }
    
    public func delete<T: Object>(_ object: T) throws {
        try realm.write {
            realm.delete(object)
        }
    }
    
    public func deleteAll<T: Object>(_ type: T.Type) throws {
        try realm.write {
            realm.delete(realm.objects(type))
        }
    }
    
    // For testing only
    public func setRealm(_ realm: Realm) {
        _realm = realm
    }
}