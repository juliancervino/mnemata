# Architecture: v2.0 Sync and Web Parity Integration

**Project:** Mnemata  
**Milestone:** v2.0 Web Client and Multi-Device Synchronization  
**Researched:** 2026-04-17  
**Scope:** Integrate web parity (ingest/list/reader/search), account/session identity, deterministic sync, and collaboration primitives into the existing Flutter + Drift feature-module architecture.

## 1) Existing architecture relevant to v2.0

### 1.1 Runtime composition and module boundaries (today)

- The app is a feature-first Flutter monolith rooted in `lib/main.dart`.
- Dependencies are wired through `GetIt`, with direct singleton registration for:
  - `AppDatabase`
  - Ingestion services (`ShareService`, `ExtractionService`, `PdfExtractionService`)
  - Intelligence services (summary/semantic/annotation)
  - Backup/auth services (`GoogleDriveAuthClient`, `CloudBackupProvider`, scheduler)
  - `SettingsService` (SharedPreferences-backed)
- Feature modules are organized under `lib/features/*` and mostly split into:
  - `presentation/` (widgets/screens)
  - `services/` (orchestration/business logic)

### 1.2 Persistence and query boundaries (today)

- `AppDatabase` in `lib/core/database/app_database.dart` is both repository and query layer.
- Drift schema currently centers on:
  - `mnemata_items`
  - `labels`
  - `item_labels`
  - intelligence caches (`summary_caches`, `semantic_*`, `annotation_records`)
- Search is local-only via SQLite FTS5 (`mnemata_search` virtual table and triggers in `lib/core/database/tables.drift`).
- Important characteristics for v2 planning:
  - Local-first streams are already strong (`watchAllItems`, `searchItems`, label-filter watches).
  - Items and labels use local auto-increment integer IDs (not globally stable across devices).
  - Soft delete exists (`deletedAt`) and can anchor sync tombstone semantics.

### 1.3 User-facing flows tied to v2 scope (today)

- **Ingestion:** `ShareService` -> extraction -> `IngestionSummaryScreen` -> `insertItem` + label assignment.
- **List/Reader/Search:** `ItemListScreen` streams directly from `AppDatabase`; reader and item editing also write directly through DB methods.
- **Search:** keyword FTS and optional semantic search fallback are local-device only.
- **Account-like behavior:** only Google Drive sign-in exists, scoped to backup operations in settings.

### 1.4 Gaps blocking v2.0 if unchanged

1. No account/session model for first-party app identity, device linking, or cross-device auth state.
2. No sync metadata model (global IDs, clocks/versions, outbox/inbox).
3. No deterministic conflict resolver contract shared by all writes.
4. UI writes bypass a command boundary and hit `AppDatabase` directly, making change journaling difficult.
5. Multiple mobile-only dependencies and `dart:io` imports are on core paths, which blocks reliable web parity rollout if not isolated behind platform adapters.

## 2) Proposed target architecture for sync + web parity

### 2.1 Core strategy

Adopt a **local-first replicated client** with deterministic merge rules and account-scoped synchronization:

- Keep Drift as the local source of rendering truth.
- Add an operation journal/outbox for all user writes.
- Introduce account, session, and device identity as first-class domain objects.
- Add a sync coordinator that pushes local operations and pulls remote deltas.
- Apply the same deterministic merge policy on client and server.

### 2.2 Target boundary map

```text
Flutter UI (mobile + web)
  -> Feature Controllers (ingest/list/reader/search)
  -> Command/Query Repositories
      -> Drift Local Store (items, labels, metadata, sync_state)
      -> Local Outbox (operations)

Sync Coordinator
  -> Authenticated Sync Transport
  -> Delta Pull + Ack Cursor
  -> Conflict Resolver + Merge Applier

Identity Layer
  -> Account Service
  -> Session/Token Service
  -> Device Registration Service

Collaboration Layer
  -> Share Graph Service (shares, invites, permissions)
```

### 2.3 Deterministic conflict resolution model (recommended)

Use **operation-based merge with stable tie-breakers**, not "last write by client clock" alone.

For each mutable entity (`item`, `label`, `item_label`, collaboration edge), store:

- `entity_uuid` (stable across devices)
- `logical_version` (monotonic per entity, server-assigned or HLC-normalized)
- `last_mutation_id` (ULID)
- `last_mutated_by_device_id`
- `updated_at_server`
- `deleted_at` (tombstone)

Merge rules:

1. **Scalar fields** (title, author, content, metadata): highest `logical_version` wins.
2. **Version tie:** lexicographically smaller `last_mutation_id` wins (stable, deterministic tie-break).
3. **Tag assignment (`item_label`)**: use OR-Set semantics with explicit add/remove operations and tombstones.
4. **Delete vs update:** delete wins when delete operation version is >= update version.
5. **Sort/order conflicts:** replace raw integer order with rank tokens (LexoRank-style strings) to avoid index-collision churn across devices.

This policy must be enforced identically in both client merge logic and backend apply logic.

### 2.4 Web parity architecture direction

Do not fork features by platform. Keep one feature set and inject platform adapters for capabilities:

- `IngestionEntryAdapter`:
  - mobile: share-intent + file path pipelines
  - web: URL form ingest + file upload ingest
- `ExternalOpenAdapter`:
  - mobile: `open_filex` / `url_launcher`
  - web: browser navigation/download APIs
- `ContentCaptureAdapter`:
  - mobile: existing extraction + optional WebView route
  - web: browser-safe extraction path without native-only assumptions

## 3) New components/services and responsibilities

### 3.1 Client-side components

| Component | Layer | Responsibility | Integrates with existing code |
|---|---|---|---|
| `AccountService` | Core identity | Sign-up/sign-in/sign-out, account profile, account-scoped app state | New service in `lib/core/identity/`; referenced from settings and startup bootstrap |
| `SessionService` | Core identity | Token lifecycle, refresh, secure persistence, session validity checks | Complements current Google Drive auth flow, but app-level identity becomes primary |
| `DeviceRegistryService` | Core sync | Stable per-install `device_id`, register device with account, key rotation hooks | Startup bootstrap in `main.dart` |
| `SyncOutboxService` | Core sync | Persist local mutations as durable operations | Called by write repositories instead of direct DB-only writes |
| `SyncCoordinatorService` | Core sync | Orchestrate push/pull cycles, backoff, retry, foreground/background scheduling | Similar orchestration role to current backup scheduler |
| `SyncTransportClient` | Core sync | HTTP/gRPC transport to sync API, cursor/delta endpoints | New API client package under `lib/features/sync/services/` |
| `ConflictResolverService` | Core sync | Deterministic merge apply for local vs remote mutations | Used during pull-apply and reconciliation |
| `SyncStateStore` | Core sync | Store sync cursor, per-entity sync status, last sync diagnostics | New Drift tables + settings diagnostics wiring |
| `ItemWriteRepository` | Domain write boundary | Create/update/delete item and emit outbox events atomically | Replaces direct write calls from screens/services |
| `LabelWriteRepository` | Domain write boundary | Label CRUD + item-label mutations + outbox events atomically | Replaces direct label writes from screens |
| `IngestionEntryAdapter` | Platform adapter | Abstract ingest entry points by platform | Wraps existing `ShareService` and web ingest UI path |
| `CollaborationService` | Collaboration domain | Create share links/invitations, accept/revoke access, map permissions | Plugs into settings/item actions and sync graph |

### 3.2 Backend-aligned components (required for full v2 behavior)

| Component | Responsibility | Why required for client integration |
|---|---|---|
| `Identity API` | Account auth, sessions, refresh tokens, device registration | Needed for device linking and per-account sync scope |
| `Sync API` | Mutation ingest, deterministic apply, delta feed by cursor | Required for multi-device convergence |
| `Collaboration API` | Share graph, invitation lifecycle, ACL decisions | Required for cross-user content exchange primitives |
| `Conflict Policy Module` | Central authoritative merge policy versioning | Ensures deterministic behavior across clients and server |

### 3.3 Boundary changes to current code

1. Screen-level write paths should move from direct `AppDatabase` calls to write repositories.
2. `AppDatabase` remains local query/read backbone (streams and FTS), but not the only write entrypoint.
3. `SettingsService` should be split conceptually into:
   - local UX preferences (auto-tag, toggles)
   - sync/account diagnostics (session + sync status)
4. Existing Google Drive auth remains backup-specific, not the main account identity source.

## 4) Data flow and state ownership changes

### 4.1 Ownership model

| State Domain | Primary Owner | Local Replica | Notes |
|---|---|---|---|
| Account profile | Identity API | Yes (cached) | Server authoritative |
| Sessions/tokens | SessionService + Identity API | Yes | Secure storage/web-safe storage policy required |
| Devices linked to account | Identity API | Yes | Needed for deterministic tie-break metadata |
| Items/tags/core metadata | Sync API + deterministic merge policy | Yes (Drift) | Local-first edits, eventual convergence |
| Item-label relations | Sync API + OR-Set merge | Yes | Must be operation-based to avoid toggle races |
| Collaboration graph (shares, permissions) | Collaboration API | Yes | ACL decisions are server-authoritative |
| FTS search index | Local DB (derived) | N/A | Rebuilt/maintained from local canonical tables |
| AI caches (summary/semantic chunks) | Local client | Yes | Keep local-only in v2 initial scope unless explicitly shared later |

### 4.2 Local write flow (target)

1. UI triggers domain command (create/update/delete/tag/change-order).
2. Write repository performs one local transaction:
   - update canonical Drift tables
   - append outbox mutation row
   - mark entity sync status = pending
3. Drift streams update UI immediately (offline-first).
4. Sync coordinator asynchronously pushes outbox operations.

### 4.3 Pull/merge flow (target)

1. Sync coordinator requests deltas since last cursor.
2. For each remote mutation, conflict resolver compares local and remote versions.
3. Winner is applied deterministically; loser retained as superseded metadata for diagnostics.
4. Cursor advances only after durable local apply.
5. FTS and derived projections remain consistent through DB triggers or explicit projection refresh.

### 4.4 Collaboration primitive flow (target)

1. Owner creates share intent for an item (or collection in future).
2. Collaboration API issues invitation/share edge with permission level.
3. Recipient accepts; share edge replicates via normal sync delta stream.
4. ACL-filtered item projections appear in recipient local DB.

## 5) Suggested implementation order by dependency

### Phase A: Platform-safe baseline for web parity

1. Introduce platform adapters for ingestion/opening/extraction entrypoints.
2. Remove direct mobile-only assumptions from app-critical startup paths.
3. Ensure web target compiles/runs with list/reader/search baseline.

### Phase B: Sync-ready data model and write boundaries

4. Add global UUIDs + sync metadata columns/tables (Drift migration).
5. Introduce write repositories and route all item/label mutations through them.
6. Add outbox and sync state tables with transactional write + outbox append semantics.

### Phase C: Identity and device linking

7. Implement account/session/device services and startup bootstrap.
8. Add account/session UX in settings and enforce account-scoped sync context.

### Phase D: Deterministic sync engine

9. Implement sync transport (push, pull, ack cursor).
10. Implement deterministic conflict resolver and merge application.
11. Add integration tests for conflict classes (concurrent edit/edit, edit/delete, tag add/remove, reorder collisions).

### Phase E: Collaboration primitives

12. Add minimal share graph support: invite, accept, revoke, read/write permission levels.
13. Sync collaboration edges and ACL-filtered item visibility.

### Phase F: Hardening and observability

14. Add sync diagnostics panel (last sync, pending ops, conflict count, session status).
15. Add migration and restore compatibility tests spanning pre-v2 and v2 schemas.

Dependency logic:

- Web parity baseline comes first because sync/account work must run on both mobile and web.
- Deterministic sync depends on stable IDs and command boundary enforcement.
- Collaboration must build on account + sync primitives, not before.

## 6) Migration/compatibility constraints

### 6.1 Drift/schema constraints

1. Current schema version is 9; v2 changes must be additive and migration-safe.
2. Existing integer IDs cannot be removed immediately; add UUID columns and backfill.
3. Existing query methods used by UI should continue to work during transition to repositories.
4. FTS triggers must stay valid after schema evolution and merge apply operations.

### 6.2 Data compatibility constraints

1. Existing local-only users must upgrade without account lockout; allow deferred account linking.
2. Backup/restore archives from prior versions must remain importable.
3. Sync metadata should not corrupt legacy backup flows; if needed, bump backup manifest schema while keeping backward reader compatibility.
4. Tombstones must be retained long enough to prevent delete resurrection on stale devices.

### 6.3 Platform compatibility constraints

1. `dart:io` and mobile-only plugins cannot remain in mandatory web execution paths.
2. Share-intent behavior must degrade gracefully on web via explicit ingestion UI.
3. File ingest/open behavior must use web-safe adapters (upload/download/browser open).

### 6.4 Determinism and reliability constraints

1. Do not use raw device wall-clock as sole conflict authority.
2. Use stable operation IDs and version ordering with explicit tie-break rules.
3. Merge policy must be versioned and test-locked across client/server.
4. Sync apply must be idempotent and crash-safe (replay same mutation without divergence).

### 6.5 Security constraints

1. App account session storage must use secure storage on mobile and hardened web strategy.
2. Device linking and collaboration permissions must be server-authoritative.
3. Client-side ACL caching is optimization only; never final authority.

## Recommended integration stance

Keep Mnemata's strongest current qualities (local-first Drift streams, feature modules, simple Flutter UI flow), but introduce three explicit new boundaries: **identity/session**, **replication/conflict**, and **collaboration graph**. Avoid a rewrite; evolve through repository/write boundary insertion + schema extension + sync coordinator layering.