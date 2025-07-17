import XCTest

final class PulseShortcutsTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testPulseShowsOnlyProfileShortcut() throws {
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
        
        // 3. Verify only Profile shortcut exists
        let profileButton = app.buttons["Profile"]
        XCTAssertTrue(profileButton.exists, "Profile shortcut should exist")
        
        // 4. Verify History and Pair Later shortcuts do NOT exist
        let historyButton = app.buttons["History"]
        XCTAssertFalse(historyButton.exists, "History shortcut should NOT exist in PulseView")
        
        let pairLaterButton = app.buttons["Pair Later"]
        XCTAssertFalse(pairLaterButton.exists, "Pair Later shortcut should NOT exist in PulseView")
        
        // 5. Verify tapping Profile navigates correctly
        profileButton.tap()
        
        let profileNavBar = app.navigationBars["Profile"]
        XCTAssertTrue(profileNavBar.waitForExistence(timeout: 5), "Should navigate to ProfileView")
    }
    
    func testProfileShortcutWidth() throws {
        // Navigate to Pulse (same as above, abbreviated)
        app.buttons["Get Started"].tap()
        app.buttons["Sign In"].tap()
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("test@example.com")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("password123")
        app.buttons["Sign In"].tap()
        app.buttons.containing(NSPredicate(format: "label CONTAINS 'Teen'")).firstMatch.tap()
        app.buttons["Continue"].tap()
        app.otherElements["moodWheel"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        app.buttons["saveMoodButton"].tap()
        
        // Verify Profile button takes full width
        let profileButton = app.buttons["Profile"]
        XCTAssertTrue(profileButton.exists, "Profile button should exist")
        
        // Get the frame of the profile button and the screen
        let buttonFrame = profileButton.frame
        let screenFrame = app.frame
        
        // Allow for some padding on sides
        let expectedMinWidth = screenFrame.width - 80  // 40 points padding on each side
        XCTAssertGreaterThan(buttonFrame.width, expectedMinWidth, 
                            "Profile button should span most of the screen width")
    }
}