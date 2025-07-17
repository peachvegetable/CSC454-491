import Foundation

class MockAuthService: AuthServiceProtocol {
    private var currentUser: User?
    
    func signIn(email: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            role: .teen,
            createdAt: Date(),
            profile: UserProfile(
                displayName: email.components(separatedBy: "@").first ?? "User",
                avatarEmoji: "🙂"
            )
        )
        
        currentUser = user
        return user
    }
    
    func signInWithApple() async throws -> User {
        // Simulate Apple Sign In
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        let user = User(
            id: UUID().uuidString,
            email: "apple.user@icloud.com",
            role: .teen,
            createdAt: Date(),
            profile: UserProfile(
                displayName: "Apple User",
                avatarEmoji: "🍎"
            )
        )
        
        currentUser = user
        return user
    }
    
    func signOut() async throws {
        currentUser = nil
    }
    
    func getCurrentUser() async throws -> User? {
        return currentUser
    }
    
    func updateUserRole(_ role: AppState.UserRole) async throws {
        guard var user = currentUser else {
            throw AuthError.userNotFound
        }
        
        let updatedUser = User(
            id: user.id,
            email: user.email,
            role: role == .teen ? .teen : .parent,
            createdAt: user.createdAt,
            profile: user.profile,
            circleId: user.circleId
        )
        
        currentUser = updatedUser
    }
}