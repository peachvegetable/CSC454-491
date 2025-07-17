import Foundation
import PeachyApp

public final class ServiceContainer {
    public static let shared = ServiceContainer()
    
    private var _authService: AuthServiceProtocol
    private let _moodService: MoodServiceProtocol
    private let _hobbyService: HobbyServiceProtocol
    private let _aiService: AIServiceProtocol
    private let _notificationService: NotificationServiceProtocol
    private let _streakService: StreakServiceProtocol
    private let _keychainService: KeychainServiceProtocol
    private let _chatService: ChatServiceProtocol
    
    var authService: AuthServiceProtocol { 
        get { _authService }
        set { _authService = newValue }
    }
    var moodService: MoodServiceProtocol { _moodService }
    var hobbyService: HobbyServiceProtocol { _hobbyService }
    var aiService: AIServiceProtocol { _aiService }
    var notificationService: NotificationServiceProtocol { _notificationService }
    var streakService: StreakServiceProtocol { _streakService }
    var keychainService: KeychainServiceProtocol { _keychainService }
    var chatService: ChatServiceProtocol { _chatService }
    
    private init() {
        // Initialize @MainActor services on main thread
        self._authService = MainActor.assumeIsolated {
            MockAuthService()
        }
        self._moodService = MainActor.assumeIsolated {
            MockMoodService()
        }
        self._hobbyService = MockHobbyService()
        self._aiService = MockAIService()
        self._notificationService = MockNotificationService()
        self._streakService = MockStreakService()
        self._keychainService = KeychainServiceMock.shared
        self._chatService = MainActor.assumeIsolated {
            MockChatService()
        }
    }
}