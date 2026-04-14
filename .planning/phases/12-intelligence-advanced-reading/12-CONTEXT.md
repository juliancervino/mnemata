# Phase 12: Intelligence & Advanced Reading - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 12 adds intelligence features to existing reading/search flows: AI article summaries, semantic search, persistent highlights/annotations in Reader View, and tag suggestions from existing tags.

This phase extends existing list, reader, and database capabilities. New ingestion channels (for example browser extension implementation) are out of scope for this context pass.
Text-to-speech is explicitly deferred to a later phase.

</domain>

<decisions>
## Implementation Decisions

### AI Summaries
- **D-01:** Summaries are generated on demand from Reader View (not precomputed at ingest time), then cached per item.
- **D-02:** Summary output format is fixed to three blocks: TL;DR (1-2 lines), Key Points (3-5 bullets), and Why it matters (1 short paragraph).
- **D-03:** Summaries are generated only for URL items with extracted `content`; file items without extractable text show an explicit unsupported-state message.
- **D-04:** Summary generation must be idempotent for unchanged content: re-run only when item content hash changes.
- **D-20:** AI summary generation requires a user-provided API key. If no key is configured, summary features are disabled with explicit setup guidance.

### Semantic Search
- **D-05:** Keep a single search entry point in the existing list screen, with a mode toggle between keyword (current FTS) and semantic search.
- **D-06:** Semantic indexing targets extracted article content first; title/url matching continues to use existing keyword logic.
- **D-07:** Query behavior is hybrid: semantic mode returns concept-near results, then falls back to keyword results when semantic recall is weak or unavailable.
- **D-08:** Semantic indexing runs asynchronously and incrementally after content is saved/updated, never blocking ingestion or reader rendering.
- **D-21:** Semantic features require a user-provided API key under the same billing model as summaries; without key, semantic mode remains unavailable and keyword mode continues to work.

### Highlights and Annotations
- **D-09:** Highlights are created from selected text in Reader View using a contextual action flow (highlight-only or highlight+note).
- **D-10:** Annotation persistence stores both quote text and positional anchors tied to item id, so highlights survive normal reader reloads.
- **D-11:** Reader UI shows inline highlight styling plus a per-item annotation list for quick navigation/edit/delete.
- **D-12:** Deleting an item cascades and removes all associated annotations/highlights.

### Tag Suggestions
- **D-13:** Add an AI-assisted tag suggestion action for an item that proposes tags only from the set of existing tags in the database.
- **D-14:** The suggestion flow must never propose creating a new tag in this phase; users can only apply, ignore, or manually edit existing tags.
- **D-15:** Tag suggestion uses extracted content/title context and follows the same API-key requirement as other AI features.

### Reliability and Privacy Guardrails
- **D-17:** AI summary and semantic features are wrapped behind settings toggles with safe defaults and explanatory copy.
- **D-18:** External AI provider calls (if used) must go through a dedicated service boundary, with request timeout and deterministic user-visible error mapping.
- **D-19:** No raw credentials are persisted in item records; sensitive configuration belongs to secure app settings integration.
- **D-22:** User API keys are stored in secure platform storage and never written to item tables, logs, or exported backup payloads.

### the agent's Discretion
- Exact summary prompt wording and token budget.
- Choice of embedding/reranker model and tuning values.
- Final UX microcopy for empty/error states.
- Fine-grained annotation visual styling.
- Ranking heuristic for selecting among existing tags returned as suggestions.

</decisions>

<specifics>
## Specific Ideas

- Preserve the existing fast local-first feel: intelligence features must layer onto current Drift + FTS behavior rather than replacing it.
- Reuse current Reader and list entry points to avoid navigation churn.
- Prefer progressive enhancement: when AI/semantic capability is unavailable, keep keyword search and reading fully functional.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product Scope and Success Criteria
- `.planning/ROADMAP.md` - Phase 12 goal, dependencies, and success criteria for summaries, semantic search, annotations, and tag suggestions.
- `.planning/PROJECT.md` - Product constraints and local-first value proposition that intelligence work must preserve.

### Requirement Mapping
- `.planning/REQUIREMENTS.md` - POR-04 intelligence requirement and POR-03 portability research status.

### Architecture and Conventions
- `.planning/codebase/ARCHITECTURE.md` - Current presentation/service/persistence layering and app data flow.
- `.planning/codebase/STRUCTURE.md` - Feature locations and integration points for list/reader/settings.
- `.planning/codebase/CONVENTIONS.md` - Naming, error-handling, and code-style conventions.
- `.planning/codebase/STACK.md` - Runtime/dependency constraints for Flutter/Drift and package additions.
- `.planning/codebase/INTEGRATIONS.md` - Existing platform and external integration surfaces.

### Current Integration Anchors in Code
- `lib/features/reader/presentation/reader_screen.dart` - Reader action surface for summary and annotation controls.
- `lib/features/chronological_list/presentation/item_list_screen.dart` - Existing search UX and stream selection logic to extend with semantic mode.
- `lib/core/database/app_database.dart` - Existing FTS search and schema migration patterns for new persistence objects.
- `lib/core/database/tables.dart` - Baseline schema definitions where annotation/insight tables will be introduced.
- `lib/features/settings/services/settings_service.dart` - Existing toggle persistence surface for intelligence feature flags.
- `lib/features/labels` - Existing tag model and assignment flows reused by suggestion feature.
- `pubspec.yaml` - Dependency baseline and constraints for any new AI/TTS/search packages.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AppDatabase.searchItems(...)` already provides FTS-backed keyword search and can remain the keyword baseline.
- `ReaderScreen` already centralizes per-item reading actions (open/share/delete), making it the natural anchor for summary, annotations, and TTS controls.
- `SettingsService` already persists feature toggles and runtime state, fitting intelligence capability switches.

### Established Patterns
- Feature-first organization with `presentation/` and `services/` split should be followed for summary, semantic, and annotation modules.
- Drift migration/versioning is already established (`schemaVersion`, `onUpgrade`) and should carry new annotation/semantic persistence safely.
- UI failures are surfaced through friendly in-app messaging (SnackBars/dialogs), not silent failure.

### Integration Points
- Search integration: `ItemListScreen._getStream(...)` is the main point to branch keyword vs semantic mode.
- Reader integration: action area in `ReaderScreen` can host summary trigger, annotation panel, and TTS controls without route changes.
- Persistence integration: `AppDatabase` + schema tables are the authoritative path for cached summaries, annotation anchors, and playback progress.

</code_context>

<deferred>
## Deferred Ideas

- Full browser-extension implementation remains a separate capability track and is not included in this context artifact.

</deferred>

---

*Phase: 12-intelligence-advanced-reading*
*Context gathered: 2026-04-14*
