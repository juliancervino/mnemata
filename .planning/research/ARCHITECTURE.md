# Architecture: v1.1 Reliability and Verification

**Project:** Mnemata  
**Milestone:** v1.1 Reliability and Verification  
**Researched:** 2026-04-16  
**Scope:** Integrate reliability verification and integration testing into the existing Flutter architecture with minimal production risk.

## Executive Direction

Use an additive test architecture around existing service boundaries instead of refactoring runtime code paths. The current code already has strong seams (provider abstraction, scheduler policy evaluator, restore validator, DI wiring, settings diagnostics). v1.1 should primarily add a reliability verification layer in test and planning artifacts, with only narrow modifications to existing components where testability or determinism is still weak.

The safest strategy is:
1. Keep production behavior unchanged unless required to expose deterministic hooks.
2. Build reusable integration harnesses in test code, not new runtime feature modules.
3. Gate release readiness on both automated integration suites and explicit human runtime verification evidence for real Google account/device behavior.

## Existing Integration Points (Leverage, Do Not Replace)

### Startup and scheduling boundary
- `lib/main.dart`
  - Initializes `ShareService` first, then triggers `BackupSchedulerService.runIfDue()` in a non-blocking path.
  - This is the key reliability handshake between ingestion startup and backup automation.

### Cloud portability boundary
- `lib/features/backup/services/cloud_backup_provider.dart`
  - Stable abstraction with deterministic error taxonomy (`CloudBackupProviderErrorCode`).
  - Correct seam for integration testing portability behavior without coupling tests to Google Drive internals.

### Scheduler policy + diagnostics boundary
- `lib/features/backup/services/backup_scheduler_service.dart`
  - Encapsulates policy checks (wifi/charging/due), execution, retention, and failure reason recording.
  - Already returns typed results and reason codes suitable for integration assertions.

### Restore validation boundary
- `lib/features/backup/services/backup_restore_service.dart`
  - Handles staging, manifest validation, checksum verification, guarded apply, and rollback.
  - This is the highest-value integration target for reliability confidence.

### User-triggered reliability path
- `lib/features/settings/presentation/settings_screen.dart`
  - Manual upload and restore flows update diagnostics fields in `SettingsService`.
  - This is the user-facing control plane for cloud reliability.

### Current test footholds already present
- `test/features/backup/backup_scheduler_service_integration_test.dart`
- `test/features/backup/google_drive_backup_provider_integration_test.dart`
- `test/features/settings/settings_backup_actions_test.dart`

These are strong foundations; v1.1 should expand breadth and scenario depth, not replace patterns.

## Proposed Components

## New Components (Additive)

### 1) Reliability integration harness (test-only)
- **Suggested location:** `test/support/reliability/`
- **Responsibility:** Build deterministic environments for multi-service integration tests.
- **Key pieces:**
  - `ReliabilityTestHarness`: creates temp storage, configures `SettingsService`, wires fakes/stubs for provider and runtime signals.
  - `FakeCloudBackupProvider`: supports seeded backup sets, deterministic error injection, and call recording.
  - `FakeRuntimeSignals`: controls wifi/charging states per test.

### 2) Reliability scenario suites (integration tests)
- **Suggested location:** `test/features/reliability/`
- **Suites:**
  - `backup_portability_flow_integration_test.dart`
    - Upload -> list -> select -> download -> preview -> apply path.
    - Includes corrupted archive and checksum mismatch negative paths.
  - `scheduler_runtime_reliability_integration_test.dart`
    - startup-triggered due/not-due/wifi/charging branches with diagnostics assertions.
  - `intelligence_critical_flow_reliability_test.dart`
    - API key gate + summary/semantic/tag suggestion fallback behavior under provider errors.

### 3) Verification matrix artifact template
- **Suggested location:** `.planning/research/` plus per-phase verification docs.
- **Responsibility:** Standardize evidence capture for:
  - Automated integration results.
  - Human runtime checks (real Google account/device).
  - Failure reason taxonomy coverage.

## Modifications to Existing Components (Narrow and Low-Risk)

### A) `lib/main.dart` (small bootstrap seam hardening)
- Keep ordering (`ShareService.init()` before scheduler run).
- Add lightweight test hook only if needed for deterministic startup orchestration tests (for example, wrapping startup tasks behind a callable injected in tests).
- No user-facing behavior changes.

### B) `lib/features/backup/services/backup_scheduler_service.dart`
- Preserve public behavior.
- If missing in tests, expose deterministic retention/scheduling observability only through return values or diagnostics reason codes (avoid logging-only assertions).
- No policy expansion in v1.1 unless a verified bug is found.

### C) `lib/features/settings/presentation/settings_screen.dart`
- Keep existing UI controls.
- Ensure diagnostic state updates remain assertion-friendly (stable result reason strings and timestamps).
- Avoid UI redesign; this milestone is reliability verification.

### D) `lib/features/intelligence/services/*`
- No architecture redesign.
- Add only integration tests for cross-service behavior and failure handling paths relevant to reliability.

## Recommended Build Order (Minimal-Risk Sequence)

1. **Stabilize baseline and traceability first**
   - Freeze current behavior with a baseline run of existing backup/settings/intelligence tests.
   - Lock expected diagnostics reason codes used by current tests.

2. **Add test harness primitives (no production edits yet)**
   - Implement `test/support/reliability/` harness and fakes.
   - Reuse in existing integration tests to reduce duplication.

3. **Expand cloud portability integration coverage**
   - Add full upload/list/download/restore-preview/apply scenarios.
   - Add corrupted archive, missing entries, checksum mismatch, auth/network/rate-limit error paths.

4. **Expand scheduler reliability integration coverage**
   - Validate startup-triggered scheduler behavior against runtime signal permutations.
   - Assert `SettingsService` diagnostics fields for each branch.

5. **Add intelligence-critical reliability flows**
   - Verify API key gating, provider failure behavior, and graceful fallback paths across summary/semantic/tag suggestion flows.

6. **Run human runtime verification and capture evidence**
   - Execute production-account/device checks for backup, restore selection, and scheduler conditions.
   - Store explicit pass/fail evidence in phase verification artifacts.

7. **Enable release-readiness gate**
   - Require both automated reliability suites and human runtime evidence to pass before milestone closure.

## Component Boundary Map

| Area | Existing Component | Action in v1.1 | Risk |
|---|---|---|---|
| Startup scheduling | `main.dart` + `BackupSchedulerService` | Reuse; optional tiny test seam | Low |
| Cloud provider contract | `CloudBackupProvider` | Reuse directly in integration harness | Low |
| Scheduler policy + diagnostics | `BackupSchedulerService` + `SettingsService` | Expand scenario coverage | Low |
| Restore safety | `BackupRestoreService` | Stress with negative-path integration cases | Medium |
| User backup/restore control plane | `SettingsScreen` | Keep UI stable; verify behavior | Low |
| Intelligence reliability | existing intelligence services | Add integration regression coverage | Medium |

## Architecture Rules for This Milestone

1. New reliability logic should live in test/support and verification artifacts first.
2. Production code changes are allowed only to improve deterministic testability, not to introduce new reliability product features.
3. All reliability assertions must map to machine-checkable outputs (typed result objects, reason codes, persisted diagnostics), not ad hoc logs.
4. Human runtime validation remains mandatory for real Google account/device behavior and cannot be replaced by mocks.

## Confidence

| Area | Confidence | Basis |
|---|---|---|
| Integration points identification | HIGH | Verified from current code wiring and service boundaries |
| Minimal-risk component strategy | HIGH | Additive test-only approach with narrow production modifications |
| Build order suitability | HIGH | Ordered by dependency and blast-radius control |
| Real-world runtime reliability closure | MEDIUM | Still requires human verification execution and artifact quality discipline |

## Sources

- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md`
- `lib/main.dart`
- `lib/features/backup/services/cloud_backup_provider.dart`
- `lib/features/backup/services/backup_scheduler_service.dart`
- `lib/features/backup/services/backup_restore_service.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `test/features/backup/backup_scheduler_service_integration_test.dart`
- `test/features/backup/google_drive_backup_provider_integration_test.dart`
- `test/features/settings/settings_backup_actions_test.dart`