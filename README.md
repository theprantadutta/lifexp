# LifeXP - Gamified Life Management Application

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org/index.html)

LifeXP is a cross-platform mobile application built with Flutter that gamifies personal productivity and life management. The application allows users to track tasks, earn experience points (XP), level up, unlock achievements, and explore a virtual world as they complete real-world activities.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Data Models](#data-models)
- [State Management](#state-management)
- [Database Layer](#database-layer)
- [Services Layer](#services-layer)
- [UI Components](#ui-components)
- [Getting Started](#getting-started)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## Overview

LifeXP combines elements of gamification with practical task and habit tracking to make personal development more engaging and rewarding. Users can categorize tasks, maintain streaks, visualize their progress through charts, and customize their experience with themes and avatars.

The app follows an offline-first approach with cloud synchronization, ensuring users can access their data even without an internet connection while keeping their information synchronized across devices.

## Features

### User Authentication
- Email/password authentication with Firebase Auth
- Guest login capability
- Profile management (name, photo)
- Email verification workflow

### Task Management
- Create, update, and complete tasks
- Categorize tasks (Health, Finance, Work, Learning, etc.)
- Set difficulty levels and due dates
- Track streaks for consistent task completion
- Earn XP rewards based on task difficulty and type

### Progress Tracking
- Daily, weekly, and monthly progress analytics
- XP gain visualization
- Streak tracking and maintenance
- Category-based breakdown of activities
- Level progression system

### Gamification Elements
- Avatar system with level progression
- Achievement unlocking system
- Virtual world exploration based on real-world progress
- Celebration animations for milestones
- Customizable themes and UI density

### Offline Support
- Full offline functionality with local database
- Automatic synchronization when online
- Conflict resolution for data consistency
- Optimistic UI updates

## Technology Stack

- **Framework**: Flutter (Dart)
- **State Management**: BLoC (Business Logic Component) Pattern
- **Database**: Drift (SQLite) for local storage
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **Animations**: Rive, Lottie, Flutter Animate
- **UI Components**: Material Design with custom gamification themes

## Architecture

LifeXP follows a clean architecture pattern with a clear separation of concerns:

```
lib/
├── data/                 # Data layer
│   ├── database/         # Local database (Drift)
│   ├── models/           # Data models
│   └── repositories/     # Data access layer
├── features/             # Feature modules
│   ├── auth/             # Authentication screens
│   ├── home/             # Home dashboard
│   ├── profile/          # User profile
│   ├── progress/         # Progress tracking and analytics
│   ├── tasks/            # Task management
│   └── world/            # Virtual world exploration
├── shared/               # Shared components
│   ├── blocs/            # Business logic components
│   ├── providers/        # Context providers
│   ├── services/         # Utility services
│   ├── themes/           # App themes and styling
│   ├── utils/            # Constants and utilities
│   └── widgets/          # Reusable UI components
├── app.dart              # Main app configuration
└── main.dart             # Application entry point
```

### Key Design Patterns
1. **BLoC Pattern**: For state management across features
2. **Repository Pattern**: To abstract data sources (local and remote)
3. **Dependency Injection**: Through constructor injection in repositories and BLoCs
4. **Offline-First**: Local database with synchronization to cloud services
5. **Service-Oriented**: Modular services for specific functionalities (notifications, animations, etc.)

## Project Structure

```
.
├── android/              # Android-specific configuration
├── assets/               # App assets (images, animations, icons)
│   ├── animations/       # Rive animation files
│   ├── icons/            # App icons
│   └── images/           # Image assets
├── ios/                  # iOS-specific configuration
├── lib/                  # Main application source code
│   ├── data/             # Data layer components
│   ├── features/         # Feature modules
│   ├── shared/           # Shared components and utilities
│   ├── app.dart          # Main application widget
│   └── main.dart         # Application entry point
├── linux/                # Linux-specific configuration
├── macos/                # macOS-specific configuration
├── web/                  # Web-specific configuration
├── windows/              # Windows-specific configuration
├── test/                 # Unit and widget tests
├── tools/                # Development tools and scripts
├── pubspec.yaml          # Project dependencies and configuration
└── README.md             # This file
```

## Data Models

### User
Represents an authenticated user with profile information and progress statistics.

Key properties:
- `id`: Unique user identifier
- `email`: User's email address
- `fullName`: User's full name
- `level`: Current level (starts at 1)
- `totalXP`: Accumulated experience points
- `currentStreak`: Current consecutive days of activity
- `longestStreak`: Longest streak achieved

### Task
Represents a user-created task that can be completed for XP rewards.

Key properties:
- `id`: Unique task identifier
- `title`: Task title
- `description`: Task description
- `type`: Task type (daily, weekly, longTerm)
- `category`: Task category (health, finance, work, etc.)
- `xpReward`: XP reward for completion
- `difficulty`: Difficulty level (1-10)
- `isCompleted`: Completion status
- `streakCount`: Consecutive completion count
- `dueDate`: Task deadline

### ProgressEntry
Tracks daily progress and analytics for user activities.

Key properties:
- `id`: Unique entry identifier
- `userId`: Associated user
- `date`: Date of entry
- `xpGained`: XP earned on this date
- `tasksCompleted`: Number of tasks completed
- `categoryBreakdown`: XP distribution by category
- `taskTypeBreakdown`: Task distribution by type
- `streakCount`: Streak count on this date

### Avatar
Represents the user's customizable avatar with attributes.

Key properties:
- `id`: Unique avatar identifier
- `userId`: Associated user
- `level`: Avatar level
- `currentXP`: Current XP in level
- `strength`: Strength attribute
- `wisdom`: Wisdom attribute
- `intelligence`: Intelligence attribute

### Achievement
Represents unlocked achievements based on user milestones.

Key properties:
- `id`: Unique achievement identifier
- `userId`: Associated user
- `title`: Achievement title
- `description`: Achievement description
- `isUnlocked`: Unlock status
- `progress`: Progress toward achievement
- `unlockedAt`: Timestamp when unlocked

## State Management (BLoC)

The application uses the BLoC pattern for state management with dedicated BLoCs for each feature:

### AuthBloc
Manages authentication state and operations:
- Handles sign up, sign in, and sign out
- Manages password reset requests
- Tracks authentication status changes
- Handles profile updates

### TaskBloc
Manages task-related operations:
- CRUD operations for tasks
- Task completion and streak management
- Task filtering and categorization

### ProgressBloc
Manages progress tracking and analytics:
- Aggregates progress data
- Calculates statistics and trends
- Manages progress visualization

### AvatarBloc
Manages avatar state and progression:
- Avatar creation and updates
- Level progression calculations
- Attribute management

### AchievementBloc
Manages achievement system:
- Achievement unlocking logic
- Progress tracking for achievements
- Achievement notifications

## Database Layer

LifeXP uses Drift (SQLite) for local data storage with a well-defined schema:

### Tables
1. **Users**: User profile information
2. **Avatars**: Avatar data and attributes
3. **Tasks**: User-created tasks
4. **Achievements**: Unlocked achievements
5. **WorldTiles**: Virtual world exploration data
6. **ProgressEntries**: Daily progress tracking

### Key Features
- Foreign key constraints for data integrity
- Indexed columns for optimized queries
- Migration support for schema updates
- Offline-first design with local persistence

## Services Layer

The application includes numerous services for cross-cutting concerns:

### Animation Services
- `CelebrationManager`: Coordinates celebration animations
- `RiveAnimationService`: Manages Rive animations
- `AnimationService`: General animation utilities

### Notification Services
- `NotificationManager`: Core notification system
- `MotivationalNotificationService`: Motivational reminders
- `StreakNotificationManager`: Streak maintenance notifications
- `AchievementNotificationManager`: Achievement notifications

### Accessibility Services
- `AccessibilityService`: General accessibility features
- `ReducedMotionService`: Reduced motion preferences
- `TextScalingService`: Text scaling adjustments
- `UIDensityService`: UI density customization

### Performance Services
- `OfflineManager`: Offline state detection
- `MemoryManagementService`: Memory optimization
- `LazyLoadingService`: Lazy loading implementation
- `PerformanceService`: Performance monitoring

### Data Services
- `FirebaseSyncService`: Cloud synchronization
- `ConflictResolutionService`: Data conflict resolution
- `OptimisticUpdateService`: Optimistic UI updates
- `OfflineDataManager`: Offline data management

## UI Components

### Themes
Multiple built-in themes:
- Light and Dark modes
- Ocean, Forest, and Sunset color schemes
- Customizable UI density
- High contrast mode for accessibility

### Navigation
- Bottom navigation bar with custom icons
- Drawer navigation for settings
- Floating action button for quick actions
- Tab-based navigation between features

### Widgets
- Progress visualization charts
- XP gain animations
- Level up celebrations
- Streak milestone indicators
- Task cards with category icons
- Avatar display components

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development
- Firebase account for backend services

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/lifexp.git
   cd lifexp
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a Firebase project at https://console.firebase.google.com/
   - Add Android and iOS apps to your Firebase project
   - Download `google-services.json` and `GoogleService-Info.plist`
   - Place them in the appropriate directories:
     - Android: `android/app/`
     - iOS: `ios/Runner/`

4. Generate Drift database code:
   ```bash
   flutter pub run build_runner build
   ```

5. Run the app:
   ```bash
   flutter run
   ```

## Development

### Code Generation
This project uses code generation for the Drift database. After making changes to the database schema, run:
```bash
flutter pub run build_runner build
```

### Code Quality
The project uses `flutter_lints` for code analysis. Run the analyzer to check for issues:
```bash
flutter analyze
```

### Adding New Features
1. Create a new feature directory in `lib/features/`
2. Implement the UI in the feature's screens directory
3. Create BLoC components in `lib/shared/blocs/` if needed
4. Add data models in `lib/data/models/` if required
5. Update repositories in `lib/data/repositories/` if needed
6. Register new BLoCs in `lib/app.dart`

## Testing

### Unit Testing
Run unit tests with:
```bash
flutter test
```

### Widget Testing
Run widget tests with:
```bash
flutter test
```

### Integration Testing
Run integration tests with:
```bash
flutter drive --target=test_driver/app.dart
```

## Deployment

### Build Process
Platform-specific builds:
```bash
# Android
flutter build apk
flutter build appbundle

# iOS
flutter build ios

# Web
flutter build web

# Desktop
flutter build linux
flutter build windows
flutter build macos
```

### Release Management
1. Update version in `pubspec.yaml`
2. Create a git tag for the release
3. Build platform-specific packages
4. Upload to respective app stores

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*LifeXP - Gamify Your Life*