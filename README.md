<div align="center">
  <img src="assets/images/logo.png" width="128" height="128">

  # Endurain Mobile

  ![License](https://img.shields.io/github/license/joaovitoriasilva/endurain)
  [![GitHub release](https://img.shields.io/github/v/release/joaovitoriasilva/endurain)](https://github.com/joaovitoriasilva/endurain/releases)
  [![Trademark Policy](https://img.shields.io/badge/trademark-Endurain%E2%84%A2-blue)](TRADEMARK.md)

  **Mobile companion app for Endurain fitness tracking service**  
  Visit Endurain's [Mastodon profile](https://fosstodon.org/@endurain) and [Discord server](https://discord.gg/6VUjUq2uZR).

  <p>
    <i>Cross-platform mobile app for iOS, Android, and macOS</i>
  </p>
</div>

## Table of Contents

- [What is Endurain Mobile?](#what-is-endurain-mobile)
- [Current Features](#current-features)
- [Planned Features](#planned-features)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Building from Source](#building-from-source)
- [Contributing](#contributing)
- [License](#license)

## What is Endurain Mobile?

Endurain Mobile is the official companion app for [Endurain](https://github.com/joaovitoriasilva/endurain), a self-hosted fitness tracking service. Built with Flutter, it provides a native mobile experience for tracking your fitness activities while maintaining full control over your data.

The app is designed with privacy in mind, connecting directly to your self-hosted Endurain server without any third-party services or analytics.

## Current Features

✅ **Authentication**
- Secure login to your Endurain server
- Two-factor authentication (MFA) support
- Server URL configuration

✅ **Map Integration**
- Real-time location display on OpenStreetMap
- Location lock/unlock with visual indicators (filled/outline arrow icons)
- Auto-centering map when location is locked
- Configurable map tile server
- Directional compass heading indicator
- Platform-adaptive UI (Cupertino for iOS/macOS, Material for Android)

✅ **Settings**
- Server configuration management
- Map tile server customization
- Session management with secure logout

✅ **User Experience**
- Multi-language support (English, Portuguese)
- Dark/light theme support
- Offline-first architecture
- F-Droid compatible (100% FOSS dependencies)

## Planned Features

🚧 **Activity Tracking** (Coming Soon)
- Start/Stop button for recording activities
- Activity type selection (running, cycling, walking, etc.)
- Real-time GPS tracking during activities
- Activity statistics (distance, duration, pace, elevation)
- GPX file generation from recorded tracks
- Automatic upload to Endurain server upon completion
- Activity history and details view

## Tech Stack

- **Framework:** Flutter 3.38+ (Dart 3.10.3+)
- **Platforms:** iOS, Android, macOS
- **State Management:** setState (may evolve to Provider/Riverpod)
- **Map Provider:** OpenStreetMap (flutter_map + latlong2)
- **Location Services:** geolocator
- **Secure Storage:** flutter_secure_storage
- **Compass:** flutter_compass (mobile only)
- **HTTP Client:** http package for API communication

**All dependencies are open-source (FOSS) to ensure F-Droid compatibility.**

## Getting Started

### Prerequisites

- Flutter SDK 3.38 or higher
- Dart SDK 3.10.3 or higher
- Xcode (for iOS/macOS development)
- Android Studio (for Android development)
- A running Endurain server instance

### Installation

1. Clone the repository:
```bash
git clone https://github.com/joaovitoriasilva/endurain.git
cd endurain/endurain_mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate localization files:
```bash
flutter gen-l10n
```

4. Run the app:
```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android

# For macOS
flutter run -d macos
```

## Building from Source

### iOS

```bash
flutter build ios --release
```

### Android

```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### macOS

```bash
flutter build macos --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root app widget
├── core/
│   ├── constants/           # App-wide constants (API, UI, Map)
│   ├── services/            # Business logic services
│   ├── theme/               # Theme configuration
│   └── utils/               # Utility functions (validators, dialogs, platform)
├── features/
│   ├── auth/                # Authentication screens
│   ├── map/                 # Map screen and location features
│   └── settings/            # Settings screens
├── shared/
│   └── widgets/             # Shared UI components
└── l10n/                    # Localization files (en, pt)
```

## Contributing

Contributions are welcomed! This mobile app is part of the main Endurain project. Please:

1. Check the [Contributing Guidelines](CONTRIBUTING.md)
2. Open an issue to discuss changes before submitting a PR
3. Follow the existing code style and architecture patterns
4. Ensure all dependencies remain FOSS-compatible
5. Test on multiple platforms when possible

### Development Guidelines

- **Never hardcode strings** - use `AppLocalizations` (l10n)
- **Use constants** - avoid magic numbers, use files in `core/constants/`
- **Platform-adaptive UI** - use `PlatformUtils` for platform checks
- **Follow conventions** - see `.github/copilot-instructions.md`

## License

This project is licensed under the AGPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Trademark Notice

Endurain® is a trademark of João Vitória Silva.  

You are welcome to self-host Endurain and use the name and logo, including for personal, educational, research, or community (non-commercial) use.  
Commercial use of the Endurain name or logos (such as offering paid hosting, products, or services) is **not permitted without prior written permission**.

See [`TRADEMARK.md`](TRADEMARK.md) for full details.

---

<div align="center">
  <sub>Built with ❤️ using Flutter | Part of the Endurain ecosystem</sub>
</div>
