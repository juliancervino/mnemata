# Technology Stack

**Analysis Date:** 2026-04-04

## Languages

**Primary:**
- Dart `>=3.11.1 <4.0.0` for app and domain logic in `lib/**/*.dart` and tests in `test/**/*.dart` (constraint in `pubspec.lock`).
- Kotlin (Android build/plugin layer) in `android/build.gradle.kts` and `android/app/build.gradle.kts`.

**Secondary:**
- Swift/Objective-C bridge surface via Flutter iOS runner in `ios/Runner/Info.plist`.
- C++ build scaffolding for desktop runners in `linux/CMakeLists.txt` and `windows/CMakeLists.txt`.
- HTML/JSON for web shell in `web/index.html` and `web/manifest.json`.

## Runtime

**Environment:**
- Flutter app runtime (project type `app`) tracked in `.metadata`.
- Flutter channel `stable` and toolchain revision recorded in `.metadata`.

**Package Manager:**
- Dart/Flutter `pub` with dependency lock in `pubspec.lock`.
- Lockfile: present (`pubspec.lock`).

## Frameworks

**Core:**
- Flutter (Material 3 UI) used from entrypoint `lib/main.dart`.
- Drift + SQLite (reactive persistence and FTS5) configured in `lib/core/database/app_database.dart`, `lib/core/database/tables.drift`, and `build.yaml`.
- GetIt for dependency injection in `lib/main.dart`.

**Testing:**
- `flutter_test` for unit/widget tests (declared in `pubspec.yaml`, test tree under `test/`).
- `mocktail` for mocking in tests (declared in `pubspec.yaml`).

**Build/Dev:**
- `build_runner` + `drift_dev` for DB code generation (`pubspec.yaml`, generated output `lib/core/database/app_database.g.dart`).
- `flutter_lints` via analyzer include in `analysis_options.yaml`.
- Android Gradle Plugin `8.11.1` and Kotlin plugin `2.2.20` in `android/settings.gradle.kts`.

## Key Dependencies

**Critical:**
- `drift` / `drift_flutter` for local DB and migrations (`lib/core/database/app_database.dart`).
- `receive_sharing_intent` for inbound share intents (`lib/features/ingestion/services/share_service.dart`).
- `readability`, `metadata_fetch`, `http`, `favicon` for article extraction (`lib/features/ingestion/services/extraction_service.dart`).
- `webview_flutter` for JS-rendered/archive fallback extraction (`lib/features/ingestion/presentation/js_rendered_scraper_screen.dart`, `lib/features/ingestion/presentation/archive_scraper_screen.dart`).

**Infrastructure:**
- `path_provider` + `path` for app document storage paths (`lib/features/ingestion/services/share_service.dart`).
- `shared_preferences` for user settings persistence (`lib/features/settings/services/settings_service.dart`).
- `share_plus`, `url_launcher`, `open_filex` for OS integrations (`lib/core/utils/share_utils.dart`, `lib/features/reader/presentation/reader_screen.dart`, `lib/features/chronological_list/presentation/item_list_screen.dart`).
- `package_info_plus` for runtime app metadata (`lib/features/settings/presentation/about_screen.dart`).

## Configuration

**Environment:**
- No `.env` files detected in repository root; runtime configuration is code/config-file driven.
- No `String.fromEnvironment(...)` or dotenv usage detected under `lib/`.

**Build:**
- Lint config: `analysis_options.yaml`.
- Drift SQLite module config (FTS5): `build.yaml`.
- Android build configs: `android/settings.gradle.kts`, `android/build.gradle.kts`, `android/app/build.gradle.kts`.
- Desktop build configs: `linux/CMakeLists.txt`, `windows/CMakeLists.txt`.
- Web shell config: `web/index.html`, `web/manifest.json`.

## Platform Requirements

**Development:**
- Flutter SDK compatible with locked constraint `flutter: ">=3.38.4"` and Dart `>=3.11.1 <4.0.0` (`pubspec.lock`).
- Android toolchain with AGP `8.11.1` and Kotlin `2.2.20` (`android/settings.gradle.kts`).
- Flutter code generation step required when schema changes: `flutter pub run build_runner build --delete-conflicting-outputs` (documented in `README.md`).

**Production:**
- Multi-platform targets are configured: Android (`android/`), iOS (`ios/`), macOS (`macos/`), Linux (`linux/`), Windows (`windows/`), Web (`web/`).
- Local/offline-first persistence target through on-device SQLite DB named `mnemata_db` (`lib/core/database/app_database.dart`).

---

*Stack analysis: 2026-04-04*