# CLAUDE.md - Peachy iOS App

This file provides guidance to Claude Code (claude.ai/code) when working with the Peachy iOS app codebase.

## Project Overview

**Peachy** is an iPhone-only SwiftUI app that bridges the parent-teen communication gap through:
- Color-coded mood updates with calm-buffer periods
- AI-generated hobby introduction cards
- Empathy-building tools and activities
- Shared quests and engagement features

## Technical Stack

- **Platform**: iOS 17+ (iPhone only)
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Concurrency**: Combine + async/await
- **Architecture**: MVVM + Clean Architecture
  - Presentation → ViewModel → Domain → Data layers
  - Dependency injection via @Environment(\.injected) or ServiceLocator
- **Persistence**: 
  - @AppStorage for user preferences
  - RealmSwift for offline mood/hobby data
- **Backend**: Mock Firebase Firestore with local JSON stubs (to be replaced later)
- **AI Integration**: AIService protocol with stubs (later OpenAI integration)

## Architecture Guidelines

### Layer Structure
```
Peachy/
├── Presentation/
│   ├── Onboarding/
│   ├── MoodSignal/
│   ├── HobbyCards/
│   ├── FlashCards/
│   ├── Chat/
│   └── Shared/
├── Domain/
│   ├── Models/
│   ├── UseCases/
│   └── Repositories/
├── Data/
│   ├── Local/
│   ├── Remote/
│   └── Mock/
└── Infrastructure/
    ├── DI/
    └── Extensions/
```

### Key Principles
- Strict MVVM separation: Views are declarative, ViewModels handle state/logic
- Protocol-oriented design for all services
- Mock implementations for all external dependencies
- Privacy-first: No personal data leaves device in demo version

## Feature Roadmap

### Sprint 0 - Onboarding & Foundation
- Role selection (Teen/Parent)
- Mock authentication (Email/Apple ID)
- Circle pairing with code-based linking

### Sprint 1 - Mood Signal Core
- MoodWheelView with color selection and emoji overlay
- Calm-Buffer timer (5-60 minutes)
- Local push notifications after buffer expires
- Parent dashboard with mood history visualization

### Sprint 2 - Hobby Intro Cards
- Multi-select hobby picker with chip UI
- AI-generated 60-word hobby introductions
- "Learn More" links opening in SafariView
- Parent-side hobby learning view

### Sprint 3+ - Advanced Features
- Flash card quiz system
- Teen-parent chat
- AI coaching with CBT tips
- Crisis detection and SOS overlay
- Shared hobby quests
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
# Open in Xcode
open Peachy.xcodeproj

# Run tests
xcodebuild test -scheme Peachy -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for device
xcodebuild -scheme Peachy -configuration Release

# SwiftLint (if integrated)
swiftlint
```

## Testing Guidelines

- Unit tests for all ViewModels and Services
- UI tests for critical user flows
- Mock all external dependencies
- Aim for >80% code coverage on business logic

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