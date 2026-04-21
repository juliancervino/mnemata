# Coding Conventions

**Analysis Date:** 2024-05-24

## Naming Patterns

**Files:**
- `snake_case.dart` for all Dart source files (e.g., `item_list_screen.dart`, `recycle_purge_service.dart`).

**Functions:**
- `camelCase` for methods and variables (e.g., `purgeExpired`, `settingsService`).

**Variables:**
- `camelCase` for local variables and properties. Private properties prefixed with underscore (e.g., `_nowProvider`).

**Types:**
- `PascalCase` for classes, enums, and typedefs (e.g., `RecyclePurgeService`, `AppDatabase`).

## Code Style

**Formatting:**
- Dart standard formatting (`dart format`).

**Linting:**
- `flutter_lints` is used as configured in `analysis_options.yaml`.
- Rule customization occurs in `analysis_options.yaml` (e.g., potential custom ignoring).

## Import Organization

**Order:**
1. `dart:` imports (e.g., `dart:ffi`, `dart:io`).
2. `package:` imports (e.g., `package:flutter/material.dart`, `package:drift/drift.dart`).
3. Project internal imports (e.g., `package:mnemata/...`).
4. Relative imports are rarely used; absolute `package:mnemata/` imports are preferred for project files.

**Path Aliases:**
- `package:mnemata/` is used as the base path.

## Dependency Injection

**Pattern:**
- Service Locator pattern using the `get_it` package. Services and Data stores are registered as singletons (e.g., `GetIt.instance.registerSingleton<SettingsService>`).

## Error Handling

**Patterns:**
- Try/catch blocks for asynchronous operations.
- Graceful degradation (e.g., falling back to default values if secure store reads fail).

## Logging

**Framework:** `debugPrint` from `package:flutter/foundation.dart`.

**Patterns:**
- Prefixing logs with feature context (e.g., `debugPrint('recycle_purge.completed retentionDays=...')`).
- Avoid standard `print` in production code.

## Comments

**When to Comment:**
- Clarification of domain logic, test setups, or non-obvious workarounds (e.g., platform-specific library loading).

**JSDoc/TSDoc:**
- Dartdoc standard `///` is used for public APIs, though many internal services rely on clear naming over extensive comments.

## Function Design

**Size:** Concise functions focusing on single responsibilities.

**Parameters:** Named parameters are heavily used, especially for constructors and complex methods, utilizing `required` modifier.

**Return Values:** Explicit return types are used (e.g., `Future<int>`).

## Module Design

**Exports:** 
- Explicit imports are used per file. Barrel files are not heavily utilized. 
- Folder structure dictates module boundaries (`lib/features/...`).
