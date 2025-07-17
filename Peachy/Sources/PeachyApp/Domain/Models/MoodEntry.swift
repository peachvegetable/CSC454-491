import Foundation
import SwiftUI

struct MoodEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let moodType: MoodType
    let intensity: Double
    let bufferMinutes: Int
    let createdAt: Date
    let sentAt: Date?
    var note: String?
    
    enum MoodType: String, Codable, CaseIterable {
        case happy
        case excited
        case calm
        case sad
        case anxious
        case angry
        case confused
        case tired
        
        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .excited: return "🤩"
            case .calm: return "😌"
            case .sad: return "😢"
            case .anxious: return "😰"
            case .angry: return "😠"
            case .confused: return "😕"
            case .tired: return "😴"
            }
        }
        
        var colorHex: String {
            switch self {
            case .happy: return "#FFD700"
            case .excited: return "#FF8C00"
            case .calm: return "#32CD32"
            case .sad: return "#4169E1"
            case .anxious: return "#9370DB"
            case .angry: return "#DC143C"
            case .confused: return "#808080"
            case .tired: return "#4B0082"
            }
        }
    }
}

struct MoodHistory: Codable {
    let userId: String
    let entries: [MoodEntry]
    let lastUpdated: Date
    
    var dailyAverage: MoodEntry.MoodType? {
        guard !entries.isEmpty else { return nil }
        // Simplified logic - return most frequent mood
        let moodCounts = entries.reduce(into: [:]) { counts, entry in
            counts[entry.moodType, default: 0] += 1
        }
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var weeklyTrend: [MoodEntry.MoodType] {
        // Group by day and get dominant mood
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.createdAt)
        }
        
        return grouped.compactMap { _, dayEntries in
            dayEntries.max(by: { $0.createdAt < $1.createdAt })?.moodType
        }
    }
}