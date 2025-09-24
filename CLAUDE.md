# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift/iOS application called "sleeptrain" that combines sleep tracking with Screen Time controls using NFC functionality. The app helps users manage their sleep schedule by blocking selected apps during designated sleep times and using NFC tags as "wake up" triggers.

## Development Commands

### Building and Running
- Open `sleeptrain.xcodeproj` in Xcode to build and run the project
- No Package.swift file - this is a pure Xcode project, not Swift Package Manager
- Target deployment: iOS (uses FamilyControls framework)

### Core Dependencies
- **FamilyControls**: For managing Screen Time and app blocking functionality
- **ManagedSettings**: For applying screen time restrictions
- **CoreNFC**: For NFC tag scanning functionality
- **SwiftData**: For local data persistence
- **SwiftUI**: Primary UI framework

## Architecture

### Core Structure
```
sleeptrain/
├── App/                    # Main app entry point and coordinator
├── Core/                   # Shared utilities and business logic
│   ├── Constants/          # Style guides and view constants
│   ├── Models/             # SwiftData models and error types
│   ├── Manager/            # Business logic managers
│   └── Components/         # Reusable UI components
├── Features/               # Feature-specific views and logic
│   ├── OnBoarding/         # Multi-step onboarding flow
│   ├── Settings/           # App settings and configuration
│   └── Transit/            # Train-themed UI components
└── Resources/              # Assets and static resources
```

### Key Models and Data Flow

**UserSettings (SwiftData Model)**:
- `targetDepartureTime` / `targetArrivalTime`: Sleep schedule times
- `blockedApps`: FamilyActivitySelection for Screen Time blocking
- `isOnboardingCompleted`: Tracks first-time setup completion

**SleepRecord (SwiftData Model)**:
- Tracks sleep sessions with train journey metaphor
- `JourneyStatus`: waitingToBoard → onTrack → arrived (or delayed/cancelled)
- Links actual vs target departure/arrival times

### Core Managers

**ScreenTimeManager**:
- Manages FamilyControls integration for app blocking
- `lockApps()`: Applies restrictions based on selected apps
- `unlockApps()`: Clears all managed settings restrictions

**NFCManager**:
- Handles NFC tag scanning for wake-up functionality
- Looks for specific message payload "\u{02}enwake" to trigger unlock
- Implements NFCNDEFReaderSessionDelegate

**AuthorizationManager**:
- Manages Family Controls authorization requests
- Required for Screen Time functionality

### UI Architecture

**OnBoardingView**:
- Multi-step flow (0-6 steps) with animated transitions
- Handles: Welcome → Intro → Name → Time Setting → App Selection → NFC Setup
- Uses step-based state management with animation coordination

**Navigation**:
- Primary navigation through NavigationStack with Coordinator pattern
- Currently shows OnBoardingView as main entry point

## Key Implementation Patterns

### NFC Integration
- NFC scanning requires specific entitlements and Info.plist configuration
- Wake-up trigger looks for exact payload: "\u{02}enwake"
- Proper error handling for device support and scanning failures

### Screen Time Controls
- Requires FamilyControls framework and proper entitlements
- Uses ManagedSettingsStore for applying/removing restrictions
- FamilyActivitySelection stores user's app choices

### SwiftData Persistence
- Models use @Model macro for SwiftData integration
- ModelContainer configured in main app for UserSettings
- Supports complex data types like FamilyActivitySelection

### UI State Management
- Heavy use of @StateObject and @EnvironmentObject
- Coordinator pattern for navigation state
- Step-based onboarding with animated transitions

## Development Notes

### Common File Locations
- Main app entry: `sleeptrain/App/timeflightApp.swift`
- Core models: `sleeptrain/Core/Models/`
- Feature views: `sleeptrain/Features/[FeatureName]/`
- Reusable components: `sleeptrain/Core/Components/`

### Testing Considerations
- NFC functionality requires physical device (not simulator)
- Family Controls requires proper provisioning profile
- Screen Time features need appropriate entitlements

### Code Style
- SwiftUI-first architecture with declarative views
- Error handling through custom enum types (AuthError, NfcError, TimeRangeError)
- Train journey metaphor used throughout for sleep concepts
- Korean comments mixed with English code