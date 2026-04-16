# Roadmap: Mnemata

## Milestone History

- [x] **v1.0 milestone** - Archived planning artifacts and release tag available in `.planning/milestones/` and `v1.0`.

## Current Milestone: v1.1 Reliability & Verification

### Phases

- [ ] **Phase 15: Runtime Cloud Validation** - Close real-device/account cloud reliability debt for backup, restore, and scheduler diagnostics.
- [ ] **Phase 16: Integration Hardening** - Add deterministic integration/regression coverage for cloud portability and intelligence-critical flows.
- [ ] **Phase 17: Verification Quality Gates** - Enforce phase-level evidence quality and release gate criteria to prevent verification backfill debt.

## Phase Details

### Phase 15: Runtime Cloud Validation
**Goal:** Validate end-to-end cloud reliability on real Google account/device environments.
**Depends on:** Phase 14
**Requirements:** POR-05, POR-06, POR-07
**Success Criteria:**
  1. Manual Google Drive backup is executed on real account/device and persisted diagnostics prove outcome.
  2. Restore selection and apply flow is validated from cloud on real account/device with integrity guards preserved.
  3. Scheduler runtime checks are validated with real conditions and deterministic reason-code evidence.
**Plans:** 1 plan
- [ ] 15-01-PLAN - Human Runtime Cloud Validation Matrix and Evidence Capture

### Phase 16: Integration Hardening
**Goal:** Convert reliability assumptions into deterministic automated integration coverage.
**Depends on:** Phase 15
**Requirements:** REL-01, REL-02, REL-03, REL-04, REL-05
**Success Criteria:**
  1. Automated integration suite covers backup upload/list/download/preview/apply happy path.
  2. Corruption and mismatch restore paths are rejected safely with all-or-nothing guarantees.
  3. Scheduler policy branch behavior is deterministic and asserted by reason-code outputs.
  4. Startup ordering between share-intent initialization and non-blocking scheduler bootstrap is protected by integration tests.
  5. Intelligence flows are validated for safe fallback behavior under key/provider failures.
**Plans:** 2 plans
- [ ] 16-01-PLAN - Cloud Portability Integration and Restore Safety Regression Suite
- [ ] 16-02-PLAN - Scheduler and Intelligence Reliability Integration Coverage

### Phase 17: Verification Quality Gates
**Goal:** Institutionalize release-readiness gates and artifact quality standards.
**Depends on:** Phase 16
**Requirements:** VER-01, VER-02
**Success Criteria:**
  1. Every v1.1 phase outputs verification artifacts with requirement-to-evidence traceability.
  2. Release gate requires automated reliability pass plus human cloud runtime validation completion.
  3. Milestone audit can pass without retrospective verification backfill work.
**Plans:** 1 plan
- [ ] 17-01-PLAN - Verification Governance and Release Gate Enforcement

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 15. Runtime Cloud Validation | 0/1 | Not started | - |
| 16. Integration Hardening | 0/2 | Not started | - |
| 17. Verification Quality Gates | 0/1 | Not started | - |

