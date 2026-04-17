# Roadmap: Mnemata

## Milestone History

- [x] **v1.0 milestone** - Archived planning artifacts and release tag available in `.planning/milestones/` and `v1.0`.

## Current Milestone: v1.1 Feature Expansion + Reliability

### Phases

- [x] **Phase 15: Content and Workflow Enhancements** - Deliver requested user-facing functionality without altering the existing title/body extraction pipeline.
- [x] **Phase 16: Runtime Cloud Validation** - Execute delayed real-device/account cloud runtime validation.
- [ ] **Phase 17: Integration Hardening** - Execute delayed deterministic integration/regression coverage.
- [ ] **Phase 18: Verification Quality Gates** - Enforce evidence quality and release gate criteria.

## Phase Details

### Phase 15: Content and Workflow Enhancements
**Goal:** Add requested product functionality while preserving existing extraction behavior and current user flows.
**Depends on:** Phase 14
**Requirements:** AUT-01, AUT-02, TRS-01, TRS-02, TRS-03, BKM-01, BKM-02, UX-04, SHR-01, SHR-02
**Success Criteria:**
  1. Author extraction is implemented in a new independent module; current title/body extraction path remains unchanged.
  2. Recycle bin is introduced with configurable 1-30 day retention and automatic permanent purge.
  3. URLs can be exported/imported using universal bookmarks format.
  4. Multi-selection no longer jumps scroll position when selecting additional items.
  5. Share flows support AI summary sharing (disabled if unavailable) and PDF attachment generation as an additional option.
**Plans:** 4 plans
Plans:
- [x] 15-01-PLAN.md - Author Extraction Module and Metadata Persistence
- [x] 15-02-PLAN.md - Recycle Bin, Retention Settings, and Auto Purge
- [x] 15-03-PLAN.md - Bookmark Import/Export (Universal HTML Format)
- [x] 15-04-PLAN.md - Multi-Select Scroll Stability and Share Enhancements (AI Summary + PDF)

### Phase 16: Runtime Cloud Validation
**Goal:** Validate end-to-end cloud reliability on real Google account/device environments.
**Depends on:** Phase 15
**Requirements:** POR-05, POR-06, POR-07
**Success Criteria:**
  1. Manual Google Drive backup is executed on real account/device and persisted diagnostics prove outcome.
  2. Restore selection and apply flow is validated from cloud on real account/device with integrity guards preserved.
  3. Scheduler runtime checks are validated with real conditions and deterministic reason-code evidence.
**Plans:** 1 plan
- [x] 16-01-PLAN - Human Runtime Cloud Validation Matrix and Evidence Capture

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
**Plans:** 2 plans
- [ ] 17-01-PLAN - Cloud Portability Integration and Restore Safety Regression Suite
- [ ] 17-02-PLAN - Scheduler and Intelligence Reliability Integration Coverage

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

