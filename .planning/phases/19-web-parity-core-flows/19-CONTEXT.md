# Phase 19: Web Parity Core Flows - Context

**Gathered:** 2026-04-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver web parity for core workflows already present on mobile: ingestion (URL/file), chronological list/filtering, reader behavior (including PDF handling), and search semantics with deterministic empty/error handling.

This phase does not expand product capability beyond WEB-01..WEB-04. New capabilities remain deferred.

</domain>

<decisions>
## Implementation Decisions

### Ingestion UX web
- **D-01:** Web uses one primary "Add" entry point that supports both URL and file ingestion.
- **D-02:** Web supports drag-and-drop plus file picker for file ingestion.
- **D-03:** Duplicate handling follows mobile parity behavior: warn user and allow continuing intentionally (with an explicit existing-item path in UX).
- **D-04:** Extraction failure uses a guided fallback flow, not a silent failure.
- **D-05:** File support in Phase 19 matches current mobile support (PDF + image).
- **D-06:** Oversized file submissions are blocked with a clear message and visible size limit.
- **D-07:** After save from ingestion summary, navigate back to list and show confirmation snackbar.
- **D-08:** Ingestion summary keeps pre-save editing for title, author, and tags (mobile parity).

### List and filter parity
- **D-09:** Default list order is newest-first, consistent with current mobile semantics.
- **D-10:** Filters are exposed as horizontal chips plus a "More filters" affordance.
- **D-11:** Per-item quick actions include open reader, mark read/unread, favorite, delete, and share.
- **D-12:** Long collections use incremental pagination (infinite scroll).
- **D-13:** Returning from reader restores exact list/search/filter state.
- **D-14:** Delete flow uses modal confirmation plus snackbar undo.
- **D-15:** Multi-select bulk actions are out of scope for Phase 19.
- **D-16:** List keyboard shortcuts are out of scope for Phase 19.

### Reader and PDF behavior
- **D-17:** Reader layout on desktop web uses centered content with optional side panel (TOC/metadata).
- **D-18:** Reader actions stay in a compact sticky header.
- **D-19:** PDF flow uses embedded basic viewer with "open in new tab" fallback.
- **D-20:** Reading position restore is persisted approximately by section (not exact character offset).
- **D-21:** Reader controls in scope: font size, column width, and theme (light/sepia/dark).
- **D-22:** Reader keyboard shortcut package is out of scope for Phase 19.
- **D-23:** Reader parse/extraction failure uses guided error UI with retry, open original, and report actions.
- **D-24:** Heavy PDFs use progressive loading with explicit progress indicator.

### Search semantics and empty/error states
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

</decisions>

<specifics>
## Specific Ideas

- Keep behavior parity as the primary anchor; avoid introducing feature drift in web-first implementations.
- Prefer guided recovery paths over silent failure for ingest/read/search error states.
- Maintain deterministic state semantics when moving list <-> reader <-> search.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and acceptance
- `.planning/ROADMAP.md` - Phase 19 goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` - WEB-01..WEB-04 parity requirements and milestone traceability.
- `.planning/PROJECT.md` - Milestone constraints and reliability-first boundaries.
- `.planning/STATE.md` - Current milestone status and phase readiness context.

### Existing implementation anchors
- `lib/features/ingestion/services/share_service.dart` - Mobile ingestion orchestration, dedupe prompt, URL/file branch behavior.
- `lib/features/ingestion/presentation/ingestion_summary_screen.dart` - Summary/edit-before-save flow and save/discard outcomes.
- `lib/features/chronological_list/presentation/item_list_screen.dart` - List/search/filter states, empty/error handling, item actions.
- `lib/features/reader/presentation/reader_screen.dart` - Reader metadata/context display and current error/fallback patterns.
- `lib/core/database/app_database.dart` - Ordering semantics, label-filter semantics, and FTS query entry points.
- `lib/features/intelligence/services/semantic_search_service.dart` - Search-mode fallback and ranking merge behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ShareService` already centralizes URL/file ingestion, duplicate prompts, and summary navigation.
- `IngestionSummaryScreen` already supports editable title/author plus label assignment before save.
- `ItemListScreen` already implements search, filter chips, semantic toggle gating, and explicit empty/error render paths.
- `ReaderScreen` already handles metadata context, no-content state, external open fallback, and delete-confirm flow.
- `AppDatabase.searchItems` already provides FTS-based search with optional AND label filtering.

### Established Patterns
- List ordering defaults to `sort_order ASC` then `created_at DESC` for active items.
- Soft-delete with recycle bin semantics is established and should remain consistent on web.
- Search and filtering are stream-driven from Drift queries; UI responds reactively to DB state.
- Error communication currently favors inline text/snackbar patterns over silent failures.

### Integration Points
- Web ingest entry should flow into existing ingestion summary save/discard semantics.
- Web list/filter/search should preserve same DB query contracts to avoid behavior divergence.
- Reader open actions should keep `last_opened_at` updates and respect existing URL/file branching.
- Search UI behavior should sit on top of current FTS service contracts unless explicitly deferred to later phases.

</code_context>

<deferred>
## Deferred Ideas

- Full multi-select bulk actions on web list (deferred beyond Phase 19).
- Keyboard shortcut packages for list and reader (deferred beyond Phase 19).
- Fuzzy/typo-tolerant search and persistent search history (deferred beyond Phase 19).

</deferred>

---

*Phase: 19-web-parity-core-flows*
*Context gathered: 2026-04-18*
