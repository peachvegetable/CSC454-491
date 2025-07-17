import Foundation

public protocol KeychainServiceProtocol {
    func save(_ data: Data, for key: String) -> Bool
    func load(key: String) -> Data?
    func delete(key: String) -> Bool
    func clear() -> Bool
}