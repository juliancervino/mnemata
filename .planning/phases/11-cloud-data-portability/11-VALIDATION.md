---
phase: 11-cloud-data-portability
created: 2026-04-04
source: 11-RESEARCH.md
status: active
---

# Validation Strategy - Phase 11 Cloud Data Portability

## Validation Architecture

This phase requires deterministic verification around data integrity and recoverability.
Validation centers on archive correctness, manifest consistency, restore safety, and scheduler policy enforcement.

## Critical Truths to Validate

1. Backup package always contains required artifacts: DB, files, settings, manifest.
2. Manifest checksums are verifiable and tamper detection works.
3. Restore preview inspects backup safely without mutating live state.
4. Restore apply operation is atomic from user perspective (either succeeds fully or aborts without partial apply).
5. Scheduled backup policy respects daily cadence and environment constraints.

## Required Automated Verification

- Unit tests for manifest generation and checksum validation.
- Unit tests for backup archive entry inventory.
- Unit tests for restore preview parser behavior.
- Integration tests for restore apply success and failure rollback behavior.
- Service-level tests for scheduler policy gating (Wi-Fi/charging decisions).

## Manual Verification

- Run a manual backup from settings, confirm generated archive metadata appears in UI.
- Run restore preview, verify contents summary before confirmation.
- Confirm restore requires explicit confirmation before apply.
- Simulate policy mismatch (no Wi-Fi or not charging) and verify scheduled backup is skipped.

## Failure Signals

- Missing manifest or required archive entries.
- Checksum mismatch not detected.
- Restore mutates live state during preview.
- Partial restore state after apply failure.
- Scheduler running when policy constraints are unmet.

## Exit Criteria

Phase is verification-complete when all automated checks pass and manual verification confirms full backup/restore lifecycle with policy-compliant scheduling behavior.
