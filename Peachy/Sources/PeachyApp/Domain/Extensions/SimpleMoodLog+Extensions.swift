import Foundation

extension SimpleMoodLog {
    /// Checks if the mood is visible to others based on buffer time
    var isVisibleToOthers: Bool {
        guard let bufferMinutes = bufferMinutes, bufferMinutes > 0 else {
            // No buffer, immediately visible
            return true
        }
        
        let bufferSeconds = TimeInterval(bufferMinutes * 60)
        let visibleTime = date.addingTimeInterval(bufferSeconds)
        
        return Date() >= visibleTime
    }
    
    /// Time remaining until mood becomes visible (nil if already visible)
    var timeUntilVisible: TimeInterval? {
        guard let bufferMinutes = bufferMinutes, bufferMinutes > 0 else {
            return nil
        }
        
        let bufferSeconds = TimeInterval(bufferMinutes * 60)
        let visibleTime = date.addingTimeInterval(bufferSeconds)
        let remaining = visibleTime.timeIntervalSince(Date())
        
        return remaining > 0 ? remaining : nil
    }
}