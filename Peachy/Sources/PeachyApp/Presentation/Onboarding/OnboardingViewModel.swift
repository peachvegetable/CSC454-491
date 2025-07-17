import Foundation
import SwiftUI
import RealmSwift

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = ServiceContainer.shared.authService
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            currentUser = try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            currentUser = try await authService.signInWithApple()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            currentUser = try await authService.signUp(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateUserRole(_ role: UserRole) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.updateUserRole(role)
            // Refresh current user after role update
            currentUser = authService.currentUser
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateHobbies(_ hobbies: [String]) async {
        guard let user = authService.currentUser else { return }
        
        // Update hobbies in Realm
        await MainActor.run {
            do {
                let realm = try Realm()
                try realm.write {
                    user.hobbiesArray = hobbies
                }
            } catch {
                print("Error updating hobbies: \(error)")
            }
        }
    }
    
    func saveMood(_ mood: MoodColor, emoji: String?) async {
        guard authService.currentUser != nil else { return }
        
        // Convert MoodColor to SimpleMoodColor
        let simpleColor: SimpleMoodColor
        switch mood {
        case .good:
            simpleColor = .green
        case .okay:
            simpleColor = .yellow
        case .tough:
            simpleColor = .red
        }
        
        // Save using the mood service
        do {
            let moodService = ServiceContainer.shared.moodService
            try await moodService.save(color: simpleColor, emoji: emoji)
        } catch {
            print("Error saving mood: \(error)")
        }
    }
}