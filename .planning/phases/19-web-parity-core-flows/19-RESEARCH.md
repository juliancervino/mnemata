# Phase 19: Web Parity Core Flows - Research

**Researched:** 2026-04-18
**Domain:** Flutter web parity for ingestion, chronological list, reader, and search
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Web uses one primary "Add" entry point that supports both URL and file ingestion.
- **D-02:** Web supports drag-and-drop plus file picker for file ingestion.
- **D-03:** Duplicate handling follows mobile parity behavior: warn user and allow continuing intentionally (with an explicit existing-item path in UX).
- **D-04:** Extraction failure uses a guided fallback flow, not a silent failure.
- **D-05:** File support in Phase 19 matches current mobile support (PDF + image).
- **D-06:** Oversized file submissions are blocked with a clear message and visible size limit.
- **D-07:** After save from ingestion summary, navigate back to list and show confirmation snackbar.
- **D-08:** Ingestion summary keeps pre-save editing for title, author, and tags (mobile parity).
- **D-09:** Default list order is newest-first, consistent with current mobile semantics.
- **D-10:** Filters are exposed as horizontal chips plus a "More filters" affordance.
- **D-11:** Per-item quick actions include open reader, mark read/unread, favorite, delete, and share.
- **D-12:** Long collections use incremental pagination (infinite scroll).
- **D-13:** Returning from reader restores exact list/search/filter state.
- **D-14:** Delete flow uses modal confirmation plus snackbar undo.
- **D-15:** Multi-select bulk actions are out of scope for Phase 19.
- **D-16:** List keyboard shortcuts are out of scope for Phase 19.
- **D-17:** Reader layout on desktop web uses centered content with optional side panel (TOC/metadata).
- **D-18:** Reader actions stay in a compact sticky header.
- **D-19:** PDF flow uses embedded basic viewer with "open in new tab" fallback.
- **D-20:** Reading position restore is persisted approximately by section (not exact character offset).
- **D-21:** Reader controls in scope: font size, column width, and theme (light/sepia/dark).
- **D-22:** Reader keyboard shortcut package is out of scope for Phase 19.
- **D-23:** Reader parse/extraction failure uses guided error UI with retry, open original, and report actions.
- **D-24:** Heavy PDFs use progressive loading with explicit progress indicator.
- **D-25:** Search executes as-you-type with ~300ms debounce.
- **D-26:** Ranking remains aligned with current mobile/FTS behavior for parity.
- **D-27:** Results show short highlighted snippets for match context.
- **D-28:** Empty results show a clear message plus recovery suggestions (clear filters/change terms).
- **D-29:** Fuzzy/typo-tolerant search is out of scope for Phase 19.
- **D-30:** Search history persistence is out of scope for Phase 19.
- **D-31:** Search errors render inline with retry action and fallback path back to list.
- **D-32:** Search respects active list filters by default (contextual search).

### the agent's Discretion
- Exact file-size threshold values and per-platform limits, as long as UX stays explicit and deterministic.
- Concrete visual treatment (spacing, iconography, microcopy) while preserving the behavior decisions above.
- Technical strategy for URL/file dedupe "open existing" affordance, as long as user intent is explicit.

### Deferred Ideas (OUT OF SCOPE)
- Full multi-select bulk actions on web list (deferred beyond Phase 19).
- Keyboard shortcut packages for list and reader (deferred beyond Phase 19).
- Fuzzy/typo-tolerant search and persistent search history (deferred beyond Phase 19).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| WEB-01 | User can ingest content from web (URL/file) with validation behavior equivalent to mobile. | Existing duplicate + summary flows are reusable, but web-safe intake and validation split is required. |
| WEB-02 | User can browse chronological list on web with ordering, tag surfaces, and filters consistent with mobile. | Existing Drift ordering/filter contracts are solid; web pagination and quick actions must be added. |
| WEB-03 | User can read extracted content on web with reader behavior and metadata context consistent with mobile. | Metadata context exists; desktop layout controls, PDF embedding, and position restore must be added. |
| WEB-04 | User can search on web with query semantics and empty/error states consistent with mobile. | FTS + label-filter semantics already exist; debounce, snippets, and deterministic empty/error UX are missing. |
</phase_requirements>

## Summary

Phase 19 is feasible, but there is a hard foundation blocker before feature parity work: current startup and storage wiring are not web-ready. App startup currently registers services that depend on dart:io and FFI-only packages, and the database is opened without required web Drift options. A Chrome-platform compile run fails with dart:ffi not available errors. [VERIFIED: [lib/main.dart](lib/main.dart#L1), [lib/features/ingestion/services/share_service.dart](lib/features/ingestion/services/share_service.dart#L1), [lib/features/ingestion/services/extraction_service.dart](lib/features/ingestion/services/extraction_service.dart#L1), [lib/features/intelligence/services/ai_provider_client.dart](lib/features/intelligence/services/ai_provider_client.dart#L1), flutter test --platform chrome test/widget_test.dart output]

Most behavioral building blocks for parity already exist in mobile-oriented code: URL duplicate detection, ingestion summary save/discard, label-filtered list streams, FTS search with label constraints, and reader metadata context. These reduce implementation risk once web compatibility is solved. [VERIFIED: [lib/features/ingestion/services/share_service.dart](lib/features/ingestion/services/share_service.dart#L176), [lib/features/ingestion/presentation/ingestion_summary_screen.dart](lib/features/ingestion/presentation/ingestion_summary_screen.dart#L93), [lib/features/chronological_list/presentation/item_list_screen.dart](lib/features/chronological_list/presentation/item_list_screen.dart#L562), [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L651), [lib/features/reader/presentation/reader_screen.dart](lib/features/reader/presentation/reader_screen.dart#L102)]

The largest parity gaps relative to locked decisions are web file ingestion and drag-drop, explicit file-size/type validation, list pagination, reader controls and PDF embedding, search debounce, highlighted snippets, and richer empty/error recovery states.

**Primary recommendation:** Execute Phase 19 in five waves with Wave 0 dedicated to web-safe platform abstraction and Drift web initialization, then deliver WEB-01 through WEB-04 in requirement order.

## Project Constraints (from copilot-instructions.md)

- No project-level copilot-instructions.md file was found in repository root. [VERIFIED: workspace file search]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---|---|---|---|
| drift | 2.32.1 (latest), repo constraint ^2.16.0 | SQL and FTS contracts for list/search parity | Already central to ordering/filter/search semantics and used throughout existing code. [VERIFIED: [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L1), pub.dev API drift] |
| drift_flutter | 0.3.0 (latest), repo constraint ^0.2.0 | Platform-specific database bootstrap | Web requires explicit DriftWebOptions and wasm worker wiring. [VERIFIED: [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L98), local drift_flutter source inspection, pub.dev API drift_flutter] |
| file_picker | 11.0.2 (latest), repo constraint ^8.1.2 | File picker path for WEB-01 | Plugin supports web and exposes byte-based web-safe file access. [VERIFIED: pub.dev API file_picker flutter.plugin.platforms, local file_picker source inspection] |
| flutter_dropzone | 4.2.1 (latest) | Drag-and-drop ingestion path for WEB-01 | Web-native drop target with clear plugin scope for browser implementation. [VERIFIED: pub.dev API flutter_dropzone flutter.plugin.platforms] |
| url_launcher | 6.3.2 (latest), repo constraint ^6.2.5 | Open-original and fallback actions | Supports web and native platforms for deterministic fallback actions. [VERIFIED: pub.dev API url_launcher flutter.plugin.platforms] |

### Supporting

| Library | Version | Purpose | When to Use |
|---|---|---|---|
| share_plus | 13.0.0 (latest), repo constraint ^10.1.2 | Item share quick action | Reuse existing share action for web parity and avoid custom Web Share wrappers. [VERIFIED: [lib/features/chronological_list/presentation/item_list_screen.dart](lib/features/chronological_list/presentation/item_list_screen.dart#L22), pub.dev API share_plus flutter.plugin.platforms] |
| syncfusion_flutter_pdfviewer | 33.1.49 (latest) | Embedded PDF reader with loading callbacks | Required for D-19 and D-24 instead of external-open only file handling. [VERIFIED: pub.dev API syncfusion_flutter_pdfviewer flutter.plugin.platforms] |
| metadata_fetch + html parser | existing in repo | URL metadata/title/image fallback | Keep as baseline extraction path while web-safe readability replacement is implemented. [VERIFIED: [lib/features/ingestion/services/extraction_service.dart](lib/features/ingestion/services/extraction_service.dart#L1)] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| flutter_dropzone | Manual HTML5 drop events via JS interop | More custom code and browser edge cases to maintain. |
| syncfusion_flutter_pdfviewer | Open PDF in new tab only | Misses D-19 embedded viewer requirement and D-24 progress behavior. |
| Keep readability everywhere | Conditional mobile-only readability + web extractor | Required because readability package is FFI plugin and not web-safe. [VERIFIED: pub.dev API readability flutter.plugin.platforms, Chrome compile output] |

## Architecture Patterns

### Recommended Project Structure

- Add a platform intake interface and platform-specific implementations under [lib/features/ingestion/services](lib/features/ingestion/services).
- Add platform-specific extraction implementations under [lib/features/ingestion/services](lib/features/ingestion/services).
- Add web reader layout shell components under [lib/features/reader/presentation](lib/features/reader/presentation).

### Pattern 1: Platform-Safe Service Registration First

**What:** Resolve all startup-time web blockers before adding parity UI.

**When to use:** Wave 0 of this phase, before WEB-01 implementation.

**Evidence:**
- App startup eagerly registers and starts ShareService. [VERIFIED: [lib/main.dart](lib/main.dart#L126)]
- ShareService imports dart:io and mobile share intent plugin. [VERIFIED: [lib/features/ingestion/services/share_service.dart](lib/features/ingestion/services/share_service.dart#L1)]
- ExtractionService imports dart:io and readability wrapper fallback using temp files. [VERIFIED: [lib/features/ingestion/services/extraction_service.dart](lib/features/ingestion/services/extraction_service.dart#L1)]
- AI provider service imports dart:io for SocketException handling. [VERIFIED: [lib/features/intelligence/services/ai_provider_client.dart](lib/features/intelligence/services/ai_provider_client.dart#L1)]

### Pattern 2: Explicit Drift Web Initialization

**What:** Open database with DriftWebOptions and ship sqlite3.wasm plus drift_worker.js.

**When to use:** Wave 0, with compile and boot smoke tests.

**Evidence:**
- Current database open path omits web options. [VERIFIED: [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L98)]
- drift_flutter web adapter throws when web options are missing. [VERIFIED: local drift_flutter source inspection]
- Current web folder lacks sqlite wasm/worker artifacts. [VERIFIED: [web](web)]

### Pattern 3: Reuse Existing Query Contracts, Extend UI Semantics

**What:** Keep list/search data contracts in AppDatabase and layer web-specific UX behavior on top.

**When to use:** WEB-02 and WEB-04 work.

**Evidence:**
- Default active ordering already deterministic via sort_order asc then created_at desc. [VERIFIED: [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L102)]
- Search already enforces active-item and optional AND label filtering. [VERIFIED: [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L651)]
- List screen currently applies selected labels to search stream. [VERIFIED: [lib/features/chronological_list/presentation/item_list_screen.dart](lib/features/chronological_list/presentation/item_list_screen.dart#L239)]

### Anti-Patterns to Avoid

- Building separate web-only SQL semantics for ordering/filter/search. Reuse existing Drift contracts.
- Adding drag-drop via ad-hoc JavaScript listeners without package guardrails.
- Deferring compile blocker fixes until after feature UI work.

## Don’t Hand-Roll

| Problem | Don’t Build | Use Instead | Why |
|---|---|---|---|
| Browser file drag-drop | Custom DOM event bridge in app code | flutter_dropzone | Less browser API edge-case handling and lower maintenance risk. [VERIFIED: pub.dev API flutter_dropzone] |
| Browser file picker bytes/path behavior | Custom file input wrappers | file_picker | Existing plugin already handles web byte-path differences. [VERIFIED: local file_picker source inspection, pub.dev API file_picker] |
| Embedded PDF rendering | Manual PDF.js integration from scratch | syncfusion_flutter_pdfviewer | Faster path to D-19 and D-24 with platform coverage. [VERIFIED: pub.dev API syncfusion_flutter_pdfviewer] |
| URL canonical duplicate logic | New URL normalization engine | Existing canonical URL candidate logic in AppDatabase | Existing behavior already tested and parity-aligned. [VERIFIED: [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L686), [test/features/ingestion/services/share_service_test.dart](test/features/ingestion/services/share_service_test.dart#L84)] |

**Key insight:** This phase should invest effort in platform adaptation and parity UX semantics, not rebuilding ingestion/search/storage primitives that already exist and are tested.

## Requirement Findings and Recommendations

### WEB-01: Web Ingestion Parity

**Current baseline**
- URL ingest flow, duplicate detection, JS/archive fallback, and summary-save path are implemented. [VERIFIED: [lib/features/ingestion/services/share_service.dart](lib/features/ingestion/services/share_service.dart#L153), [lib/features/ingestion/presentation/archive_scraper_screen.dart](lib/features/ingestion/presentation/archive_scraper_screen.dart#L1), [lib/features/ingestion/presentation/js_rendered_scraper_screen.dart](lib/features/ingestion/presentation/js_rendered_scraper_screen.dart#L1)]
- Summary screen supports pre-save edits for title, author, and labels and returns saved/discarded result. [VERIFIED: [lib/features/ingestion/presentation/ingestion_summary_screen.dart](lib/features/ingestion/presentation/ingestion_summary_screen.dart#L13)]

**Gaps to close**
- No web file picker or drag-drop entry path in list UI; current FAB only opens Add URL dialog. [VERIFIED: [lib/features/chronological_list/presentation/item_list_screen.dart](lib/features/chronological_list/presentation/item_list_screen.dart#L198)]
- File ingestion path assumes dart:io File copy semantics and device file paths. [VERIFIED: [lib/features/ingestion/services/share_service.dart](lib/features/ingestion/services/share_service.dart#L235)]
- Explicit size/type validation and visible file limits are not implemented.
- Extraction failure fallback is partially guided for JS/archive but not for general null extraction result.

**Concrete recommendation**
1. Replace Add URL dialog with a unified Add sheet: URL tab + File tab + Drop zone. [VERIFIED: D-01/D-02 locked decisions]
2. Introduce web ingestion adapter using file_picker with bytes and optional flutter_dropzone overlay. [VERIFIED: file_picker web byte model, pub.dev plugin metadata]
3. Add deterministic validation contract:
   - Allowed types in this phase: PDF and common image MIME/extension set.
   - Max size constant surfaced in UI copy and failure snackbar/modal.
4. Reuse existing duplicate checks for URL and file identity; add open-existing action path instead of only add-again/discard. [VERIFIED: [lib/features/ingestion/services/share_service.dart](lib/features/ingestion/services/share_service.dart#L176)]
5. For extraction failure, show guided recovery card with Retry, Open Original, and Report options before summary fallback. [VERIFIED: D-04, D-23 locked decisions]

### WEB-02: Chronological List and Filters

**Current baseline**
- Label chips and history mode are present in horizontal filter bar. [VERIFIED: [lib/features/chronological_list/presentation/item_list_screen.dart](lib/features/chronological_list/presentation/item_list_screen.dart#L562)]
- Default ordering contract already deterministic in DB. [VERIFIED: [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L102)]
- Returning from reader naturally preserves in-memory list state in same route stack. [VERIFIED: [lib/features/chronological_list/presentation/item_list_screen.dart](lib/features/chronological_list/presentation/item_list_screen.dart#L1169)]

**Gaps to close**
- No incremental pagination; all items render in a full stream-backed list.
- Per-item quick actions do not yet include read/unread, favorite, or delete shortcut path.
- Delete flow snackbar currently has no undo action.
- More-filters affordance is implicit via drawer but not explicit in filter row.

**Concrete recommendation**
1. Add page-size driven incremental loading for list body while preserving ordering contract from DB.
2. Add explicit More filters button next to quick chips to open existing label selector surface.
3. Implement quick actions row/menu per item: open, read/unread, favorite, delete, share.
4. Implement delete confirmation + snackbar undo by calling restoreItemFromRecycle on undo action. [VERIFIED: [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L200)]
5. Keep multi-select actions hidden for web phase scope compliance (already out of scope by decision).

### WEB-03: Reader and PDF Parity

**Current baseline**
- Reader displays title, author, labels, source host, and open-in-browser fallback for URL items. [VERIFIED: [lib/features/reader/presentation/reader_screen.dart](lib/features/reader/presentation/reader_screen.dart#L52)]
- Reader already updates last_opened_at on open-original action. [VERIFIED: [lib/features/reader/presentation/reader_screen.dart](lib/features/reader/presentation/reader_screen.dart#L465)]

**Gaps to close**
- No desktop-centered layout with side panel controls.
- No font size/column width/theme controls.
- No embedded PDF reader path; files currently open via open_filex which is mobile-only plugin.
- No persisted section-level reading position restore.
- No guided parse failure workflow with retry/report.

**Concrete recommendation**
1. Build a web reader shell with centered max-width content and optional side panel for metadata/TOC.
2. Add sticky compact header controls: font scale, column width preset, light/sepia/dark themes.
3. Route PDF items into embedded viewer using syncfusion_flutter_pdfviewer and retain open-in-new-tab fallback.
4. Persist approximate read position by section index or scroll bucket keyed by item id.
5. Add no-content failure card with Retry extraction, Open original, and Report actions.

### WEB-04: Search Parity

**Current baseline**
- Search stream already routes through FTS and respects active label filters. [VERIFIED: [lib/features/chronological_list/presentation/item_list_screen.dart](lib/features/chronological_list/presentation/item_list_screen.dart#L239), [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L651)]
- Semantic fallback service merges semantic and keyword paths deterministically. [VERIFIED: [lib/features/intelligence/services/semantic_search_service.dart](lib/features/intelligence/services/semantic_search_service.dart#L45)]

**Gaps to close**
- Search currently updates on every keystroke without debounce.
- Result snippets and highlighting are missing.
- Empty-state recovery suggestions are missing.
- Error state has no retry action.

**Concrete recommendation**
1. Add 300ms debounce layer before stream refresh in search update handler.
2. Add deterministic snippet extraction per item (title/content around first token hit) and highlight matching tokens.
3. Replace generic empty state with guidance actions: clear filters, clear query, view all items.
4. Replace inline error text with actionable retry and back-to-list controls.

## Implementation Sequence

1. Wave 0: Web foundation unblockers
   - Add conditional service registration for web-safe startup.
   - Split mobile-only ingestion/extraction/open-file code from web implementation.
   - Configure Drift web path with DriftWebOptions and ship web wasm/worker artifacts.
   - Gate with Chrome compile smoke run.
2. Wave 1: WEB-01 ingestion parity
   - Unified Add entry point with URL + file + drop zone.
   - Duplicate/open-existing handling and explicit type/size validation.
   - Guided extraction failure UX.
3. Wave 2: WEB-02 list/filter parity
   - Incremental pagination and explicit More filters affordance.
   - Quick actions completion and delete undo.
   - State persistence checks for list/search/filter across reader round-trip.
4. Wave 3: WEB-03 reader/PDF parity
   - Desktop reader shell and sticky controls.
   - Embedded PDF viewer with fallback open-in-new-tab and progress indicators.
   - Approximate section-level position restore.
5. Wave 4: WEB-04 search parity
   - Debounce, snippets/highlights, empty/error recovery surfaces.
   - Verify contextual filter-respecting search semantics.
6. Wave 5: parity hardening and regression checks
   - Cross-platform targeted test pass.
   - Manual UAT for all D-01..D-32 in scope.

## Risk Register

| Risk | Severity | Why It Matters | Mitigation |
|---|---|---|---|
| Web compile blocker from dart:io and dart:ffi dependencies in startup graph | Critical | Phase cannot start feature parity until app compiles on web | Wave 0 conditional imports and web-safe service adapters first. [VERIFIED: Chrome test output, [lib/main.dart](lib/main.dart#L1)] |
| Drift web DB open misconfiguration | Critical | Runtime startup failure if DriftWebOptions not provided on web | Add explicit DriftWebOptions and required artifacts in web folder. [VERIFIED: [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L98), local drift_flutter source inspection] |
| Feature drift from current list actions vs locked decisions | High | D-11 quick actions require additional behavior not currently present | Implement quick-action matrix explicitly and cover in widget tests. |
| Reader parity under-specified for file/PDF path | High | Existing open_filex path is mobile-only and bypasses reader UX | Add dedicated web PDF flow and fallback behavior tests. [VERIFIED: [lib/features/chronological_list/presentation/item_list_screen.dart](lib/features/chronological_list/presentation/item_list_screen.dart#L1172), pub.dev API open_filex] |
| Search behavior regressions while adding debounce/snippets | Medium | Could break current FTS semantics and filter constraints | Keep DB query contract unchanged; limit changes to UI orchestration and presentation layer. |
| Test command instability/timeouts in heavier widget suites | Medium | Can hide regressions and delay planning verification loops | Split widget suites and run focused files; treat hangs as validation signal and fix timers. [VERIFIED: local run of item_list_screen_test did not complete within timeout] |

## Testing Approach

1. Foundation checks (Wave 0)
   - Chrome compile smoke: flutter test --platform chrome test/widget_test.dart
   - Static analysis: flutter analyze
   - DB unit baseline: flutter test test/core/database/app_database_test.dart

2. WEB-01 tests
   - Unit: URL normalization, duplicate branching, file type/size validation.
   - Widget: Add sheet URL/file tabs, drag-drop hover/drop, error messaging, summary save/discard navigation.
   - Regression: extend [test/features/ingestion/services/share_service_test.dart](test/features/ingestion/services/share_service_test.dart)

3. WEB-02 tests
   - Unit: pagination cursor/offset logic and reorder constraints.
   - Widget: filter chips + more-filters, quick actions, delete undo snackbar.
   - Regression: extend [test/features/chronological_list/presentation/item_list_screen_test.dart](test/features/chronological_list/presentation/item_list_screen_test.dart) and [test/features/chronological_list/presentation/item_list_multiselect_scroll_test.dart](test/features/chronological_list/presentation/item_list_multiselect_scroll_test.dart)

4. WEB-03 tests
   - Widget: desktop reader controls, no-content recovery card, open-original fallback.
   - Integration/manual: PDF embedded load + progress + new-tab fallback.
   - Gap note: there are currently no reader feature tests under the existing [test/features](test/features) tree. [VERIFIED: file search]

5. WEB-04 tests
   - Unit: debounce behavior and snippet/highlight function determinism.
   - Widget: empty suggestions, error retry, contextual filtering while searching.
   - Regression: extend [test/features/intelligence/services/semantic_search_service_test.dart](test/features/intelligence/services/semantic_search_service_test.dart) for fallback and ranking stability.

## Validation Architecture

### Validation Dimensions and Checks

| Dimension | Check | Requirement Coverage | Verification Method | Pass Condition |
|---|---|---|---|---|
| Web boot viability | App compiles and launches on Chrome with no dart:io/dart:ffi startup crash | WEB-01 to WEB-04 gate | chrome platform test + manual run | Build succeeds and root list renders |
| Ingestion parity | URL and file ingest enforce duplicate, size/type validation, and guided fallback | WEB-01 | widget + unit tests | All branches deterministically reach expected UX outcome |
| List parity semantics | Ordering, chips, more-filters, quick actions, and pagination behavior | WEB-02 | widget tests + DB assertions | Observed item order and actions match locked decisions |
| Reader parity | Metadata context, sticky controls, pdf embedded fallback, position restore | WEB-03 | widget/manual integration | Reader returns to preserved list state and restores approximate position |
| Search parity | 300ms debounce, FTS semantics, snippets, empty/error recovery | WEB-04 | unit + widget tests | Debounce window stable and result semantics unchanged |
| Determinism under errors | Retry/back pathways for ingest/read/search errors | WEB-01/03/04 | failure-path widget tests | No silent failures; all failures expose deterministic action paths |

### Phase Gate Commands

| Scope | Command | Expected Outcome |
|---|---|---|
| DB semantics baseline | flutter test test/core/database/app_database_test.dart | Pass (verified locally) |
| Ingestion baseline | flutter test test/features/ingestion/services/share_service_test.dart | Pass after web-safe adapter refactor |
| Search fallback baseline | flutter test test/features/intelligence/services/semantic_search_service_test.dart | Pass with unchanged ranking fallback behavior |
| List parity suite | flutter test test/features/chronological_list/presentation/item_list_screen_test.dart | Pass without hangs/timeouts |
| Web compile gate | flutter test --platform chrome test/widget_test.dart | Currently fails; must pass before feature waves proceed |

### Verification Sampling

- Per commit in this phase: run one focused unit test file plus analyze.
- Per wave merge: run all updated ingestion/list/reader/search tests.
- Phase completion gate: run chrome platform compile test and parity checklist for WEB-01 through WEB-04.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Flutter SDK | All web parity implementation and tests | Yes | 3.41.4 | None |
| Dart SDK | Build and analyzer | Yes | 3.11.1 | None |
| Chrome | Web platform tests | Yes | system binary present at /usr/bin/google-chrome | Chromium if needed |
| npm | Optional toolchain utilities | Yes | 10.9.3 | None |

**Missing dependencies with no fallback:**
- None in local environment.

**Missing dependencies with fallback:**
- Repository is missing Drift web artifacts (sqlite3.wasm and drift_worker.js in web assets); add during Wave 0. [VERIFIED: [web](web), local drift_flutter source inspection]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | Not in scope for Phase 19 |
| V3 Session Management | No | Not in scope for Phase 19 |
| V4 Access Control | Yes | Deterministic action gating in UI flows (delete, undo, open-existing) |
| V5 Input Validation | Yes | URL/file type/size validation before ingest and explicit error handling |
| V6 Cryptography | No | Not introduced in this phase |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Malicious URL payloads and invalid schemes | Tampering | Strict URI parse and scheme allow-list before extraction/open actions |
| Oversized or unsupported files causing denial behavior | DoS | Hard file-size and MIME/extension validation with immediate rejection UI |
| HTML rendering injection risk in previews | XSS / Injection | Sanitize and constrain rendered preview content, avoid unsafe script execution |
| Search query abuse causing expensive refresh loops | DoS | Debounce and bounded pagination to cap query/render churn |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Mobile-only intake via share intent plugin | Web parity requires picker + drag-drop + bytes-first model | 2026 web phase | Requires service adapter split and web-safe file handling |
| Implicit immediate search updates | Debounced as-you-type with contextual filters | Phase 19 requirement | Lower churn and deterministic UX |
| External file open for file items | Embedded PDF viewer plus fallback | Phase 19 requirement | Brings reader parity to web |

**Deprecated/outdated for web path:**
- readability package as a universal extractor: it is an FFI plugin and not suitable for browser runtime. [VERIFIED: pub.dev API readability flutter.plugin.platforms, Chrome compile output]
- receive_sharing_intent for web ingestion: plugin supports Android/iOS only. [VERIFIED: pub.dev API receive_sharing_intent flutter.plugin.platforms]
- open_filex as web file-open path: plugin supports Android/iOS only. [VERIFIED: pub.dev API open_filex flutter.plugin.platforms]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Favorite and read/unread quick actions are implemented via deterministic reserved label toggles (`read`, `favorite`) in Phase 19. [RESOLVED] | WEB-02 recommendation | If reserved labels collide with user-defined semantics, normalize labels and document reserved behavior. |
| A2 | Approximate section-level position restore is acceptable for Phase 19 and tracked as deterministic continuity baseline. [RESOLVED] | WEB-03 recommendation | Precision restore can be deferred to a later phase if user feedback requires finer granularity. |

## Open Questions (RESOLVED)

1. Favorite and read/unread data model
   - What we know: quick actions are locked in D-11; current schema lacks explicit is_favorite and is_read fields.
   - Resolution: Phase 19 uses deterministic reserved labels (`read`, `favorite`) instead of schema migration, matching plan `19-04-PLAN.md`.
   - Status: RESOLVED.

2. File-size threshold policy
   - What we know: D-06 requires explicit size limit and messaging.
   - Resolution: Cross-platform cap fixed at 25 MB for Phase 19 and reflected in UI-SPEC copy contract.
   - Status: RESOLVED.

3. Reader side panel scope
   - What we know: D-17 requires optional side panel (TOC/metadata).
   - Resolution: Start with metadata panel and TOC-ready slot in Phase 19; generated TOC remains incremental when extraction quality supports it.
   - Status: RESOLVED.

## Sources

### Primary (HIGH confidence)

- [Phase context decisions](.planning/phases/19-web-parity-core-flows/19-CONTEXT.md)
- [Requirements mapping](.planning/REQUIREMENTS.md)
- [Roadmap phase scope](.planning/ROADMAP.md)
- [State and workflow flags](.planning/STATE.md)
- [Workflow config with nyquist validation enabled](.planning/config.json)
- [App startup registration and ShareService initialization](lib/main.dart#L30)
- [Ingestion orchestration and duplicate handling](lib/features/ingestion/services/share_service.dart#L153)
- [Ingestion summary save/discard behavior](lib/features/ingestion/presentation/ingestion_summary_screen.dart#L93)
- [List search/filter and state flow](lib/features/chronological_list/presentation/item_list_screen.dart#L227)
- [Reader baseline behavior and fallback actions](lib/features/reader/presentation/reader_screen.dart#L52)
- [Search and ordering contracts in DB](lib/core/database/app_database.dart#L102)
- [Semantic search fallback behavior](lib/features/intelligence/services/semantic_search_service.dart#L45)
- [Existing phase-relevant tests](test/features/ingestion/services/share_service_test.dart#L1)
- drift_flutter web requirement source in local pub cache: ../.pub-cache/hosted/pub.dev/drift_flutter-0.2.8/lib/src/web.dart
- file_picker web bytes/path behavior source in local pub cache: ../.pub-cache/hosted/pub.dev/file_picker-8.3.7/lib/src/platform_file.dart
- Local command verification:
  - flutter test test/core/database/app_database_test.dart passed.
  - flutter test --platform chrome test/widget_test.dart failed with dart:ffi and related web incompatibilities.

### Secondary (MEDIUM confidence)

- pub.dev API package metadata queries (versions, publish dates, plugin platforms):
  - https://pub.dev/api/packages/drift
  - https://pub.dev/api/packages/drift_flutter
  - https://pub.dev/api/packages/file_picker
  - https://pub.dev/api/packages/flutter_dropzone
  - https://pub.dev/api/packages/url_launcher
  - https://pub.dev/api/packages/syncfusion_flutter_pdfviewer
  - https://pub.dev/api/packages/receive_sharing_intent
  - https://pub.dev/api/packages/open_filex
  - https://pub.dev/api/packages/readability

### Tertiary (LOW confidence)

- None. All major claims are code-verified or directly sourced from pub.dev API metadata.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH for package capability/version evidence, MEDIUM for migration effort projections
- Architecture: MEDIUM due multi-surface web parity integration complexity
- Pitfalls and risks: HIGH for compile/runtime blockers, MEDIUM for UX scope effort

**Research date:** 2026-04-18
**Valid until:** 2026-05-18