# Phase 11 Research: Cloud & Data Portability

**Phase:** 11-cloud-data-portability
**Date:** 2026-04-04
**Status:** Complete

## Objective

Design an implementation approach for Google Drive backup and restore that fits the existing Flutter + Drift local-first architecture, while honoring Phase 11 context decisions.

## Inputs Reviewed

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/phases/11-cloud-data-portability/11-CONTEXT.md`
- `.planning/codebase/STACK.md`
- `.planning/codebase/STRUCTURE.md`
- `.planning/codebase/INTEGRATIONS.md`
- `lib/main.dart`
- `lib/core/database/app_database.dart`
- `lib/features/settings/services/settings_service.dart`
- `lib/features/settings/presentation/settings_screen.dart`

## Locked Decisions From Context

- D-01: Backup package includes DB + attachments + settings + integrity/version manifest.
- D-02: Restore is full restore with preview + integrity validation + explicit confirmation.
- D-03/D-04/D-05: Daily schedule, Wi-Fi + charging constraints, manual trigger always available.
- D-06: Browser extension is out of scope for Phase 11.

## Recommended Architecture

### 1. Backup Domain Layer

Create a dedicated feature module under `lib/features/backup/` with services:

- `backup_manifest.dart` (model and checksum metadata)
- `backup_archive_service.dart` (create/read `.zip` package)
- `backup_storage_service.dart` (local staging paths)
- `backup_restore_service.dart` (preview + validate + apply)

### 2. Google Drive Adapter Boundary

Define an adapter interface to isolate cloud vendor implementation:

- `cloud_backup_provider.dart` (interface)
- `google_drive_backup_provider.dart` (implementation)

This keeps future providers possible without changing backup core flow.

### 3. Scheduler Integration

Use app bootstrap path in `lib/main.dart` to initialize a scheduler service after DI setup:

- `backup_scheduler_service.dart` checks eligibility (Wi-Fi + charging) and run windows.
- Persist schedule state and last-run metadata in `SettingsService`.

### 4. Settings UX

Extend settings UI for:

- Manual backup now
- Last successful backup metadata
- Auto-backup enable/disable
- Policy summary (daily + Wi-Fi + charging)
- Restore flow entrypoint with preview confirmation

## Data/Artifact Shape

Backup archive content (versioned):

- `manifest.json` (schemaVersion, createdAt, appVersion, checksum list)
- `database/mnemata_db.sqlite`
- `files/` copied attachments
- `settings/settings.json` selected app settings

Integrity strategy:

- SHA-256 per artifact in manifest
- Verify before restore apply
- Hard fail on checksum mismatch

## Risks and Mitigations

- Risk: Partial restore leaves inconsistent state.
  - Mitigation: two-phase restore with staging directory + swap only after successful validation.

- Risk: Large attachments produce slow backups.
  - Mitigation: stream copy with progress state and cancellation-safe cleanup.

- Risk: Platform constraints for background schedule execution.
  - Mitigation: start with best-effort foreground-triggered scheduler loop and explicit manual backup path.

## Out of Scope (Phase 11)

- Browser extension implementation and research.
- Semantic sync/merge between two active devices.
- Differential/incremental backup format.

## Validation Architecture

The phase must prove correctness through deterministic checks:

- Manifest is generated and parseable.
- Backup archive contains required entries.
- Checksum validation rejects tampered archives.
- Restore preview can be loaded without applying changes.
- Restore apply creates expected DB + files state.
- Auto-scheduler policy gate honors Wi-Fi + charging conditions.

## Must-Have Technical Outcomes

- Backup/restore module exists and is isolated from unrelated ingestion logic.
- Settings screen exposes manual backup and restore entry points.
- Scheduler initialization is wired at app startup.
- Google Drive provider is bounded behind interface contract.

## Recommendation

Plan as three execute plans:

1. Core backup contracts + archive/manifest pipeline.
2. Restore preview/apply + settings UX.
3. Scheduling + cloud provider wiring + end-to-end verification.
