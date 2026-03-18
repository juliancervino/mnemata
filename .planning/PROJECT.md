# Mnemata

## What This Is

Mnemata is a cross-platform knowledge and reference manager (iOS, Android, Web). It allows users to save URLs and documents (PDFs, images), organize them in an infinite tree structure of folders, and assign multiple tags. It features content extraction for offline reading, full-text search, and seamless native integration via Share Intents on mobile devices.

## Core Value

A centralized, cross-platform repository for all knowledge and references, ensuring content is permanently saved, cleanly extracted, effortlessly discoverable through full-text search, and intuitively organized.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. -->

- [ ] Save URLs and copy received documents (PDFs, images) to local secure storage.
- [ ] Organize items in a hierarchical tree structure (items can be in root, folders, or subfolders).
- [ ] Assign multiple tags to items and filter/group by tags (many-to-many relationship).
- [ ] Native integration (iOS/Android) as a Share Intent target to receive URLs from browsers and files from other apps.
- [ ] Extract content from URLs (title and main content), removing ads and clutter for offline reading.
- [ ] Full-text search across item titles, URLs, document names, and extracted content.
- [ ] Maintain a reading history of the last 20 accessed items.
- [ ] Main view displaying a list of items (newest to oldest) with interactions: tap to open, swipe right to share, swipe left to edit.

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
| — | — | — |

---
*Last updated: March 18, 2026 after initialization*
