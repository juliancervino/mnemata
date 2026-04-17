# Domain Pitfalls: v2.0 Web Parity + Multi-Device Sync + Collaboration Primitives

**Domain:** Offline-first Flutter app evolving from local SQLite + backup portability into web parity, account-linked sync, and collaboration primitives.
**Project:** Mnemata v2.0 Web Client and Multi-Device Synchronization
**Researched:** 2026-04-17

## Scope Assumptions

- Current app architecture is a feature-first modular monolith with `GetIt` singletons, Drift streams, and service orchestration from `lib/main.dart`.
- Persistence is local-first SQLite through Drift (`MnemataItems`, `Labels`, `ItemLabels`, etc.) with no global IDs, no sync metadata, and no account ownership columns.
- Existing cloud capability is backup/restore snapshot transport (`CloudBackupProvider`) rather than per-record replication.

## 1) High-probability failure modes for this scope

| ID | Failure mode | Severity | Confidence |
|----|--------------|----------|------------|
| P1 | Record identity collisions across devices (items/labels) due to local auto-increment integer IDs being treated as business identity. | Critical | HIGH |
| P2 | Delete resurrection and ghost records from current recycle-bin purge model once devices go offline for long periods. | Critical | HIGH |
| P3 | Non-deterministic conflict outcomes caused by missing causal metadata and mixed UTC/local timestamps. | Critical | HIGH |
| P4 | Reorder thrash (list order oscillation) when concurrent devices sync `sortOrder` snapshots. | High | HIGH |
| P5 | Tag fragmentation (duplicate semantic labels) because label identity is currently name-based and case-sensitive. | High | HIGH |
| P6 | Treating backup archive pipeline as sync pipeline (large snapshots, poor convergence, attachment path breakage). | High | HIGH |
| P7 | Web client blocked by current ingestion stack and platform imports (`readability` FFI, share-intent assumptions, file APIs). | Critical | HIGH |
| P8 | Drift web persistence instability from missing explicit `DriftWebOptions` wiring, worker assets, and browser-mode guardrails. | High | HIGH |
| P9 | Google sign-in popup failures when combining drift performance headers (COOP/COEP) with account-linking UX. | High | MEDIUM |
| P10 | Startup choreography regressions from mobile-first bootstrap assumptions when web/session sync boot paths are added. | High | HIGH |
| P11 | Collaboration data leaks or edit authority bugs because no principal/ACL model exists in schema or services today. | Critical | HIGH |
| P12 | Late discovery of sync bugs because current tests do not model multi-device causal races or browser multi-tab behavior. | Critical | HIGH |

## 2) Why each pitfall happens in apps like this

### P1: Record identity collisions across devices
Apps that begin local-first typically use DB row IDs as stable IDs. In Mnemata, `MnemataItems.id` and `Labels.id` are `integer().autoIncrement()` and all joins depend on those integers. That is fine locally, but two devices can both create `id=42` with different meaning. If sync logic reuses these IDs as global keys, merges become corrupt.

### P2: Delete resurrection and ghost records
Offline-first sync needs durable tombstones until every replica has observed deletion. Mnemata currently uses `deletedAt` soft delete plus startup purge in `RecyclePurgeService` with time-based retention. That local retention policy can erase evidence of deletion before remote replicas receive it.

### P3: Non-deterministic conflict outcomes
Deterministic sync needs a stable ordering primitive (server version, Lamport, vector, or equivalent). Current writes mix `DateTime.now()` and `.toUtc()` across fields (`createdAt`, `lastOpenedAt`, cache metadata), and there is no per-entity version vector/revision.

### P4: Reorder thrash from `sortOrder`
`ReorderableListView` writes a full in-memory order back through `updateItemsSortOrderInBatch`, resetting `sortOrder` positions for all visible rows. With multi-device edits, this causes last-writer-wins oscillation or repeated reorder conflicts unless order is modeled as intent-based operations.

### P5: Tag fragmentation
`Labels` has no unique constraint on normalized names; `getLabelByName` is exact match (`name.equals(name)`), while some call sites insert labels directly. In collaboration/sync, case and punctuation variants (`ai`, `AI`, `ai `) become separate IDs, fragmenting filters and permissions.

### P6: Backup-as-sync misuse
Current provider abstraction supports archive upload/list/download/delete, not incremental mutation exchange. Snapshot archives include whole DB/files and local path assumptions. That model is excellent for backup portability but poor for near-real-time state convergence and collaborative edits.

### P7: Web client blocked by platform-specific ingestion stack
The current build fails for web because `readability` imports `dart:ffi`. Ingestion and settings flows also rely on `dart:io`, share-intent plugin streams, and file-system operations. Without conditional interfaces, web parity stalls before sync even begins.

### P8: Drift web mode instability
Mnemata opens DB with `driftDatabase(name: ...)` and no explicit web options. Current `web/` folder has no `sqlite3.wasm` or drift worker. Drift docs indicate robust web behavior depends on explicit wasm/worker wiring and browser capability handling; otherwise fallback implementations may be slow or unsafe for multi-tab.

### P9: COOP/COEP and auth popup incompatibilities
For high-performance drift web modes, COOP/COEP headers may be needed. Google Identity docs warn popup communication can break under strict COOP unless configured correctly (`same-origin-allow-popups` when FedCM is not handling popup flow). Account/device linking introduces this conflict directly.

### P10: Mobile-first startup assumptions
`main.dart` currently bootstraps share listeners and background services immediately after DI setup. The startup-order test is a simulated call-order test, not a platform-real bootstrap integration. Adding web session bootstrap + sync scheduling can regress this choreography.

### P11: Collaboration without principal model
Current schema has no user, membership, role, or item-level ACL tables. All edits are local-authoritative operations. Collaboration primitives (shared items, invites, permissions) require principal ownership and authorization boundaries before exposing cross-user writes.

### P12: Insufficient test topology for distributed bugs
Current tests are strong for local DB behavior and backup reliability, but they do not simulate two replicas editing concurrently, nor browser tab concurrency behavior. Distributed correctness bugs therefore surface late in manual QA or production.

## 3) Early warning signals in implementation/testing

| ID | Early warning signals to watch immediately |
|----|-------------------------------------------|
| P1 | Sync payloads require ID remapping tables; duplicate-key or foreign-key mismatch incidents appear in first prototype migrations. |
| P2 | Items deleted on one device reappear after another device reconnects; retention purge runs before long-offline device sync catches up. |
| P3 | Same edit sequence yields different merged values between emulator runs; timestamp skew or timezone-dependent merges appear in logs. |
| P4 | List order "jumps" after sync, especially after two devices reorder concurrently. |
| P5 | Tag picker shows near-duplicate labels; filter counts diverge between devices after merge. |
| P6 | Sync intervals produce large upload/download payloads with minimal user-visible changes; attachment copies dominate transfer time. |
| P7 | `flutter build web` fails (already observed) with `dart:ffi` import path from ingestion extraction stack. |
| P8 | Browser console shows fallback storage warnings, tab desync, or degraded persistence mode; missing worker/wasm assets in deployment. |
| P9 | Google sign-in popup opens blank or closes without callback after enabling cross-origin isolation headers. |
| P10 | Startup regressions: missed share ingestion, duplicate bootstrap runs, or transient navigation null-state errors in early web sessions. |
| P11 | Shared content appears editable by unintended users in prototype collaboration flows; no auditable owner metadata on records. |
| P12 | Team adds sleeps/retries in sync tests; intermittent CI failures around race-heavy scenarios become normalized. |

## 4) Preventive architecture/testing strategies

### P1-P3 core data convergence strategy
- Add immutable global IDs (UUID/ULID) for `MnemataItems`, `Labels`, and join records; keep integer row IDs as local storage internals only.
- Add sync metadata columns/tables: `updatedAtUtc`, `deletedAtUtc`, `deviceId`, `actorId`, and per-entity revision (or operation log with causal ordering).
- Normalize all domain timestamps to UTC at write boundaries. Remove mixed local-time writes.

### P2 durable delete semantics
- Introduce explicit tombstone table or tombstone state that survives recycle retention until remote acknowledgment watermark advances.
- Gate physical purge behind sync checkpoint, not only elapsed days.

### P4 ordering conflict mitigation
- Replace full-list rewrites with operation-based ordering (move-after/before operations) or conflict-friendly rank keys (fractional indexing / sequence CRDT approach).
- Include reorder conflict tests with interleaved operations from at least two replicas.

### P5 canonical label identity
- Add normalized label key (`lower(trim(name))`) with unique index.
- Route all label creation through a single service API; remove direct `insertLabel` write paths in UI flows that bypass normalization.

### P6 explicit boundary between backup and sync
- Keep backup archive pipeline for disaster recovery only.
- Build a dedicated sync protocol with delta exchange, idempotent upserts, and content-addressed attachment transfer.
- Introduce attachment IDs and metadata records; avoid syncing absolute local file paths as identity.

### P7-P10 web parity architecture hardening
- Introduce platform interfaces + conditional imports for ingestion, file opening, and extraction pipelines.
- Replace or isolate `readability` FFI path for web-compatible extraction.
- Configure drift web explicitly with `DriftWebOptions` and ship required worker/wasm assets.
- Add startup policy matrix per platform so web bootstrap excludes mobile-only listeners while preserving non-blocking scheduler behavior.

### P9 auth and browser-header compatibility strategy
- Decide early whether to rely on FedCM-first web sign-in or popup fallback.
- Validate COOP/COEP and Google auth behavior together in staging before enabling cross-origin isolation globally.

### P11 collaboration safety baseline
- Add account/session and membership model before collaborative writes.
- Add ACL checks at service boundary for read/write operations and audit metadata (`createdBy`, `lastModifiedBy`).
- Define deterministic permission merge rules before adding UI invite flows.

### P12 verification strategy for distributed correctness
- Add deterministic multi-replica integration harness (at least two logical devices plus optional third stale replica).
- Add browser multi-tab integration tests for web DB behavior and sync race conditions.
- Add conflict golden tests (same operation trace must produce same final state).

## 5) Which future phases should own each mitigation

### Proposed v2.0 phase ownership map

- **Phase 19 (existing): Synchronization Core**
  - Global IDs, causal metadata, tombstones, delta protocol, attachment identity, deterministic conflict engine.
- **Phase 20 (proposed): Web Parity Runtime Foundation**
  - Conditional imports, web-safe ingestion fallbacks, drift web asset/config setup, platform bootstrap split.
- **Phase 21 (proposed): Account and Device Linking**
  - Principal model, session/device identity, auth-browser-header compatibility hardening.
- **Phase 22 (proposed): Collaboration Primitives**
  - Shared-space membership, ACL enforcement, collaborative edit permission rules.
- **Phase 23 (proposed): Sync Verification and Rollout Hardening**
  - Multi-replica integration suite, browser multi-tab race suite, release gates for convergence guarantees.

### Pitfall-to-phase ownership matrix

| Pitfall ID | Primary phase owner | Secondary owner |
|------------|---------------------|-----------------|
| P1 | Phase 19 | Phase 23 |
| P2 | Phase 19 | Phase 23 |
| P3 | Phase 19 | Phase 23 |
| P4 | Phase 19 | Phase 23 |
| P5 | Phase 19 | Phase 22 |
| P6 | Phase 19 | Phase 20 |
| P7 | Phase 20 | Phase 23 |
| P8 | Phase 20 | Phase 23 |
| P9 | Phase 21 | Phase 20 |
| P10 | Phase 20 | Phase 23 |
| P11 | Phase 22 | Phase 21 |
| P12 | Phase 23 | Phase 19/20/21/22 |

## Confidence Assessment

- **Repository-specific failure modes:** HIGH (directly grounded in current schema, services, startup flow, and build results).
- **Web platform constraints:** HIGH (validated by current web build failure and Flutter/Drift/Google docs).
- **Auth-header compatibility guidance:** MEDIUM (official docs confirm constraints; exact behavior depends on chosen FedCM/popup flow and deployment headers).

## Sources

### Internal code and planning sources
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `lib/core/database/tables.dart`
- `lib/core/database/tables.drift`
- `lib/core/database/app_database.dart`
- `lib/features/chronological_list/services/recycle_purge_service.dart`
- `lib/features/chronological_list/presentation/item_list_screen.dart`
- `lib/features/ingestion/presentation/ingestion_summary_screen.dart`
- `lib/features/ingestion/services/extraction_service.dart`
- `lib/features/ingestion/services/share_service.dart`
- `lib/features/backup/services/cloud_backup_provider.dart`
- `lib/features/backup/services/backup_archive_service.dart`
- `lib/features/backup/services/backup_restore_service.dart`
- `lib/features/intelligence/services/api_key_store.dart`
- `lib/main.dart`
- `test/main_startup_test.dart`

### External references (official/current)
- Flutter Web FAQ (platform differences, `dart:io` and platform-specific imports): https://docs.flutter.dev/platform-integration/web/faq
- Flutter Web support overview: https://docs.flutter.dev/platform-integration/web
- Drift web docs (storage implementations, workers, headers, tab safety): https://drift.simonbinder.eu/platforms/web/
- `drift_flutter` API docs (`DriftWebOptions` requiring wasm/worker URIs): https://pub.dev/documentation/drift_flutter/latest/drift_flutter/DriftWebOptions-class.html
- pub.dev package metadata for `readability` (FFI plugin platforms): https://pub.dev/api/packages/readability
- pub.dev package metadata for `receive_sharing_intent` (android/ios only): https://pub.dev/api/packages/receive_sharing_intent
- Google Identity setup docs (COOP popup requirements): https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid?hl=en#cross_origin_opener_policy

### Empirical validation executed in this repository
- `flutter build web` run on 2026-04-17 fails due to `readability` importing `dart:ffi`, confirming immediate web parity blocker in current codebase.
