# Roadmap: Mnemata

## Milestone History

- [x] **v1.0 milestone** - Archived planning artifacts and release tag available in `.planning/milestones/` and `v1.0`.
- [x] **v1.1 milestone** - Feature Expansion + Reliability. Released 2026-04-17.

## Current Milestone: v2.0 (Planned)

### Phases

- [ ] **Phase 19: Synchronization Core** - Robust multi-device state synchronization.

## Phase Details
...
### Phase 17: Integration Hardening
**Goal:** Convert reliability assumptions into deterministic automated integration coverage.
**Depends on:** Phase 16
**Requirements:** REL-01, REL-02, REL-03, REL-04, REL-05
**Success Criteria:**
  1. Automated integration suite covers backup upload/list/download/preview/apply happy path.
  2. Corruption and mismatch restore paths are rejected safely with all-or-nothing guarantees.
  3. Scheduler policy branch behavior is deterministic and asserted by reason-code outputs.
  4. Startup ordering between share-intent initialization and non-blocking scheduler bootstrap is protected by integration tests.
  5. Intelligence flows are validated for safe fallback behavior under key/provider failures.
**Plans:** 1 plan
- [x] 17-01-PLAN - Cloud Portability Integration and Restore Safety Regression Suite
...

### Phase 18: Verification Quality Gates
**Goal:** Institutionalize release-readiness gates and artifact quality standards.
**Depends on:** Phase 17
**Requirements:** VER-01, VER-02
**Success Criteria:**
  1. Every v1.1 phase outputs verification artifacts with requirement-to-evidence traceability.
  2. Release gate requires automated reliability pass plus human cloud runtime validation completion.
  3. Milestone audit can pass without retrospective verification backfill work.
**Plans:** 1 plan
- [x] 18-01-PLAN - Verification Governance and Release Gate Enforcement

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 15. Content and Workflow Enhancements | 4/4 | Completed | 2026-04-17 |
| 16. Runtime Cloud Validation | 1/1 | Completed | 2026-04-17 |
| 17. Integration Hardening | 1/1 | Completed | 2026-04-17 |
| 18. Verification Quality Gates | 1/1 | Completed | 2026-04-17 |

## Completed Milestones

- [x] **v1.1 milestone** - Feature Expansion + Reliability. Released 2026-04-17.

