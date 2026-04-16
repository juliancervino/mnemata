# Requirements: Mnemata

**Defined:** 2026-04-16
**Core Value:** A centralized, cross-platform repository for all knowledge and references, ensuring content is permanently saved, cleanly extracted, effortlessly discoverable through full-text search, and intuitively organized.

## v1.1 Requirements

Requirements for the v1.1 milestone (Feature Expansion + Reliability).

### Author Metadata (AUT)

- [ ] **AUT-01**: System extracts article author using a dedicated author-extraction module, without modifying existing title/body extraction modules.
- [ ] **AUT-02**: Extracted author metadata is persisted in the item model and available for display/use in item views.

### Recycle Bin and Retention (TRS)

- [ ] **TRS-01**: Deleted items are moved to a recycle bin (soft delete) instead of being immediately removed.
- [ ] **TRS-02**: User can configure recycle-bin retention in Settings between 1 and 30 days.
- [ ] **TRS-03**: Items in recycle bin are permanently deleted automatically when retention period expires.

### Bookmark Import/Export (BKM)

- [ ] **BKM-01**: User can export saved URLs to a universal bookmarks format (Netscape Bookmark HTML).
- [ ] **BKM-02**: User can import URLs from the same universal bookmarks format.

### Sharing and Selection UX (SHR/UX)

- [ ] **UX-04**: Multi-selection preserves current scroll position when selecting additional items.
- [ ] **SHR-01**: User can share AI summary from summary view and item-share view; option is disabled when summary does not exist.
- [ ] **SHR-02**: User can share item content as generated PDF attachment as an additional share option.

### Cloud Runtime Validation (POR) (Deferred Within v1.1)

- [ ] **POR-05**: User can complete a manual Google Drive backup on a real account/device and see persisted success diagnostics.
- [ ] **POR-06**: User can select a cloud backup and complete restore on a real account/device with integrity checks enforced.
- [ ] **POR-07**: Scheduler runtime behavior (run/skip/fail) is verified on real-device conditions and recorded with deterministic reason codes.

### Integration Reliability (REL) (Deferred Within v1.1)

- [ ] **REL-01**: System has an automated integration test for backup upload/list/download/preview/apply happy-path flow.
- [ ] **REL-02**: Restore safety is verified by automated tests for corruption classes (checksum mismatch, missing required entries) with all-or-nothing apply guarantees.
- [ ] **REL-03**: Scheduler reliability tests are deterministic across policy branches (not due, network/power constraints, due-and-run).
- [ ] **REL-04**: Startup-order integration test verifies share-intent initialization remains non-regressed while scheduler bootstrap stays non-blocking.
- [ ] **REL-05**: Intelligence critical flows (summary, semantic search, tag suggestions) fail safely and fall back predictably under missing key/provider failures.

### Verification Governance (VER) (Deferred Within v1.1)

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
| New AI generation capabilities or new model providers | Expands risk surface while v1.1 prioritizes functional expansion plus controlled reliability sequencing. |
| Additional cloud providers beyond Google Drive | Current provider still needs full runtime and integration verification closure first. |
| Major UX redesign unrelated to requested improvements | Increases regression noise without helping milestone goals. |
| Aggressive scheduler policy redesign | Prioritize deterministic validation of current policy over behavior expansion. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUT-01 | Phase 15 | Pending |
| AUT-02 | Phase 15 | Pending |
| TRS-01 | Phase 15 | Pending |
| TRS-02 | Phase 15 | Pending |
| TRS-03 | Phase 15 | Pending |
| BKM-01 | Phase 15 | Pending |
| BKM-02 | Phase 15 | Pending |
| UX-04 | Phase 15 | Pending |
| SHR-01 | Phase 15 | Pending |
| SHR-02 | Phase 15 | Pending |
| POR-05 | Phase 16 | Pending |
| POR-06 | Phase 16 | Pending |
| POR-07 | Phase 16 | Pending |
| REL-01 | Phase 17 | Pending |
| REL-02 | Phase 17 | Pending |
| REL-03 | Phase 17 | Pending |
| REL-04 | Phase 17 | Pending |
| REL-05 | Phase 17 | Pending |
| VER-01 | Phase 18 | Pending |
| VER-02 | Phase 18 | Pending |

**Coverage:**
- v1.1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

---
*Requirements defined: 2026-04-16*
*Last updated: 2026-04-16 after scope replan request*
