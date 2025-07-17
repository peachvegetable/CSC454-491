import XCTest

final class OnboardingFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testFirstLaunchGoesToMoodWheel() throws {
        // 1. Launch app and tap Get Started
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5), "Get Started button should be visible")
        getStartedButton.tap()
        
        // 2. Wait for auth screen and tap Sign In
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign In button should be visible")
        
        // Fill in email field
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2), "Email field should be visible")
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Fill in password field
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 2), "Password field should be visible")
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Tap Sign In
        signInButton.tap()
        
        // 3. Choose role (Teen)
        let teenButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Teen'")).firstMatch
        XCTAssertTrue(teenButton.waitForExistence(timeout: 5), "Teen role button should be visible")
        teenButton.tap()
        
        // 4. Tap Continue
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2), "Continue button should be visible")
        continueButton.tap()
        
        // 5. Assert MoodWheelView appears (full screen mood wheel)
        let moodWheel = app.otherElements["moodWheel"]
        XCTAssertTrue(moodWheel.waitForExistence(timeout: 5), "Mood wheel should be visible after role selection")
        
        // Verify save button exists
        let saveMoodButton = app.buttons["saveMoodButton"]
        XCTAssertTrue(saveMoodButton.exists, "Save Mood button should be visible")
    }
    
    func testAppleSignInToHomeView() throws {
        // 1. Launch app and tap Get Started
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5), "Get Started button should be visible")
        getStartedButton.tap()
        
        // 2. Sign in with Apple
        // SignInWithAppleButton doesn't have a direct identifier, so we'll look for it by its frame
        let appleSignInButton = app.buttons.matching(NSPredicate(format: "frame.height == 50")).element(boundBy: 1)
        XCTAssertTrue(appleSignInButton.waitForExistence(timeout: 5), "Apple Sign In button should be visible")
        appleSignInButton.tap()
        
        // 3. Select Parent role
        let parentButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Parent'")).firstMatch
        XCTAssertTrue(parentButton.waitForExistence(timeout: 5), "Parent role button should be visible")
        parentButton.tap()
        
        // 4. Tap Continue
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2), "Continue button should be visible")
        continueButton.tap()
        
        // 5. Verify MoodWheelView appears
        let moodWheel = app.otherElements["moodWheel"]
        XCTAssertTrue(moodWheel.waitForExistence(timeout: 10), "moodWheel element must appear")
        
        // Additional verification
        let saveMoodButton = app.buttons["saveMoodButton"]
        XCTAssertTrue(saveMoodButton.exists, "Save Mood button should be visible")
    }
    
    func testHomeAppears() throws {
        // 1. Launch app and tap Get Started
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5), "Get Started button should be visible")
        getStartedButton.tap()
        
        // 2. Sign in with test credentials
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign In button should be visible")
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        signInButton.tap()
        
        // 3. Select Teen role
        let teenButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Teen'")).firstMatch
        XCTAssertTrue(teenButton.waitForExistence(timeout: 5), "Teen role button should be visible")
        teenButton.tap()
        
        // 4. Tap Continue
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 2), "Continue button should be visible")
        continueButton.tap()
        
        // 5. Verify moodWheel appears
        let moodWheel = app.otherElements["moodWheel"]
        XCTAssertTrue(moodWheel.waitForExistence(timeout: 10), "moodWheel element must appear")
        
    }
    
    func testPairLaterFlow() throws {
        // 1. Launch app and tap Get Started
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5), "Get Started button should be visible")
        getStartedButton.tap()
        
        // 2. Wait for auth screen and tap Sign In
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign In button should be visible")
        
        // Fill in email field
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2), "Email field should be visible")
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Fill in password field
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 2), "Password field should be visible")
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Tap Sign In
        signInButton.tap()
        
        // 3. On role picker, tap Pair Later
        let pairLaterButton = app.buttons["Pair Later"]
        XCTAssertTrue(pairLaterButton.waitForExistence(timeout: 5), "Pair Later button should be visible")
        pairLaterButton.tap()
        
        // 4. Assert HomeView identifier exists (moodWheel)
        let moodWheel = app.otherElements["moodWheel"]
        XCTAssertTrue(moodWheel.waitForExistence(timeout: 5), "Mood wheel should be visible in HomeView after Pair Later")
    }
    
    func testFullNewUserPathEndsAtPulse() throws {
        // 1. Launch app and tap Sign Up
        let signUpButton = app.buttons["Sign Up"]
        XCTAssertTrue(signUpButton.waitForExistence(timeout: 5), "Sign Up button should be visible")
        signUpButton.tap()
        
        // 2. Fill sign up form
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2), "Email field should be visible")
        emailField.tap()
        emailField.typeText("newuser@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        confirmPasswordField.tap()
        confirmPasswordField.typeText("password123")
        
        let signUpSubmitButton = app.buttons["Sign Up"].element(boundBy: 1)
        signUpSubmitButton.tap()
        
        // 3. Select hobbies
        let hobbyChip = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Gaming'")).firstMatch
        XCTAssertTrue(hobbyChip.waitForExistence(timeout: 5), "Gaming hobby should be visible")
        hobbyChip.tap()
        
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.exists, "Next button should be visible")
        nextButton.tap()
        
        // 4. Select mood
        let moodWheel = app.otherElements["moodWheel"]
        XCTAssertTrue(moodWheel.waitForExistence(timeout: 5), "Mood wheel should be visible")
        // Tap green section (approximate location)
        moodWheel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        
        let saveMoodButton = app.buttons["Save Mood"]
        XCTAssertTrue(saveMoodButton.waitForExistence(timeout: 2), "Save Mood button should be visible")
        saveMoodButton.tap()
        
        // 5. Verify we're at PulseView
        let pulseRoot = app.otherElements["pulseRoot"]
        XCTAssertTrue(pulseRoot.waitForExistence(timeout: 10), "pulseRoot element must appear")
        
        // Additional verification
        let pulseNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(pulseNavBar.exists, "Pulse navigation bar should be visible")
    }
}