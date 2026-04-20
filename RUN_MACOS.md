# Running Mnemata on macOS

Quick runbook for launching and stopping the app locally on macOS (Apple Silicon).

## Prerequisites

Install once:

```bash
brew install --cask flutter
brew install cocoapods
```

Xcode (full, from the App Store) is required for the macOS build. After installing it:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

Verify the toolchain:

```bash
flutter doctor
```

## First-time project setup

From the repo root:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`build_runner` regenerates Drift (SQLite) code under `lib/core/database/`. Re-run it whenever tables or `.drift` files change.

## Run the app

```bash
flutter run -d macos
```

First build takes 3-6 min (CocoaPods install + native compile). Subsequent runs are much faster.

If the window does not come to the foreground automatically, activate it manually:

```bash
osascript -e 'tell application "mnemata" to activate'
```

### Optional: Google Drive backup credentials

Pass OAuth client IDs at launch to enable cloud backup:

```bash
flutter run -d macos \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID=<client_id> \
  --dart-define=GOOGLE_OAUTH_SERVER_CLIENT_ID=<server_client_id>
```

Without them the app still runs; backup features are simply disabled.

## Hot reload / hot restart

With `flutter run` attached to your terminal:

- `r` — hot reload (keep state)
- `R` — hot restart (reset state)
- `h` — list all interactive commands
- `c` — clear screen
- `q` — quit (also stops the app)

## Stop the app

From the `flutter run` terminal, press `q`.

If the terminal is gone or the process is orphaned:

```bash
pkill -f "build/macos/Build/Products/Debug/mnemata.app"
```

## Known warnings (safe to ignore)

- `MissingPluginException` on `receive_sharing_intent/...` — the share-intent plugin is mobile-only; harmless on macOS.
- SQLite `ambiguous expansion of macro 'MIN'` and `deprecated AVKeyValueStatus` build warnings — upstream, not actionable here.

## Other platforms

- **Web** (`flutter run -d chrome`) does not currently build — `readability` uses `dart:ffi`. Web support is the goal of milestone v2.0, Phase 19.
- **iOS / Android** need their own toolchain setup (Xcode simulator runtimes, Android Studio + SDK).
