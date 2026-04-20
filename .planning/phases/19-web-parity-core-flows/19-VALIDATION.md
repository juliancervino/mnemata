---
phase: 19
slug: web-parity-core-flows
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-18
---

# Phase 19 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter `flutter_test` + Dart `test` |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `flutter test test/features/ingestion/services/share_service_test.dart test/features/chronological_list/presentation/item_list_screen_test.dart test/features/intelligence/services/semantic_search_service_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/ingestion/services/share_service_test.dart test/features/chronological_list/presentation/item_list_screen_test.dart test/features/intelligence/services/semantic_search_service_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | WEB-01 | T-19-01 | Web ingest blocks unsupported/oversize inputs and exposes deterministic recovery actions | widget/unit | `flutter test test/features/ingestion/services/share_service_test.dart` | ✅ | ⬜ pending |
| 19-02-01 | 02 | 2 | WEB-02 | T-19-02 | List order/filter semantics match mobile and delete undo path remains deterministic | widget | `flutter test test/features/chronological_list/presentation/item_list_screen_test.dart` | ✅ | ⬜ pending |
| 19-03-01 | 03 | 3 | WEB-03 | T-19-03 | Reader/PDF states expose non-silent failures and preserve state continuity | widget/integration | `flutter test test/features/reader/presentation/reader_screen_web_test.dart` | ❌ W0 | ⬜ pending |
| 19-04-01 | 04 | 4 | WEB-04 | T-19-04 | Search debounce/semantics and empty/error states remain deterministic | unit/widget | `flutter test test/features/intelligence/services/semantic_search_service_test.dart test/features/chronological_list/presentation/item_list_screen_test.dart` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/features/reader/presentation/reader_screen_web_test.dart` - WEB-03 reader/PDF parity checks for web behavior and deterministic failures.
- [ ] `test/features/ingestion/presentation/ingestion_summary_screen_web_test.dart` - WEB-01 summary/edit-before-save parity on web.
- [ ] `test/features/chronological_list/presentation/item_list_web_parity_test.dart` - WEB-02 list/filter restore and delete undo behavior.
- [ ] `test/features/search/search_web_parity_test.dart` - WEB-04 debounce/snippet/empty/error contract.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Drag-and-drop file ingest in browser | WEB-01 | Requires browser DnD events not fully represented in current widget harness | Run `flutter run -d chrome`, drag supported and unsupported files, verify deterministic validation copy and fallback actions. |
| Embedded PDF fallback to new tab | WEB-03 | Browser tab behavior depends on runtime capabilities and user agent policies | Open heavy and malformed PDFs in Chrome, verify progress indication and fallback opens new tab when embed is unavailable. |
| Reader-to-list state continuity | WEB-02, WEB-03 | Requires full navigation stack and scroll restoration behavior across routes | Apply filters and search, open reader, return, confirm identical query/filter/scroll state. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
