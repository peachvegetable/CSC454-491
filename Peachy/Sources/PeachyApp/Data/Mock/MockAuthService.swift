import Foundation
import RealmSwift

@MainActor
public class MockAuthService: AuthServiceProtocol {
    private let keychain = KeychainServiceMock.shared
    private let realmManager = RealmManager.shared
    private var _currentUserId: String?
    
    private let userKey = "currentUser"
    
    // Handler to call before sign out
    public var signOutHandler: (() -> Void)?
    
    public init() {
        loadCurrentUser()
    }
    
    public var isSignedIn: Bool {
        return _currentUserId != nil
    }
    
    public var currentUser: UserProfile? {
        guard let userId = _currentUserId else { return nil }
        
        // Always fetch fresh from Realm to avoid thread issues
        let predicate = NSPredicate(format: "id == %@", userId)
        return realmManager.fetch(UserProfile.self, predicate: predicate).first
    }
    
    public func signIn(email: String, password: String) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }
        
        // Create user profile with all properties set before saving
        let userId = UUID().uuidString
        let userProfile = UserProfile()
        
        // Save to Realm with a write transaction
        userProfile.id = userId
        userProfile.email = email
        userProfile.displayName = email.components(separatedBy: "@").first ?? "User"
        userProfile.role = UserRole.teen.rawValue
        userProfile.createdAt = Date()
        
        try await MainActor.run {
            try realmManager.save(userProfile)
            _currentUserId = userProfile.id
            saveUserToKeychain(userProfile)
        }
        
        return userProfile
    }
    
    public func signInWithApple() async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let userId = UUID().uuidString
        let userProfile = UserProfile()
        
        userProfile.id = userId
        userProfile.email = "apple.user@icloud.com"
        userProfile.displayName = "Apple User"
        userProfile.role = UserRole.teen.rawValue
        userProfile.createdAt = Date()
        
        try await MainActor.run {
            try realmManager.save(userProfile)
            _currentUserId = userProfile.id
            saveUserToKeychain(userProfile)
        }
        
        return userProfile
    }
    
    public func signUp(email: String, password: String) async throws -> UserProfile {
        return try await signIn(email: email, password: password)
    }
    
    public func signOut() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Call handler to navigate away from profile first
        await MainActor.run {
            signOutHandler?()
        }
        
        // Small delay to ensure navigation completes
        try await Task.sleep(nanoseconds: 100_000_000)
        
        try await MainActor.run {
            if let userId = _currentUserId,
               let user = currentUser {
                // Delete all mood logs for this user
                let userMoodLogs = realmManager.fetch(MoodLog.self, predicate: NSPredicate(format: "userId == %@", user.id))
                for log in userMoodLogs {
                    try realmManager.delete(log)
                }
                
                // Delete the user profile
                if let realmUser = realmManager.fetch(UserProfile.self, predicate: NSPredicate(format: "id == %@", user.id)).first {
                    try realmManager.delete(realmUser)
                }
            }
            
            _currentUserId = nil
            _ = keychain.delete(key: userKey)
        }
    }
    
    public func updateUserRole(_ role: UserRole) async throws {
        guard let userId = _currentUserId else {
            throw AuthError.userNotFound
        }
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        try await MainActor.run {
            // Get a fresh copy from Realm to modify
            let predicate = NSPredicate(format: "id == %@", userId)
            guard let realmUser = realmManager.fetch(UserProfile.self, predicate: predicate).first else {
                throw AuthError.userNotFound
            }
            
            // Update in a write transaction
            let realm = try Realm()
            try realm.write {
                realmUser.role = role.rawValue
            }
            
            // Update our reference
            _currentUserId = realmUser.id
            saveUserToKeychain(realmUser)
        }
    }
    
    private func saveUserToKeychain(_ user: UserProfile) {
        if let data = try? JSONEncoder().encode([
            "id": user.id,
            "email": user.email,
            "displayName": user.displayName,
            "role": user.role
        ]) {
            _ = keychain.save(data, for: userKey)
        }
    }
    
    private func loadCurrentUser() {
        guard let data = keychain.load(key: userKey),
              let dict = try? JSONDecoder().decode([String: String].self, from: data),
              let id = dict["id"] else { return }
        
        DispatchQueue.main.async { [weak self] in
            do {
                self?._currentUserId = id
            } catch {
                print("Error loading user from Realm: \(error)")
            }
        }
    }
}