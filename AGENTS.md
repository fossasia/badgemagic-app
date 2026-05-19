# Project Overview

**Badge Magic App** is a Flutter cross-platform application for designing and
programming LED badges and electronic displays. It allows users to create
custom messages and layouts using text, images, clipart, QR codes, barcodes,
and other elements, then transfer them to compatible LED badge devices.

## Tech Stack

- **Framework**: Flutter (stable channel)
- **Language**: Dart
- **State Management**: Provider pattern
- **Supported Platforms**: Android, iOS, Linux, macOS, Windows, Web

## Repository Structure

```text
badgemagic-app/
├── android/          # Android-specific platform code
├── iOS/              # iOS-specific platform code
├── linux/            # Linux-specific platform code
├── macos/            # macOS-specific platform code
├── windows/          # Windows-specific platform code
├── web/              # Web-specific platform code
├── lib/              # Code shared by all platforms
│   ├── bademagic_module/  # Core badge logic, BLE transfer, data generators
│   ├── badge_animation/   # Badge animation definitions
│   ├── badge_effect/      # Badge effect definitions
│   ├── globals/           # Global state and singletons
│   ├── providers/         # State management using Provider
│   ├── services/          # App-level services
│   ├── utils/             # Helper functions and utilities
│   ├── view/              # UI screens and widgets
│   ├── virtualbadge/      # Virtual badge preview
│   ├── l10n/              # Localization (i18n) files
│   ├── constants.dart     # Shared constants
│   └── main.dart          # App entry point
├── test/             # Unit and widget tests
├── assets/           # Images, clipart, icons, and fonts
├── .github/
│   └── workflows/    # CI/CD workflows
├── pubspec.yaml      # Dependencies and project configuration
└── README.md         # Project documentation
```

## Coding Standards

- Adhere to the coding style described in <https://dart.dev/effective-dart/style>.
- Adhere to the SOLID design principles described in <https://simple.wikipedia.org/wiki/SOLID_(object-oriented_design)>.
- Adhere to Object-Oriented Design best practices described in <http://butunclebob.com/ArticleS.UncleBob.PrinciplesOfOod>.
- Keep in mind the architecture recommendations described in <https://docs.flutter.dev/app-architecture/guide>.

## Commit Style

- Adhere to the commit style described in the file `commitStyle.md` in the `docs` folder of this project.

## UI guidelines

- The UI of the app must be consistent
- The UI of the app should adhere to the best practices for adaptive design described in <https://docs.flutter.dev/ui/adaptive-responsive/best-practices>.
