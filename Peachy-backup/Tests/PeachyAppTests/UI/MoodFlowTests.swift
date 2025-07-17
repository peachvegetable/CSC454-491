import XCTest

final class MoodFlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSaveNavigatesToPulse() throws {
        // 1. Complete sign-in flow to get to MoodWheel
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
        
        // 2. Verify MoodWheelView appears
        let moodWheel = app.otherElements["moodWheel"]
        XCTAssertTrue(moodWheel.waitForExistence(timeout: 5), "Mood wheel should be visible")
        
        // 3. Select a mood color (tap green section)
        moodWheel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        
        // Wait for save button to be enabled
        let saveMoodButton = app.buttons["saveMoodButton"]
        XCTAssertTrue(saveMoodButton.waitForExistence(timeout: 2), "Save Mood button should be visible")
        
        // 4. Save mood
        saveMoodButton.tap()
        
        // 5. Verify navigation to PulseView
        let pulseRoot = app.otherElements["pulseRoot"]
        XCTAssertTrue(pulseRoot.waitForExistence(timeout: 5), "Should navigate to PulseView after saving mood")
        
        // Verify Pulse navigation bar
        let pulseNavBar = app.navigationBars["Pulse"]
        XCTAssertTrue(pulseNavBar.exists, "Pulse navigation bar should be visible")
        
        // Verify mood is displayed in TodayCard
        let todayCard = app.otherElements.containing(NSPredicate(format: "label CONTAINS 'Today'")).firstMatch
        XCTAssertTrue(todayCard.exists, "Today card should be visible with saved mood")
    }
    
    func testEditMoodNavigatesBackToMoodWheel() throws {
        // First complete the save mood flow
        try testSaveNavigatesToPulse()
        
        // Find and tap Edit button
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2), "Edit button should be visible")
        editButton.tap()
        
        // Verify we're back at MoodWheelView
        let moodWheel = app.otherElements["moodWheel"]
        XCTAssertTrue(moodWheel.waitForExistence(timeout: 5), "Should navigate back to MoodWheel for editing")
        
        // Verify save button exists
        let saveMoodButton = app.buttons["saveMoodButton"]
        XCTAssertTrue(saveMoodButton.exists, "Save Mood button should be visible for editing")
    }
}