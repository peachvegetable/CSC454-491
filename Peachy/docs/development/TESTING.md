# Peachy Testing Guide

## Overview

Peachy follows a comprehensive testing strategy covering unit tests, integration tests, and UI tests. All tests use mock services to ensure consistent, fast, and reliable test execution.

## Testing Philosophy

1. **Test Behavior, Not Implementation**: Focus on what the code does, not how
2. **Fast and Reliable**: Tests should run quickly and consistently
3. **Isolated**: Each test should be independent
4. **Meaningful**: Test names should describe the scenario clearly

## Test Structure

```
Tests/PeachyAppTests/
   Chat/              # Chat feature tests
   Services/          # Service layer tests
   ViewModels/        # ViewModel tests  
   Models/            # Model tests
   UI/                # UI/Integration tests
   Helpers/           # Test utilities
```

## Unit Testing

### Service Tests

Test service implementations thoroughly:

```swift
@MainActor
final class MoodServiceTests: XCTestCase {
    var sut: MockMoodService!
    var realm: Realm!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Use in-memory Realm
        let config = Realm.Configuration(
            inMemoryIdentifier: "MoodServiceTests-\(UUID().uuidString)",
            schemaVersion: 2
        )
        realm = try Realm(configuration: config)
        RealmManager.shared.setRealm(realm)
        
        sut = MockMoodService()
    }
    
    override func tearDown() async throws {
        sut = nil
        realm = nil
        try await super.tearDown()
    }
    
    func testSaveMoodCreatesLog() async throws {
        // Given
        let color = SimpleMoodColor.happy
        let emoji = "=
"
        
        // When
        try await sut.save(color: color, emoji: emoji)
        
        // Then
        let log = await sut.todaysLog
        XCTAssertNotNil(log)
        XCTAssertEqual(log?.color, color)
        XCTAssertEqual(log?.emoji, emoji)
    }
    
    func testMultipleMoodsAppendNotReplace() async throws {
        // Given
        let firstColor = SimpleMoodColor.happy
        let secondColor = SimpleMoodColor.excited
        
        // When
        try await sut.save(color: firstColor, emoji: nil)
        try await sut.save(color: secondColor, emoji: nil)
        
        // Then
        let logs = try await sut.allLogs()
        XCTAssertEqual(logs.count, 2)
        XCTAssertEqual(logs[0].color, firstColor)
        XCTAssertEqual(logs[1].color, secondColor)
    }
}
```

### ViewModel Tests

Test ViewModel logic and state management:

```swift
@MainActor
final class PulseViewModelTests: XCTestCase {
    var sut: PulseViewModel!
    var mockMoodService: MockMoodService!
    var mockQuestService: MockQuestService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mocks
        mockMoodService = MockMoodService()
        mockQuestService = MockQuestService()
        
        // Inject mocks
        ServiceContainer.shared.moodService = mockMoodService
        ServiceContainer.shared.questService = mockQuestService
        
        sut = PulseViewModel()
    }
    
    func testLoadDataPopulatesState() async {
        // Given
        let expectedMood = SimpleMoodLog(
            color: .calm,
            emoji: "=",
            date: Date()
        )
        mockMoodService.todaysLog = expectedMood
        
        // When
        sut.loadData()
        await Task.yield() // Allow async updates
        
        // Then
        XCTAssertEqual(sut.todayMoodLog?.color, .calm)
        XCTAssertNotNil(sut.todaysQuest)
    }
    
    func testSaveMoodUpdatesUI() async throws {
        // Given
        let color = SimpleMoodColor.happy
        let emoji = "=
"
        
        // When
        await sut.saveMood(color, emoji)
        
        // Then
        XCTAssertEqual(sut.todayMoodLog?.color, color)
        XCTAssertEqual(sut.todayMoodLog?.emoji, emoji)
    }
}
```

### Model Tests

Test model behavior and transformations:

```swift
final class MoodEntryTests: XCTestCase {
    func testMoodColorDisplayName() {
        // Given
        let color = SimpleMoodColor.happy
        
        // When
        let displayName = color.displayName
        
        // Then
        XCTAssertEqual(displayName, "Happy")
    }
    
    func testMoodColorHexValue() {
        // Given
        let color = SimpleMoodColor.happy
        
        // When
        let hex = color.hex
        
        // Then
        XCTAssertEqual(hex, "#FFD700")
    }
}
```

## Integration Testing

### Service Integration Tests

Test services working together:

```swift
@MainActor
final class QuestServiceIntegrationTests: XCTestCase {
    var questService: MockQuestService!
    var hobbyService: MockHobbyService!
    var pointService: MockPointService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup integrated services
        hobbyService = MockHobbyService()
        pointService = MockPointService()
        questService = MockQuestService()
        
        // Set dependencies
        hobbyService.setPointService(pointService)
        questService.setServices(
            authService: MockAuthService(),
            pointService: pointService,
            hobbyService: hobbyService
        )
    }
    
    func testQuestCompletionAwardsPoints() async throws {
        // Given
        let hobby = HobbyPresetItem(
            id: "1",
            name: "Guitar",
            category: .music,
            description: "String instrument",
            emoji: "<�"
        )
        let fact = "Guitars have 6 strings"
        let userId = "test-user"
        
        // When
        try await questService.markDone(hobby: hobby, fact: fact)
        
        // Then
        let points = await pointService.total(for: userId)
        XCTAssertEqual(points, 6) // 5 for hobby + 1 for quest
        
        let hobbies = await hobbyService.allHobbies()
        XCTAssertEqual(hobbies.count, 1)
        XCTAssertEqual(hobbies.first?.fact, fact)
    }
}
```

### Chat Service Tests

Test chat functionality:

```swift
@MainActor
final class ChatServiceTests: XCTestCase {
    var sut: MockChatService!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = MockChatService()
        sut.setAuthService(MockAuthService())
    }
    
    func testSendMessageCreatesAndReturnsMessage() async throws {
        // Given
        let threadID = "thread-1"
        let messageText = "Hello, Mom!"
        
        // When
        let message = try await sut.sendMessage(threadID: threadID, text: messageText)
        
        // Then
        XCTAssertEqual(message.text, messageText)
        XCTAssertEqual(message.threadID, threadID)
        XCTAssertFalse(message.isRead)
    }
}
```

## UI Testing

### SwiftUI View Tests

Test view behavior using ViewInspector or snapshot tests:

```swift
final class MoodWheelViewTests: XCTestCase {
    func testMoodWheelDisplaysColors() throws {
        // Given
        let view = ColorWheelView(
            selectedColor: .constant(.happy),
            selectedEmoji: .constant(nil),
            onSave: { _, _ in }
        )
        
        // When rendered
        let hostingController = UIHostingController(rootView: view)
        
        // Then
        XCTAssertNotNil(hostingController.view)
        // Add ViewInspector or snapshot assertions
    }
}
```

### Navigation Flow Tests

Test complete user flows:

```swift
final class OnboardingFlowTests: XCTestCase {
    func testCompleteOnboardingFlow() async throws {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // When - Complete onboarding
        app.buttons["Get Started"].tap()
        app.buttons["I'm a Teen"].tap()
        app.buttons["Continue with Email"].tap()
        
        // Fill form
        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("test@example.com")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("password123")
        app.buttons["Sign Up"].tap()
        
        // Then - Should reach main app
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
}
```

## Mock Service Configuration

### Creating Test Doubles

```swift
@MainActor
class MockMoodService: MoodServiceProtocol {
    // Control test behavior
    var shouldFailSave = false
    var saveDelay: TimeInterval = 0
    
    // Capture test interactions
    var saveCalled = false
    var savedColor: SimpleMoodColor?
    var savedEmoji: String?
    
    // Provide test data
    var mockLogs: [SimpleMoodLog] = []
    var todaysLog: SimpleMoodLog?
    
    func save(color: SimpleMoodColor, emoji: String?) async throws {
        saveCalled = true
        savedColor = color
        savedEmoji = emoji
        
        if saveDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(saveDelay * 1_000_000_000))
        }
        
        if shouldFailSave {
            throw MoodServiceError.saveFailed
        }
        
        // Normal mock behavior
        let log = SimpleMoodLog(color: color, emoji: emoji, date: Date())
        mockLogs.append(log)
        todaysLog = log
    }
}
```

### Test Data Builders

Create builders for complex test data:

```swift
struct TestDataBuilder {
    static func makeMoodLog(
        color: SimpleMoodColor = .happy,
        emoji: String? = "=
",
        date: Date = Date()
    ) -> SimpleMoodLog {
        SimpleMoodLog(
            id: UUID().uuidString,
            userId: "test-user",
            color: color,
            emoji: emoji,
            date: date
        )
    }
    
    static func makeQuest(
        title: String = "Test Quest",
        kind: Quest.Kind = .shareHobby
    ) -> Quest {
        Quest(
            id: UUID(),
            title: title,
            description: "Test description",
            kind: kind
        )
    }
    
    static func makeChatThread(
        otherUserName: String = "Mom"
    ) -> ChatThread {
        ChatThread(
            id: UUID().uuidString,
            participants: ["user-1", "user-2"],
            participantNames: ["Teen", otherUserName],
            lastMessage: "Hello!",
            lastMessageTime: Date(),
            unreadCount: 1
        )
    }
}
```

## Testing Best Practices

### 1. Test Naming

Use descriptive names following the pattern: `test_[condition]_[expectedResult]`

```swift
// Good
func testSaveMoodWithEmptyEmoji_SavesSuccessfully() { }
func testLoadQuestsWhenNotAuthenticated_ReturnsEmpty() { }
func testMarkHobbyAsSeenTwice_AwardsPointsOnlyOnce() { }

// Bad
func testMood() { }
func test1() { }
```

### 2. Arrange-Act-Assert

Structure tests clearly:

```swift
func testExample() async throws {
    // Arrange - Set up test conditions
    let service = MockService()
    let expectedValue = "test"
    
    // Act - Perform the action
    let result = try await service.performAction()
    
    // Assert - Verify the outcome
    XCTAssertEqual(result, expectedValue)
}
```

### 3. Test Isolation

Each test should be independent:

```swift
override func setUp() async throws {
    try await super.setUp()
    // Fresh setup for each test
    realm = try createInMemoryRealm()
    service = MockService()
}

override func tearDown() async throws {
    // Clean up
    realm = nil
    service = nil
    try await super.tearDown()
}

private func createInMemoryRealm() throws -> Realm {
    let config = Realm.Configuration(
        inMemoryIdentifier: UUID().uuidString,
        schemaVersion: 2
    )
    return try Realm(configuration: config)
}
```

### 4. Async Testing

Handle async code properly:

```swift
func testAsyncOperation() async throws {
    // Use async/await
    let result = try await service.fetchData()
    XCTAssertFalse(result.isEmpty)
}

func testPublisher() async {
    // Use AsyncPublisher
    var receivedValues: [String] = []
    
    for await value in service.valuePublisher.values {
        receivedValues.append(value)
        if receivedValues.count == 3 { break }
    }
    
    XCTAssertEqual(receivedValues.count, 3)
}
```

### 5. Error Testing

Test both success and failure paths:

```swift
func testSaveFailsWithNetworkError() async {
    // Given
    mockService.shouldFailWithError = NetworkError.timeout
    
    // When/Then
    do {
        try await mockService.save(data)
        XCTFail("Expected error but succeeded")
    } catch NetworkError.timeout {
        // Expected error
    } catch {
        XCTFail("Wrong error type: \(error)")
    }
}
```

## Test Coverage

### Current Coverage Goals

- **Services**: >90% coverage
- **ViewModels**: >80% coverage  
- **Models**: >95% coverage
- **Views**: Critical paths tested

### Running Coverage Reports

```bash
# Generate coverage report
xcodebuild test -scheme Peachy \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES

# View in Xcode
# Product � Show Build Folder � Products � Coverage
```

## Continuous Integration

### GitHub Actions Configuration

```yaml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.app
      
    - name: Run tests
      run: |
        xcodebuild test \
          -scheme Peachy \
          -destination 'platform=iOS Simulator,name=iPhone 15' \
          -resultBundlePath TestResults
          
    - name: Upload results
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: TestResults.xcresult
```

## Performance Testing

### Measure Critical Operations

```swift
func testMoodSavePerformance() throws {
    let service = MockMoodService()
    
    measure {
        let expectation = expectation(description: "Save completes")
        
        Task {
            try await service.save(color: .happy, emoji: "=
")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
```

## Debugging Tests

### Common Issues

1. **Realm Thread Errors**: Ensure `@MainActor` usage
   ```swift
   @MainActor
   final class TestClass: XCTestCase { }
   ```

2. **Async Timing**: Use `Task.yield()` or expectations
   ```swift
   await Task.yield() // Allow state updates
   ```

3. **Mock State**: Reset mocks in `setUp`
   ```swift
   mockService.reset()
   ```

4. **Memory Leaks**: Check for retain cycles
   ```swift
   weak var weakSut = sut
   // Test...
   XCTAssertNil(weakSut)
   ```

### Debugging Tools

```swift
// Add breakpoints in tests
func testDebugging() async {
    let service = MockService()
    
    // Set breakpoint here
    debugPrint("Service state: \(service)")
    
    let result = await service.fetchData()
    
    // Inspect result
    XCTAssertFalse(result.isEmpty)
}
```

## Test Maintenance

### Keep Tests Updated

- Update tests when requirements change
- Remove obsolete tests
- Refactor tests with production code
- Document complex test scenarios

### Test Review Checklist

- [ ] Test covers the requirement
- [ ] Test name is descriptive
- [ ] Test is isolated
- [ ] Test is deterministic
- [ ] Test runs quickly
- [ ] Test failure message is clear
- [ ] No hardcoded delays
- [ ] Proper async handling
- [ ] Memory management checked
- [ ] Edge cases covered