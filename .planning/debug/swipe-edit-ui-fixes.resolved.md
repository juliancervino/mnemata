---
status: investigating
trigger: "swipe-edit-ui-fixes"
created: 2024-05-24T12:00:00Z
updated: 2024-05-24T12:00:00Z
---

## Current Focus

hypothesis: Multiple UI/UX and logic issues reported.
test: Gathering initial evidence across the codebase.
expecting: Identify relevant files for swipe, editor, metadata, and layout.
next_action: Search for "Slidable", "ItemEditorScreen", "Metadata", and "SafeArea".

## Symptoms

expected: 
- Right swipe (Start) -> Edit.
- Left swipe (End) -> Share.
- Slidable item closes automatically after action.
- Action triggers at a threshold without full displacement.
- Edit view saves on exit.
- Edit view has a delete button with confirmation.
- `lavozdegalicia.es` title correctly extracted.
- UI respects system navigation bar.
actual: 
- Swipes are reversed.
- Items stay open/slid after action.
- Edit view requires manual Save tap.
- No delete in edit view.
- Title is "www" for `lavozdegalicia.es`.
- Content is visible under system buttons.
errors: None.
reproduction: 
- Swipe right/left on list items.
- Open edit view and try to save or delete.
- Share a link from La Voz de Galicia.
- Observe bottom of screen on Android with button navigation enabled.
started: Since recent feature additions.

## Eliminated

## Evidence

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
