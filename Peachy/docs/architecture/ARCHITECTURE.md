# Peachy Architecture Documentation

## Overview

Peachy follows Clean Architecture principles with MVVM presentation pattern, ensuring separation of concerns, testability, and maintainability.

## Architecture Diagram

```
                                                             
                     Presentation Layer                       
                                                     
      Views        ViewModels       Navigation       
    (SwiftUI)  �� (ObservableObject)   (AppRouter)     
                                                     
                                                             
                              �
                                                             
                      Domain Layer                            
                                                     
     Models         Protocols       Use Cases       
   (Entities)     (Interfaces)    (Business Logic)   
                                                     
                                                             
                              �
                                                             
                       Data Layer                             
                                                     
      Local          Remote           Mock           
     (Realm)       (Network)       (In-Memory)       
                                                     
                                                             
                              �
                                                             
                   Infrastructure Layer                       
                                                     
       DI          Extensions        Services        
   (Container)     (Helpers)        (Keychain)       
                                                     
                                                             
```

## Core Principles

### 1. Dependency Rule
Dependencies point inward. Inner layers know nothing about outer layers:
- Domain layer has no dependencies
- Data layer depends on Domain
- Presentation layer depends on Domain
- Infrastructure supports all layers

### 2. Dependency Injection
All dependencies are injected via:
- Constructor injection for required dependencies
- Setter injection for circular dependencies
- ServiceContainer for centralized management

### 3. Protocol-Oriented Design
Every service has a protocol interface:
```swift
@MainActor
public protocol MoodServiceProtocol {
    var todaysLog: SimpleMoodLog? { get }
    func save(color: SimpleMoodColor, emoji: String?) async throws
}
```

### 4. Thread Safety
- UI operations use `@MainActor`
- Realm operations are thread-isolated
- Async/await for concurrent operations

## Layer Responsibilities

### Presentation Layer

**Purpose**: Handle UI and user interactions

**Components**:
- **Views**: SwiftUI views, purely declarative
- **ViewModels**: State management, user action handling
- **Navigation**: AppRouter for navigation flow

**Example**:
```swift
// View
struct PulseView: View {
    @StateObject private var viewModel = PulseViewModel()
    
    var body: some View {
        // Declarative UI
    }
}

// ViewModel
@MainActor
class PulseViewModel: ObservableObject {
    @Published var todayMoodLog: SimpleMoodLog?
    private let moodService: MoodServiceProtocol
    
    func saveMood(_ color: SimpleMoodColor) async {
        try? await moodService.save(color: color, emoji: nil)
    }
}
```

### Domain Layer

**Purpose**: Business logic and entities

**Components**:
- **Models**: Core business entities
- **Protocols**: Service interfaces
- **Use Cases**: Complex business operations

**Key Models**:
- `SimpleMoodLog`: Mood tracking data
- `HobbyModel`: Hobby facts and metadata
- `ChatMessage/ChatThread`: Messaging entities
- `Quest`: Daily challenges
- `UserProfile`: User information

### Data Layer

**Purpose**: Data persistence and retrieval

**Components**:
- **Local**: RealmSwift for offline storage
- **Remote**: Network services (future)
- **Mock**: In-memory implementations

**Realm Configuration**:
```swift
@MainActor
public final class RealmManager {
    static let shared = RealmManager()
    private(set) var realm: Realm
    
    init() {
        let config = Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { migration, oldVersion in
                // Handle migrations
            }
        )
        realm = try! Realm(configuration: config)
    }
}
```

### Infrastructure Layer

**Purpose**: Cross-cutting concerns and utilities

**Components**:
- **ServiceContainer**: Dependency injection
- **Extensions**: Date, Color utilities
- **Services**: Keychain, Analytics (future)

**ServiceContainer Pattern**:
```swift
@MainActor
public final class ServiceContainer {
    static let shared = ServiceContainer()
    
    // Services with setter injection
    private let _authService: AuthServiceProtocol
    private let _moodService: MoodServiceProtocol
    
    private init() {
        // Initialize services
        _authService = MockAuthService()
        _moodService = MockMoodService()
        
        // Set dependencies after initialization
        MainActor.assumeIsolated {
            (_hobbyService as? MockHobbyService)?.setAuthService(_authService)
        }
    }
}
```

## Data Flow

### User Action � Update UI
1. User taps button in View
2. View calls ViewModel method
3. ViewModel calls Service
4. Service updates data (Realm/Network)
5. Service publishes change via Combine
6. ViewModel receives update
7. View re-renders with new state

### Example: Saving Mood
```swift
// 1. User taps mood color
MoodWheelView(onSave: { color, emoji in
    await viewModel.saveMood(color, emoji)
})

// 2. ViewModel processes
func saveMood(_ color: SimpleMoodColor, _ emoji: String?) async {
    // 3. Call service
    try? await moodService.save(color: color, emoji: emoji)
    
    // 4. Update local state
    await loadTodaysMood()
}

// 5. Service updates Realm
func save(color: SimpleMoodColor, emoji: String?) async throws {
    let log = SimpleMoodLog(color: color, emoji: emoji)
    try realm.write {
        realm.add(log)
    }
    
    // 6. Publish update
    todaysLogSubject.send(log)
}
```

## Key Patterns

### 1. Setter Injection for Circular Dependencies
```swift
class MockHobbyService: HobbyServiceProtocol {
    private var pointService: PointServiceProtocol?
    
    func setPointService(_ service: PointServiceProtocol) {
        self.pointService = service
    }
}
```

### 2. Combine Publishers for Reactive Updates
```swift
@Published var moodLogs: [SimpleMoodLog] = []
var moodLogsPublisher: AnyPublisher<[SimpleMoodLog], Never> {
    $moodLogs.eraseToAnyPublisher()
}
```

### 3. Async/Await for Concurrency
```swift
func loadData() async {
    async let mood = moodService.todaysMoodLog()
    async let quest = questService.getTodaysQuest()
    
    self.todayMoodLog = await mood
    self.todaysQuest = await quest
}
```

### 4. Realm List for Collections
```swift
class HobbyModel: Object {
    @Persisted var seenBy = RealmSwift.List<String>()
    // Not Set<String> - Realm doesn't support Set
}
```

## Testing Architecture

### Unit Testing
- Mock all external dependencies
- Test ViewModels in isolation
- Use in-memory Realm for data tests

### Integration Testing
- Test service interactions
- Verify data flow through layers
- Test navigation flows

### UI Testing
- Test critical user journeys
- Verify view states
- Test error handling

## Security Considerations

1. **Data Privacy**: All data stored locally
2. **Authentication**: Mock auth for demo
3. **Encryption**: Keychain for sensitive data
4. **Network**: HTTPS only (future)

## Performance Optimizations

1. **Lazy Loading**: Load data on demand
2. **Caching**: In-memory caches for frequently accessed data
3. **Batch Operations**: Group Realm writes
4. **Main Thread**: UI updates on main thread only

## Future Considerations

### Migration to Production
1. Replace mock services with network implementations
2. Add proper authentication (OAuth/JWT)
3. Implement real-time sync (WebSocket/Firebase)
4. Add analytics and crash reporting

### Scalability
1. Modularize into Swift packages
2. Implement proper caching strategy
3. Add offline queue for network operations
4. Implement data sync conflict resolution