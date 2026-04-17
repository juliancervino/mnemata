# Feature Landscape: Mnemata v2.0 Web Client and Multi-Device Synchronization

**Domain:** Cross-platform knowledge capture and reader app (mobile + web)
**Milestone:** v2.0 Web Client and Multi-Device Synchronization
**Researched:** April 17, 2026
**Overall confidence:** MEDIUM-HIGH (official product/help docs + project context)

## 1) User-facing outcomes for v2.0

Users should feel the milestone in five concrete outcomes:

1. **Use Mnemata from desktop browser with no workflow downgrade**
    - Save content, browse chronological list, open reader, and run search from web with predictable behavior relative to mobile.
2. **Trust that library state converges across all devices**
    - Items, tags, and metadata updates appear on every signed-in device without manual repair.
3. **Understand and trust conflict behavior**
    - When two devices edit the same entity, Mnemata follows deterministic merge rules and exposes the outcome.
4. **Control account and linked devices securely**
    - Users can see where they are signed in, link new devices, and revoke unknown sessions/devices.
5. **Start sharing/collaboration without overcommitting architecture**
    - Users can share content via link or invite-based collection primitives, while advanced collaboration remains future scope.

## 2) Table-stakes features (must-have)

These are expected baseline capabilities for a 2026 cross-device reading/knowledge product.

| Feature group | Must-have capability | Why table-stakes now | Complexity |
|---------------|----------------------|----------------------|------------|
| **Web parity: ingest** | Web entry for URL/content ingestion with same core validation and dedupe semantics as mobile. | Users expect capture from desktop browser in modern read-later/bookmark apps. | Medium |
| **Web parity: chronological list** | List, sort order, tags, and metadata badges match mobile semantics. | Cross-platform parity breaks if ordering/filtering differ by platform. | Medium |
| **Web parity: reader** | Read extracted content on web with stable rendering and metadata context. | "Save anywhere, read anywhere" is baseline across competitors. | Medium |
| **Web parity: search** | Full-text search on web with same query expectations as mobile and deterministic empty/error states. | Users expect instant retrieval from any device. | Medium |
| **Multi-device sync core** | Bidirectional sync for items, tags, and critical metadata; offline changes queue and replay safely. | Cross-device continuity is the core promise of v2.0. | High |
| **Deterministic conflict handling** | Defined merge matrix by entity/field (for example, additive tags merge, scalar metadata by deterministic precedence), plus idempotent replays. | Sync without deterministic conflict rules destroys trust quickly. | High |
| **Sync observability UX** | Last sync timestamp, sync status state, retry signal, and actionable error messages. | Users need to know if data is actually synced. | Medium |
| **Account + session/device model** | Account identity, sign-in/out, device/session listing, and remote revoke/sign-out. | Secure device linking is expected for multi-device products. | High |
| **Collaboration primitives (minimum viable)** | Share by link and invite-to-collection primitive with at least read-only vs contributor role. | Sharing is expected, but deep collaboration can be deferred. | Medium |

## 3) Differentiators (should-have)

These are high-value enhancements that improve adoption and perceived quality, but can follow table-stakes if schedule pressure rises.

| Feature | Value proposition | Complexity | Why it matters for v2.0 |
|--------|-------------------|------------|--------------------------|
| **Conflict resolution timeline** | Human-readable "what won and why" history for conflicted entities. | Medium | Turns sync from "black box" into explainable behavior. |
| **Manual conflict review mode** | For high-risk fields, allow "create conflict copy" or manual pick-winner action. | High | Provides safety valve for users who distrust silent merges. |
| **Device trust controls** | Rename device, mark trusted, and revoke sessions quickly from account screen. | Medium | Improves security confidence and reduces support burden. |
| **Link controls for shared artifacts** | Expiring links, visibility mode (private/invite/public), and quick unpublish. | Medium | Matches practical sharing patterns without full ACL systems. |
| **Import bridge from common read-later sources** | Bring existing saved links into Mnemata during onboarding. | Medium | Reduces switching friction from incumbents. |
| **Cross-device state continuity polish** | Preserve "where I left off" in reader/search context between devices. | Medium | Tangibly improves daily multi-device workflow quality. |

## 4) Anti-features / not for this milestone

These are intentionally out of scope to protect schedule and reduce architecture risk.

| Anti-feature | Why not in v2.0 | Better v2.0 alternative |
|--------------|------------------|-------------------------|
| **Real-time collaborative live editing (multi-cursor)** | Requires low-latency co-edit architecture and conflict semantics beyond milestone goals. | Async collaboration via sync + explicit conflict workflows. |
| **Fine-grained enterprise ACL model** | Roles, groups, inheritance, and policy engines inflate scope sharply. | Start with owner + read-only/contributor sharing roles. |
| **Custom CRDT framework from scratch** | High algorithmic and operational risk for first sync milestone. | Deterministic merge matrix + explicit conflict records. |
| **Multi-provider sync backends at launch** | Multiplying providers multiplies auth, consistency, and support complexity. | Ship one robust sync backend first with clean abstraction seam. |
| **Large cross-platform UI redesign** | Parity milestone should optimize behavioral consistency, not visual churn. | Limit UX changes to sync/account/share usability and clarity. |
| **Advanced team workspace suite (org billing, admin console, audit exports)** | Collaboration primitives do not require enterprise surface area yet. | Validate collection-level sharing model first. |

## 5) Complexity notes and suggested slicing order

### Complexity notes by feature group

| Feature group | Complexity | Hidden risk to plan for |
|---------------|------------|-------------------------|
| Account/session primitives | High | Token lifecycle, revoked-session propagation, and safe device relinking. |
| Sync transport + change model | High | Idempotency, partial failure replay, and migration compatibility. |
| Conflict rules + merge behavior | High | Edge cases around concurrent edits and offline bursts. |
| Web parity surfaces (ingest/list/reader/search) | Medium | Subtle parity drift vs mobile behavior and metadata presentation. |
| Sharing primitives | Medium | Permission leakage and link-scope mistakes. |
| Observability UX | Medium | Event taxonomy quality determines debuggability/supportability. |

### Suggested slicing order for roadmap phases

1. **Slice A: Identity and session backbone**
    - Account model, auth/session lifecycle, linked-device list, revoke flow.
2. **Slice B: Sync contract and engine**
    - Entity versioning, change feed protocol, idempotent apply, offline queue replay.
3. **Slice C: Deterministic conflict engine**
    - Merge matrix by entity/field, conflict event persistence, deterministic tests.
4. **Slice D: Web parity read path**
    - Web list + reader + search wired to synced data model.
5. **Slice E: Web parity write path**
    - Web ingest/edit flows with same validation/dedupe/metadata semantics.
6. **Slice F: Sharing primitives**
    - Invite + link sharing, basic roles, revoke/unpublish paths.
7. **Slice G: Trust and support polish**
    - Sync status UX, conflict timeline, retry affordances, account security ergonomics.

## 6) Dependencies among feature groups

```text
Account/session model
  -> Device linking + session revoke
  -> Authenticated sync transport

Canonical entity schema (items/tags/metadata) + versioning
  -> Sync engine
  -> Conflict merge matrix

Sync engine (idempotent apply, replay, retries)
  -> Web parity consistency (list/reader/search/ingest)
  -> Collaboration primitives consistency

Conflict merge matrix + conflict event store
  -> Deterministic conflict UX
  -> User trust diagnostics

Permission model (owner/read-only/contributor) + identity
  -> Invite collaboration
  -> Public/private link sharing controls

Observability taxonomy (sync states, errors, conflict reasons)
  -> Supportability and QA verification
  -> Release confidence gates for v2.0
```

## Sources

- `.planning/PROJECT.md` (v2.0 goals and scope)
- `https://readwise.io/read` (cross-device parity, local-first web app, full-text search, offline sync claims)
- `https://www.instapaper.com/` (save-anything/read-anywhere and offline cross-device baseline)
- `https://raindrop.io/` (cross-device access, full-text search, sharing/collaboration baseline)
- `https://help.raindrop.io/collaboration` (invite links, member/read-only role model)
- `https://help.raindrop.io/public-page` (public page lifecycle, publish/unpublish behavior)
- `https://www.notion.com/help/share-your-work` (invite, team share, web link permissions and expiration)
- `https://obsidian.md/help/sync/troubleshoot` (deterministic conflict handling options and merge behavior)
- `https://obsidian.md/help/sync/messages` (sync status and merge/conflict observability expectations)
- `https://obsidian.md/help/sync/version-history` (version restore/recovery expectation for sync safety)
- `https://support.google.com/accounts/answer/3067630?hl=en` (session definition, device/session visibility, remote sign-out expectations)
