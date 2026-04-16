---
phase: 15-content-and-workflow-enhancements
created: 2026-04-16
status: ready
nyquist_compliant: pending
wave_0_complete: false
---

# Phase 15 Validation Strategy

## Scope

Phase 15 validates AUT/TRS/BKM/UX/SHR requirements through wave-based checks before execution summary.

## Requirement to Evidence Map

| Requirement | Planned Evidence | Automated Checks |
|---|---|---|
| AUT-01 | `15-01-PLAN.md` task outputs, dedicated author extraction service | `flutter test test/features/ingestion/services/author_extraction_service_test.dart` |
| AUT-02 | DB persistence + item view wiring in `15-01-PLAN.md` | `flutter test test/core/database/app_database_author_test.dart test/features/chronological_list/presentation/item_list_screen_test.dart` |
| TRS-01 | Soft-delete + recycle query behavior in `15-02-PLAN.md` | `flutter test test/core/database/app_database_recycle_bin_test.dart` |
| TRS-02 | Settings clamp 1..30 in `15-02-PLAN.md` | `flutter test test/features/settings/recycle_retention_settings_test.dart` |
| TRS-03 | Purge service + startup trigger in `15-02-PLAN.md` | `flutter test test/features/chronological_list/services/recycle_purge_service_test.dart` |
| BKM-01 | Export service in `15-03-PLAN.md` | `flutter test test/features/bookmarks/bookmark_export_service_test.dart` |
| BKM-02 | Import service + URL validation in `15-03-PLAN.md` | `flutter test test/features/bookmarks/bookmark_import_service_test.dart` |
| UX-04 | Multi-select scroll stability in `15-04-PLAN.md` | `flutter test test/features/chronological_list/presentation/item_list_multiselect_scroll_test.dart` |
| SHR-01 | AI summary share option/gating in `15-04-PLAN.md` | `flutter test test/features/sharing/share_summary_option_test.dart` |
| SHR-02 | PDF attachment share option in `15-04-PLAN.md` | `flutter test test/features/sharing/share_pdf_option_test.dart` |

## Wave Verification Gates

### Wave 1 Gate (15-01)
- AUT tests pass.
- Existing extraction title/body behavior remains unchanged.

### Wave 2 Gate (15-02)
- Recycle-bin lifecycle and retention tests pass.
- Startup purge trigger is non-blocking.

### Wave 3 Gate (15-03)
- Bookmark import/export tests pass.
- Settings workflow test includes import/export path assertions.

### Wave 4 Gate (15-04)
- Multi-select scroll stability test passes.
- Summary/PDF sharing tests pass with gating behavior.

## Phase Exit Criteria

1. All wave-specific automated checks pass.
2. Requirement-to-evidence matrix remains complete (10/10).
3. No violation of locked decision: author extraction remains separate from existing title/body extraction path.
4. `15-VERIFICATION.md` is generated at execution close with explicit evidence links.
