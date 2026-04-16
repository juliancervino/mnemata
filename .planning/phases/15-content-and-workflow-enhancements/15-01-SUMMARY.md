---
phase: 15-content-and-workflow-enhancements
plan: 01
subsystem: ingestion
tags: [flutter, drift, ingestion, metadata, author]
requires: []
provides:
  - Dedicated author extraction module with sanitization and fallback-safe behavior
  - Drift author column migration and persistence path
  - Author rendering in chronological list and reader surfaces
affects: [ingestion, database, chronological-list, reader]
tech-stack:
  added: []
  patterns: [dedicated extraction module, additive drift migration, non-blocking metadata enrichment]
key-files:
  created:
    - lib/features/ingestion/services/author_extraction_service.dart
    - test/features/ingestion/services/author_extraction_service_test.dart
    - test/core/database/app_database_author_test.dart
  modified:
    - lib/features/ingestion/services/share_service.dart
    - lib/features/ingestion/presentation/ingestion_summary_screen.dart
    - lib/core/database/tables.dart
    - lib/core/database/app_database.dart
    - lib/core/database/app_database.g.dart
    - lib/features/chronological_list/presentation/item_list_screen.dart
    - lib/features/reader/presentation/reader_screen.dart
    - lib/features/ingestion/services/extraction_service.dart
    - test/features/chronological_list/presentation/item_list_screen_test.dart
key-decisions:
  - "Author extraction remains isolated in author_extraction_service.dart and is called as additive enrichment from ShareService."
  - "Title/body extraction logic in ExtractionService was not repurposed for author parsing."
  - "Author persistence flows through existing ingestion summary save path to preserve current UX."
patterns-established:
  - "Non-blocking enrichment: author extraction failure must not interrupt ingestion save flow."
  - "Security hygiene for untrusted metadata: trim, normalize, cap length, and reject script-like payloads."
requirements-completed: [AUT-01, AUT-02]
duration: 11m
completed: 2026-04-16
---

# Phase 15 Plan 01: Author Metadata Pipeline Summary

**Dedicated author extraction now enriches shared URL ingestion, persists via Drift migration, and appears in list/reader UI while title/body extraction semantics stay unchanged.**

## Performance

- **Duration:** 11m
- **Started:** 2026-04-16T15:50:55Z
- **Completed:** 2026-04-16T16:01:08Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments
- Added `AuthorExtractionService` as a dedicated module with candidate priority and sanitization constraints.
- Added nullable `author` persistence in `mnemata_items` with schema v8 migration and write/read support.
- Surfaced persisted author in `ItemListScreen` and `ReaderScreen` with fallback behavior retained when author is absent.
- Added AUT-focused tests for author extraction behavior, database migration/persistence, and list rendering behavior.

## Task Commits

1. **Task 1: Add author extraction and persistence test scaffolds** - `d2b1c8a` (test)
2. **Task 2: Implement dedicated author extraction module and schema migration** - `c077a06` (feat)
3. **Task 3: Expose persisted author in item views** - `3249e1e` (feat)

## Files Created/Modified
- `lib/features/ingestion/services/author_extraction_service.dart` - dedicated author extraction with sanitization and HTML/meta candidate parsing.
- `lib/features/ingestion/services/share_service.dart` - additive author enrichment call with non-blocking fallback.
- `lib/features/ingestion/presentation/ingestion_summary_screen.dart` - save pipeline now carries optional author value.
- `lib/core/database/tables.dart` - nullable `author` column on `mnemata_items`.
- `lib/core/database/app_database.dart` - schema v8 migration and optional author update support.
- `lib/core/database/app_database.g.dart` - regenerated Drift model/companion updates.
- `lib/features/chronological_list/presentation/item_list_screen.dart` - author shown in subtitle row when present.
- `lib/features/reader/presentation/reader_screen.dart` - byline display for author metadata.
- `lib/features/ingestion/services/extraction_service.dart` - hardened metadata/favicon error isolation without changing title/body extraction contract.
- `test/features/ingestion/services/author_extraction_service_test.dart` - author extraction + extraction contract coverage.
- `test/core/database/app_database_author_test.dart` - insert/read + migration coverage for author column.
- `test/features/chronological_list/presentation/item_list_screen_test.dart` - author render and fallback subtitle regression coverage.

## Decisions Made
- Kept author extraction fully separate from title/body extraction logic (D-01/D-02 lock upheld).
- Routed author through existing ingestion summary persistence path instead of bypassing current save UX.
- Treated author extraction as non-critical enrichment to avoid ingestion failures when remote metadata fetch fails.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Regenerated sources before verification due schema/API drift**
- **Found during:** Task 2
- **Issue:** Drift-generated companions/models were out of sync after adding `author` column.
- **Fix:** Ran code generation before verification and regenerated `app_database.g.dart`.
- **Files modified:** `lib/core/database/app_database.g.dart`
- **Verification:** Task 2 targeted tests compiled and passed.
- **Committed in:** `c077a06`

**2. [Rule 1 - Bug] Isolated metadata/favicon network failures inside ExtractionService**
- **Found during:** Task 2 verification
- **Issue:** Transient metadata fetch errors aborted extraction early, causing title/body contract tests to fail before readability parsing.
- **Fix:** Added per-step failure isolation for metadata/manual-title/favicon fetch so extraction remains non-fatal.
- **Files modified:** `lib/features/ingestion/services/extraction_service.dart`
- **Verification:** `test/features/ingestion/extraction_service_test.dart` and full AUT regression suite passed.
- **Committed in:** `c077a06`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Changes were correctness-focused and required to satisfy AUT verification without scope expansion.

## Issues Encountered
- Network-dependent metadata fetches made extraction tests unstable; resolved by making non-critical network steps fault-tolerant.

## User Setup Required
None - no external configuration required.

## Known Stubs
None.

## Next Phase Readiness
- AUT-01/AUT-02 are complete and regression-tested.
- Phase can proceed to recycle-bin/bookmark/share enhancement plans without additional author-metadata groundwork.

## Self-Check
- Pending
