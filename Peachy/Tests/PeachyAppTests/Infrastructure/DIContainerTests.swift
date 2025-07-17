import XCTest
@testable import PeachyApp

final class DIContainerTests: XCTestCase {
    
    func testAllServicesResolvable() throws {
        // Test that ServiceContainer.shared initializes without throwing
        let container = ServiceContainer.shared
        
        // Verify all services are non-nil and can be accessed
        XCTAssertNotNil(container.authService, "AuthService should be resolvable")
        XCTAssertNotNil(container.moodService, "MoodService should be resolvable")
        XCTAssertNotNil(container.hobbyService, "HobbyService should be resolvable")
        XCTAssertNotNil(container.aiService, "AIService should be resolvable")
        XCTAssertNotNil(container.notificationService, "NotificationService should be resolvable")
        XCTAssertNotNil(container.streakService, "StreakService should be resolvable")
        XCTAssertNotNil(container.keychainService, "KeychainService should be resolvable")
        
        // Test basic functionality of each service
        XCTAssertNoThrow({
            // Auth service basic check
            _ = container.authService.isSignedIn
            _ = container.authService.currentUser
        }(), "AuthService basic operations should not throw")
        
        // Verify services are of correct mock types
        XCTAssertTrue(type(of: container.authService) == MockAuthService.self, 
                      "AuthService should be MockAuthService")
        XCTAssertTrue(type(of: container.moodService) == MockMoodService.self,
                      "MoodService should be MockMoodService")
        XCTAssertTrue(type(of: container.hobbyService) == MockHobbyService.self,
                      "HobbyService should be MockHobbyService")
        XCTAssertTrue(type(of: container.aiService) == MockAIService.self,
                      "AIService should be MockAIService")
        XCTAssertTrue(type(of: container.notificationService) == MockNotificationService.self,
                      "NotificationService should be MockNotificationService")
        XCTAssertTrue(type(of: container.streakService) == MockStreakService.self,
                      "StreakService should be MockStreakService")
        XCTAssertTrue(type(of: container.keychainService) == KeychainServiceMock.self,
                      "KeychainService should be KeychainServiceMock")
    }
    
    func testServiceContainerSingleton() throws {
        // Verify ServiceContainer.shared returns the same instance
        let container1 = ServiceContainer.shared
        let container2 = ServiceContainer.shared
        
        XCTAssertTrue(container1 === container2, "ServiceContainer should be a singleton")
        
        // Verify services remain the same across accesses
        XCTAssertTrue(container1.authService === container2.authService,
                      "AuthService should be the same instance")
        XCTAssertTrue(container1.moodService === container2.moodService,
                      "MoodService should be the same instance")
    }
    
    func testServicesAreProtocolConformant() throws {
        let container = ServiceContainer.shared
        
        // These should compile without issues if protocols are properly conformed to
        let _: AuthServiceProtocol = container.authService
        let _: MoodServiceProtocol = container.moodService
        let _: HobbyServiceProtocol = container.hobbyService
        let _: AIServiceProtocol = container.aiService
        let _: NotificationServiceProtocol = container.notificationService
        let _: StreakServiceProtocol = container.streakService
        let _: KeychainServiceProtocol = container.keychainService
        
        XCTAssertTrue(true, "All services conform to their respective protocols")
    }
}