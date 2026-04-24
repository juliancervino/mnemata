# Roadmap: Mnemata

## Milestone History

- [x] **v1.0 milestone** - Archived planning artifacts and release tag available in `.planning/milestones/` and `v1.0`.
- [x] **v1.1 milestone** - Feature Expansion + Reliability. Released 2026-04-17.


## Current Milestone: v2.0 (Planned)

**Milestone Goal:** Deliver a reliability-first web client and deterministic multi-device synchronization foundation with secure account/device identity and baseline collaboration primitives.

## Phases

- [x] **Phase 19: Web Parity Core Flows** - Web ingest, list, reader, and search behave consistently with mobile.
- [ ] **Phase 20: Account Sessions and Device Linking** - Secure account identity and linked-device session management for sync trust.
- [ ] **Phase 21: Deterministic Sync and Conflict Convergence** - Offline-safe bidirectional sync with reproducible conflict outcomes and sync diagnostics.
- [ ] **Phase 22: Collaboration Primitive Access Model** - Controlled sharing links, collaborator invites, and basic role enforcement.


## Phase Details

### Phase 19: Web Parity Core Flows
**Goal**: Users can complete core Mnemata workflows on web with behavior parity to mobile.
**Depends on**: Nothing (first phase)
**Requirements**: WEB-01, WEB-02, WEB-03, WEB-04
**Success Criteria** (what must be TRUE):
  1. User can ingest URL/file on web with validation and failure behavior equivalent to mobile.
  2. User can browse chronological content on web with ordering, tag surfaces, and filters consistent with mobile semantics.
  3. User can read extracted content on web with equivalent metadata context and deterministic empty/error handling.
  4. User can run search on web with query behavior and empty/error states consistent with mobile.
**Plans**: 5 plans
Plans:
- [x] 19-01-PLAN.md - Web-safe startup and Drift web runtime foundation
- [x] 19-02-PLAN.md - WEB-01 ingestion parity (unified add, validation, duplicate/recovery)
- [x] 19-03-PLAN.md - WEB-03 reader and PDF parity (layout, controls, restore, guided errors)
- [x] 19-04-PLAN.md - WEB-02 list/filter parity (quick actions, pagination, delete undo, state continuity)
- [x] 19-05-PLAN.md - WEB-04 search parity (debounce, snippets, actionable empty/error states)
**UI hint**: yes

### Phase 19.1: Fix content extract problems on web version (INSERTED)

**Goal:** Users can reliably ingest URLs and PDFs on the web version using tiered proxies and client-side distillation, with manual fallbacks.
**Requirements**: WEB-05
**Depends on:** Phase 19
**Plans:** 4 plans

Plans:
- [ ] 19.1-00-PLAN.md — Extraction and Metadata Priority Test Scaffolding
- [ ] 19.1-01-PLAN.md — Web Foundation (JS-Interop for Defuddle & Metadata priority)
- [ ] 19.1-02-PLAN.md — Tiered Raw Proxy Pipeline (corsproxy.io, allorigins.win)
- [ ] 19.1-03-PLAN.md — PDF Web Fix & Manual Ingest UI

### Phase 20: Account Sessions and Device Linking
**Goal**: Users can authenticate into stable account sessions and manage linked devices required for secure sync identity.
**Depends on**: Phase 19
**Requirements**: ACC-01, ACC-02, ACC-03
**Success Criteria** (what must be TRUE):
  1. User can create/use an app account session and remain authenticated across restarts until sign-out or revocation.
  2. User can view linked devices/sessions associated with their account.
  3. User can revoke an active device/session remotely and that revoked session loses subsequent sync authorization deterministically.
**Plans**: TBD
**UI hint**: yes

### Phase 21: Deterministic Sync and Conflict Convergence
**Goal**: Users get reliable, offline-safe multi-device convergence with deterministic merge outcomes and transparent sync health.
**Depends on**: Phase 20
**Requirements**: SYNC-01, SYNC-02, SYNC-03, CNF-01
**Success Criteria** (what must be TRUE):
  1. User data (items, tags, critical metadata) converges bidirectionally across linked devices under one account.
  2. User changes made offline are queued and replayed idempotently when connectivity returns, without duplicate or lost effects.
  3. Concurrent cross-device edits resolve with deterministic merge rules per entity/field and produce reproducible final state on every linked device.
  4. User can view sync health diagnostics including last sync, pending changes, and actionable failures.
**Plans**: TBD
**UI hint**: yes

### Phase 22: Collaboration Primitive Access Model
**Goal**: Users can share and collaborate with minimum viable controls while preserving deterministic authorization boundaries.
**Depends on**: Phase 21
**Requirements**: COL-01, COL-02, COL-03
**Success Criteria** (what must be TRUE):
  1. User can create controlled share links for content and recipients can access linked content under defined sharing controls.
  2. User can invite collaborators to shared collections and invited users can access accepted shares.
  3. Shared content enforces basic roles so read-only users cannot modify content while contributors can.
**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 19. Web Parity Core Flows | 5/5 | Completed | 2026-04-20 |
| 19.1 Fix content extract problems on web version | 0/4 | In Progress | - |
| 20. Account Sessions and Device Linking | 0/0 | Not started | - |
| 21. Deterministic Sync and Conflict Convergence | 0/0 | Not started | - |
| 22. Collaboration Primitive Access Model | 0/0 | Not started | - |

## Completed Milestones


- [x] **v1.1 milestone** - Feature Expansion + Reliability. Released 2026-04-17.
