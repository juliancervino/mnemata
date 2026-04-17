# Testing Patterns

**Analysis Date:** 2026-04-04

## Test Framework

**Runner:**
- `flutter_test` (declared in `pubspec.yaml` under `dev_dependencies`).
- Mocking uses `mocktail` (`pubspec.yaml`, examples in `test/features/ingestion/services/share_service_test.dart`).
- No standalone Jest/Vitest-like config files detected; testing is Flutter-native.

**Assertion Library:**
- `expect`/matchers from `package:flutter_test/flutter_test.dart`.

**Run Commands:**
```bash
flutter test                               # Run full test suite
flutter test test/features/ingestion/services/share_service_test.dart   # Run one test file
flutter test --coverage                    # Generate coverage/lcov output
```

## Test File Organization

**Location:**
- Tests live under top-level `test/` and mostly mirror feature paths in `lib/`.
- Examples: `test/core/database/app_database_test.dart`, `test/features/chronological_list/presentation/item_list_screen_test.dart`.

**Naming:**
- Uses `*_test.dart` suffix consistently.

**Structure:**
```text
test/
  core/database/*_test.dart
  features/<feature>/<layer>/*_test.dart
  widget_test.dart
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  late AppDatabase database;

  setUpAll(() { /* platform setup */ });
  setUp(() { /* fresh test state */ });
  tearDown(() async { /* cleanup */ });

  test('...', () async { /* assertions */ });
  testWidgets('...', (tester) async { /* widget assertions */ });
}
```

**Patterns:**
- `setUpAll` frequently configures Linux sqlite shared library loading (`test/core/database/app_database_test.dart`, `test/widget_test.dart`).
- `setUp` builds isolated in-memory DB state using `AppDatabase.forTesting(NativeDatabase.memory())`.
- Widget tests use `pumpWidget` + `pumpAndSettle` then verify with `find` matchers.

## Mocking

**Framework:**
- `mocktail` with `class X extends Mock implements Y` pattern.

**Patterns:**
```dart
class MockExtractionService extends Mock implements ExtractionService {}

when(() => mockExtractionService.extractContent(url))
  .thenAnswer((_) async => (title: 'A', content: 'B', thumbnailUrl: null));

verify(() => mockExtractionService.extractContent(url)).called(1);
verifyNever(() => mockExtractionService.extractContent(any()));
```

**What to Mock:**
- External/service boundaries and UI navigation (`ExtractionService`, `PdfExtractionService`, `NavigatorState`) in `test/features/ingestion/services/share_service_test.dart`.

**What NOT to Mock:**
- Core DB behaviors are tested against real in-memory Drift+SQLite, not mocked (`test/core/database/app_database_test.dart`).

## Fixtures and Factories

**Test Data:**
```dart
await database.insertItem(MnemataItemsCompanion.insert(
  title: const Value('Apple'),
  type: 'url',
  createdAt: DateTime.now(),
));
```

**Location:**
- Inline data builders inside each test file are primary pattern.
- Dedicated shared fixture/factory usage is not detected in sampled tests.

## Coverage

**Requirements:**
- No enforced minimum threshold detected in project config.
- Coverage artifacts are expected to be local-only (`/coverage/` ignored in `.gitignore`).

**View Coverage:**
```bash
flutter test --coverage
# then inspect coverage/lcov.info with preferred tooling
```

## Test Types

| Type | Current Usage | Representative Files |
|---|---|---|
| Unit/service | Strong in ingestion and DB logic | `test/features/ingestion/extraction_service_test.dart`, `test/features/ingestion/services/archive_content_processor_test.dart`, `test/core/database/app_database_test.dart` |
| Widget | Present for main list and app smoke | `test/features/chronological_list/presentation/item_list_screen_test.dart`, `test/widget_test.dart` |
| Integration | Enforced for Reliability phases | `test/features/backup/cloud_to_restore_integration_test.dart`, `test/main_startup_test.dart` |

## Reliability Standards (v1.1 Handoff)

Starting with milestone v1.1, all "Reliability" and "Sync" features must adhere to the following standards:

1. **Deterministic Integration Coverage:** Features involving cloud providers, background scheduling, or multi-service choreography must include integration tests that verify the full "round-trip" (e.g., `cloud_to_restore_integration_test.dart`).
2. **Safety Rejection Assertions:** Restore or import logic must explicitly test for corrupted or malformed payloads, asserting that live data remains untouched (all-or-nothing guarantees).
3. **Traceability Artifacts:** Every phase must output a summary file that maps implemented requirements to specific test paths or manual verification screenshots.
4. **Startup Guarding:** Critical startup sequences (like share listeners) must be protected by tests verifying their initialization order relative to non-blocking background services.

## Common Patterns

**Async Testing:**
```dart
final result = await service.extractContent(url);
expect(result, isNotNull);
```

**Error/edge-path Testing:**
```dart
await duplicateService.handleUrl(incomingUrl);
verifyNever(() => mockExtractionService.extractContent(any()));
```

## Coverage Posture and Gaps

- Best-covered areas: share ingestion flows and Drift persistence/search behavior (`test/features/ingestion/services/share_service_test.dart`, `test/core/database/app_database_test.dart`).
- Partially covered: UI behavior of main list/search interactions (`test/features/chronological_list/presentation/item_list_screen_test.dart`).
- Gaps: settings flows, organization label manager behavior, and reader screens (`lib/features/settings/presentation/settings_screen.dart`, `lib/features/organization/presentation/label_manager_screen.dart`, `lib/features/reader/presentation/reader_screen.dart`).
- Gaps: end-to-end cross-platform share-intent behavior is simulated rather than device-level validated.

---

*Testing analysis: 2026-04-04*
