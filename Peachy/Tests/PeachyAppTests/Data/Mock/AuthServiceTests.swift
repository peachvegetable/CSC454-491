import XCTest
@testable import PeachyApp

final class AuthServiceTests: XCTestCase {
    var authService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        authService = MockAuthService()
    }
    
    override func tearDown() {
        authService = nil
        super.tearDown()
    }
    
    func testSignUpCreatesProfile() async throws {
        // Given
        let email = "newuser@example.com"
        let password = "password123"
        
        // When
        let userProfile = try await authService.signUp(email: email, password: password)
        
        // Then
        XCTAssertNotNil(userProfile, "User profile should be created")
        XCTAssertEqual(userProfile.email, email, "Email should match")
        XCTAssertEqual(userProfile.displayName, "newuser", "Display name should be extracted from email")
        XCTAssertEqual(userProfile.role, UserRole.teen.rawValue, "Default role should be teen")
        XCTAssertTrue(userProfile.hobbies.isEmpty, "Hobbies should be empty initially")
        XCTAssertNotNil(userProfile.id, "User ID should be generated")
        
        // Verify the user is now signed in
        XCTAssertTrue(authService.isSignedIn, "User should be signed in after sign up")
        XCTAssertNotNil(authService.currentUser, "Current user should be set")
        XCTAssertEqual(authService.currentUser?.id, userProfile.id, "Current user should match created user")
    }
    
    func testSignUpWithInvalidEmailThrows() async throws {
        // Given
        let invalidEmail = "notanemail"
        let password = "password123"
        
        // When/Then
        do {
            _ = try await authService.signUp(email: invalidEmail, password: password)
            XCTFail("Sign up should throw error for invalid email")
        } catch {
            XCTAssertTrue(error is AuthError, "Error should be AuthError type")
            if let authError = error as? AuthError {
                XCTAssertEqual(authError, .invalidEmail, "Error should be invalidEmail")
            }
        }
    }
    
    func testSignOutDoesNotCrash() async throws {
        // Given - Sign in first
        let email = "test@example.com"
        let password = "password123"
        let userProfile = try await authService.signIn(email: email, password: password)
        
        // Verify signed in
        XCTAssertTrue(authService.isSignedIn, "User should be signed in")
        XCTAssertNotNil(authService.currentUser, "Current user should exist")
        
        // When - Sign out
        do {
            try await authService.signOut()
            
            // Then - Should complete without throwing
            XCTAssertFalse(authService.isSignedIn, "User should be signed out")
            XCTAssertNil(authService.currentUser, "Current user should be nil")
        } catch {
            XCTFail("Sign out should not throw an error: \(error)")
        }
    }
}