# Testing Patterns

**Analysis Date:** 2024-05-24

## Test Framework

**Runner:**
- Flutter Test (`flutter_test` package) 
- Config: Configured via standard Flutter tooling, no custom `jest` or `vitest` config.

**Assertion Library:**
- Built-in `flutter_test` assertions (`expect`, `equals`, `findsOneWidget`).

**Run Commands:**
```bash
flutter test              # Run all tests
```

## Test File Organization

**Location:**
- Replicates the `lib/` directory structure inside the `test/` directory.

**Naming:**
- Matches the source file name with `_test.dart` appended (e.g., `recycle_purge_service_test.dart` tests `recycle_purge_service.dart`).

**Structure:**
```
test/
├── features/
│   ├── chronological_list/
│   │   ├── presentation/
│   │   │   └── item_list_screen_test.dart
│   │   └── services/
│   │       └── recycle_purge_service_test.dart
├── helpers/
│   └── test_database_factory.dart
└── widget_test.dart
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  setUpAll(() {
    // Global setup, e.g., platform specific library loads
  });

  setUp(() async {
    // Per-test setup, resetting GetIt, initializing in-memory DB
  });

  tearDown(() async {
    // Cleanup, closing DB
  });

  test('description', () async {
    // Arrange
    // Act
    // Assert
  });
}
```

**Patterns:**
- `setUpAll` used for overriding native library loading (e.g., `sqlite3` for Linux).
- `setUp` used for clearing and resetting `GetIt` registry, creating fresh mock instances, and opening in-memory databases.
- `tearDown` used for closing database connections.

## Mocking

**Framework:** `mocktail` and custom fake classes.

**Patterns:**
```dart
import 'package:mocktail/mocktail.dart';

class MockSettingsService extends Mock implements SettingsService {}

// In setUp():
final mockSettingsService = MockSettingsService();
when(() => mockSettingsService.autoTagDomain).thenReturn(true);
GetIt.instance.registerSingleton<SettingsService>(mockSettingsService);
```

**What to Mock:**
- External services (`ShareService`, `ExtractionService`).
- Key-Value stores (`SharedPreferences.setMockInitialValues`).
- User settings (`SettingsService`).

**What NOT to Mock:**
- The database: Instead of mocking `AppDatabase`, tests use an in-memory SQLite instance (`AppDatabase.forTesting(NativeDatabase.memory())`).

## Fixtures and Factories

**Test Data:**
```dart
// Creating models directly via Drift companions
final id = await database.insertItem(
  MnemataItemsCompanion.insert(
    title: const Value('Old'),
    type: 'url',
    createdAt: DateTime.utc(2026, 3, 1),
  ),
);
```

**Location:**
- Helper functions located in `test/helpers/` (e.g., `test_database_factory.dart`).

## Test Types

**Unit Tests:**
- Business logic and services (e.g., `recycle_purge_service_test.dart`). Uses in-memory database and mocked dependencies.

**Widget Tests:**
- UI components (e.g., `item_list_screen_test.dart`). Tests interactions using `tester.pumpWidget()` and `tester.tap()`. Validates widget rendering and state changes.

**Integration Tests:**
- Larger flows combining multiple services or complex UI interactions, often ending with `_integration_test.dart`.

## Common Patterns

**Async Testing:**
- Standard Dart `async`/`await` pattern is used pervasively since most DB operations are asynchronous.
- For widget tests, `tester.pumpAndSettle()` and `tester.pump(const Duration(...))` are used to await animations and async state resolutions.

**Platform Differences:**
- Linux testing requires loading `libsqlite3.so.0` dynamically in `setUpAll`.
```dart
if (Platform.isLinux) {
  open.overrideFor(
    OperatingSystem.linux,
    () => DynamicLibrary.open('libsqlite3.so.0'),
  );
}
```
