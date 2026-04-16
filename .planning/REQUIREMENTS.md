# Requirements: Mnemata

**Defined:** 2026-04-16
**Core Value:** A centralized, cross-platform repository for all knowledge and references, ensuring content is permanently saved, cleanly extracted, effortlessly discoverable through full-text search, and intuitively organized.

## v1.1 Requirements

Requirements for the v1.1 milestone (Reliability & Verification).

### Cloud Runtime Validation (POR)

- [ ] **POR-05**: User can complete a manual Google Drive backup on a real account/device and see persisted success diagnostics.
- [ ] **POR-06**: User can select a cloud backup and complete restore on a real account/device with integrity checks enforced.
- [ ] **POR-07**: Scheduler runtime behavior (run/skip/fail) is verified on real-device conditions and recorded with deterministic reason codes.

### Integration Reliability (REL)

- [ ] **REL-01**: System has an automated integration test for backup upload/list/download/preview/apply happy-path flow.
- [ ] **REL-02**: Restore safety is verified by automated tests for corruption classes (checksum mismatch, missing required entries) with all-or-nothing apply guarantees.
- [ ] **REL-03**: Scheduler reliability tests are deterministic across policy branches (not due, network/power constraints, due-and-run).
- [ ] **REL-04**: Startup-order integration test verifies share-intent initialization remains non-regressed while scheduler bootstrap stays non-blocking.
- [ ] **REL-05**: Intelligence critical flows (summary, semantic search, tag suggestions) fail safely and fall back predictably under missing key/provider failures.

### Verification Governance (VER)

- [ ] **VER-01**: Every v1.1 phase publishes verification artifacts with explicit requirement-to-evidence mapping before phase closure.
- [ ] **VER-02**: Milestone release gate requires both automated reliability suite pass and human cloud runtime validation completion.

## v2 Requirements (Deferred)

### Reliability UX Enhancements

- **RUX-01**: Reliability confidence scorecard in Settings (backup age, scheduler health, restore readiness).
- **RUX-02**: Restore readiness preview with explicit risk flags before apply.
- **RUX-03**: Audit-ready verification evidence bundle export for milestone handoff.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New AI generation capabilities or new model providers | Expands risk surface during reliability hardening milestone. |
| Additional cloud providers beyond Google Drive | Current provider still has human-runtime validation debt to close first. |
| Major UX redesign unrelated to reliability observability | Increases regression noise without improving trust outcomes. |
| Aggressive scheduler policy redesign | Prioritize deterministic validation of current policy over behavior expansion. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| POR-05 | Phase 15 | Pending |
| POR-06 | Phase 15 | Pending |
| POR-07 | Phase 15 | Pending |
| REL-01 | Phase 16 | Pending |
| REL-02 | Phase 16 | Pending |
| REL-03 | Phase 16 | Pending |
| REL-04 | Phase 16 | Pending |
| REL-05 | Phase 16 | Pending |
| VER-01 | Phase 17 | Pending |
| VER-02 | Phase 17 | Pending |

**Coverage:**
- v1.1 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-04-16*
*Last updated: 2026-04-16 after v1.1 milestone definition*
