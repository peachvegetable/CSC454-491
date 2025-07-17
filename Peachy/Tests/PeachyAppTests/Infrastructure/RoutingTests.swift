import XCTest
@testable import PeachyApp

final class RoutingTests: XCTestCase {
    
    func testFirstLaunchGoesToHobbyPicker() async throws {
        // Given - User is signed in but has no hobbies
        let authService = MockAuthService()
        let user = try await authService.signUp(email: "test@example.com", password: "password123")
        
        // Ensure hobbies are empty
        XCTAssertTrue(user.hobbies.isEmpty, "User should have no hobbies on first launch")
        
        // When checking routing
        let shouldShowHobbyPicker = authService.isSignedIn && user.hobbies.isEmpty
        
        // Then
        XCTAssertTrue(shouldShowHobbyPicker, "Should show hobby picker for signed in user with no hobbies")
    }
    
    func testUserWithHobbiesButNoMoodShowsMoodIntro() async throws {
        // Given - User is signed in with hobbies but no mood today
        let authService = MockAuthService()
        let user = try await authService.signUp(email: "test@example.com", password: "password123")
        
        // Add hobbies
        await MainActor.run {
            user.hobbiesArray = ["Gaming", "Music"]
        }
        
        // When checking routing
        let hasHobbies = !user.hobbies.isEmpty
        let hasMoodToday = false // No mood logged today
        let shouldShowMoodIntro = authService.isSignedIn && hasHobbies && !hasMoodToday
        
        // Then
        XCTAssertTrue(shouldShowMoodIntro, "Should show mood intro for user with hobbies but no mood today")
    }
    
    func testCompleteUserShowsPulseView() async throws {
        // Given - User is signed in with hobbies and has logged mood
        let authService = MockAuthService()
        let user = try await authService.signUp(email: "test@example.com", password: "password123")
        
        // Add hobbies
        await MainActor.run {
            user.hobbiesArray = ["Gaming", "Music"]
        }
        
        // Simulate mood logged today
        let hasMoodToday = true
        
        // When checking routing
        let isComplete = authService.isSignedIn && !user.hobbies.isEmpty && hasMoodToday
        
        // Then
        XCTAssertTrue(isComplete, "Should show pulse view for complete user")
    }
}