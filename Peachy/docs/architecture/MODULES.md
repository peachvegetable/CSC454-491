# Peachy Module Documentation

## Module Overview

Peachy is organized into feature modules that align with user-facing functionality. Each module follows MVVM pattern with clear separation of concerns.

## Core Modules

### <� Onboarding Module

**Purpose**: User registration and family circle setup

**Components**:
- `OnboardingFlow`: Main navigation controller
- `RolePickerView`: Teen/Parent selection
- `AuthView`: Email/Apple ID authentication
- `SignUpView`: Account creation
- `PairingView`: Family circle pairing with 6-digit codes
- `HobbyPickerView`: Interest selection

**Dependencies**:
- AuthService for authentication
- UserDefaults for onboarding state

**Key Features**:
- Role-based onboarding flow
- Mock authentication
- Circle pairing system
- Hobby preference setup

### <� Mood Signal Module

**Purpose**: Mood tracking and communication

**Components**:
- `PulseView`: Main mood dashboard
- `ColorWheelView`: Unified mood color selector
- `MoodWheelView`: Legacy mood selector (being phased out)
- `EmojiPickerSheet`: Emoji overlay selection
- `ParentDashboardView`: Parent's view of teen moods

**Services**:
- `MoodServiceProtocol`: Mood persistence
- `NotificationServiceProtocol`: Buffer notifications

**Key Features**:
- 8 mood colors with meanings
- Optional emoji overlays
- Calm buffer (5-60 minutes)
- Append-only mood logging
- History visualization

**Data Flow**:
```
User selects mood � ColorWheelView � PulseViewModel � MoodService � Realm
```

### <� Quest Module

**Purpose**: Daily challenges and engagement

**Components**:
- `QuestDetailView`: Quest details and actions
- `ShareHobbyFactSheet`: Hobby fact entry
- `QuestViewModel`: Quest state management

**Services**:
- `QuestServiceProtocol`: Quest management
- `HobbyServiceProtocol`: Hobby fact storage
- `PointServiceProtocol`: Point rewards

**Key Features**:
- Daily "Share a Hobby" quest
- 5 points for completing quest
- Automatic flash card generation
- Progress tracking

### <� Flash Cards Module

**Purpose**: Gamified learning about family hobbies

**Components**:
- `FlashCardQuizView`: Swipe-based quiz interface
- `FlashCard` model: Quiz data structure

**Services**:
- `HobbyServiceProtocol`: Flash card retrieval

**Key Features**:
- Auto-generated from hobby facts
- Swipe gestures (right = know, left = skip)
- 2 points per correct answer
- One-time point award per card
- Visual feedback animations

### =� Chat Module

**Purpose**: Family messaging system

**Components**:
- `ChatListView`: Conversation list
- `ChatView`: Message thread
- `ChatRowView`: Individual message display
- `ChatViewModel`: Message state management
- `ChatListViewModel`: Thread list management

**Services**:
- `ChatServiceProtocol`: Message persistence and retrieval

**Key Features**:
- Real-time messaging (mock)
- Read receipts
- Unread indicators
- Green gradient for parent messages
- Timestamp display

**Data Models**:
```swift
ChatThread {
    id: String
    participants: [String]
    lastMessage: String?
    lastMessageTime: Date?
    unreadCount: Int
}

ChatMessage {
    id: String
    threadID: String
    senderID: String
    text: String
    timestamp: Date
    isRead: Bool
}
```

### =� History Module

**Purpose**: Mood history and analytics

**Components**:
- `HistoryView`: Mood log timeline

**Services**:
- `MoodServiceProtocol`: Historical data
- `StreakServiceProtocol`: Streak calculations

**Key Features**:
- Chronological mood display
- Color-coded entries
- Emoji display
- Date grouping

### =d Profile Module

**Purpose**: User settings and account management

**Components**:
- `ProfileView`: User profile and settings
- `ProfileViewModel`: Profile state management

**Services**:
- `AuthServiceProtocol`: User data
- `PointServiceProtocol`: Point display

**Key Features**:
- Display name and avatar
- Total points with star icon
- Family circle code
- Settings access
- Sign out functionality

### <� Home Module

**Purpose**: Main app navigation and tab structure

**Components**:
- `ContentView`: Root view with navigation
- `TabBarView`: Bottom tab navigation
- `HomeView`: Welcome screen (currently unused)

**Navigation Structure**:
```
TabBarView
   Pulse (Mood)
   Chat
   History
   Profile
```

## Shared Components

### <� UI Components
- `ColorExtensions`: Brand colors and mood color definitions
- `ProfileDestination`: Profile navigation enum
- Various button styles and modifiers

### =' Infrastructure
- `ServiceContainer`: Dependency injection
- `AppRouter`: Navigation management
- `RealmManager`: Database access
- `DateExtensions`: Date formatting utilities

## Module Communication

### Service Dependencies
```
AuthService (root)
    �
MoodService � StreakService
    �
QuestService � HobbyService � PointService
    �
ChatService
```

### Data Flow Patterns

1. **Direct Service Access**:
   ```swift
   @StateObject private var viewModel = ViewModel()
   // ViewModel accesses services directly
   ```

2. **Publisher Subscription**:
   ```swift
   moodService.todaysLogPublisher
       .sink { [weak self] log in
           self?.updateUI(log)
       }
   ```

3. **Async/Await**:
   ```swift
   Task {
       let quests = await questService.getQuests()
       updateQuests(quests)
   }
   ```

## Module Guidelines

### Creating New Modules

1. **Structure**:
   ```
   NewFeature/
      Views/
      ViewModels/
      Models/
      Services/
   ```

2. **Dependencies**:
   - Define protocol in Domain layer
   - Implement in Data layer
   - Inject via ServiceContainer

3. **Testing**:
   - Unit tests for ViewModels
   - Integration tests for Services
   - UI tests for critical flows

### Module Best Practices

1. **Single Responsibility**: Each module handles one feature
2. **Clear Interfaces**: Use protocols for all services
3. **Minimal Dependencies**: Modules should be loosely coupled
4. **Consistent Patterns**: Follow established MVVM patterns
5. **Documentation**: Document public interfaces

## Future Modules

### =� Crisis Detection Module (Planned)
- Keyword monitoring
- SOS overlay
- Emergency resources

### > AI Coaching Module (Planned)
- CBT-based suggestions
- Mood insights
- Communication tips

### <� Achievements Module (Planned)
- Badges and rewards
- Streak tracking
- Leaderboards

### =� Media Sharing Module (Planned)
- Photo journals
- Voice messages
- Shared memories