import Foundation
import RealmSwift

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userSnapshot: UserProfile?
    @Published var currentStreak = 0
    @Published var pairingCode: String?
    @Published var isLoading = false
    @Published var totalPoints = 0
    
    private let authService = ServiceContainer.shared.authService
    private let streakService = ServiceContainer.shared.streakService
    private let pointService = ServiceContainer.shared.pointService
    
    init() {
        loadUserProfile()
        loadStreak()
    }
    
    func loadUserProfile() {
        if let currentUser = authService.currentUser {
            // Create a detached copy that survives Realm deletion
            userSnapshot = UserProfile(value: currentUser)
            userSnapshot?.id = currentUser.id
            userSnapshot?.email = currentUser.email
            userSnapshot?.displayName = currentUser.displayName
            userSnapshot?.role = currentUser.role
            userSnapshot?.pairingCode = currentUser.pairingCode
        }
    }
    
    func loadStreak() {
        guard let userId = userSnapshot?.id else { return }
        
        Task {
            let streak = await streakService.calculateStreak(for: userId)
            await MainActor.run {
                currentStreak = streak
            }
        }
    }
    
    func generatePairingCode() {
        let code = String((100000...999999).randomElement() ?? 123456)
        pairingCode = code
        
        if let currentUser = authService.currentUser {
            do {
                let realm = try Realm()
                try realm.write {
                    currentUser.pairingCode = code
                }
                // Update snapshot
                userSnapshot?.pairingCode = code
            } catch {
                print("Error saving pairing code: \(error)")
            }
        }
    }
    
    func loadPoints() async {
        guard let userId = userSnapshot?.id else { return }
        
        let points = await pointService.total(for: userId)
        await MainActor.run {
            totalPoints = points
        }
    }
    
    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}