import Foundation
import RealmSwift

@MainActor
public class RealmManager {
    public static let shared = RealmManager()
    
    private var _realm: Realm?
    
    private var realm: Realm {
        if let realm = _realm {
            return realm
        }
        
        do {
            let config = Realm.Configuration(
                inMemoryIdentifier: ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ? "test" : nil,
                schemaVersion: 1,
                deleteRealmIfMigrationNeeded: true
            )
            Realm.Configuration.defaultConfiguration = config
            let realm = try Realm()
            _realm = realm
            return realm
        } catch {
            print("Failed to initialize Realm: \(error)")
            // Return a default in-memory Realm as fallback
            let fallbackConfig = Realm.Configuration(inMemoryIdentifier: "fallback")
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
}