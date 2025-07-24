# Peachy API Contracts

## Overview

This document defines the service protocols and API contracts used throughout the Peachy app. All services follow protocol-oriented design for testability and future backend integration.

## Core Service Protocols

### AuthServiceProtocol

**Purpose**: Handle user authentication and session management

```swift
@MainActor
public protocol AuthServiceProtocol {
    var currentUser: UserProfile? { get }
    var isAuthenticated: Bool { get }
    
    func signIn(email: String, password: String) async throws -> UserProfile
    func signInWithApple() async throws -> UserProfile
    func signUp(email: String, password: String, role: UserRole) async throws -> UserProfile
    func signOut() async throws
    func updateProfile(displayName: String) async throws
    func deleteAccount() async throws
}
```

**Error Cases**:
- `AuthError.invalidCredentials`: Wrong email/password
- `AuthError.userNotFound`: Account doesn't exist
- `AuthError.emailAlreadyInUse`: Duplicate registration
- `AuthError.networkError`: Connection issues

### MoodServiceProtocol

**Purpose**: Manage mood tracking operations

```swift
@MainActor
public protocol MoodServiceProtocol {
    var todaysLog: SimpleMoodLog? { get }
    var todaysLogPublisher: AnyPublisher<SimpleMoodLog?, Never> { get }
    
    func save(color: SimpleMoodColor, emoji: String?) async throws
    func todaysMoodLog() async -> SimpleMoodLog?
    func allLogs() async throws -> [SimpleMoodLog]
    func deleteLog(_ log: SimpleMoodLog) async throws
}
```

**Business Rules**:
- Multiple moods can be logged per day (append-only)
- Each log includes timestamp
- Optional emoji overlay
- Logs persist indefinitely

### HobbyServiceProtocol

**Purpose**: Manage hobby-related operations

```swift
@MainActor
public protocol HobbyServiceProtocol {
    func getHobbies() async throws -> [HobbyPresetItem]
    func saveHobby(name: String, fact: String) async throws
    func allHobbies() async -> [HobbyModel]
    func markHobbyAsSeen(hobbyId: ObjectId, by userId: String) async throws -> Bool
}
```

**Key Features**:
- 30+ preset hobbies available
- Facts generate flash cards automatically
- Track which users have seen each hobby
- One-time point award per hobby view

### ChatServiceProtocol

**Purpose**: Handle messaging between family members

```swift
@MainActor
public protocol ChatServiceProtocol {
    func fetchThreads() async throws -> [ChatThread]
    func fetchMessages(threadID: String) async throws -> [ChatMessage]
    func sendMessage(threadID: String, text: String) async throws -> ChatMessage
    func createThread(with userID: String) async throws -> ChatThread
    func markMessagesAsRead(threadID: String) async throws
    func deleteMessage(messageID: String) async throws
    func ensureInitialData()
}
```

**Message Flow**:
1. Create/fetch thread between users
2. Send messages to thread
3. Messages marked read on view
4. Unread count updates automatically

### QuestServiceProtocol

**Purpose**: Manage quest system and rewards

```swift
@MainActor
public protocol QuestServiceProtocol {
    func getTodaysQuest() async -> Quest?
    func markDone(hobby: HobbyPresetItem, fact: String) async throws
    func getCompletedQuests(for userId: String) async -> [QuestModel]
    func isQuestCompleted(_ quest: Quest) async -> Bool
}
```

**Quest Logic**:
- One quest per day (currently "Share a Hobby")
- Completing quest awards 5 points
- Creates flash card for family quiz
- Tracks completion history

### PointServiceProtocol

**Purpose**: Track and award points for activities

```swift
@MainActor  
public protocol PointServiceProtocol {
    func award(userId: String, delta: Int) async
    func total(for userId: String) async -> Int
}
```

**Point System**:
| Action | Points | Condition |
|--------|--------|-----------|
| Share hobby fact | 5 | Once per hobby |
| Answer flash card | 2 | Once per card per user |
| Complete daily quest | 1 | Additional to hobby points |
| 7-day mood streak | 10 | Weekly bonus |

### NotificationServiceProtocol

**Purpose**: Handle local and push notifications

```swift
public protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func scheduleBufferEndNotification(at date: Date) async
    func cancelBufferNotification() async
    func scheduleDailyReminder(at hour: Int) async
    func cancelDailyReminder() async
}
```

**Notification Types**:
- Buffer end: "Your mood is ready to share"
- Daily reminder: "Don't forget to log your mood"
- Quest available: "New quest available!"

### StreakServiceProtocol

**Purpose**: Calculate engagement metrics

```swift
@MainActor
public protocol StreakServiceProtocol {
    func calculateStreak(for userId: String) async -> Int
    func getTodayMoodCount(for userId: String) async -> Int
    func getWeeklyStats(for userId: String) async -> WeeklyStats
}
```

### AIServiceProtocol (Future)

**Purpose**: Generate content and provide coaching

```swift
public protocol AIServiceProtocol {
    func generateHobbyIntro(for hobby: String) async throws -> String
    func generateFlashCardQuestion(for fact: String) async throws -> String
    func generateCoachingTip(for mood: MoodEntry) async throws -> String
    func analyzeConversationSentiment(messages: [ChatMessage]) async throws -> SentimentScore
}
```

## Data Models

### User Models

```swift
public struct UserProfile: Identifiable, Codable {
    public let id: String
    public var email: String
    public var displayName: String
    public var role: UserRole
    public var familyCircleID: String?
    public var avatar: String?
}

public enum UserRole: String, Codable {
    case teen = "teen"
    case parent = "parent"
}
```

### Mood Models

```swift
public struct SimpleMoodLog: Identifiable {
    public let id: String
    public let userId: String
    public let color: SimpleMoodColor
    public let emoji: String?
    public let date: Date
}

public enum SimpleMoodColor: String, CaseIterable {
    case happy = "Happy"      // #FFD700
    case excited = "Excited"  // #FF6B6B
    case calm = "Calm"        // #4ECDC4
    case anxious = "Anxious"  // #9B59B6
    case sad = "Sad"          // #5DADE2
    case angry = "Angry"      // #E74C3C
    case confused = "Confused"// #F39C12
    case tired = "Tired"      // #95A5A6
}
```

### Quest Models

```swift
public struct Quest: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let kind: Kind
    
    public enum Kind: String, Codable {
        case shareHobby = "share_hobby"
        case dailyMood = "daily_mood"
        case familyChat = "family_chat"
    }
}
```

### Hobby Models

```swift
public class HobbyModel: Object {
    @Persisted(primaryKey: true) public var id: ObjectId = ObjectId()
    @Persisted public var name: String = ""
    @Persisted public var ownerId: String = ""
    @Persisted public var fact: String = ""
    @Persisted public var createdAt: Date = Date()
    @Persisted public var seenBy = RealmSwift.List<String>()
}
```

## Service Implementation Guidelines

### Mock Service Pattern

```swift
@MainActor
public final class MockMoodService: MoodServiceProtocol {
    private let realmManager = RealmManager.shared
    
    public var todaysLog: SimpleMoodLog? {
        // Implementation
    }
    
    public func save(color: SimpleMoodColor, emoji: String?) async throws {
        // Validate input
        // Save to Realm
        // Publish update
    }
}
```

### Error Handling

Services should throw appropriate errors:

```swift
enum ServiceError: LocalizedError {
    case notAuthenticated
    case invalidInput(String)
    case networkError(Error)
    case databaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be authenticated"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}
```

### Thread Safety

All UI-facing services use `@MainActor`:

```swift
@MainActor
public final class ServiceImplementation: ServiceProtocol {
    // All methods run on main thread
}
```

## Migration to Production

### Network Layer (Future)

```swift
class NetworkMoodService: MoodServiceProtocol {
    private let apiClient: APIClient
    
    func save(color: SimpleMoodColor, emoji: String?) async throws {
        let request = MoodRequest(color: color, emoji: emoji)
        try await apiClient.post("/api/moods", body: request)
    }
}
```

### Authentication (Future)

```swift
class FirebaseAuthService: AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> UserProfile {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return UserProfile(from: result.user)
    }
}
```

## Testing Contracts

### Mock Variations

Create testable mocks:

```swift
class TestMoodService: MoodServiceProtocol {
    var saveCallCount = 0
    var shouldFailSave = false
    
    func save(color: SimpleMoodColor, emoji: String?) async throws {
        saveCallCount += 1
        if shouldFailSave {
            throw ServiceError.databaseError
        }
    }
}
```

### Contract Tests

Ensure implementations match protocol:

```swift
func testServiceConformsToProtocol() {
    let service: MoodServiceProtocol = MockMoodService()
    XCTAssertNotNil(service)
}
```

## Versioning

API versions for future backend:

```swift
enum APIVersion: String {
    case v1 = "/api/v1"
    case v2 = "/api/v2"
}
```

## Security Considerations

1. **Authentication**: All requests require valid auth token
2. **Authorization**: Role-based access control
3. **Encryption**: TLS for network, Keychain for local
4. **Privacy**: Minimal data collection, local-first approach

## Performance Requirements

- Service calls should complete within 2 seconds
- Batch operations for bulk updates
- Implement caching where appropriate
- Use pagination for large datasets