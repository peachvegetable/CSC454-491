import Foundation
import SwiftUI

public struct MoodEntry: Identifiable, Codable {
    public let id: String
    public let userId: String
    public let moodType: MoodType
    public let intensity: Double
    public let bufferMinutes: Int
    public let createdAt: Date
    public let sentAt: Date?
    public var note: String?
    
    public init(id: String, userId: String, moodType: MoodType, intensity: Double, bufferMinutes: Int, createdAt: Date, sentAt: Date? = nil, note: String? = nil) {
        self.id = id
        self.userId = userId
        self.moodType = moodType
        self.intensity = intensity
        self.bufferMinutes = bufferMinutes
        self.createdAt = createdAt
        self.sentAt = sentAt
        self.note = note
    }
    
    public enum MoodType: String, Codable, CaseIterable {
        case happy
        case excited
        case calm
        case sad
        case anxious
        case angry
        case confused
        case tired
        
        public var emoji: String {
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
        
        public var colorHex: String {
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

public struct MoodHistory: Codable {
    public let userId: String
    public let entries: [MoodEntry]
    public let lastUpdated: Date
    
    public var dailyAverage: MoodEntry.MoodType? {
        guard !entries.isEmpty else { return nil }
        // Simplified logic - return most frequent mood
        let moodCounts = entries.reduce(into: [:]) { counts, entry in
            counts[entry.moodType, default: 0] += 1
        }
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    public var weeklyTrend: [MoodEntry.MoodType] {
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