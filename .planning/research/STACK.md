# Technology Stack Delta: Mnemata v2.0

**Project:** Mnemata
**Milestone:** v2.0 Web Client and Multi-Device Synchronization
**Researched:** 2026-04-17
**Scope:** v2 additions only (do not restate stable v1.x stack except where needed for integration)

## Executive Recommendation

Adopt **Supabase (Auth + Postgres + RLS + Realtime + Storage)** as the single v2 backend platform, keep **Drift as the local source of UI truth**, and add a **deterministic sync layer** (operation outbox + versioned merge policy) between local Drift and cloud state.

This is the highest-leverage path because it solves identity, device linking, data authorization, and synchronization transport without introducing a second backend framework or rewriting the existing local-first app architecture.

## 1) v2.0 Stack Additions

### 1.1 Backend and Identity (new)

| Technology | Recommended Version | Purpose in v2 | Why this choice |
|---|---:|---|---|
| Supabase Auth | Managed service (current) | First-party account/session model, device linking foundation, OAuth/email flows | Native integration with Flutter SDK, JWT model fits row-level ownership and sync scoping |
| Supabase Postgres | Managed service (current) | Canonical multi-device data model (items, labels, memberships, sync metadata) | Mature relational model, strong transaction support, deterministic conflict policy implementable via SQL/functions |
| Supabase Row Level Security (RLS) | Postgres policy layer | Enforce per-user/per-share authorization in database | Security boundary is server-authoritative and testable; prevents client-side ACL drift |
| Supabase Realtime | Managed service (current) | Lightweight invalidation and collaboration events | Avoid polling-heavy sync loops; enables responsive convergence indicators |
| Supabase Storage | Managed service (current) | Shared attachment/blob storage for multi-device and collaboration primitives | Keeps metadata in Postgres and binary payloads in object storage, with one auth model |

### 1.2 Flutter/Dart client dependencies (new or upgraded)

| Library | Version Baseline | Role in v2 | Integration note |
|---|---:|---|---|
| supabase_flutter | 2.12.4 | Auth, database API, realtime channels, storage access | Add under core identity/sync services, not directly in UI widgets |
| drift | 2.32.1 | Local replica and query engine | Upgrade from 2.16.x to align with current drift web guidance |
| drift_flutter | 0.3.0 | Cross-platform DB bootstrap including web options | Explicitly configure DriftWebOptions and web wasm/worker URIs |
| flutter_secure_storage | 10.0.0 | Mobile secure token persistence | Use custom Supabase LocalStorage on mobile; do not rely on web secure-storage semantics |
| uuid | 4.5.3 | Stable globally unique IDs for entities and mutations | Replace integer ID assumptions in sync identity layer |
| dio (optional) | 5.9.2 | Custom sync transport client (if bypassing PostgREST for sync endpoints) | Keep optional; only add if sync API shape requires richer HTTP middleware |

## 2) Integration with Existing Mnemata Architecture

### 2.1 What remains unchanged

- Flutter feature module structure under lib/features.
- Drift-backed local-first reads and FTS behavior as primary rendering path.
- Existing backup/restore flow remains disaster recovery, not sync transport.

### 2.2 New integration boundaries to add

| Existing Area | v2 Addition | Integration contract |
|---|---|---|
| main.dart bootstrapping | Identity + session bootstrap | Register AccountService, SessionService, DeviceRegistryService in DI before sync starts |
| AppDatabase write paths | Write repositories + outbox appends | Every write must atomically update local tables and enqueue sync operation |
| settings/account UI | Session/device management | Surface signed-in account, linked devices, revoke/sign-out state |
| ingestion/list/reader/search | Platform adapters for web safety | Move mobile-only plugin calls behind conditional interfaces |
| sync scheduling | SyncCoordinator service | Push/pull loop with deterministic conflict resolution and cursor ack |

### 2.3 Required web runtime additions

- Add web assets for drift:
  - web/sqlite3.wasm
  - web/drift_worker.dart.js
- Configure DriftWebOptions with explicit URIs.
- Keep conditional imports for dart:io dependent flows.
- Add browser compatibility handling when drift falls back to weaker persistence modes.

## 3) Explicit Exclusions (Do Not Add in v2.0)

| Exclusion | Why excluded now | Safer v2 choice |
|---|---|---|
| Firestore as primary sync store | Official offline conflict model is last-write-wins for multiple changes to same document, which conflicts with deterministic merge guarantees | Postgres + explicit merge policy versioning |
| Custom CRDT framework | High algorithmic and operational risk for first sync milestone | Deterministic operation merge matrix with explicit tie-break rules |
| Multi-backend provider abstraction at launch | Doubles auth/consistency/test burden | One backend platform first (Supabase), abstraction later if needed |
| Replacing Drift with remote-first reads | Breaks current local-first UX and increases latency/offline regressions | Keep Drift as local query source of truth |
| Advanced enterprise ACL (orgs, nested roles, billing) | Scope explosion relative to milestone goals | Owner + read-only/contributor collaboration primitives |
| Service-role key in client apps | Security anti-pattern; bypasses RLS controls | Client uses publishable/anon key + authenticated JWT only |

## 4) Risks and Compatibility Notes

| Risk | Impact | Mitigation | Confidence |
|---|---|---|---|
| COOP/COEP headers needed for preferred drift web mode can conflict with popup auth | Google sign-in popup failures on web | Validate FedCM path first; if popup flow needed, tune COOP per Google guidance and fall back from strict cross-origin isolation when required | HIGH |
| Drift web storage mode varies by browser capabilities | Potential multi-tab persistence edge cases | Detect chosen storage implementation; warn users when running degraded modes | HIGH |
| flutter_secure_storage web mode is not equivalent to native secure enclave/keychain | False security assumptions for browser token storage | Use Supabase session persistence strategy with explicit web policy; reserve secure storage for mobile secrets | HIGH |
| Existing mobile-only plugins in critical flows (readability FFI, share-intent) block web parity | Build/runtime failures on web | Isolate platform-specific code behind adapters and conditional imports | HIGH |
| RLS policy complexity can create performance regressions | Slow list/search/sync queries at scale | Add indexes for policy predicates and policy-aware query filters | MEDIUM-HIGH |
| Sync merge behavior drift between client and backend implementations | Non-deterministic convergence across devices | Version merge policy and enforce golden tests on both sides | HIGH |

## 5) Confidence Notes by Decision

| Decision | Confidence | Why |
|---|---|---|
| Supabase as v2 backend platform | MEDIUM-HIGH | Strong feature fit (Auth + Postgres + RLS + Realtime + Storage) with Flutter support; still requires schema/policy rigor |
| Keep Drift as local canonical read store | HIGH | Matches current architecture strengths and minimizes migration risk |
| Deterministic operation-based sync (not raw LWW) | HIGH | Required by explicit v2 milestone goals and conflict-trust requirements |
| Web parity through adapters + conditional imports | HIGH | Consistent with Flutter web constraints and current plugin compatibility realities |
| Excluding CRDT framework in v2 | MEDIUM-HIGH | Reduces initial delivery risk while preserving a later migration path |

## 6) Roadmap Decomposition Guidance (Actionable)

Current roadmap has a single v2 phase entry. Split into dependency-ordered implementation slices:

1. **Phase 19.1: Web Runtime Baseline**
   - Add conditional imports/adapters.
   - Enable drift web assets and DriftWebOptions.
   - Exit criteria: web build green; list/reader/search compile and run.

2. **Phase 19.2: Sync-Ready Schema and Identity Keys**
   - Add entity UUIDs, mutation IDs, sync metadata, tombstone retention fields.
   - Introduce write repositories + outbox transaction pattern.
   - Exit criteria: all writes produce deterministic local mutation records.

3. **Phase 19.3: Account, Session, and Device Linking**
   - Integrate Supabase Auth and session persistence.
   - Add device registration and session management surfaces.
   - Exit criteria: secure sign-in/out and linked-device visibility.

4. **Phase 19.4: Deterministic Sync Engine**
   - Implement push/pull cursor protocol and merge policy versioning.
   - Add conflict classes: edit/edit, edit/delete, add/remove label, reorder.
   - Exit criteria: repeatable convergence in multi-device integration tests.

5. **Phase 19.5: Collaboration Primitives**
   - Add share/invite tables and RLS policies for owner/contributor/read-only.
   - Use realtime for invalidation and UX freshness, not authoritative state.
   - Exit criteria: controlled cross-user read/write according to policy.

6. **Phase 19.6: Hardening and Release Gates**
   - Browser matrix, multi-tab tests, startup ordering tests, failure-injection sync tests.
   - Add diagnostics UI (last sync, pending ops, conflict count, auth status).
   - Exit criteria: deterministic pass criteria and rollback-safe migration path.

## 7) Practical Adoption Notes

### 7.1 Dependency baseline commands

```bash
# New
flutter pub add supabase_flutter uuid

# Upgrades for web+sync foundation
flutter pub add drift@^2.32.1 drift_flutter@^0.3.0 flutter_secure_storage@^10.0.0

# Optional (only if custom sync HTTP client needed)
flutter pub add dio
```

### 7.2 Backend setup notes

- Use Supabase migrations for schema and RLS policy evolution from day one.
- Keep a single source of truth for merge policy version and apply logic.
- Enforce RLS on all exposed sync/collaboration tables before client rollout.

## 8) Sources

### High-confidence (official docs / package APIs)
- https://supabase.com/docs/guides/auth
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/database/functions
- https://supabase.com/docs/guides/realtime
- https://supabase.com/docs/guides/getting-started/tutorials/with-flutter
- https://pub.dev/documentation/supabase_flutter/latest/
- https://drift.simonbinder.eu/platforms/web/
- https://docs.flutter.dev/platform-integration/web/faq
- https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid?hl=en#cross_origin_opener_policy
- https://pub.dev/api/packages/drift
- https://pub.dev/api/packages/drift_flutter
- https://pub.dev/api/packages/supabase_flutter
- https://pub.dev/api/packages/flutter_secure_storage
- https://pub.dev/api/packages/uuid
- https://pub.dev/api/packages/dio
- https://pub.dev/api/packages/readability
- https://pub.dev/api/packages/receive_sharing_intent
- https://raw.githubusercontent.com/mogol/flutter_secure_storage/develop/README.md
- https://firebase.google.com/docs/firestore/manage-data/enable-offline

### Internal project context
- .planning/PROJECT.md
- .planning/ROADMAP.md
- .planning/research/FEATURES.md
- .planning/research/ARCHITECTURE.md
- .planning/research/PITFALLS.md
- pubspec.yaml
