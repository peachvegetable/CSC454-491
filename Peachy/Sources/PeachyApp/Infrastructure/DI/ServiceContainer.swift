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
    private let _treeService: TreeServiceProtocol
    private let _taskService: TaskService
    private let _rewardService: RewardService
    private let _pointsService: PointsService
    private let _featureSettingsService: FeatureSettingsService
    private let _subscriptionService: SubscriptionService
    private let _empathyTipService: EmpathyTipService
    
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
    var treeService: TreeServiceProtocol { _treeService }
    var taskService: TaskService { _taskService }
    var rewardService: RewardService { _rewardService }
    var pointsService: PointsService { _pointsService }
    var featureSettingsService: FeatureSettingsService { _featureSettingsService }
    var subscriptionService: SubscriptionService { _subscriptionService }
    var empathyTipService: EmpathyTipService { _empathyTipService }
    
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
        self._treeService = MainActor.assumeIsolated {
            MockTreeService()
        }
        self._taskService = MainActor.assumeIsolated {
            TaskService()
        }
        self._rewardService = MainActor.assumeIsolated {
            RewardService()
        }
        self._pointsService = MainActor.assumeIsolated {
            PointsService()
        }
        self._featureSettingsService = MainActor.assumeIsolated {
            FeatureSettingsService()
        }
        self._subscriptionService = MainActor.assumeIsolated {
            SubscriptionService()
        }
        self._empathyTipService = MainActor.assumeIsolated {
            EmpathyTipService()
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
            
            // Set dependencies for reward system services
            _taskService.authService = _authService
            _rewardService.authService = _authService
            _pointsService.authService = _authService
            _pointsService.taskService = _taskService
            _pointsService.rewardService = _rewardService
            
            // Set dependencies for empathy tip service
            _empathyTipService.setServices(
                moodService: _moodService,
                authService: _authService,
                subscriptionService: _subscriptionService
            )
        }
    }
}