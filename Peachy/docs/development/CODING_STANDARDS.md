# Peachy Coding Standards

## Swift Style Guide

### Naming Conventions

#### Types and Protocols
- Use `UpperCamelCase` for types and protocols
- Protocols describing capability should end in `able`, `ible`, or `ing`
- Protocols describing a type should end in `Protocol`

```swift
// Good
protocol MoodServiceProtocol { }
class PulseViewModel { }
struct MoodEntry { }
enum MoodColor { }

// Bad
protocol MoodService { } // Should end with Protocol
class pulseViewModel { } // Should be UpperCamelCase
```

#### Variables and Functions
- Use `lowerCamelCase` for variables, functions, and enum cases
- Boolean variables should read like assertions
- Avoid abbreviations

```swift
// Good
var isQuestCompleted = false
func loadTodaysQuest() async { }
let backgroundColor = Color.white

// Bad
var questComp = false // Abbreviation
func LoadQuest() { } // Should be lowerCamelCase
```

#### Constants
- Use `lowerCamelCase` for instance constants
- Static constants can use `UpperCamelCase` if they represent a singleton-like value

```swift
// Good
static let shared = ServiceContainer()
let maximumRetryCount = 3

// Bad
let MAXIMUM_RETRY = 3 // Don't use SCREAMING_SNAKE_CASE
```

### Code Organization

#### File Structure
Each Swift file should follow this order:
1. Import statements
2. Protocol definitions (if any)
3. Main type declaration
4. Extensions

```swift
import SwiftUI
import Combine

// MARK: - Protocols
protocol ViewModelProtocol { }

// MARK: - Main Type
public struct PulseView: View {
    // Properties
    @StateObject private var viewModel = PulseViewModel()
    
    // Body
    public var body: some View { }
    
    // Private methods
    private func updateUI() { }
}

// MARK: - Extensions
extension PulseView {
    // Additional functionality
}
```

#### Property Organization
Within a type, organize properties in this order:
1. Static properties
2. Instance properties
3. Computed properties

```swift
class ExampleClass {
    // Static
    static let defaultTimeout = 30.0
    
    // Instance - Public
    public var isEnabled = true
    
    // Instance - Private
    private let service: ServiceProtocol
    
    // Computed
    var displayText: String {
        isEnabled ? "Active" : "Inactive"
    }
}
```

### SwiftUI Best Practices

#### View Composition
- Keep views small and focused
- Extract complex views into separate components
- Use view builders for conditional content

```swift
// Good
struct ContentView: View {
    var body: some View {
        VStack {
            HeaderView()
            MainContent()
            FooterView()
        }
    }
}

// Bad - Too much in one view
struct ContentView: View {
    var body: some View {
        VStack {
            // 200 lines of nested views...
        }
    }
}
```

#### State Management
- Use appropriate property wrappers:
  - `@State` for view-local state
  - `@StateObject` for view-owned reference types
  - `@ObservedObject` for externally-owned reference types
  - `@EnvironmentObject` for shared state

```swift
struct ExampleView: View {
    @State private var isPresented = false // View-local
    @StateObject private var viewModel = ViewModel() // View owns this
    @EnvironmentObject var appState: AppState // Shared state
    
    var body: some View {
        // View implementation
    }
}
```

#### Modifiers Order
Apply modifiers in a consistent order:
1. Content modifiers (padding, background)
2. Layout modifiers (frame, position)
3. Visual effects (shadow, blur)
4. Event handlers (onTapGesture, onAppear)

```swift
Text("Hello")
    .padding()                    // Content
    .background(Color.blue)       // Content
    .frame(width: 200)           // Layout
    .shadow(radius: 5)           // Visual
    .onTapGesture { }           // Event
```

### Concurrency

#### Async/Await
- Prefer async/await over completion handlers
- Mark functions that update UI with `@MainActor`
- Handle errors appropriately

```swift
// Good
@MainActor
func loadData() async {
    do {
        let data = try await service.fetchData()
        self.items = data
    } catch {
        self.errorMessage = error.localizedDescription
    }
}

// Avoid
func loadData(completion: @escaping (Result<[Item], Error>) -> Void) {
    // Completion handler pattern
}
```

#### Combine
- Use `@Published` for observable properties
- Clean up subscriptions with `AnyCancellable`
- Prefer operators over imperative code

```swift
class ViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var items: [Item] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performSearch(text)
            }
            .store(in: &cancellables)
    }
}
```

### Architecture Patterns

#### MVVM Guidelines
- Views should be purely declarative
- ViewModels handle all business logic
- No direct data access from Views

```swift
// Good - Clean separation
struct ItemView: View {
    @StateObject private var viewModel = ItemViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task {
            await viewModel.loadItems()
        }
    }
}

@MainActor
class ItemViewModel: ObservableObject {
    @Published var items: [Item] = []
    private let service: ItemServiceProtocol
    
    func loadItems() async {
        items = await service.fetchItems()
    }
}
```

#### Dependency Injection
- Use constructor injection for required dependencies
- Use property injection for optional dependencies
- Avoid accessing `ServiceContainer.shared` during initialization

```swift
// Good
class ExampleService {
    private let authService: AuthServiceProtocol
    private var logger: LoggerProtocol?
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    func setLogger(_ logger: LoggerProtocol) {
        self.logger = logger
    }
}

// Bad - Circular dependency risk
class ExampleService {
    private let authService = ServiceContainer.shared.authService // Don't do this
}
```

### Error Handling

#### Error Types
Define clear error types for each module:

```swift
enum MoodServiceError: LocalizedError {
    case invalidMoodData
    case saveFailed(underlying: Error)
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidMoodData:
            return "Invalid mood data provided"
        case .saveFailed(let error):
            return "Failed to save mood: \(error.localizedDescription)"
        case .notAuthenticated:
            return "User must be authenticated"
        }
    }
}
```

#### Error Propagation
- Use `throw` for recoverable errors
- Use `Result` for async operations without async/await
- Log errors appropriately

```swift
func saveMood(_ mood: MoodEntry) async throws {
    guard isAuthenticated else {
        throw MoodServiceError.notAuthenticated
    }
    
    do {
        try await database.save(mood)
    } catch {
        Logger.error("Failed to save mood: \(error)")
        throw MoodServiceError.saveFailed(underlying: error)
    }
}
```

### Testing Standards

#### Unit Test Structure
Follow the Arrange-Act-Assert pattern:

```swift
func testSaveMoodSucceeds() async throws {
    // Arrange
    let mood = MoodEntry(color: .happy, emoji: "=
")
    let service = MockMoodService()
    
    // Act
    try await service.save(mood)
    
    // Assert
    let saved = await service.todaysLog()
    XCTAssertEqual(saved?.color, .happy)
    XCTAssertEqual(saved?.emoji, "=
")
}
```

#### Test Naming
Use descriptive test names that explain what is being tested:

```swift
// Good
func testMarkQuestCompleteAwardsPoints() { }
func testEmptyFactDisablesMarkDoneButton() { }

// Bad
func testQuest() { }
func test1() { }
```

#### Mock Objects
Create focused mocks for testing:

```swift
class MockAuthService: AuthServiceProtocol {
    var currentUser: User?
    var signInCalled = false
    var signInError: Error?
    
    func signIn(email: String, password: String) async throws -> User {
        signInCalled = true
        if let error = signInError {
            throw error
        }
        return currentUser ?? User(id: "test", email: email)
    }
}
```

### Documentation

#### Code Comments
- Use `///` for public API documentation
- Use `//` for implementation comments
- Document complex algorithms

```swift
/// Calculates the user's current mood streak
/// - Parameter userId: The ID of the user to check
/// - Returns: Number of consecutive days with mood logs
public func calculateStreak(for userId: String) async -> Int {
    // Get all logs sorted by date
    let logs = await fetchLogs(for: userId)
    
    // Complex streak calculation logic...
    return streakCount
}
```

#### MARK Comments
Use MARK comments to organize code:

```swift
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Actions
```

### Performance Guidelines

#### SwiftUI Performance
- Use `@StateObject` only once per object
- Avoid complex computations in body
- Use `EquatableView` for expensive views

```swift
// Good
struct ExpensiveView: View, Equatable {
    let data: ComplexData
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data.id == rhs.data.id
    }
    
    var body: some View {
        // Expensive rendering
    }
}
```

#### Memory Management
- Use `[weak self]` in closures to avoid retain cycles
- Clean up observers and subscriptions
- Avoid storing large data in memory

```swift
class ViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: .someNotification)
            .sink { [weak self] _ in
                self?.handleNotification()
            }
            .store(in: &cancellables)
    }
}
```

### Realm-Specific Guidelines

#### Thread Safety
Always use `@MainActor` for Realm services:

```swift
@MainActor
public final class MockMoodService: MoodServiceProtocol {
    private let realm = RealmManager.shared.realm
    // All operations on main thread
}
```

#### Collection Types
Use `List` instead of `Set` for Realm collections:

```swift
// Good
@Persisted var seenBy = RealmSwift.List<String>()

// Bad - Not supported by Realm
@Persisted var seenBy = Set<String>()
```

### Code Review Checklist

Before submitting PR, ensure:
- [ ] No compiler warnings
- [ ] All tests pass
- [ ] Code follows naming conventions
- [ ] Complex logic is documented
- [ ] No hardcoded values
- [ ] Error cases are handled
- [ ] Memory leaks are avoided
- [ ] UI is responsive
- [ ] Accessibility is considered
- [ ] Privacy is maintained
- [ ] Realm operations use @MainActor
- [ ] No circular dependencies in ServiceContainer