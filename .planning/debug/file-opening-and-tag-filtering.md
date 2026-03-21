---
status: investigating
trigger: "Investigate and fix two issues in the main list:\n1. File opening is currently disabled with a placeholder error message (\"Opening files is temporarily disabled in this build.\").\n2. Tag filters from the QuickFilterBar or Drawer have no effect when the 'Recently Opened' (History) view is active."
created: 2024-05-24T12:00:00Z
updated: 2024-05-24T12:00:00Z
---

## Current Focus

hypothesis: File opening is a known TODO or placeholder implementation. Tag filtering in History mode is not implemented in the repository/provider layer.
test: Search for the error message "Opening files is temporarily disabled in this build." and examine the History view's filtering logic.
expecting: To find the code responsible for file opening and the history view's tag filtering.
next_action: Search for the file opening error message and history filtering logic.

## Symptoms

expected: 
- Tapping a file item in the list should open it in a native platform viewer.
- Tapping a tag in the QuickFilterBar or Drawer while in 'Recently Opened' mode should filter the 20 most recently opened items by that tag.
actual: 
- Shows an error snackbar: "Error: Exception: Opening files is temporarily disabled in this build."
- The filter has no effect; the list continues to show all 20 recent items regardless of the selected tag.
errors: 
- Exception: Opening files is temporarily disabled in this build.
reproduction: 
- Share a PDF to the app, then try to tap it in the chronological list.
- Open 'Recently Opened' from the drawer, then tap a tag in the horizontal bar.
started: 
- File opening: Always been like this.
- Tag filtering: Since the introduction of the QuickFilterBar.

## Eliminated

## Evidence

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
