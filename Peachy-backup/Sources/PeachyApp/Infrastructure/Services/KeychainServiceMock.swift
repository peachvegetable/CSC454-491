import Foundation

public final class KeychainServiceMock: KeychainServiceProtocol {
    public static let shared = KeychainServiceMock()
    private var storage: [String: Data] = [:]
    
    public init() {}
    
    public func save(_ data: Data, for key: String) -> Bool {
        storage[key] = data
        return true
    }
    
    public func load(key: String) -> Data? {
        return storage[key]
    }
    
    public func delete(key: String) -> Bool {
        storage.removeValue(forKey: key)
        return true
    }
    
    public func clear() -> Bool {
        storage.removeAll()
        return true
    }
}