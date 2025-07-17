import Foundation

public protocol AuthServiceProtocol {
    var isSignedIn: Bool { get }
    var currentUser: UserProfile? { get }
    var signOutHandler: (() -> Void)? { get set }
    
    func signIn(email: String, password: String) async throws -> UserProfile
    func signInWithApple() async throws -> UserProfile
    func signUp(email: String, password: String) async throws -> UserProfile
    func signOut() async throws
    func updateUserRole(_ role: UserRole) async throws
}

public enum AuthError: LocalizedError {
    case invalidEmail
    case userNotFound
    case networkError
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network connection error"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}