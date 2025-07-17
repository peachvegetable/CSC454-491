import Foundation

@MainActor
class EmojiPickerViewModel: ObservableObject {
    @Published var selectedEmoji: String?
    @Published var recentEmojis: [String] = []
    
    private let maxRecentEmojis = 12
    private let recentEmojisKey = "recentEmojis"
    
    init() {
        loadRecentEmojis()
    }
    
    func selectEmoji(_ emoji: String) {
        selectedEmoji = emoji
        addToRecentEmojis(emoji)
    }
    
    func clearSelection() {
        selectedEmoji = nil
    }
    
    private func addToRecentEmojis(_ emoji: String) {
        var recent = recentEmojis
        
        if let index = recent.firstIndex(of: emoji) {
            recent.remove(at: index)
        }
        
        recent.insert(emoji, at: 0)
        
        if recent.count > maxRecentEmojis {
            recent = Array(recent.prefix(maxRecentEmojis))
        }
        
        recentEmojis = recent
        saveRecentEmojis()
    }
    
    private func loadRecentEmojis() {
        if let data = UserDefaults.standard.data(forKey: recentEmojisKey),
           let emojis = try? JSONDecoder().decode([String].self, from: data) {
            recentEmojis = emojis
        }
    }
    
    private func saveRecentEmojis() {
        if let data = try? JSONEncoder().encode(recentEmojis) {
            UserDefaults.standard.set(data, forKey: recentEmojisKey)
        }
    }
}