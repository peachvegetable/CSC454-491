import Foundation

public final class ServiceContainer {
    public static let shared = ServiceContainer()
    
    private var _authService: AuthServiceProtocol
    private let _moodService: MoodServiceProtocol
    private let _hobbyService: HobbyServiceProtocol
    private let _aiService: AIServiceProtocol
    private let _notificationService: NotificationServiceProtocol
    private let _streakService: StreakServiceProtocol
    private let _keychainService: KeychainServiceProtocol
    
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
    
    private init() {
        self._authService = MockAuthService()
        self._moodService = MockMoodService()
        self._hobbyService = MockHobbyService()
        self._aiService = MockAIService()
        self._notificationService = MockNotificationService()
        self._streakService = MockStreakService()
        self._keychainService = KeychainServiceMock.shared
    }
}