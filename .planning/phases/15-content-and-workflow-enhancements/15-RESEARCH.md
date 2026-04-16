# Phase 15: Content and Workflow Enhancements - Research

**Researched:** 2026-04-16
**Domain:** Flutter feature enhancement over ingestion, storage lifecycle, sharing, and list interaction behavior
**Confidence:** MEDIUM-HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Author extraction must be implemented in a dedicated module and must not modify existing title/body extraction behavior.
- Existing content extraction pipeline for title and body remains unchanged.
- Recycle-bin retention must be configurable in Settings between 1 and 30 days.
- Permanent deletion must run automatically after retention window.
- Import/export scope is URLs only, using universal bookmarks format (Netscape Bookmark HTML).
- Multi-select must preserve current scroll position when selecting while scrolling.
- Sharing must support AI summary from summary view and item-share view.
- AI summary share option must be disabled when summary is unavailable.
- Sharing must support additional option to attach generated PDF from item content.

### the agent's Discretion
- Internal architecture, data migration approach, and service boundaries.
- Specific UI affordance labels/placement, as long as behavior matches requirements.
- Test strategy details and fixture design.

### Deferred Ideas (OUT OF SCOPE)
- POR-05..07 (runtime cloud validation) in Phase 16.
- REL-01..05 (integration hardening) in Phase 17.
- VER-01..02 (verification quality gates) in Phase 18.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUT-01 | Extract author using dedicated module without modifying title/body modules. | Dedicated `author_extraction_service.dart` + integration seam in ingestion pipeline; no edits to existing title/body extraction logic. |
| AUT-02 | Persist author metadata and make it available in item views. | Drift schema extension (`author` nullable), migration strategy, and view model wiring for list/reader/summary surfaces. |
| TRS-01 | Soft delete to recycle bin. | Replace hard delete paths with soft-delete timestamp + filtered active queries. |
| TRS-02 | Retention setting 1-30 days in Settings. | SharedPreferences setting key + clamped numeric input + default policy. |
| TRS-03 | Auto purge expired recycle-bin items. | Startup/background purge service based on retention window and `deletedAt` age. |
| BKM-01 | Export URLs in Netscape Bookmark HTML. | HTML writer service emitting interoperable bookmark HTML structure. |
| BKM-02 | Import URLs from Netscape Bookmark HTML. | HTML parser service using existing `html` package and URL validation. |
| UX-04 | Preserve scroll while multi-selecting during scrolling. | Stable `ScrollController` and key strategy; avoid list rebuild patterns that reset position. |
| SHR-01 | Share AI summary from summary and item-share views; disable option when unavailable. | Share action matrix with capability gating tied to summary availability state. |
| SHR-02 | Share generated PDF attachment as additional option. | PDF generation service + `share_plus` file share via `XFile` attachments. |
</phase_requirements>

## Summary

Phase 15 should be implemented as four narrowly scoped vertical changes that share common persistence and sharing seams, but avoid broad refactors. Existing code already has clear insertion points: extraction (`lib/features/ingestion/services/extraction_service.dart`), persistence (`lib/core/database/app_database.dart`, `lib/core/database/tables.dart`), list behavior (`lib/features/chronological_list/presentation/item_list_screen.dart`), and share utilities (`lib/core/utils/share_utils.dart`). [VERIFIED: workspace code inspection]

The highest-risk area is data lifecycle migration: current deletes are hard deletes (`deleteItem`, `deleteItems`) and search is backed by Drift FTS triggers tied to `mnemata_items`. Introducing soft delete without query hygiene can create regressions (ghost search results, incorrect counts, purge races). [VERIFIED: workspace code inspection] Drift migration guidance supports additive migrations and explicit strategy hooks; this phase should use additive nullable fields and staged query updates rather than destructive schema rewrite. [CITED: https://drift.simonbinder.eu/migrations/]

Bookmark interoperability should stay intentionally conservative: URLs-only import/export with Netscape Bookmark HTML, because major browsers support HTML bookmark transfer workflows. [CITED: https://support.google.com/chrome/answer/96816] [CITED: https://support.mozilla.org/en-US/kb/import-bookmarks-html-file] Sharing enhancements should piggyback on existing `share_plus` patterns for text/files and attach generated PDFs via file-based shares. [CITED: https://github.com/fluttercommunity/plus_plugins/blob/main/packages/share_plus/share_plus/README.md]

**Primary recommendation:** Execute plans in roadmap order (`15-01 -> 15-02 -> 15-03 -> 15-04`) and treat schema + query updates as the phase backbone before UI polish. [VERIFIED: `.planning/ROADMAP.md`]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| drift | 2.32.1 (latest published 2026-03-22) | Local relational persistence + migrations | Existing project database stack; supports explicit migration strategies. [VERIFIED: workspace `pubspec.yaml`] [VERIFIED: pub.dev API] [CITED: https://drift.simonbinder.eu/migrations/] |
| shared_preferences | 2.5.5 (latest published 2026-03-25) | Persist retention settings | Already used settings substrate in project. [VERIFIED: workspace code inspection] [VERIFIED: pub.dev API] |
| share_plus | 13.0.0 (latest published 2026-04-10) | Native share sheet for text/files | Existing app share transport and supports file attachments. [VERIFIED: workspace `pubspec.yaml`] [VERIFIED: pub.dev API] [CITED: https://github.com/fluttercommunity/plus_plugins/blob/main/packages/share_plus/share_plus/README.md] |
| syncfusion_flutter_pdf | 33.1.49 (latest published 2026-04-14) | Generate PDF content for attachment sharing | Already present dependency for PDF generation capability. [VERIFIED: workspace `pubspec.yaml`] [VERIFIED: pub.dev API] |
| html | 0.15.6 (latest published 2025-04-24) | Parse imported Netscape bookmark HTML | Existing parser dependency suited for HTML tree traversal. [VERIFIED: workspace `pubspec.yaml`] [VERIFIED: pub.dev API] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| metadata_fetch | project pinned | Metadata extraction from URL/DOM metadata | Keep for existing title extraction path only. [VERIFIED: workspace extraction service] |
| readability | project pinned | Article content extraction | Keep unchanged for title/body extraction behavior contract. [VERIFIED: workspace extraction service] |
| flutter_test | SDK | Unit/widget tests | For all new behavior verifications in this phase. [VERIFIED: tests import `flutter_test`] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Drift soft-delete columns | Separate recycle-bin table | Increases migration complexity and duplicate query/update paths for this phase scope. [ASSUMED] |
| `html` package parsing | Regex/manual string parser | Fragile against nested bookmark folders and malformed HTML edge cases. [ASSUMED] |
| `share_plus` file share | Platform channels per OS | Higher maintenance and cross-platform regression risk. [ASSUMED] |

**Installation (if dependencies change):**
```bash
flutter pub add drift shared_preferences share_plus syncfusion_flutter_pdf html
```

## Architecture Patterns

### Recommended Project Structure
```text
lib/
├── features/ingestion/services/
│   ├── extraction_service.dart           # existing title/body extraction (unchanged)
│   └── author_extraction_service.dart    # new dedicated author extraction module
├── core/database/
│   ├── tables.dart                       # additive author/deletedAt fields
│   └── app_database.dart                 # migration + soft-delete query methods
├── features/bookmarks/services/
│   ├── bookmark_export_service.dart      # Netscape HTML writer (URLs only)
│   └── bookmark_import_service.dart      # Netscape HTML parser (URLs only)
└── core/utils/
		├── share_utils.dart                  # share action routing
		└── pdf_export_service.dart           # item->pdf file generation
```

### Pattern 1: Additive Schema Evolution
**What:** Add nullable columns (`author`, `deletedAt`) and bump schema version with explicit migration strategy. [CITED: https://drift.simonbinder.eu/migrations/]
**When to use:** Any persistence expansion that must preserve existing records. [VERIFIED: phase requirements AUT-02/TRS-01]
**Example:**
```dart
// Source: Drift migration docs + current app_database.dart structure
@override
int get schemaVersion => 8;

@override
MigrationStrategy get migration => MigrationStrategy(
	onUpgrade: (m, from, to) async {
		if (from < 8) {
			await m.addColumn(mnemataItems, mnemataItems.author);
			await m.addColumn(mnemataItems, mnemataItems.deletedAt);
		}
	},
);
```

### Pattern 2: Capability-Gated Share Actions
**What:** Compute share options from content capabilities (summary exists, pdf generation available). [VERIFIED: requirement SHR-01/SHR-02]
**When to use:** Dynamic share sheets where some actions are conditional.
**Example:**
```dart
final canShareSummary = summaryText != null && summaryText.trim().isNotEmpty;
final actions = <ShareAction>[
	ShareAction.text,
	if (canShareSummary) ShareAction.aiSummary,
	ShareAction.pdfAttachment,
];
```

### Pattern 3: Scroll-State Stability During Selection
**What:** Keep a stable `ScrollController`/list key and avoid selection toggles that rebuild the entire scrollable subtree. [CITED: https://api.flutter.dev/flutter/widgets/Scrollable-class.html]
**When to use:** Multi-select interactions in long, actively scrolling lists.
**Example:**
```dart
// Keep controller as State field and preserve key identity across selection updates.
final _scrollController = ScrollController();

ReorderableListView.builder(
	key: const PageStorageKey<String>('item_list_reorderable'),
	scrollController: _scrollController,
	itemBuilder: ...,
)
```

### Anti-Patterns to Avoid
- **Mutating current title/body extraction logic:** Violates locked decisions and increases ingestion regression risk. [VERIFIED: `15-CONTEXT.md`]
- **Hard-delete fallback in UI paths after soft-delete migration:** Causes inconsistent recycle semantics. [ASSUMED]
- **Bookmark regex parser:** Breaks on folder hierarchy and escaped entities. [ASSUMED]
- **Generating PDF synchronously on UI thread for large content:** Can cause frame jank and ANRs. [ASSUMED]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML bookmark parsing | Manual token parser / regex parser | `html` DOM parser | Handles malformed and nested markup more robustly. [ASSUMED] |
| Cross-platform share channels | Per-platform method channel implementations | `share_plus` | Existing cross-platform abstraction already in project. [VERIFIED: workspace dependency] |
| DB migration orchestration | Raw SQL-only ad hoc migration flow | Drift `MigrationStrategy` | Built-in migration path and schema evolution patterns. [CITED: https://drift.simonbinder.eu/migrations/] |
| PDF binary wiring for share | Custom byte transport per platform | Generate file + `XFile` sharing via `share_plus` | File sharing path is documented and portable. [CITED: https://github.com/fluttercommunity/plus_plugins/blob/main/packages/share_plus/share_plus/README.md] |

**Key insight:** Phase 15 is mostly composition over existing libraries; custom implementations create edge-case burden disproportionate to the feature value. [ASSUMED]

## Common Pitfalls

### Pitfall 1: Soft-delete without query partitioning
**What goes wrong:** Deleted items still appear in primary lists or search results.
**Why it happens:** Existing list/search queries are not filtered by `deletedAt IS NULL`. [VERIFIED: current delete model is hard-delete]
**How to avoid:** Centralize active/recycle query builders and update all read paths before enabling delete UI changes. [ASSUMED]
**Warning signs:** Item count mismatch between list and storage; restored items duplicating visible records.

### Pitfall 2: Retention purge races with restore actions
**What goes wrong:** Item restored while concurrent purge removes it permanently.
**Why it happens:** Purge and restore run without row-level guard conditions.
**How to avoid:** Purge with `deletedAt <= cutoff` and restore with optimistic row check in a transaction. [ASSUMED]
**Warning signs:** Intermittent restore failures in tests.

### Pitfall 3: Scroll jump during selection updates
**What goes wrong:** Multi-select tap changes reset offset while user scrolls.
**Why it happens:** Scrollable identity/controller changes under rebuild. [CITED: https://api.flutter.dev/flutter/widgets/Scrollable-class.html]
**How to avoid:** Stable `PageStorageKey`, persistent controller, and local item-state updates where possible.
**Warning signs:** Widget test reproduces offset drift after rapid select+drag gestures.

### Pitfall 4: Share option shown when summary is absent
**What goes wrong:** User sees action that fails or shares empty content.
**Why it happens:** Capability gating not wired to summary presence check.
**How to avoid:** Explicit summary availability predicate in both summary and item-share entrypoints. [VERIFIED: requirement SHR-01]
**Warning signs:** Null/empty summary path still enables share action.

## Code Examples

Verified patterns from current stack and official docs:

### Share file attachment
```dart
// Source: share_plus README
final params = ShareParams(
	text: 'Item export',
	files: [XFile(pdfPath)],
);
await SharePlus.instance.share(params);
```

### Preserve scroll offset across rebuilds
```dart
// Source: Flutter Scrollable docs (PageStorage + keepScrollOffset behavior)
ReorderableListView.builder(
	key: const PageStorageKey<String>('chronological-items'),
	scrollController: _scrollController,
	itemBuilder: _buildRow,
);
```

### Additive migration skeleton (Drift)
```dart
// Source: Drift migrations docs
if (from < 8) {
	await m.addColumn(mnemataItems, mnemataItems.author);
	await m.addColumn(mnemataItems, mnemataItems.deletedAt);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Immediate hard delete | Soft delete + retention purge | Current phase target | Better recoverability and safer UX for accidental deletion. [VERIFIED: requirements TRS-01..03] |
| Share static text only | Capability-driven share options (text/AI summary/PDF) | Current phase target | More flexible share workflows while preserving existing behavior. [VERIFIED: requirements SHR-01/SHR-02] |
| Non-portable bookmark transfers | Netscape HTML bookmark import/export | De-facto browser interoperability pattern | Enables cross-browser URL transfer. [CITED: https://support.google.com/chrome/answer/96816] [CITED: https://support.mozilla.org/en-US/kb/import-bookmarks-html-file] |

**Deprecated/outdated:**
- Immediate hard-delete-only UX for user content is outdated for recoverability expectations in modern note/reference apps. [ASSUMED]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Separate recycle-bin table is unnecessary versus soft-delete columns for this phase scope. | Standard Stack / Alternatives | Medium: may need larger migration if future recycle features expand. |
| A2 | `html` parser is sufficient for all required Netscape bookmark import edge cases in this phase. | Don't Hand-Roll | Medium: malformed real-world files may require extra sanitization. |
| A3 | PDF generation should run off critical UI path to avoid jank for large items. | Anti-Patterns | Low-Medium: UX degradation if ignored. |

## Open Questions (RESOLVED)

1. **Where should recycle-bin UI live (dedicated screen vs filter mode in existing list)?**
	 - What we know: Behavior is required; exact UI placement is discretionary. [VERIFIED: `15-CONTEXT.md`]
	 - Resolution: Use a dedicated `RecycleBinScreen` reachable from list/settings actions.
	 - Why: Dedicated screen reduces accidental destructive actions and keeps active-list query logic clean.

2. **Should imported bookmarks deduplicate against existing URLs automatically?**
	 - What we know: Scope is URLs import/export only.
	 - Resolution: Deduplicate by canonical URL during import and skip already-existing URLs.
	 - Why: Avoid noisy duplicates and preserve idempotent repeated imports.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build/tests for all plans | yes | 3.41.4 | none |
| Dart SDK | Build/tests for all plans | yes | 3.11.1 | none |
| git | workflow operations | yes | 2.25.1 | none |
| jq | optional scripting/inspection | yes | 1.6 | none |
| sqlite3 CLI | manual DB inspection only | no | - | use Drift tests and app-level verification |

Evidence: [VERIFIED: local command checks in this session]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter SDK) |
| Config file | none dedicated (standard Flutter test layout) |
| Quick run command | `flutter test test/features/chronological_list/presentation/item_list_screen_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUT-01 | Dedicated author extraction module, no title/body regression | unit | `flutter test test/features/ingestion/author_extraction_service_test.dart` | no (Wave 0) |
| AUT-02 | Author persists and reads in item views | unit/integration | `flutter test test/core/database/app_database_author_test.dart` | no (Wave 0) |
| TRS-01 | Delete moves item to recycle state | unit/integration | `flutter test test/core/database/app_database_recycle_bin_test.dart` | no (Wave 0) |
| TRS-02 | Retention setting clamp 1-30 | unit/widget | `flutter test test/features/settings/recycle_retention_settings_test.dart` | no (Wave 0) |
| TRS-03 | Auto purge after retention | unit/integration | `flutter test test/features/chronological_list/services/recycle_purge_service_test.dart` | no (Wave 0) |
| BKM-01 | Export URLs as Netscape HTML | unit | `flutter test test/features/bookmarks/bookmark_export_service_test.dart` | no (Wave 0) |
| BKM-02 | Import URLs from Netscape HTML | unit | `flutter test test/features/bookmarks/bookmark_import_service_test.dart` | no (Wave 0) |
| UX-04 | Multi-select preserves scroll offset | widget | `flutter test test/features/chronological_list/presentation/item_list_multiselect_scroll_test.dart` | no (Wave 0) |
| SHR-01 | Summary share option gating by availability | widget/unit | `flutter test test/features/sharing/share_summary_option_test.dart` | no (Wave 0) |
| SHR-02 | PDF attachment share option works | unit/widget | `flutter test test/features/sharing/share_pdf_option_test.dart` | no (Wave 0) |

### Sampling Rate
- **Per task commit:** target file test command for touched requirement
- **Per wave merge:** `flutter test`
- **Phase gate:** full suite green + manual smoke on list/share/settings flows

### Wave 0 Gaps
- [ ] `test/features/ingestion/author_extraction_service_test.dart` - AUT-01
- [ ] `test/core/database/app_database_author_test.dart` - AUT-02
- [ ] `test/core/database/app_database_recycle_bin_test.dart` - TRS-01/TRS-03
- [ ] `test/features/settings/recycle_retention_settings_test.dart` - TRS-02
- [ ] `test/features/bookmarks/bookmark_export_service_test.dart` - BKM-01
- [ ] `test/features/bookmarks/bookmark_import_service_test.dart` - BKM-02
- [ ] `test/features/chronological_list/presentation/item_list_multiselect_scroll_test.dart` - UX-04
- [ ] `test/features/sharing/share_summary_option_test.dart` - SHR-01
- [ ] `test/features/sharing/share_pdf_option_test.dart` - SHR-02

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A for this local feature phase |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | yes | URL validation on bookmark import; retention range clamp 1-30 |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for Flutter + local persistence + import/share
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed bookmark HTML causing parser failure | Denial of Service | Defensive parsing with size limits and graceful reject paths |
| Unsafe URL schemes imported (e.g., javascript:) | Tampering | Allowlist schemes (`http`, `https`) before insertion |
| Oversharing sensitive text via share sheet | Information Disclosure | Explicit user action and clear share option labeling |
| Large PDF generation from huge content causing app freeze | Denial of Service | Generate asynchronously and cap content size/timeout |

## Recommended Sequence for Plans

1. **15-01 Author Extraction Module and Metadata Persistence**
	 - Build dedicated author extraction service.
	 - Add nullable `author` persistence and wire read surfaces.
	 - Guard against any title/body pipeline changes.

2. **15-02 Recycle Bin, Retention Settings, and Auto Purge**
	 - Introduce `deletedAt` soft-delete semantics.
	 - Add settings key/UI for retention 1-30 days.
	 - Implement purge service and startup trigger.

3. **15-03 Bookmark Import/Export (Universal HTML Format)**
	 - Implement URLs-only exporter to Netscape HTML.
	 - Implement importer + URL validation + insertion path.
	 - Add tests for malformed and nested-folder files.

4. **15-04 Multi-Select Scroll Stability and Share Enhancements**
	 - Fix list selection/scroll interaction with stable controller/keying.
	 - Add AI summary share option in both entry points with disabled state when unavailable.
	 - Add PDF attachment share as additive option.

Rationale: This order resolves foundational data model and lifecycle first, reducing rework in later UI/share plans. [VERIFIED: roadmap split + dependency logic]

## Sources

### Primary (HIGH confidence)
- Workspace code inspection (`lib/features/ingestion/services/extraction_service.dart`, `lib/core/database/tables.dart`, `lib/core/database/app_database.dart`, `lib/core/utils/share_utils.dart`, `lib/features/chronological_list/presentation/item_list_screen.dart`, `lib/features/settings/services/settings_service.dart`) - current architecture and constraints
- Drift docs - migrations strategy: https://drift.simonbinder.eu/migrations/
- Phase planning docs - `.planning/phases/15-content-and-workflow-enhancements/15-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`

### Secondary (MEDIUM confidence)
- Share Plus official README: https://github.com/fluttercommunity/plus_plugins/blob/main/packages/share_plus/share_plus/README.md
- Flutter Scrollable docs: https://api.flutter.dev/flutter/widgets/Scrollable-class.html
- Browser bookmark interoperability docs:
	- https://support.google.com/chrome/answer/96816
	- https://support.mozilla.org/en-US/kb/import-bookmarks-html-file

### Tertiary (LOW confidence)
- Implementation-detail assumptions around parser edge-case behavior and performance constraints (captured in Assumptions Log)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - aligned with existing repo dependencies and documented libraries
- Architecture: MEDIUM-HIGH - strongly grounded in current code seams, with a few implementation assumptions
- Pitfalls: MEDIUM - derived from current architecture plus common Flutter/DB integration failure modes

**Research date:** 2026-04-16
**Valid until:** 2026-05-16
