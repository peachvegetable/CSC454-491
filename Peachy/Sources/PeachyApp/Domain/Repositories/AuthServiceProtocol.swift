import Foundation

protocol AuthServiceProtocol {
    func signIn(email: String) async throws -> User
    func signInWithApple() async throws -> User
    func signOut() async throws
    func getCurrentUser() async throws -> User?
    func updateUserRole(_ role: AppState.UserRole) async throws
}

enum AuthError: LocalizedError {
    case invalidEmail
    case userNotFound
    case networkError
    case unknown
    
    var errorDescription: String? {
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