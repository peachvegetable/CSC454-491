# Peachy

A SwiftUI iOS app that bridges the parent-teen communication gap through color-coded mood updates and shared activities.

## Running Tests

### Unit Tests

To run the StreakService and EmojiPickerViewModel tests:

```bash
# Run all tests
swift test

# Run specific test classes
swift test --filter StreakServiceTests
swift test --filter EmojiPickerViewModelTests
```

### In Xcode

1. Open the project in Xcode
2. Press `Cmd+U` to run all tests
3. Or navigate to specific test files and click the diamond icons to run individual tests

## Sprint Features

### Sprint 0 - Foundation & Onboarding
- ✅ Welcome screen with "Get Started" flow
- ✅ Email/Apple ID sign-in (mock authentication)
- ✅ Role selection (Teen/Parent)
- ✅ Keychain persistence for auth state
- ✅ Skip pairing for now with "Pair Later" option

### Sprint 1 - Mood Signal Core
- ✅ 3-color mood wheel (Green: Good, Yellow: Okay, Red: Tough)
- ✅ Optional emoji picker after color selection
- ✅ Mood logs stored in Realm database
- ✅ Tab bar navigation (Mood, Profile)

### Sprint 2 - Profile & Engagement
- ✅ Display name and role in profile
- ✅ 6-digit pairing code generation (stub)
- ✅ Streak counter for consecutive days
- ✅ Sign out functionality

## Architecture

- **MVVM + Clean Architecture**
- **SwiftUI** for UI
- **Realm** for local persistence
- **Combine** for reactive programming
- **Mock services** for all external dependencies