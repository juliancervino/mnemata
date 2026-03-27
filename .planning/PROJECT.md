# Mnemata

## What This Is

Mnemata is a cross-platform knowledge and reference manager (iOS, Android, Web). It allows users to save URLs and documents (PDFs, images), organize them in an infinite tree structure of folders, and assign multiple tags. It features content extraction for offline reading, full-text search, and seamless native integration via Share Intents on mobile devices.

## Core Value

A centralized, cross-platform repository for all knowledge and references, ensuring content is permanently saved, cleanly extracted, effortlessly discoverable through full-text search, and intuitively organized.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- [x] Save URLs and copy received documents (PDFs, images) to local secure storage.
- [x] Extract content from URLs (clean reader) and PDFs (indexed search).
- [x] Native integration via Share Intents.
- [x] Full-text search across items and content.
- [x] Unified "Tags" organization model with multi-tag filtering.
- [x] Swipe gestures for Share/Edit and drag-and-drop reordering.

### Active

<!-- Current scope. Building toward these. -->

- [ ] Add "About" view and "Settings" menu for app personalization.
- [ ] Implement auto-tagging (domain and year) for incoming content.
- [ ] Add "Delete" action directly within the Reader View.
- [ ] Implement multi-selection mode for bulk Tag/Delete/Share operations.
- [ ] Optimize list UI to maximize title space and show origin domains.
- [ ] Integrate Google Drive for full project backups.
- [ ] Research AI-driven features (summaries, semantic search).

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- (None defined yet)

## Context

- The application must support iOS, Android, and Web platforms.
- It requires robust local storage management for handling physical files securely.
- The UI needs to be highly responsive to gestures (swiping) for quick actions on the main list.
- Web content extraction logic needs to be smart enough to differentiate between main article content and extraneous elements like navigation or advertising.

## Constraints

- **Platform**: Cross-platform (iOS, Android, Web) — To maximize accessibility across user devices.
- **Integration**: Native Share Intents on mobile — Essential for the core user workflow of saving references on the go.
- **Storage**: Local secure storage — Documents must be copied and stored safely by the app.
- **Search**: Full-text indexing — Required for the search functionality across diverse content types.

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Organization Model | Removed "Folders" to simplify hierarchy; using "Tags" for everything. | Unified Tag system (Phase 8) |
| Cloud Strategy | Google Drive for backups instead of custom cloud sync for privacy/simplicity. | Phase 11 priority |
| Interaction | Bulk actions via long-press multi-select. | Phase 10 goal |

---
*Last updated: March 18, 2026 after initialization*
