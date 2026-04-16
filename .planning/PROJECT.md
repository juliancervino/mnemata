# Mnemata

## What This Is

Mnemata is a cross-platform knowledge and reference manager (iOS, Android, Web). It allows users to save URLs and documents (PDFs, images), organize them in an infinite tree structure of folders, and assign multiple tags. It features content extraction for offline reading, full-text search, and seamless native integration via Share Intents on mobile devices.

## Core Value

A centralized, cross-platform repository for all knowledge and references, ensuring content is permanently saved, cleanly extracted, effortlessly discoverable through full-text search, and intuitively organized.

## Current Milestone: v1.1 Feature Expansion + Reliability

**Goal:** Deliver requested functional enhancements first (metadata, recycle bin, import/export, selection/share UX) and delay reliability closure work to subsequent phases in the same milestone.

**Target features:**
- Extract and persist article author via a dedicated author module without changing current title/body extraction flow.
- Add recycle bin with configurable retention (1-30 days) and automatic permanent purge.
- Add bookmark URL import/export using universal bookmarks format.
- Fix multi-select scroll jump behavior.
- Add AI summary sharing option (disabled when summary is unavailable).
- Add PDF attachment sharing option generated from item content.
- Defer cloud runtime validation, integration hardening, and verification gates to later phases (16-18).

## Requirements

### Active

- [ ] Add author metadata extraction through an isolated module and persist it in item model.
- [ ] Add recycle bin lifecycle and retention controls in settings.
- [ ] Add URL import/export interoperability with bookmarks HTML format.
- [ ] Improve multi-select and share workflows (AI summary + PDF attachment).
- [ ] Complete delayed runtime cloud validation and integration hardening after functional expansion.

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

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: April 16, 2026 after v1.1 scope replan (feature-first sequencing)*
