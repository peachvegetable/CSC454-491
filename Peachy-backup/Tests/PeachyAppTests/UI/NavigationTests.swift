import XCTest

final class NavigationTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testHistoryShortcutOpensProfileHistory() throws {
        // 1. Complete sign-in to get to Pulse
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5), "Get Started button should be visible")
        getStartedButton.tap()
        
        // Sign in
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign In button should be visible")
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        signInButton.tap()
        
        // Select role
        let teenButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Teen'")).firstMatch
        XCTAssertTrue(teenButton.waitForExistence(timeout: 5), "Teen role button should be visible")
        teenButton.tap()
        
        let continueButton = app.buttons["Continue"]
        continueButton.tap()
        
        // Complete mood selection to get to Pulse
        let moodWheel = app.otherElements["moodWheel"]
        XCTAssertTrue(moodWheel.waitForExistence(timeout: 5), "Mood wheel should be visible")
        moodWheel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        
        let saveMoodButton = app.buttons["saveMoodButton"]
        saveMoodButton.tap()
        
        // 2. Verify we're at PulseView
        let pulseRoot = app.otherElements["pulseRoot"]
        XCTAssertTrue(pulseRoot.waitForExistence(timeout: 5), "Should be at PulseView")
        
        // 3. Tap History shortcut
        let historyButton = app.buttons["History"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 2), "History shortcut should be visible")
        historyButton.tap()
        
        // 4. Verify ProfileView appears
        let profileNavBar = app.navigationBars["Profile"]
        XCTAssertTrue(profileNavBar.waitForExistence(timeout: 5), "Profile navigation bar should be visible")
        
        // 5. Verify History section is visible
        // The History section should be scrolled into view
        let streakText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'day streak'")).firstMatch
        XCTAssertTrue(streakText.waitForExistence(timeout: 2), "Streak/History section should be visible")
    }
    
    func testPairLaterShortcutOpensProfilePairing() throws {
        // 1. Complete sign-in to get to Pulse
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.waitForExistence(timeout: 5), "Get Started button should be visible")
        getStartedButton.tap()
        
        // Sign in
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign In button should be visible")
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        signInButton.tap()
        
        // Select role
        let teenButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Teen'")).firstMatch
        XCTAssertTrue(teenButton.waitForExistence(timeout: 5), "Teen role button should be visible")
        teenButton.tap()
        
        let continueButton = app.buttons["Continue"]
        continueButton.tap()
        
        // Complete mood selection to get to Pulse
        let moodWheel = app.otherElements["moodWheel"]
        XCTAssertTrue(moodWheel.waitForExistence(timeout: 5), "Mood wheel should be visible")
        moodWheel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        
        let saveMoodButton = app.buttons["saveMoodButton"]
        saveMoodButton.tap()
        
        // 2. Verify we're at PulseView
        let pulseRoot = app.otherElements["pulseRoot"]
        XCTAssertTrue(pulseRoot.waitForExistence(timeout: 5), "Should be at PulseView")
        
        // 3. Tap Pair Later shortcut
        let pairLaterButton = app.buttons["Pair Later"]
        XCTAssertTrue(pairLaterButton.waitForExistence(timeout: 2), "Pair Later shortcut should be visible")
        pairLaterButton.tap()
        
        // 4. Verify ProfileView appears
        let profileNavBar = app.navigationBars["Profile"]
        XCTAssertTrue(profileNavBar.waitForExistence(timeout: 5), "Profile navigation bar should be visible")
        
        // 5. Verify Pairing section is visible
        let pairingText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Pairing Code'")).firstMatch
        XCTAssertTrue(pairingText.waitForExistence(timeout: 2), "Pairing section should be visible")
    }
}