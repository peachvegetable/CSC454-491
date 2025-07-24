# CLAUDE.md - Peachy iOS App

This file provides guidance to Claude Code (claude.ai/code) when working with the Peachy iOS app codebase.

## 📚 Documentation Structure

For comprehensive documentation, see the `docs/` directory:

### Main Guide
- [`docs/README.md`](docs/README.md) - Documentation overview and navigation

### Architecture (`docs/architecture/`)
- [`ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md) - System architecture, Clean Architecture principles
- [`MODULES.md`](docs/architecture/MODULES.md) - Feature module descriptions
- [`API_CONTRACTS.md`](docs/architecture/API_CONTRACTS.md) - Service protocols and API design

### Development (`docs/development/`)
- [`SETUP.md`](docs/development/SETUP.md) - Project setup and environment guide
- [`CODING_STANDARDS.md`](docs/development/CODING_STANDARDS.md) - Swift style guide and conventions
- [`TESTING.md`](docs/development/TESTING.md) - Testing strategy and practices
- [`ROADMAP.md`](docs/development/ROADMAP.md) - Feature roadmap and release schedule

### Guides (`docs/guides/`)
- [`PERSONAL_ASSISTANT_PROMPTS.md`](docs/guides/PERSONAL_ASSISTANT_PROMPTS.md) - AI assistant integration

## Project Overview

**Peachy** is an iPhone-only SwiftUI app that bridges the parent-teen communication gap through:
- Color-coded mood updates with calm-buffer periods
- Hobby fact sharing with gamified flash cards
- Point-based reward system (5 points per hobby share, 2 per correct quiz)
- Real-time chat between family members
- Shared quests and engagement features

## Technical Stack

- **Platform**: iOS 17+ (iPhone only)
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Concurrency**: Combine + async/await with @MainActor
- **Architecture**: MVVM + Clean Architecture
  - Presentation → ViewModel → Domain → Data layers
  - Dependency injection via ServiceContainer with setter injection
- **Persistence**: 
  - @AppStorage for user preferences
  - RealmSwift for mood logs, hobbies, flash cards, and chat data
  - In-memory Realm for testing
- **Backend**: Mock services with realistic behavior (future: Firebase/Custom API)
- **AI Integration**: AIService protocol with stubs (future: OpenAI integration)

## Architecture Guidelines

See [`docs/architecture/ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md) for complete architecture documentation.

### Quick Reference
- **Architecture Pattern**: Clean Architecture + MVVM
- **Dependency Injection**: ServiceContainer with setter injection
- **State Management**: Combine + @Published properties
- **Data Persistence**: RealmSwift with @MainActor
- **Navigation**: AppRouter pattern

### Key Principles
- Strict MVVM separation: Views are declarative, ViewModels handle state/logic
- Protocol-oriented design for all services (see [`API_CONTRACTS.md`](docs/architecture/API_CONTRACTS.md))
- Mock implementations for all external dependencies
- Privacy-first: No personal data leaves device in demo version

## Feature Roadmap

### Sprint 0 - Onboarding & Foundation ✅
- Role selection (Teen/Parent)
- Mock authentication (Email/Apple ID)
- Circle pairing with code-based linking
- Profile creation with display names

### Sprint 1 - Mood Signal Core ✅
- ColorWheelView with 8 mood colors
- Emoji overlay selection
- Calm-Buffer timer (5-60 minutes configurable)
- Mood history persistence with append-only logs
- Parent dashboard with mood visualization

### Sprint 2 - Hobby Intro Cards ✅
- Multi-select hobby picker with 30+ presets
- Share a Hobby quest system
- Flash card generation from hobby facts
- Points system (5 for sharing, 2 for quiz)
- Swipe-based quiz interface

### Sprint 3 - Chat & Communication ✅
- Real-time chat between family members
- Message persistence with Realm
- Read receipts and timestamps
- Chat list with unread indicators
- Green gradient styling for parent messages

### Sprint 4+ - Advanced Features 🚧
- AI coaching with CBT tips
- Crisis detection and SOS overlay
- Voice messages and photo sharing
- Shared activity challenges
- Engagement mechanics (streaks, avatars, mood mosaics)

## UI/UX Standards

- **Colors**: Brand peach #FFC7B2, teal #2BB3B3
- **Dark Mode**: Full support required
- **Icons**: SF Symbols preferred
- **Animations**: Lottie for celebrations/confetti
- **Feedback**: Haptic feedback on key actions
- **Accessibility**: VoiceOver labels, dynamic type support

## Development Commands

```bash
# Open in Xcode (use PeachyRunner for running the app)
open PeachyRunner/PeachyRunner.xcodeproj

# Run tests
xcodebuild test -scheme Peachy -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for device
xcodebuild -scheme Peachy -configuration Release

# SwiftLint (if integrated)
swiftlint

# Clean build artifacts
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Testing Guidelines

- Unit tests for all ViewModels and Services
- UI tests for critical user flows
- Mock all external dependencies
- Aim for >80% code coverage on business logic
- See [`docs/development/TESTING.md`](docs/development/TESTING.md) for detailed testing practices

## Safety & Privacy

- No real user data in demo/development
- All AI responses are stubbed
- Parent dashboard uses local mock data
- Implement keyword detection for crisis scenarios
- SOSOverlayView for emergency resources

## Important Notes

- This is a demo/prototype - production features like real authentication, backend services, and AI integration will be added later
- Always respect teen privacy in design decisions
- Focus on empathy and positive communication patterns
- Keep UI playful but respectful of serious topics
- App icon is PeachyIcon.png (1024x1024) in PeachyRunner/Assets.xcassets

## Recent Updates

### Completed Features (Latest)
1. **Chat System**: Full implementation with ChatListView, ChatView, real-time messaging
2. **Share a Hobby Quest**: Complete flow from fact entry to flash card quiz with points
3. **Mood Logging**: Fixed to append logs instead of replacing, uses unified ColorWheelView
4. **Points System**: Awards 5 points for hobby sharing, 2 for correct quiz answers
5. **Realm Models**: HobbyModel, FlashCard, UserPoint with proper List<String> usage
6. **Service Architecture**: Fixed circular dependencies with setter injection pattern

### Known Patterns & Solutions
1. **Realm Threading**: Always use @MainActor for services accessing Realm
2. **ServiceContainer**: Use setter injection to avoid circular dependencies
3. **Realm Collections**: Use List<String> instead of Set<String> for persistable collections
4. **Parameter Passing**: Ensure all sheet/navigation parameters are non-optional
5. **Focus State**: Always bind @FocusState variables when using .focused()

## Continuous Improvement

1. **Bug Memory** – After fixing a bug you must:
   - Add/extend regression tests that would fail without the fix
   - Document the issue in the relevant section of the docs
   - Consider adding to "Common Issues" in `docs/development/SETUP.md`
   - Treat similar patterns as "known pitfalls" and avoid re-introducing them

2. **Full-Codebase Scan for New Features** – Before implementing new features:
   - Review existing models and services for reusability
   - Check naming conventions in similar modules (see `docs/architecture/MODULES.md`)
   - Follow patterns in `docs/development/CODING_STANDARDS.md`
   - Update `docs/development/ROADMAP.md` when features are completed

## Documentation-First Development

To improve code clarity and reduce context-related errors, follow these documentation practices:

1. **Inline Documentation for Complex Functions**
   - Add detailed comments explaining complex logic flows
   - Document edge cases and assumptions
   - Include "why" explanations, not just "what"
   ```swift
   // Example: This buffer prevents mood spam by ensuring a minimum
   // time gap between updates. The delay helps parents prepare
   // emotionally before seeing potentially concerning mood changes.
   ```

2. **Example Input/Output in Service Protocols**
   - Add documentation comments with usage examples
   - Show expected inputs and outputs
   ```swift
   /// Logs a mood update for the current user
   /// - Parameter mood: The mood to log
   /// - Returns: Success/failure status
   /// Example:
   ///   Input: MoodLog(color: .red, emoji: "😢", intensity: 0.8)
   ///   Output: true (success)
   ```

3. **Task-Specific Markdown Files**
   - Create focused documentation for each major feature
   - Include implementation notes, decisions, and gotchas
   - Structure: `docs/features/FEATURE_NAME.md`
   - Contents: Overview, Technical Approach, Known Issues, Future Improvements

4. **Decision Logs for Architectural Choices**
   - Document why specific patterns or libraries were chosen
   - Record trade-offs and alternatives considered
   - Create `docs/architecture/decisions/` directory
   - Use ADR (Architecture Decision Record) format:
     - Context: What prompted the decision
     - Decision: What was decided
     - Consequences: Trade-offs and impacts

## Code Maintenance Best Practices

### CRITICAL: Remove Redundant Code After Updates
1. **Always Clean Up After Refactoring**
   - Remove old implementations when creating new ones
   - Delete duplicate view definitions
   - Clear out unused helper functions
   - Example: When replacing TreeView with EnhancedTreeView, delete the old TreeView implementation

2. **Verify Single Source of Truth**
   - Each component should have only one implementation
   - No duplicate struct definitions across files
   - Check for naming conflicts before creating new types

3. **Common Issues to Avoid**
   - **Tree Game Issue**: Multiple TreeView implementations caused wrong visualization
   - **Solution**: Always search for existing implementations before creating new ones
   - Use `Grep` to check for duplicate struct names: `struct StructName`
   - Remove old implementations immediately after confirming new ones work

4. **File Organization**
   - One primary view per file
   - Helper views should be in the same file as their parent
   - Shared components go in separate files with clear naming

5. **Testing After Major Changes**
   - Verify the correct implementation is being used
   - Check for compilation warnings about ambiguous types
   - Test all affected features thoroughly