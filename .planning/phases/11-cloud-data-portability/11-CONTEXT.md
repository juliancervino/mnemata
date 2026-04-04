# Phase 11: Cloud & Data Portability - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 11 delivers Google Drive backup and restore for Mnemata data portability.
This phase explicitly excludes browser extension implementation and extension research.

</domain>

<decisions>
## Implementation Decisions

### Backup Scope
- **D-01:** MVP backup is a full package: database, attachment files, settings, and a versioned integrity manifest.

### Restore Policy
- **D-02:** Restore flow is full restore with preview, integrity validation, and explicit user confirmation before applying changes.

### Scheduled Backup Policy
- **D-03:** Automatic backup runs daily.
- **D-04:** Automatic backup runs only on Wi-Fi and while charging.
- **D-05:** A manual backup trigger is always available.

### Portability Scope Control
- **D-06:** Browser extension work is deferred and out of scope for Phase 11.

### the agent's Discretion
- Technical format of backup manifest.
- Retry and telemetry details for scheduler runs.
- Exact restore preview UX details.

</decisions>

<specifics>
## Specific Ideas

- No additional non-negotiables were provided.
- Priority is to complete backup and restore robustly before extension work.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and Product
- `.planning/ROADMAP.md` - Phase 11 goal and success criteria.
- `.planning/PROJECT.md` - Cloud strategy decision prioritizing Google Drive.

### Requirements Mapping
- `.planning/REQUIREMENTS.md` - POR-01 and POR-02 for this phase; POR-03 intentionally deferred.

### Codebase Context
- `.planning/codebase/STACK.md` - Runtime and dependency constraints.
- `.planning/codebase/STRUCTURE.md` - Module and folder integration points.
- `.planning/codebase/INTEGRATIONS.md` - Existing platform and external integration surfaces.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Drift/SQLite persistence foundation already exists for export/import orchestration.
- Settings service and screens can host backup schedule controls.

### Established Patterns
- Feature-first modules with presentation/services split.
- Local-first architecture with platform integration points already used by ingestion and sharing.

### Integration Points
- Database and file-storage orchestration under `lib/core/database/` and ingestion services.
- Settings UX under `lib/features/settings/` for backup controls.
- App lifecycle entry in `lib/main.dart` for scheduling bootstrap.

</code_context>

<deferred>
## Deferred Ideas

- Browser extension implementation and browser-extension research moved to backlog/future phase.

</deferred>

---

*Phase: 11-cloud-data-portability*
*Context gathered: 2026-04-04*
