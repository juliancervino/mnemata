# 15-02 Summary - Recycle Bin, Retention, and Auto-Purge

## Scope Delivered
- Converted delete flows to soft-delete so items move into recycle state instead of immediate permanent deletion.
- Added recycle-bin retention setting with enforced 1..30 day range.
- Added automatic startup purge for recycle-bin items older than configured retention window.

## Implementation Notes
- Data model and DB flow now partition active vs. recycled records via `deletedAt` semantics.
- Recycle-bin UI supports browsing/restoring recycled items and integrates with the updated database behavior.
- Settings now persist retention policy and clamp invalid values to the supported range.
- Startup bootstrap invokes recycle purge service to clean expired recycled records without blocking normal app behavior.

## Tests and Verification
- Recycle and retention behavior covered in targeted tests:
  - `test/core/database/app_database_recycle_bin_test.dart`
  - `test/features/settings/recycle_retention_settings_test.dart`
  - `test/features/chronological_list/services/recycle_purge_service_test.dart`
- Integration/regression support from list/recycle UI tests and subsequent wave regressions.

## Outcome
- TRS-01, TRS-02, and TRS-03 are implemented:
  - soft-delete lifecycle,
  - user-configurable bounded retention,
  - automatic expiration purge.
