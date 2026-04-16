# Phase 15: Content and Workflow Enhancements - Context

**Gathered:** 2026-04-16
**Status:** Ready for planning
**Source:** User scope replan (feature-first sequencing)

<domain>
## Phase Boundary

Deliver requested functional enhancements before deferred reliability phases:
- Author metadata extraction
- Recycle bin with retention and auto purge
- Bookmark import/export for URLs
- Multi-select scroll stability fix
- Share enhancements (AI summary option + PDF attachment)

Do not include cloud runtime validation/integration hardening/governance in this phase.

</domain>

<decisions>
## Implementation Decisions

### Locked
- Author extraction must be implemented in a dedicated module and must not modify existing title/body extraction behavior.
- Existing content extraction pipeline for title and body remains unchanged.
- Recycle-bin retention must be configurable in Settings between 1 and 30 days.
- Permanent deletion must run automatically after retention window.
- Import/export scope is URLs only, using universal bookmarks format (Netscape Bookmark HTML).
- Multi-select must preserve current scroll position when selecting while scrolling.
- Sharing must support AI summary from summary view and item-share view.
- AI summary share option must be disabled when summary is unavailable.
- Sharing must support additional option to attach generated PDF from item content.

### the agent's Discretion
- Internal architecture, data migration approach, and service boundaries.
- Specific UI affordance labels/placement, as long as behavior matches requirements.
- Test strategy details and fixture design.

</decisions>

<canonical_refs>
## Canonical References

### Planning
- `.planning/ROADMAP.md` — Phase 15 goals, success criteria, plan split.
- `.planning/REQUIREMENTS.md` — AUT/TRS/BKM/UX/SHR requirement definitions.
- `.planning/PROJECT.md` — milestone goal and feature-first sequencing.
- `.planning/STATE.md` — active milestone state.

### Code areas likely impacted
- `lib/features/ingestion/services/` — extraction services.
- `lib/core/database/` — item schema and lifecycle behavior.
- `lib/features/chronological_list/presentation/` — multi-select list behavior.
- `lib/features/intelligence/` — summary sharing availability.
- `lib/features/settings/` — retention configuration.
- existing sharing flows in list/reader/ingestion features.

</canonical_refs>

<specifics>
## Specific Ideas

- Keep author extraction loosely coupled: new service/class plus explicit integration point.
- Recycle bin likely requires soft-delete metadata and cleanup scheduler/job.
- PDF sharing should be additive to existing share behavior, not replacement.

</specifics>

<deferred>
## Deferred Ideas

- POR-05..07 (runtime cloud validation) in Phase 16.
- REL-01..05 (integration hardening) in Phase 17.
- VER-01..02 (verification quality gates) in Phase 18.

</deferred>

---
*Phase: 15-content-and-workflow-enhancements*
*Context gathered: 2026-04-16 via user-directed scope replan*
