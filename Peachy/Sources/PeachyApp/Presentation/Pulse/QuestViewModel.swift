import Foundation
import SwiftUI

@MainActor
public class QuestViewModel: ObservableObject {
    @Published var hobbies: [HobbyPresetItem] = []
    @Published var selectedHobbyIds: Set<String> = []
    @Published var isLoading = true
    
    private let hobbyService = ServiceContainer.shared.hobbyService
    private let authService = ServiceContainer.shared.authService
    private let questService = ServiceContainer.shared.questService
    
    func loadHobbies() async {
        guard authService.currentUser != nil else {
            isLoading = false
            return
        }
        
        do {
            // Get hobbies from service
            hobbies = try await hobbyService.getHobbies()
            isLoading = false
        } catch {
            print("Error loading hobbies: \(error)")
            hobbies = []
            isLoading = false
        }
    }
    
    func toggleHobby(_ hobbyId: String) {
        if selectedHobbyIds.contains(hobbyId) {
            selectedHobbyIds.remove(hobbyId)
        } else {
            selectedHobbyIds.insert(hobbyId)
        }
    }
    
    func markQuestComplete(hobby: HobbyPresetItem, fact: String) async {
        do {
            try await questService.markDone(hobby: hobby, fact: fact)
            print("Quest completed with hobby: \(hobby.name)")
        } catch {
            print("Error marking quest complete: \(error)")
        }
    }
}