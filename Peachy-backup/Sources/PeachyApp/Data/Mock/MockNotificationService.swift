import Foundation

public final class MockNotificationService: NotificationServiceProtocol {
    public init() {}
    
    public func scheduleBufferNotification(after minutes: Int) {
        // Mock implementation
        print("Scheduled notification after \(minutes) minutes")
    }
    
    public func cancelPendingNotifications() async throws {
        // Mock implementation
        print("Cancelled pending notifications")
    }
    
    public func requestPermission() async throws -> Bool {
        return true
    }
    
    public func scheduleMoodReminder(after minutes: Int) async throws {
        print("Scheduled mood reminder after \(minutes) minutes")
    }
    
    public func sendMoodUpdate(to userId: String, mood: MoodEntry) async throws {
        print("Sent mood update to \(userId)")
    }
}