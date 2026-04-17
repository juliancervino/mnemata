# Project Research Summary

**Project:** Mnemata
**Domain:** Local-first knowledge capture and reader platform
**Milestone:** v2.0 Web Client and Multi-Device Synchronization
**Researched:** 2026-04-17
**Confidence:** MEDIUM-HIGH

## Executive Summary

Mnemata v2.0 should be built as a local-first replicated system: keep Drift as the local rendering/query source of truth, then add account-linked deterministic synchronization for cross-device convergence. The recommended implementation pattern is not a rewrite. Instead, introduce explicit identity/session, outbox/sync, and collaboration boundaries around the current feature-module architecture so web and mobile share one behavioral contract.

The strongest stack direction is a single backend platform for v2.0: Supabase Auth + Postgres + RLS + Realtime + Storage, with `supabase_flutter` on client and Drift upgraded for robust web support. This gives one coherent identity and authorization model while preserving Mnemata's current local-first UX strengths.

Key risks are deterministic merge drift, web platform blockers in mobile-only code paths, and authorization leaks when adding sharing primitives. Mitigation is reliability-first: versioned merge policy, idempotent outbox/apply semantics, RLS-enforced data access, browser/runtime hardening, and phase gates that prove deterministic behavior before collaboration rollout.

## Key Findings

### Recommended Stack

v2.0 should add cloud identity and sync capabilities without replacing local Drift reads. Keep one backend for launch to reduce operational and test complexity, and prefer explicit deterministic merge policy over implicit last-write-wins behavior.

**Core technologies:**
- Supabase Auth: account/session and device-linking foundation with Flutter SDK support.
- Supabase Postgres + RLS: canonical multi-device state with server-authoritative per-user/share authorization.
- Supabase Realtime + Storage: low-latency invalidation/events and attachment storage under same auth model.
- Drift 2.32.1 + drift_flutter 0.3.0: local replica/query engine with explicit web wasm/worker configuration.
- supabase_flutter 2.12.4 + uuid 4.5.3: client identity/sync transport and stable global IDs.

**Stack changes vs v1.x baseline:**
- Add first-party account/session architecture (not backup-only identity).
- Add deterministic sync metadata/outbox model between Drift and cloud.
- Add web-specific Drift runtime assets and platform adapter boundaries.

### Expected Features

**Must-have (table stakes):**
- Web parity groups: ingest, chronological list, reader, and full-text search with consistent semantics.
- Multi-device sync groups: bidirectional item/tag/metadata sync, offline queue replay, idempotent apply.
- Trust groups: deterministic conflict handling, sync status/diagnostics UX, account + linked-device visibility/revoke.
- Collaboration minimum: invite/link sharing primitives with basic roles (owner/read-only/contributor).

**Should-have (competitive):**
- Conflict timeline/explainability.
- Device trust controls (rename/trust/revoke ergonomics).
- Link lifecycle controls (expiry, visibility mode, unpublish).

**Out of scope for v2.0 (explicit boundaries):**
- Real-time multi-cursor collaborative editing.
- Enterprise ACL/billing/admin workspace model.
- Custom CRDT framework and multi-backend sync provider abstraction.
- Large cross-platform visual redesign unrelated to parity/reliability.

### Architecture Approach

Integrate v2.0 through additive boundaries around the current modular Flutter app: all writes move through command repositories that atomically update Drift and append outbox operations; a SyncCoordinator pushes/pulls deltas and applies a deterministic merge policy; account/session/device services initialize before sync; collaboration graph data is server-authoritative and replicated locally.

**Major components:**
1. Identity layer (AccountService, SessionService, DeviceRegistryService) for account scope and secure sessions.
2. Sync layer (Write repositories, SyncOutboxService, SyncCoordinator, ConflictResolver, SyncStateStore) for deterministic convergence.
3. Platform/runtime layer (web-safe adapters + Drift web config) for single-codebase parity.
4. Collaboration layer (share graph, invites, ACL-enforced permissions) for controlled cross-user data access.

### Critical Pitfalls

1. **Local integer IDs used as global identity**: add immutable UUIDs and sync metadata before multi-device rollout.
2. **Delete resurrection from premature purging**: retain tombstones until sync acknowledgment watermark allows safe cleanup.
3. **Non-deterministic conflict outcomes**: enforce versioned merge matrix with stable tie-breakers and golden tests.
4. **Web blockers from mobile-only imports/plugins**: isolate with conditional imports and platform adapters; remove `dart:io` from web-critical paths.
5. **Collaboration permission leakage**: ship principal + ACL model with server-side enforcement and auditable ownership metadata.

## Implications for Roadmap

Based on research, suggested v2.0 phase structure:

### Phase 19.1: Web Runtime Baseline
**Rationale:** Web compile/runtime blockers must be removed before sync/account work can be validated cross-platform.
**Delivers:** Platform adapters, web-safe ingestion/open paths, Drift wasm/worker configuration.
**Addresses:** Web parity foundation for list/reader/search.
**Avoids:** Pitfalls around `dart:ffi`/mobile-only dependencies and unstable drift web fallback modes.

### Phase 19.2: Sync-Ready Data Model and Write Boundaries
**Rationale:** Deterministic sync depends on stable identity and transactional write journaling.
**Delivers:** UUID backfill, sync metadata/tombstones, outbox tables, repository-only write path.
**Addresses:** Multi-device sync core and offline replay.
**Avoids:** Identity collisions, delete resurrection, and direct-write divergence.

### Phase 19.3: Account, Session, and Device Linking
**Rationale:** Cross-device sync and collaboration require authenticated principal context.
**Delivers:** Account/session lifecycle, device registration/list/revoke, startup bootstrap ordering.
**Uses:** Supabase Auth and secure token persistence patterns.
**Avoids:** Session drift, unauthorized device linkage, startup regressions.

### Phase 19.4: Deterministic Sync Engine
**Rationale:** This is the reliability-critical core and should be isolated behind clear pass/fail gates.
**Delivers:** Push/pull cursor protocol, idempotent apply, conflict resolver with versioned policy.
**Implements:** SyncCoordinator + ConflictResolver architecture.
**Avoids:** Non-deterministic convergence and reorder/tag conflict thrash.

### Phase 19.5: Collaboration Primitives
**Rationale:** Sharing should layer on verified identity/sync primitives, not precede them.
**Delivers:** Invite/link sharing, minimal roles, permission-filtered replication.
**Addresses:** Table-stake collaboration baseline.
**Avoids:** ACL leakage and role ambiguity.

### Phase 19.6: Hardening and Release Gates
**Rationale:** v2.0 trust depends on proving deterministic behavior under failure/race conditions.
**Delivers:** Browser matrix, multi-tab and multi-device race tests, diagnostics UX, rollback-safe migrations.
**Addresses:** Reliability-first release readiness.
**Avoids:** Late-discovered distributed bugs and support escalations.

### Phase Ordering Rationale

- Web runtime viability first, because all subsequent milestones must validate on both mobile and web.
- Identity and deterministic sync before collaboration, because permissions and sharing require converged principal-scoped state.
- Hardening last but mandatory, with explicit reliability gates before release.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 19.1:** Browser capability matrix, drift web storage mode behavior, and auth popup/header interplay.
- **Phase 19.4:** Detailed merge semantics for reorder/tags and backend/client parity verification strategy.
- **Phase 19.5:** Collaboration ACL schema and invite lifecycle edge cases.

Phases with standard patterns (can minimize extra research):
- **Phase 19.2:** UUID/backfill/outbox repository boundaries are well-established local-first patterns.
- **Phase 19.3:** Session/device management follows standard managed-auth service patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Strong official docs and Flutter package maturity; policy/schema rigor remains implementation-sensitive. |
| Features | MEDIUM-HIGH | Competitive baseline is clear across comparable products; exact prioritization still depends on delivery capacity. |
| Architecture | HIGH | Recommendations map directly to current codebase seams and migration path. |
| Pitfalls | HIGH | Risks are grounded in current schema/runtime constraints and known web/sync failure modes. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- Final backend schema and RLS policy shape must be validated against concrete collaboration use cases before Phase 19.5 execution.
- Merge-policy edge cases (especially reorder and label-set operations) need a shared golden-spec across client/server before release.
- Web auth flow and cross-origin header strategy must be tested early in staging to avoid late integration regressions.

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`
- Supabase official docs (Auth, Postgres, RLS, Realtime, Flutter)
- Drift official web/platform documentation
- Flutter web platform documentation

### Secondary (MEDIUM confidence)
- Comparable product/help docs used in FEATURES research (Readwise, Raindrop, Notion, Obsidian, Google Account session UX references)

---
*Research completed: 2026-04-17*
*Ready for roadmap: yes*
