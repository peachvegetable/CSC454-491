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
    private let _pointService: PointServiceProtocol
    private let _questService: QuestServiceProtocol
    
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
    var pointService: PointServiceProtocol { _pointService }
    var questService: QuestServiceProtocol { _questService }
    
    private init() {
        // Initialize @MainActor services on main thread
        self._authService = MainActor.assumeIsolated {
            MockAuthService()
        }
        self._moodService = MainActor.assumeIsolated {
            MockMoodService()
        }
        self._hobbyService = MainActor.assumeIsolated {
            MockHobbyService()
        }
        self._aiService = MockAIService()
        self._notificationService = MockNotificationService()
        self._streakService = MockStreakService()
        self._keychainService = KeychainServiceMock.shared
        self._chatService = MainActor.assumeIsolated {
            MockChatService()
        }
        self._pointService = MainActor.assumeIsolated {
            MockPointService()
        }
        self._questService = MainActor.assumeIsolated {
            MockQuestService()
        }
        
        // Set dependencies after initialization to avoid circular references
        MainActor.assumeIsolated {
            // Set auth service for services that need it
            (_hobbyService as? MockHobbyService)?.setAuthService(_authService)
            (_hobbyService as? MockHobbyService)?.setPointService(_pointService)
            (_chatService as? MockChatService)?.setAuthService(_authService)
            (_questService as? MockQuestService)?.setServices(
                authService: _authService,
                pointService: _pointService,
                hobbyService: _hobbyService
            )
        }
    }
}