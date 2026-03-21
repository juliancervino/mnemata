# Phase 1: Foundation & Ingestion - Research

**Researched:** 2024-05-24
**Domain:** Flutter Cross-Platform Ingestion & Persistence
**Confidence:** HIGH

## Summary
Phase 1 focuses on the "In" part of the app—getting data into Mnemata via native share intents and persisting it locally. The research confirms that `receive_sharing_intent_plus` is the industry standard for 2024, providing robust support for both Android and iOS. Persistence will be handled by `drift` (SQLite), utilizing the modern `drift_flutter` helper for simplified initialization and isolate handling.

**Primary recommendation:** Use `receive_sharing_intent_plus` for mobile and implement a PWA manifest with `share_target` for Web support. Ensure iOS App Groups are configured early to prevent file access issues.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `receive_sharing_intent_plus` | ^0.1.0 | Share Intent Handling | Modern fork of original plugin, maintained for 2024 compatibility. |
| `drift` | ^2.16.0 | Reactive SQLite | Best-in-class type-safe persistence for Flutter. |
| `drift_flutter` | ^0.2.0 | Drift Initialization | Simplifies `path_provider` and isolate setup (recommended for 2024). |
| `path_provider` | ^2.1.2 | File System Paths | Official Flutter tool for cross-platform paths. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|--------------|
| `path` | ^1.9.0 | Path Manipulation | Required for joining directory paths and filenames. |

**Installation:**
```bash
flutter pub add receive_sharing_intent_plus drift drift_flutter path_provider path
flutter pub add --dev drift_dev build_runner
```

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── core/
│   ├── database/
│   │   ├── app_database.dart  # Drift database definition
│   │   └── tables.dart        # Table definitions
├── features/
│   ├── ingestion/
│   │   ├── services/
│   │   │   └── share_service.dart # Handles incoming intents (Streams/Initial)
│   └── chronological_list/
│       └── presentation/
│           └── item_list_screen.dart # Chronological ListView with StreamBuilder
```

### Pattern 1: Reactive Ingestion
**What:** Incoming share intents (Files/Text) are received via Streams. Files are immediately copied to the app's permanent document directory, and metadata is inserted into Drift.
**When to use:** Crucial for iOS where files in the Share Extension container are transient and subject to deletion.

### Pattern 2: Chronological Stream
**What:** Use `(select(items)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).watch()` to provide a real-time sorted list.
**Implementation:** Use `StreamBuilder` in the UI to react to database changes automatically.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sharing | Custom platform channels | `receive_sharing_intent_plus` | Handles complex iOS Share Extension lifecycle and data passing. |
| DB Setup | Manual `LazyDatabase` | `drift_flutter` | Handles background isolates and `path_provider` boilerplate for you. |

## Common Pitfalls

### Pitfall 1: iOS Sandbox Isolation
**What goes wrong:** Shared files appear to exist but cannot be read, or the app crashes when attempting access.
**Why it happens:** iOS Share Extensions run in a different sandbox. 
**How to avoid:** 1. Configure **App Groups** in Xcode for both Runner and Extension. 2. Move files to `getApplicationDocumentsDirectory()` immediately upon receipt.

### Pitfall 2: Android Launch Mode
**What goes wrong:** A new instance of the app opens every time something is shared, losing existing state.
**How to avoid:** Set `android:launchMode="singleTask"` in `AndroidManifest.xml`.

### Pitfall 3: Stream Recreation
**What goes wrong:** The list flickers or resets every time the widget rebuilds.
**How to avoid:** Never call the database `watch()` method directly inside the `build` method. Store the stream in a variable or use a Provider.

## Code Examples

### Drift Database Setup (2024 Pattern)
```dart
@DriftDatabase(tables: [MnemataItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mnemata_db'); // drift_flutter handles the rest
  }
}
```

### Moving Shared Files (iOS/Android)
```dart
Future<void> handleSharedFile(SharedMediaFile file) async {
  final appDir = await getApplicationDocumentsDirectory();
  final newPath = p.join(appDir.path, p.basename(file.path));
  await File(file.path).copy(newPath);
  // Now save 'newPath' to Drift
}
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Flutter Test |
| Config file | `pubspec.yaml` |
| Quick run command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| REQ-01 | Receive Text Intent | Integration | `flutter drive --target=test_driver/share_text.dart` |
| REQ-02 | Persist Metadata | Unit | `flutter test test/database_test.dart` |
| REQ-03 | Sort Descending | Unit | `flutter test test/sorting_test.dart` |

## Sources
- [pub.dev/packages/receive_sharing_intent_plus](https://pub.dev/packages/receive_sharing_intent_plus)
- [drift.simonbinder.eu](https://drift.simonbinder.eu/docs/getting-started/)
- [Apple Developer: App Groups](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
