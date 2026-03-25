---
status: verifying
trigger: "slidable-share-reset: Left swipe (Share) stays open after action on Android, while Right swipe (Edit) resets correctly."
created: 2025-01-24T16:00:00.000Z
updated: 2025-01-24T16:10:00.000Z
---

## Current Focus

hypothesis: The Share action in Slidable endActionPane was blocking the closing animation because it was awaiting Share.share in confirmDismiss, and calling it immediately in onPressed.
test: Apply Future.microtask pattern to both confirmDismiss and onPressed to allow the Slidable to close/snap back before the system share dialog appears.
expecting: The slidable will now correctly close on both full swipe and button tap, matching the behavior of the Edit action.
next_action: request human verification

## Symptoms

expected: Left swipe (Share) should reset to base state after share action.
actual: Item remains swiped open after sharing content.
errors: none
reproduction: Swipe left on an item, tap Share, complete/cancel the Android share dialog, return to app.
started: Regression or incomplete fix from Phase 8.

## Eliminated

## Evidence

- timestamp: 2025-01-24T16:05:00.000Z
  checked: lib/features/chronological_list/presentation/item_list_screen.dart
  found: The Edit action (startActionPane) uses `Future.microtask` in `confirmDismiss` and returns `false` immediately. The Share action (endActionPane) `await`s `Share.share` in `confirmDismiss` before returning `false`.
  implication: This explains why full-swipe Share stays open (waiting for Share dialog). For button tap, `Slidable.of(context)?.close()` is called followed by `Share.share` immediately, which might also be interrupted by the system dialog.
- timestamp: 2025-01-24T16:10:00.000Z
  checked: lib/features/chronological_list/presentation/item_list_screen.dart
  found: Applied Future.microtask pattern to Share action's confirmDismiss and onPressed.
  implication: This allows the Slidable state to be updated and animation to start before the system call blocks or pauses the app.

## Resolution

root_cause: Share.share was being awaited in confirmDismiss, preventing the immediate return of false which is required for the Slidable to snap back. In onPressed, calling Share.share immediately after close() could also block the closing animation on Android.
fix: Wrapped Share.share calls in Future.microtask and ensured confirmDismiss returns false immediately, mirroring the working Edit action pattern.
verification: Requires human verification on Android device.
files_changed: [/home/xian/src/mnemata/lib/features/chronological_list/presentation/item_list_screen.dart]
