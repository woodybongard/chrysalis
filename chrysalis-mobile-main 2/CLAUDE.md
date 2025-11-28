# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
Chrysalis Mobile is a Flutter-based secure messaging application with cross-platform support (Android, iOS, Web). It implements Clean Architecture with BLoC pattern for state management and provides real-time messaging with end-to-end encryption.

## Essential Commands

### Development
```bash
# Run application
flutter run                    # Debug mode on connected device
flutter run -d web            # Run web version
flutter run --release         # Release mode

# Code quality
flutter analyze               # Run static analysis
dart format .                 # Format code
dart fix --apply             # Apply automatic fixes

# Dependencies
flutter pub get              # Install dependencies
flutter pub upgrade          # Update dependencies

# Clean and rebuild
flutter clean                # Clean build artifacts
flutter pub get && flutter run  # Clean start
```

### Building
```bash
# Android
flutter build apk --release   # Build APK
flutter build appbundle      # Build App Bundle for Play Store

# iOS
flutter build ios --release   # Build for iOS (requires Mac)

# Web
flutter build web            # Build for web deployment
```

### Testing
```bash
flutter test                 # Run all tests
flutter test --coverage      # Generate coverage report
flutter test test/[specific_test].dart  # Run specific test file
```

## Architecture

### Clean Architecture Layers
The codebase strictly follows Clean Architecture with three distinct layers:

1. **Data Layer** (`lib/features/*/data/`)
   - Models: DTOs for API communication
   - Remote: API service implementations using DioClient
   - Local: Database operations (Hive, SQLite)
   - Repository: Concrete implementations of domain interfaces

2. **Domain Layer** (`lib/features/*/domain/`)
   - Entities: Core business objects
   - Repository interfaces: Contracts for data layer
   - Use cases: Business logic encapsulation

3. **Presentation Layer** (`lib/features/*/presentation/`)
   - BLoCs: State management following BLoC pattern
   - Pages: Screen widgets
   - Widgets: Reusable UI components

### Core Services (`lib/core/`)
- **DioClient**: HTTP client with auth interceptors at `lib/core/dio_client.dart`
- **SocketService**: WebSocket management for real-time features at `lib/core/socket_service.dart`
- **CryptoService**: End-to-end encryption utilities
- **LocalStorage**: Secure storage abstraction using flutter_secure_storage, Hive, and SQLite

### Feature Modules
Each feature follows the same structure:
```
lib/features/[feature_name]/
├── data/
├── domain/
└── presentation/
```

Key features: authentication, homepage (chat list), chat_detail, profile, search_groups, notifications

### State Management
Uses flutter_bloc with the following patterns:
- Events trigger state changes
- BLoCs handle business logic
- States are immutable using Equatable
- Dependency injection via get_it service locator

## Development Guidelines

### Adding New Features
1. Create feature folder structure following Clean Architecture
2. Define domain entities and repository interfaces first
3. Implement data layer with models and repositories
4. Create BLoC for state management
5. Build UI components in presentation layer

### API Integration
- All API calls go through DioClient
- Authentication handled via interceptors
- Base URL and endpoints defined in respective service classes
- Error handling through custom exceptions

### Real-time Features
- Socket.IO client for WebSocket connections
- SocketService manages connection lifecycle
- Event listeners in relevant BLoCs
- Automatic reconnection handling

### Security Considerations
- End-to-end encryption for messages using PointyCastle
- Secure storage for sensitive data
- Device fingerprinting for authentication
- Firebase for push notifications

### Testing Approach
- Unit tests for use cases and repositories
- Widget tests for UI components
- BLoC tests for state management
- Integration tests for critical flows

## Environment Setup
1. Ensure `.env` file exists with required environment variables
2. Firebase configuration files must be present:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - Web Firebase config in `web/index.html`
3. Run `flutter pub get` before starting development

## Code Standards
- Follows `very_good_analysis` linting rules
- Clean Architecture principles must be maintained
- BLoC pattern for all state management
- Repository pattern for data access
- Dependency injection through get_it