import Foundation
import SwiftUI

@MainActor
public class QuestViewModel: ObservableObject {
    @Published var hobbies: [Hobby] = []
    @Published var selectedHobbyIds: Set<String> = []
    @Published var isLoading = true
    
    private let hobbyService = ServiceContainer.shared.hobbyService
    private let authService = ServiceContainer.shared.authService
    
    func loadHobbies() async {
        guard authService.currentUser != nil else {
            isLoading = false
            return
        }
        
        // Get hobby names from service
        let hobbyNames = hobbyService.getHobbies()
        
        // Convert hobby names to Hobby objects using presets
        hobbies = HobbyPreset.presets.filter { preset in
            hobbyNames.contains(preset.name)
        }
        
        isLoading = false
    }
    
    func toggleHobby(_ hobbyId: String) {
        if selectedHobbyIds.contains(hobbyId) {
            selectedHobbyIds.remove(hobbyId)
        } else {
            selectedHobbyIds.insert(hobbyId)
        }
    }
    
    func markQuestComplete() {
        let selectedHobbyNames = hobbies
            .filter { selectedHobbyIds.contains($0.id) }
            .map { $0.name }
        print("Quest completed with hobbies: \(selectedHobbyNames)")
        // TODO: Save quest completion to a service
    }
}