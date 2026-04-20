# Phase 19 Discussion Log

**Date:** 2026-04-18
**Mode:** discuss
**Phase:** 19 - Web Parity Core Flows

## Gray Areas Selected

1. Ingestion UX web
2. List/filter parity
3. Reader/PDF behavior
4. Search semantics + empty/error states

## Decision Trace

### Ingestion UX web
- WEB-ING-1: Single "Add" CTA with unified URL/file flow.
- WEB-ING-2: Drag and drop + file picker.
- WEB-ING-3: Mobile-equivalent dedupe behavior (warn and allow intentional continue; open-existing path desired in web UX).
- WEB-ING-4: Guided fallback when automatic extraction fails.
- WEB-ING-5: File types match mobile in this phase (PDF + image).
- WEB-ING-6: Oversize files are blocked with clear limit messaging.
- WEB-ING-7: After save, return to list with snackbar.
- WEB-ING-8: Keep editable title/author/tags in summary before save.

### List/filter parity
- WEB-LIST-1: Default order is newest first (mobile parity).
- WEB-LIST-2: Horizontal chips + "More filters" entry point.
- WEB-LIST-3: Quick actions include open reader, mark read/unread, favorite, delete, share.
- WEB-LIST-4: Infinite scroll for long lists.
- WEB-LIST-5: Restore exact list/search/filter state when returning from reader.
- WEB-LIST-6: Delete uses modal confirmation + snackbar undo.
- WEB-LIST-7: No bulk multi-select actions in Phase 19.
- WEB-LIST-8: No list keyboard shortcuts in Phase 19.

### Reader/PDF behavior
- WEB-READER-1: Center column + optional side panel layout.
- WEB-READER-2: Compact sticky header.
- WEB-READER-3: Embedded basic PDF viewer + open-in-new-tab fallback.
- WEB-READER-4: Restore reading position approximately by section.
- WEB-READER-5: Include font size, column width, and theme controls.
- WEB-READER-6: No reader keyboard shortcuts in Phase 19.
- WEB-READER-7: Guided read error state (retry/open original/report).
- WEB-READER-8: Progressive loading with explicit progress for heavy PDFs.

### Search semantics + empty/error states
- WEB-SEARCH-1: As-you-type with ~300ms debounce.
- WEB-SEARCH-2: Keep current mobile/FTS ranking semantics.
- WEB-SEARCH-3: Show short highlighted snippets.
- WEB-SEARCH-4: Empty state includes actionable suggestions.
- WEB-SEARCH-5: No fuzzy/typo tolerance in Phase 19.
- WEB-SEARCH-6: No recent-search history in Phase 19.
- WEB-SEARCH-7: Inline error with retry and fallback to list.
- WEB-SEARCH-8: Search respects active list filters by default.

## Scope Control Notes

- Discussion stayed within WEB-01..WEB-04 parity boundary.
- Deferred to later phases: bulk web actions, keyboard shortcut packs, fuzzy search/history persistence.

## Ready State

Context is complete and ready for `/gsd-plan-phase 19`.
