# Technology Stack

**Analysis Date:** 2024-05-24

## Languages

**Primary:**
- Dart ^3.11.1 - Core application logic, UI components, state management, database schema definition

**Secondary:**
- JavaScript - Web workers for database operations (`web/drift_worker.js`)
- C/C++ - WebAssembly support for SQLite (`web/sqlite3.wasm`)
- Kotlin / Swift / C++ - Native runner code for Android, iOS/macOS, Windows/Linux

## Runtime

**Environment:**
- Flutter SDK

**Package Manager:**
- `pub` (via Flutter)
- Lockfile: `pubspec.lock` present

## Frameworks

**Core:**
- Flutter - Cross-platform UI framework

**Testing:**
- `flutter_test` - Standard Flutter testing framework
- `mocktail` ^1.0.4 - Mocking library for unit tests

**Build/Dev:**
- `build_runner` ^2.4.9 - Code generation tool
- `drift_dev` ^2.16.0 - Database schema and query generation
- `flutter_lints` ^6.0.0 - Static analysis rules
- `flutter_launcher_icons` ^0.13.1 - App icon generation

## Key Dependencies

**Critical:**
- `drift` ^2.16.0 & `drift_flutter` ^0.2.0 - SQLite ORM and reactive data layer. Crucial for the offline-first architecture.
- `sqlite3` ^2.9.4 - Native SQLite implementation (including WebAssembly support).
- `get_it` ^9.2.1 - Dependency injection and service locator.
- `http` ^1.2.0 - Core networking for external API integrations (AI providers, extraction).

**Infrastructure:**
- `google_sign_in` ^6.2.1 - OAuth authentication for cloud backups.
- `flutter_secure_storage` ^9.2.2 - Secure credential storage for API keys.
- `shared_preferences` ^2.5.5 - Lightweight local key-value storage.
- `path_provider` ^2.1.2 - File system path resolution.
- `receive_sharing_intent` ^1.8.1, `share_plus` ^10.1.2, `flutter_dropzone` ^4.2.1 - OS-level data ingestion and extraction.
- `syncfusion_flutter_pdf` ^33.1.44, `webview_flutter` ^4.10.0, `flutter_widget_from_html` ^0.15.0 - Rich content parsing and rendering.

## Configuration

**Environment:**
- Dart compile-time variables (via `--dart-define`), specifically for configurations like `GOOGLE_OAUTH_CLIENT_ID`. Web platform uses meta tags in `web/index.html`.
- User-provided API keys are configured at runtime and stored in secure storage.

**Build:**
- `pubspec.yaml` - Primary project configuration
- `build.yaml` - Build runner configuration
- `analysis_options.yaml` - Linter settings

## Platform Requirements

**Development:**
- Flutter SDK
- Android Studio / Xcode / CMake (depending on target platform)

**Production:**
- Cross-platform support for Android (min SDK 21), iOS, macOS, Windows, Linux, and Web (WASM).

---

*Stack analysis: 2024-05-24*
