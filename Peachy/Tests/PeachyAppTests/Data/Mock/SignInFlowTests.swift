import XCTest
@testable import PeachyApp

final class SignInFlowTests: XCTestCase {
    var authService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        authService = MockAuthService()
    }
    
    override func tearDown() {
        authService = nil
        super.tearDown()
    }
    
    func testSignInDoesNotCrash() async throws {
        // Test with valid email credentials
        let testEmail = "test@example.com"
        let testPassword = "password123"
        
        // Use XCTAssertNoThrow to verify the entire call doesn't crash
        try await XCTAssertNoThrowAsync {
            let userProfile = try await authService.signIn(email: testEmail, password: testPassword)
            
            // Assert result is success and UserProfile is stored
            XCTAssertNotNil(userProfile, "UserProfile should not be nil after successful sign in")
            XCTAssertEqual(userProfile.email, testEmail, "Email should match the input")
            XCTAssertEqual(userProfile.displayName, "test", "Display name should be extracted from email")
            XCTAssertEqual(userProfile.role, UserRole.teen.rawValue, "Default role should be teen")
            XCTAssertNotNil(userProfile.id, "User ID should be generated")
            
            // Verify the user is now signed in
            XCTAssertTrue(authService.isSignedIn, "User should be signed in after successful authentication")
            XCTAssertNotNil(authService.currentUser, "Current user should be set")
            XCTAssertEqual(authService.currentUser?.id, userProfile.id, "Current user should match returned user")
        }
    }
    
    func testSignInWithAppleDoesNotCrash() async throws {
        // Use XCTAssertNoThrow to verify Apple sign in doesn't crash
        try await XCTAssertNoThrowAsync {
            let userProfile = try await authService.signInWithApple()
            
            // Assert result is success and UserProfile is stored
            XCTAssertNotNil(userProfile, "UserProfile should not be nil after successful Apple sign in")
            XCTAssertEqual(userProfile.email, "apple.user@icloud.com", "Email should be the default Apple email")
            XCTAssertEqual(userProfile.displayName, "Apple User", "Display name should be default Apple User")
            XCTAssertEqual(userProfile.role, UserRole.teen.rawValue, "Default role should be teen")
            XCTAssertNotNil(userProfile.id, "User ID should be generated")
            
            // Verify the user is now signed in
            XCTAssertTrue(authService.isSignedIn, "User should be signed in after successful authentication")
            XCTAssertNotNil(authService.currentUser, "Current user should be set")
            XCTAssertEqual(authService.currentUser?.id, userProfile.id, "Current user should match returned user")
        }
    }
    
    func testSignInWithInvalidEmailThrows() async throws {
        // Test with invalid email (no @ symbol)
        let invalidEmail = "notanemail"
        let testPassword = "password123"
        
        do {
            _ = try await authService.signIn(email: invalidEmail, password: testPassword)
            XCTFail("Sign in should throw error for invalid email")
        } catch {
            // Expected error
            XCTAssertTrue(error is AuthError, "Error should be AuthError type")
            if let authError = error as? AuthError {
                XCTAssertEqual(authError, .invalidEmail, "Error should be invalidEmail")
            }
        }
        
        // Verify user is not signed in after failed attempt
        XCTAssertFalse(authService.isSignedIn, "User should not be signed in after failed authentication")
        XCTAssertNil(authService.currentUser, "Current user should remain nil")
    }
    
    func testSignOutClearsUserData() async throws {
        // First sign in
        let testEmail = "test@example.com"
        let testPassword = "password123"
        
        let userProfile = try await authService.signIn(email: testEmail, password: testPassword)
        XCTAssertTrue(authService.isSignedIn, "User should be signed in")
        XCTAssertNotNil(authService.currentUser, "Current user should be set")
        
        // Now sign out
        try await XCTAssertNoThrowAsync {
            try await authService.signOut()
        }
        
        // Verify user is signed out
        XCTAssertFalse(authService.isSignedIn, "User should not be signed in after sign out")
        XCTAssertNil(authService.currentUser, "Current user should be nil after sign out")
    }
}

// Helper function for async XCTAssertNoThrow
func XCTAssertNoThrowAsync<T>(_ expression: () async throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) async throws {
    do {
        _ = try await expression()
    } catch {
        XCTFail("Expected no throw but got error: \(error) - \(message)", file: file, line: line)
        throw error
    }
}