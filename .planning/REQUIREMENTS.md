# Requirements: Mnemata

**Defined:** 2026-04-17
**Core Value:** A centralized, cross-platform repository for all knowledge and references, ensuring content is permanently saved, cleanly extracted, effortlessly discoverable through full-text search, and intuitively organized.

## v2.0 Requirements

Requirements for milestone v2.0 (Web Client and Multi-Device Synchronization).

### Web Parity (WEB)

- [ ] **WEB-01**: User can ingest content from web (URL/file) with validation behavior equivalent to mobile.
- [ ] **WEB-02**: User can browse chronological list on web with ordering, tag surfaces, and filters consistent with mobile.
- [ ] **WEB-03**: User can read extracted content on web with reader behavior and metadata context consistent with mobile.
- [ ] **WEB-04**: User can search on web with query semantics and empty/error states consistent with mobile.

### Synchronization Core (SYNC)

- [ ] **SYNC-01**: User data (items, tags, critical metadata) converges bidirectionally across linked devices under one account.
- [ ] **SYNC-02**: User changes made offline are queued and replayed idempotently when connectivity returns.
- [ ] **SYNC-03**: User can view sync health (last sync, pending changes, actionable failures) from app diagnostics.

### Conflict Determinism (CNF)

- [ ] **CNF-01**: Concurrent cross-device edits resolve through deterministic merge rules per entity/field with reproducible outcomes.

### Account and Device Linking (ACC)

- [ ] **ACC-01**: User can create/use app account sessions required for secure sync identity.
- [ ] **ACC-02**: User can list linked devices/sessions associated with account.
- [ ] **ACC-03**: User can revoke an active device/session remotely.

### Collaboration Primitives (COL)

- [ ] **COL-01**: User can share content through controlled share links.
- [ ] **COL-02**: User can invite collaborators to shared collections.
- [ ] **COL-03**: Shared content enforces basic roles (read-only and contributor).

## Future Requirements (Deferred)

### Conflict UX and Recovery

- **CNF-02**: User can inspect conflict timeline showing what won and why.
- **CNF-03**: User can manually resolve selected conflicts with explicit winner choice.

### Device Trust Controls

- **ACC-04**: User can rename and mark trusted devices.

### Link Governance

- **COL-04**: User can configure link expiration/visibility and unpublish links.

### Migration and Continuity

- **MIG-01**: User can continue reading context across devices (position/context carry-over).
- **MIG-02**: User can import from common read-later sources during onboarding.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Real-time multi-cursor collaboration | Requires low-latency co-edit architecture and conflict semantics beyond v2.0 baseline. |
| Enterprise ACL/workspace suite | Expands permissions and operations surface beyond minimum collaboration primitives. |
| Custom CRDT framework from scratch | High algorithmic/operational risk for first sync milestone. |
| Multi-backend sync at launch | Increases auth and convergence complexity before baseline stability is proven. |
| Major cross-platform visual redesign | v2.0 prioritizes behavior parity, convergence, and reliability over aesthetic overhaul. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| WEB-01 | TBD | Pending |
| WEB-02 | TBD | Pending |
| WEB-03 | TBD | Pending |
| WEB-04 | TBD | Pending |
| SYNC-01 | TBD | Pending |
| SYNC-02 | TBD | Pending |
| SYNC-03 | TBD | Pending |
| CNF-01 | TBD | Pending |
| ACC-01 | TBD | Pending |
| ACC-02 | TBD | Pending |
| ACC-03 | TBD | Pending |
| COL-01 | TBD | Pending |
| COL-02 | TBD | Pending |
| COL-03 | TBD | Pending |

**Coverage:**
- v2.0 requirements: 14 total
- Mapped to phases: 0
- Unmapped: 14 ⚠

---
*Requirements defined: 2026-04-17*
*Last updated: 2026-04-17 after v2.0 scope confirmation*
