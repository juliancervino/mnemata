# Architecture

**Analysis Date:** 2026-04-04

## Pattern Overview

**Overall:** Feature-first modular monolith with layered responsibilities (presentation -> services -> persistence).

**Key Characteristics:**
- Use `lib/features/*/presentation/` for UI state and interaction orchestration.
- Use `lib/features/*/services/` for extraction, ingestion, parsing, and platform-integration logic.
- Centralize persistence and query logic in `lib/core/database/app_database.dart` with Drift streams and SQL helpers.

## Layers

| Layer | Purpose | Location | Depends on | Used by |
| --- | --- | --- | --- | --- |
| Presentation | Screens, dialogs, navigation, user interaction state | `lib/features/*/presentation/*.dart` | Flutter widgets, `GetIt`, service/database APIs | App entry and user routes |
| Services | Content extraction, share-intent orchestration, file/pdf processing | `lib/features/ingestion/services/*.dart`, `lib/features/settings/services/settings_service.dart` | HTTP/WebView/readability libs, database, navigator key | Presentation layer and bootstrap |
| Persistence | SQLite schema, migrations, FTS index, CRUD/query streams | `lib/core/database/app_database.dart`, `lib/core/database/tables.dart`, `lib/core/database/tables.drift` | Drift/SQLite | All features |
| Utilities | Shared cross-feature helpers (share formatting) | `lib/core/utils/share_utils.dart` | `share_plus`, database model types | List and reader presentation |

## Data Flow

**Flow: Share Intent Ingestion (URL/File)**
1. `lib/main.dart` boots and registers `ShareService`, then calls `ShareService.init()`.
2. `lib/features/ingestion/services/share_service.dart` listens to `ReceiveSharingIntent` stream and initial payload.
3. `ShareService` performs duplicate checks via `AppDatabase` (`getItemByCanonicalUrl`, `getItemByFilePath`).
4. URL path uses `ExtractionService`; archive/JS-blocked pages route to WebView-based extractors.
5. `lib/features/ingestion/presentation/ingestion_summary_screen.dart` confirms metadata and labels, then writes item + label links.

**Flow: Browse and Read**
1. `lib/features/chronological_list/presentation/item_list_screen.dart` subscribes to Drift streams (`watchAllItems`, `searchItems`, label filters).
2. Opening URL items navigates to `lib/features/reader/presentation/reader_screen.dart`.
3. Opening file items delegates to platform launcher via `open_filex`.
4. Read/open actions update recency through `AppDatabase.updateLastOpenedAt`.

**Flow: Label Management**
1. Label CRUD happens in `lib/features/organization/presentation/label_manager_screen.dart`.
2. Assignment paths use `label_selector_sheet.dart`, `item_editor_screen.dart`, and `ingestion_summary_screen.dart`.
3. Persistence uses `Labels` and `ItemLabels` tables with many-to-many mapping in `app_database.dart`.

**State Management:**
- Widget-local state (`StatefulWidget`, controllers, `setState`) in presentation screens.
- Reactive data state through Drift streams (`StreamBuilder`) from `AppDatabase`.
- App-wide service instances via `GetIt` singleton/lazy-singleton registration in `lib/main.dart`.

## Key Abstractions

**AppDatabase (repository + query gateway):**
- Purpose: Encapsulate schema migrations, indexes, CRUD, FTS search, sort-order updates, and label joins.
- Examples: `lib/core/database/app_database.dart`, `lib/core/database/tables.dart`, `lib/core/database/tables.drift`.
- Pattern: Single database facade consumed directly by UI/services via dependency locator.

**ShareService (ingestion orchestrator):**
- Purpose: Normalize incoming shared payloads, dedupe, and route extraction/navigation.
- Examples: `lib/features/ingestion/services/share_service.dart`.
- Pattern: Long-lived service with stream subscription lifecycle and navigation side effects.

**Content processors (specialized extraction pipelines):**
- Purpose: Transform captured HTML into readable title/content/thumbnail payloads.
- Examples: `lib/features/ingestion/services/archive_content_processor.dart`, `lib/features/ingestion/services/js_rendered_content_processor.dart`, `lib/features/ingestion/services/extraction_service.dart`.
- Pattern: Focused processors invoked by presentation/service orchestration layers.

## Entry Points

**Flutter app entry:**
- Location: `lib/main.dart`
- Triggers: Process launch.
- Responsibilities: DI registration (`GetIt`), share listener startup, root `MaterialApp` configuration.

**Primary user route:**
- Location: `lib/features/chronological_list/presentation/item_list_screen.dart`
- Triggers: `MaterialApp.home`.
- Responsibilities: Listing, filtering/search, multi-select actions, reorder, navigation drawer.

**Ingestion extractor routes:**
- Location: `lib/features/ingestion/presentation/archive_scraper_screen.dart`, `lib/features/ingestion/presentation/js_rendered_scraper_screen.dart`
- Triggers: ShareService URL heuristics for archive/JS-gated pages.
- Responsibilities: Render page in WebView, capture HTML, forward processed output to summary/save flow.

## Error Handling

**Strategy:** Local try/catch with user-facing `SnackBar` feedback and conservative fallback behavior.

**Patterns:**
- Guard clauses for null/empty payloads and existence checks before work (`share_service.dart`, `pdf_extraction_service.dart`).
- UI-level failure reporting with `ScaffoldMessenger` in ingestion, reader, and list interactions.
- Best-effort parsing fallback in extraction processors when readability/native parsing fails.

## Cross-Cutting Concerns

**Logging:**
- Use `debugPrint`/`print` for runtime diagnostics in service and extraction code (`share_service.dart`, `extraction_service.dart`).

**Validation:**
- URL parsing/normalization and duplicate detection via helper methods in `share_service.dart` and `app_database.dart`.

**Authentication:**
- Not detected in application architecture.

---

*Architecture analysis: 2026-04-04*
