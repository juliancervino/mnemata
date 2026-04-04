# Codebase Concerns

**Analysis Date:** 2026-04-04

## Tech Debt

| Area | Issue | Files | Impact | Fix approach |
|---|---|---|---|---|
| Main list feature | A single screen owns search, filters, history, bulk actions, sharing, open-file/url behavior, and multiple dialogs. | `lib/features/chronological_list/presentation/item_list_screen.dart` | High regression risk for unrelated edits; hard to reason about UI state transitions. | Split into focused widgets/controllers (search bar, filter state, item actions, bulk actions) and move business logic to services/use-cases. |
| Share ingestion orchestration | One service handles plugin intake, dedupe state, navigation orchestration, file I/O, extraction routing, and dialogs. | `lib/features/ingestion/services/share_service.dart` | Tight coupling makes bug isolation difficult; navigation/state bugs can affect ingestion reliability. | Separate intent intake, dedupe, persistence, and UI orchestration behind testable interfaces. |
| Generated code churn | Large generated Drift file is tracked and frequently changes with schema updates. | `lib/core/database/app_database.g.dart` | Large diffs/merge conflicts reduce review quality. | Keep generated file committed (required), but isolate schema changes and enforce small migration PRs with focused review notes. |

## Known Bugs

**No deterministic reproduction script detected in repo docs/tests.**
- Symptoms observed in code shape: multiple broad `catch (_) {}` branches can hide failures and produce silent no-op behavior.
- Files: `lib/core/utils/share_utils.dart`, `lib/features/ingestion/services/extraction_service.dart`, `lib/features/ingestion/services/archive_content_processor.dart`, `lib/features/chronological_list/presentation/item_list_screen.dart`
- Trigger: malformed URLs, parsing failures, plugin errors, or external content edge cases.
- Workaround: user retries action manually; logs are limited.

## Security Considerations

**Web content execution and scraping:**
- Risk: untrusted pages run with JavaScript enabled in embedded webview.
- Files: `lib/features/ingestion/presentation/archive_scraper_screen.dart`, `lib/features/ingestion/presentation/js_rendered_scraper_screen.dart`
- Current mitigation: none beyond user-driven flow.
- Recommendations: restrict navigations to expected hosts, block non-http(s) schemes, and add explicit allow/deny URL policy hooks.

**Unencrypted local persistence of sensitive content:**
- Risk: extracted article text and copied files are stored on-device without app-level encryption.
- Files: `lib/core/database/tables.dart`, `lib/core/database/app_database.dart`, `lib/features/ingestion/services/share_service.dart`
- Current mitigation: platform sandbox only.
- Recommendations: add optional encryption at rest and user-facing privacy mode (lock, wipe, export controls).

**Network fetch trust boundary:**
- Risk: arbitrary shared URLs are fetched and parsed, including metadata/image endpoints.
- Files: `lib/features/ingestion/services/extraction_service.dart`, `lib/features/ingestion/services/share_service.dart`
- Current mitigation: basic URL regex and timeout on one fetch path.
- Recommendations: validate scheme/host, add stronger request timeout/retry budgets, and deny localhost/private-network targets by policy.

## Performance Bottlenecks

**High-frequency full-screen rebuild pressure:**
- Problem: extensive `setState` usage in a 1000+ line screen with many interactive controls.
- Files: `lib/features/chronological_list/presentation/item_list_screen.dart`
- Cause: broad state ownership in one widget.
- Improvement path: split state domains and reduce rebuild scope with smaller widgets/selective listeners.

**Bulk reorder write amplification:**
- Problem: full batch writes every item order position.
- Files: `lib/core/database/app_database.dart`
- Cause: `updateItemsSortOrderInBatch` updates all rows in sequence.
- Improvement path: update only changed indices and consider transactional diff-based reorder persistence.

**Archive extraction CPU/memory cost:**
- Problem: repeated HTML parse/sanitize/score cycles and multiple readability passes.
- Files: `lib/features/ingestion/services/archive_content_processor.dart`
- Cause: candidate ranking + multi-pass parsing.
- Improvement path: cap input size, add early-exit heuristics, and instrument timing/size metrics for guardrails.

## Fragile Areas

**Share-intent lifecycle and navigator readiness race:**
- Files: `lib/features/ingestion/services/share_service.dart`, `lib/main.dart`
- Why fragile: mutable flags (`_isProcessingIncomingShare`, `_pendingIncomingShare`, `_isLoadingShowing`) coordinate async intake + navigation readiness.
- Safe modification: keep lifecycle transitions covered by focused async tests; avoid changing overlay/navigator logic without race-condition tests.
- Test coverage: unit tests exist for parts of duplicate flow, but not full plugin stream + app lifecycle integration.

**UI action branching inside list item tap/open logic:**
- Files: `lib/features/chronological_list/presentation/item_list_screen.dart`, `lib/core/utils/share_utils.dart`
- Why fragile: complex branching across URL parsing, deep-link launching, fallback extraction, and file open.
- Safe modification: extract item-action strategy classes and test each item type branch independently.
- Test coverage: only partial widget coverage for list rendering/search.

## Scaling Limits

**Content growth in local SQLite + FTS:**
- Current capacity: not explicitly bounded in code.
- Limit: database size and query latency can degrade as extracted content/documents grow.
- Scaling path: add retention controls, pagination for expensive views, and maintenance jobs (vacuum/index health checks).
- Files: `lib/core/database/app_database.dart`, `lib/core/database/tables.dart`

## Dependencies at Risk

**Unpinned dependency:**
- Risk: `favicon: any` can introduce non-deterministic upgrades.
- Impact: extraction metadata behavior may change unexpectedly between installs.
- Migration plan: pin to tested semver range in `pubspec.yaml`.
- Files: `pubspec.yaml`, `lib/features/ingestion/services/extraction_service.dart`

## Missing Critical Features

**Observability for ingestion failures:**
- Problem: failures are often swallowed or printed, without structured telemetry.
- Blocks: reliable diagnosis of extraction/share failures in production-like usage.
- Files: `lib/features/ingestion/services/extraction_service.dart`, `lib/features/ingestion/services/share_service.dart`, `lib/features/ingestion/services/archive_content_processor.dart`

**Data protection controls:**
- Problem: no user-selectable data encryption/locking policy despite storing personal reading corpus.
- Blocks: stronger privacy posture for sensitive sources and shared files.
- Files: `lib/core/database/app_database.dart`, `lib/features/ingestion/services/share_service.dart`

## Test Coverage Gaps

**Ingestion scraper screens and JS/archive extraction paths:**
- What's not tested: `WebView`-driven extraction flows and fallback transitions.
- Files: `lib/features/ingestion/presentation/archive_scraper_screen.dart`, `lib/features/ingestion/presentation/js_rendered_scraper_screen.dart`
- Risk: regressions in parsing/navigation when external page behavior changes.
- Priority: High

**Large list screen behavior matrix:**
- What's not tested: multi-select + bulk operations + reorder + history/filter combined paths.
- Files: `lib/features/chronological_list/presentation/item_list_screen.dart`, `test/features/chronological_list/presentation/item_list_screen_test.dart`
- Risk: hidden interaction regressions with state flags.
- Priority: High

**Cross-platform share intent integration:**
- What's not tested: platform intent delivery timing and lifecycle race scenarios.
- Files: `android/app/src/main/AndroidManifest.xml`, `lib/features/ingestion/services/share_service.dart`, `test/features/ingestion/services/share_service_test.dart`
- Risk: dropped or duplicated inbound shares in real device conditions.
- Priority: High

---

*Concerns audit: 2026-04-04*
