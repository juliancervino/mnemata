# Coding Conventions

**Analysis Date:** 2026-04-04

## Naming Patterns

**Files:**
- Use `snake_case.dart` for files in both app and tests (for example `lib/features/ingestion/services/share_service.dart`, `test/features/ingestion/services/share_service_test.dart`).
- Generated Drift files use `.g.dart` suffix (for example `lib/core/database/app_database.g.dart`).

**Functions:**
- Public APIs use lowerCamelCase (`setupLocator`, `extractContent`, `watchAllItems`).
- Private helpers are prefixed with `_` (`_handleUrl`, `_buildPayloadKey`, `_createPerformanceIndexes`).
- Async methods usually return `Future<T>`/`Future<void>` and are verb-first (`insertItem`, `updateItemContent`, `handleUrl`).

**Variables:**
- lowerCamelCase for locals/fields (`_searchQuery`, `mockExtractionService`, `finalContent`).
- `const`/`final` is preferred for immutability throughout services and widgets (`lib/features/ingestion/services/extraction_service.dart`, `lib/features/chronological_list/presentation/item_list_screen.dart`).

**Types:**
- Class names use PascalCase (`ShareService`, `ArchiveContentProcessor`, `ItemListScreen`).
- Stateful widget state classes use leading underscore + widget name (`_ItemListScreenState` in `lib/features/chronological_list/presentation/item_list_screen.dart`).

## Code Style

**Formatting:**
- Analyzer config includes `flutter_lints` via `analysis_options.yaml`.
- No project-specific formatter overrides detected; default Dart formatter style is used.

**Linting:**
- Lint baseline is `package:flutter_lints/flutter.yaml` (`analysis_options.yaml`).
- Local suppressions are rare and mostly in generated code (`// ignore_for_file: type=lint` in `lib/core/database/app_database.g.dart`).

## Import Organization

**Order:**
1. Dart SDK imports (`dart:async`, `dart:io`, `dart:convert`).
2. Third-party package imports (`package:flutter/...`, `package:http/http.dart`).
3. Internal package imports via `package:mnemata/...`.

**Path Aliases:**
- Internal imports consistently use package paths (`package:mnemata/core/database/app_database.dart`) instead of relative `../` traversal.

## Error Handling

**Patterns:**
- Service-layer operations use `try/catch` with graceful fallback (`extractContent` returns `null` on failure in `lib/features/ingestion/services/extraction_service.dart`).
- Database APIs often propagate exceptions directly and keep methods thin wrappers over Drift (`lib/core/database/app_database.dart`).
- UI async flows guard interactions after await using `context.mounted` checks (for example bulk delete flow in `lib/features/chronological_list/presentation/item_list_screen.dart`).

## Logging

**Framework:**
- Uses `debugPrint` for UI/service lifecycle logs and `print` in extraction/PDF service error paths.

**Patterns:**
- Diagnostic logs focus on share-intent lifecycle and extraction outcomes (`lib/features/ingestion/services/share_service.dart`, `lib/features/ingestion/services/extraction_service.dart`).
- Keep logs as operational breadcrumbs, not structured telemetry.

## Comments

**When to Comment:**
- Comments are used sparingly for non-obvious intent (dedupe semantics, SQL logic, platform sqlite override, heuristic behavior).
- Prefer concise inline comments near tricky blocks (`lib/features/ingestion/services/share_service.dart`, `lib/core/database/app_database.dart`, `test/core/database/app_database_test.dart`).

**JSDoc/TSDoc:**
- Not applicable in this Dart codebase.
- Dart doc comments (`///`) are uncommon in sampled production code.

## Function Design

**Size:**
- Service methods can be medium/large when orchestrating flows (`_handleUrl` in `lib/features/ingestion/services/share_service.dart`, `extractFromCapturedHtml` in `lib/features/ingestion/services/archive_content_processor.dart`).

**Parameters:**
- Named required parameters are used for complex inputs (`extractFromCapturedHtml({required String sourceUrl, required String rawHtml})`).
- Optional dependencies are constructor-injected to enable testing (`ExtractionService([ReadabilityWrapper? wrapper])`).

**Return Values:**
- Uses nullable returns for failure/fallback (`Future<MnemataItem?>`, `Future<...?>`).
- Uses Dart records for multi-value results in extraction paths (`({String title, String content, String? thumbnailUrl})`).

## Module Design

**Exports:**
- Modules are file-oriented with direct imports; no barrel exports detected.
- Feature-first packaging under `lib/features/*` with shared primitives in `lib/core/*`.

**Barrel Files:**
- Not detected in sampled source tree.

---

*Convention analysis: 2026-04-04*
