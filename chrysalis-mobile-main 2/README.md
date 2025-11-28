# 🦋 Chrysalis Mobile

A Flutter-based secure messaging application with real-time chat capabilities, file sharing, and push notifications. Built with clean architecture principles and modern Flutter best practices.

## ✨ Features

### 🔐 Authentication & Security
- Secure user authentication with token-based login
- End-to-end encryption using PointyCastle
- Secure storage for sensitive data
- Device-specific key management

### 💬 Real-time Messaging
- Socket.IO-based real-time communication
- Message status tracking (sent, delivered, read)
- Typing indicators
- File attachments and media sharing
- Message persistence with SQLite

### 🔔 Push Notifications
- Firebase Cloud Messaging integration
- Local notification handling
- In-app notification overlay
- Background message processing

### 🔍 Search & Discovery
- Group search functionality
- Recent search history
- Real-time search results

### 🎨 User Interface
- Material Design 3 principles
- Custom typography (Instrument Sans, Inter)
- Responsive design with shimmer loading effects
- Dark/light theme support
- Smooth animations and transitions

## 🏗️ Architecture

The app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── app/                    # App-level configuration
├── core/                   # Shared utilities and services
│   ├── bloc/              # Global state management
│   ├── crypto_services/   # Encryption services
│   ├── network/           # HTTP and socket clients
│   ├── theme/             # UI theming
│   └── widgets/           # Reusable components
└── features/              # Feature modules
    ├── authentication/    # Login/logout functionality
    ├── chat_detail/       # Individual chat interface
    ├── homepage/          # Chat list and home screen
    ├── notifications/     # Push notification handling
    ├── search_groups/     # Group search functionality
    └── splash/            # Onboarding screens
```

Each feature follows the pattern:
- **Data Layer**: Models, remote services, repositories
- **Domain Layer**: Entities, use cases, repository interfaces
- **Presentation Layer**: BLoC state management, pages, widgets

## 🛠️ Tech Stack

### Core Framework
- **Flutter** 3.8+ - Cross-platform mobile development
- **Dart** - Programming language

### State Management
- **flutter_bloc** - Predictable state management
- **equatable** - Value equality

### Networking & Real-time
- **dio** - HTTP client with interceptors
- **socket_io_client** - Real-time communication
- **connectivity_plus** - Network connectivity monitoring

### Security & Storage
- **encrypt** - Encryption library
- **pointycastle** - Cryptographic algorithms
- **flutter_secure_storage** - Secure key-value storage
- **sqflite** - Local database

### Firebase Services
- **firebase_core** - Firebase initialization
- **firebase_messaging** - Push notifications

### UI & Assets
- **flutter_svg** - SVG rendering
- **cached_network_image** - Optimized image loading
- **shimmer** - Loading placeholders
- **file_picker** - File selection

### Development Tools
- **very_good_analysis** - Lint rules
- **flutter_dotenv** - Environment configuration
- **logger** - Logging utility

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.8 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- iOS development: Xcode (for iOS builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd chrysalis-mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup**
   - Create a `.env` file in the root directory
   - Add required environment variables (API endpoints, keys, etc.)

4. **Firebase Configuration**
   - Add `google-services.json` for Android
   - Add `GoogleService-Info.plist` for iOS
   - Configure Firebase project settings

5. **Run the application**
   ```bash
   flutter run
   ```

### Development Commands

```bash
# Run the app in debug mode
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .

# Build for production
flutter build apk          # Android
flutter build ios          # iOS
```

## 📁 Project Structure Details

### Core Services

- **DioClient**: HTTP client with authentication interceptors
- **SocketService**: Real-time communication handler
- **CryptoService**: End-to-end encryption implementation
- **LocalStorage**: Secure data persistence
- **NotificationService**: Push notification management

### Key Features Implementation

#### Authentication Flow
1. User enters credentials
2. API authentication with device fingerprinting
3. Secure token storage
4. Automatic token refresh

#### Messaging Flow
1. Real-time socket connection
2. Message encryption before sending
3. Local storage for offline access
4. Push notification for background messages

#### File Sharing
1. File selection with picker
2. Secure upload with progress tracking
3. Media preview and download
4. File type validation

## 🔧 Configuration

### Environment Variables (.env)
```bash
API_BASE_URL=your_api_endpoint
SOCKET_URL=your_socket_endpoint
ENCRYPTION_KEY=your_encryption_key
```

### Firebase Setup
1. Create a Firebase project
2. Enable Authentication and Cloud Messaging
3. Download configuration files
4. Update Firebase options in `lib/firebase_options.dart`

## 📱 Platform Support

- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Code Style
- Follow Dart/Flutter conventions
- Use the provided linting rules
- Maintain clean architecture patterns
- Document public APIs

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🐛 Known Issues

- File uploads may timeout on slow connections
- Some older Android devices may have notification issues
- iOS background refresh limitations may affect real-time updates

## 📞 Support

For support, email: [your-email@domain.com]
For bugs and feature requests, please use the GitHub issues page.

---

**Built with ❤️ using Flutter**