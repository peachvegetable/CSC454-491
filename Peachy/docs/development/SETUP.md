# Peachy Development Setup Guide

## Prerequisites

### System Requirements
- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **iOS Deployment Target**: iOS 17.0+

### Required Tools
- Git for version control
- Swift Package Manager (included with Xcode)
- (Optional) SwiftLint for code linting
- (Optional) Sourcery for code generation

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/peachy.git
cd peachy
```

### 2. Open the Project

The project uses PeachyRunner as the main executable target:

```bash
open PeachyRunner/PeachyRunner.xcodeproj
```

### 3. Install Dependencies

The project uses Swift Package Manager. Dependencies will be automatically resolved when you open the project in Xcode.

Current dependencies:
- **RealmSwift**: Local database for mood logs, hobbies, and chat data
- **Lottie** (future): Animation framework
- **ViewInspector** (tests only): SwiftUI testing

### 4. Configure the Development Environment

#### Set up the app icon:
The app icon is located at:
```
PeachyRunner/PeachyRunner/Assets.xcassets/AppIcon.appiconset/
```

#### Configure signing (for device testing):
1. Select the PeachyRunner project in Xcode
2. Go to Signing & Capabilities tab
3. Select your development team
4. Xcode will automatically manage provisioning profiles

## Project Structure

```
Peachy/
   Sources/
      PeachyApp/
          PeachyApp.swift          # App entry point
          ContentView.swift        # Root view
          Presentation/            # UI layer (Views & ViewModels)
          Domain/                  # Business logic & models
          Data/                    # Data layer (Local, Remote, Mock)
          Infrastructure/          # DI, Navigation, Extensions
   Tests/
      PeachyAppTests/              # Unit and integration tests
   docs/                            # Project documentation
   PeachyRunner/                    # Xcode project for running the app
```

## Development Workflow

### 1. Feature Development

Create a new feature branch:
```bash
git checkout -b feature/your-feature-name
```

### 2. Code Organization

Follow the module structure:
```
Presentation/YourFeature/
   YourFeatureView.swift         # SwiftUI view
   YourFeatureViewModel.swift    # ViewModel with business logic
   Components/                   # Reusable view components
```

### 3. Service Implementation

1. Define protocol in `Domain/Protocols/`:
```swift
@MainActor
public protocol YourServiceProtocol {
    func performAction() async throws -> Result
}
```

2. Implement mock in `Data/Mock/`:
```swift
@MainActor
public final class MockYourService: YourServiceProtocol {
    func performAction() async throws -> Result {
        // Mock implementation
    }
}
```

3. Register in `ServiceContainer`:
```swift
public var yourService: YourServiceProtocol {
    _yourService
}
```

### 4. State Management

Use appropriate SwiftUI property wrappers:
```swift
struct YourView: View {
    @StateObject private var viewModel = YourViewModel()
    @State private var localState = false
    @EnvironmentObject var appState: AppState
}
```

### 5. Navigation

Use the AppRouter pattern:
```swift
enum YourDestination {
    case detail(id: String)
    case settings
}

NavigationLink(value: YourDestination.detail(id: item.id)) {
    ItemRow(item: item)
}
```

## Running the App

### Simulator

1. Select a simulator (iPhone 15 recommended)
2. Press `Cmd+R` or click the Run button
3. The app will build and launch in the simulator

### Physical Device

1. Connect your iPhone via USB
2. Select your device from the device picker
3. Ensure your device is trusted in Xcode
4. Press `Cmd+R` to build and run

### Debug Build

```bash
xcodebuild -scheme PeachyRunner -configuration Debug
```

### Release Build

```bash
xcodebuild -scheme PeachyRunner -configuration Release
```

## Testing

### Run All Tests

In Xcode:
- Press `Cmd+U` or Product � Test

Command line:
```bash
xcodebuild test -scheme Peachy -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run Specific Tests

```bash
xcodebuild test -scheme Peachy \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:PeachyAppTests/MoodServiceTests
```

### Test Coverage

Enable code coverage in scheme settings:
1. Edit scheme (Cmd+Shift+,)
2. Test � Options
3. Check "Gather coverage for all targets"

## Debugging

### Common Issues

#### 1. Build Errors

**"Cannot find type 'X' in scope"**
- Check that the file is included in the target
- Verify imports are correct
- Ensure the type is public if used across modules

**Realm Threading Errors**
- Ensure all Realm-accessing services use `@MainActor`
- Don't pass Realm objects between threads

#### 2. Runtime Crashes

**ServiceContainer Circular Dependency**
- Use setter injection pattern
- Don't access ServiceContainer.shared in service init

**Sheet Presentation Issues**
- Ensure all required parameters are non-optional
- Check that @State variables are properly initialized

### Debug Tools

#### Print Debugging
```swift
#if DEBUG
print("= [YourService] State: \(state)")
#endif
```

#### Breakpoints
- Set breakpoints by clicking line numbers
- Use symbolic breakpoints for system methods
- Add actions to log without stopping

#### View Hierarchy Debugger
- Run the app
- Debug � View Debugging � Capture View Hierarchy

#### Memory Graph Debugger
- Debug � View Debugging � Capture GPU Frame
- Check for retain cycles and memory leaks

## Code Quality

### SwiftLint Setup (Optional)

1. Install SwiftLint:
```bash
brew install swiftlint
```

2. Add build phase to Xcode:
- Select PeachyRunner target
- Build Phases � + � New Run Script Phase
- Add script:
```bash
if which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

### Code Formatting

Follow the coding standards in [CODING_STANDARDS.md](./CODING_STANDARDS.md)

Key points:
- Use consistent indentation (4 spaces)
- Follow Swift API Design Guidelines
- Keep functions under 40 lines
- Extract complex views into components

## Troubleshooting

### Clean Build

If you encounter persistent build errors:

```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean SPM cache
rm -rf .build
rm Package.resolved

# In Xcode
Product � Clean Build Folder (Cmd+Shift+K)
```

### Reset Simulator

```bash
# Reset all simulators
xcrun simctl erase all

# Or reset specific simulator
xcrun simctl erase "iPhone 15"
```

### Xcode Issues

1. Restart Xcode
2. Delete derived data
3. Reset package caches: File � Packages � Reset Package Caches
4. Restart Mac if issues persist

## Environment Variables

For future production builds, create a `.env` file:

```bash
# API Configuration
API_BASE_URL=https://api.peachy.app
API_KEY=your_api_key

# Feature Flags
ENABLE_AI_COACHING=false
ENABLE_CRASH_REPORTING=true
```

## Next Steps

1. Review [ARCHITECTURE.md](../architecture/ARCHITECTURE.md) to understand the system design
2. Check [MODULES.md](../architecture/MODULES.md) for feature-specific details
3. Read [CODING_STANDARDS.md](./CODING_STANDARDS.md) for code style guidelines
4. See [TESTING.md](./TESTING.md) for testing practices

## Support

If you encounter issues:
1. Check existing GitHub issues
2. Review troubleshooting section
3. Ask in the team Slack channel
4. Create a detailed bug report with:
   - Xcode version
   - Error messages
   - Steps to reproduce
   - Expected vs actual behavior