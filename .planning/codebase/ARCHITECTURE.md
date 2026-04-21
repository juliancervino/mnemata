# Architecture

**Analysis Date:** 2024-05-24

## Pattern Overview

**Overall:** Feature-First (Feature Slices) Architecture

**Key Characteristics:**
- **Modular by Feature:** Code is organized by functional domain (e.g., `chronological_list`, `ingestion`, `intelligence`) rather than by technical layer (e.g., all models, all views).
- **Dependency Injection:** `get_it` is used extensively for singleton and lazy singleton management of services.
- **Reactive Data:** High usage of `Stream` and `StreamBuilder` mapping directly from the local SQLite (Drift) database to the UI.

## Layers

**Core Layer:**
- Purpose: Application-wide shared infrastructure, utilities, database setup, and generic UI components.
- Location: `lib/core/`
- Contains: Database definition (`app_database.dart`), foundational widgets (`item_card.dart`), theme configuration.
- Used by: Feature layers.

**Feature Layer - Services:**
- Purpose: Business logic, API communication, background processing, and orchestration.
- Location: `lib/features/[feature_name]/services/`
- Contains: Classes like `SummaryService`, `SemanticSearchService`, `ShareService`.
- Depends on: Core database, standard libraries, other feature services (via DI).
- Used by: Feature presentation layer.

**Feature Layer - Presentation:**
- Purpose: User interface, screen definitions, and view-specific state management.
- Location: `lib/features/[feature_name]/presentation/`
- Contains: Flutter widgets, screens (e.g., `ItemListScreen.dart`), sheets, and view components.
- Depends on: Feature services and Core widgets.

## Data Flow

**List & Read Flow:**
1. Database queries expose continuous `Stream<List<MnemataItem>>` objects.
2. `ItemListScreen` uses a `StreamBuilder` to listen to these streams.
3. UI automatically reacts and rebuilds when underlying data in Drift is modified (e.g., a background service updates a summary).

**State Management:**
- Application state (like current user query, active labels) is primarily handled using `StatefulWidget` combined with standard Flutter `setState`.
- Background tasks and long-running operations are encapsulated in injected Services.
- Global singletons (like `GlobalKey<NavigatorState>`) are managed by `GetIt`.

## Key Abstractions

**Dependency Injection:**
- Purpose: Decouples object creation from usage, allowing easier testing and modularity.
- Examples: `getIt.registerLazySingleton<AppDatabase>(() => AppDatabase())`
- Pattern: Service Locator (via `get_it`).

**Database Access:**
- Purpose: Type-safe SQL querying and reactive streams.
- Examples: `lib/core/database/app_database.dart`
- Pattern: Active Record / DAO hybrid through the `drift` package.

## Entry Points

**Application Start:**
- Location: `lib/main.dart`
- Triggers: OS launch
- Responsibilities: Initializes Flutter bindings, sets up DI locator (`setupLocator()`), fires startup background tasks (e.g., `BackupSchedulerService`, `ShareService`), and runs the root `MyApp` widget.

**Item List:**
- Location: `lib/features/chronological_list/presentation/item_list_screen.dart`
- Triggers: Default home screen routing.
- Responsibilities: Displays primary list, handles search, tag filtering, and delegates to item detail/reader views.

## Error Handling

**Strategy:** Pragmatic try-catch blocks with UI feedback.

**Patterns:**
- Standard asynchronous `try/catch` wrapping API or file system calls.
- User-facing errors are surfaced via `ScaffoldMessenger.of(context).showSnackBar()`.
- Background initialization errors (e.g., recycle purge failure) are swallowed/logged with `debugPrint`.

## Cross-Cutting Concerns

**Logging:** Standard `debugPrint` or simple `print` for non-critical developer output.
**Authentication:** Delegated to `GoogleDriveAuthClient` or specific API key stores (`ApiKeyStore`).
**Theming:** Centralized in `lib/core/theme/app_theme.dart` supporting both light and dark mode automatically via `ThemeMode.system`.

---

*Architecture analysis: 2024-05-24*