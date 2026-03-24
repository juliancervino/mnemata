---
status: investigating
trigger: "Investigate issue: guided-ingestion-bypass-and-title-extraction"
created: 2025-05-23T12:00:00Z
updated: 2025-05-23T12:00:00Z
---

## Current Focus

hypothesis: Shared items are being handled by a direct save path instead of navigating to the IngestionSummaryScreen.
test: Examine the sharing intent handling logic to see how it routes incoming shared content.
expecting: To find code that calls the database save method directly instead of pushing the IngestionSummaryScreen.
next_action: Examine sharing intent handling in `lib/main.dart` or relevant features.

## Symptoms

expected: 
- Sharing a link should show a summary screen before saving.
- The title should be correctly extracted from the page metadata or HTML.
actual: 
- Items are added directly to the list.
- The title is not always captured correctly (uses a generic or empty title).
errors: None reported.
reproduction: 
- Share the provided URL to the app.
- Observe that it goes straight to the list and check the title.
started: Never worked as expected.

## Eliminated

## Evidence

## Resolution

root_cause: 
fix: 
verification: 
files_changed: []
