---
phase: 11-cloud-data-portability
plan: 05
subsystem: backup
tags: [flutter, scheduler, connectivity, charging, traceability]
requires:
  - phase: 11-04
    provides: Runtime-authenticated cloud provider path for scheduler uploads.
provides:
  - Runtime Wi-Fi and charging signal adapters backed by platform APIs.
  - Scheduler policy integration using injected runtime signal service.
  - POR-03 ownership remap to Phase 12 research per deferred scope decision D-06.
affects: [backup, startup, planning]
tech-stack:
  added: [connectivity_plus, battery_plus]
  patterns: [tdd-red-green, runtime-signal-adapter, deterministic-policy-reasons]
key-files:
  created:
    - lib/features/backup/services/network_power_signal_service.dart
    - test/features/backup/backup_scheduler_service_integration_test.dart
  modified:
    - lib/features/backup/services/backup_scheduler_service.dart
    - lib/main.dart
    - test/features/backup/backup_scheduler_service_test.dart
    - pubspec.yaml
    - pubspec.lock
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
key-decisions:
  - "Scheduler runtime signal checks now flow through NetworkPowerSignalService so policy gates reflect real device state."
  - "Battery full and connected-not-charging states are treated as charging-eligible for backup policy compliance."
  - "POR-03 is not Phase 11-owned work; it is tracked as Phase 12 research to match deferred scope decision D-06."
requirements-completed: []
duration: 33min
completed: 2026-04-04
---

# Phase 11 Plan 05: Runtime Signals and Traceability Gap Closure Summary

**Scheduler policy now evaluates real network/power platform signals at runtime and POR-03 ownership is corrected to deferred Phase 12 research**

## Performance

- **Duration:** 33 min
- **Completed:** 2026-04-04T23:03:37Z
- **Tasks:** 2 (Task 1 via TDD)
- **Files modified:** 11

## Accomplishments

- Added `NetworkPowerSignalService` with `isWifiConnected()` using `connectivity_plus` and `isCharging()` using `battery_plus`.
- Updated `BackupSchedulerService` to consume `NetworkPowerSignalService` instead of function placeholders while preserving deterministic reason-code persistence semantics.
- Rewired startup DI in `main.dart` to register/inject `NetworkPowerSignalService` and removed `_defaultWifiSignal` / `_defaultChargingSignal` placeholder functions.
- Added integration-style scheduler tests that verify:
  - skip when Wi-Fi signal is false,
  - skip when charging signal is false,
  - upload execution when both signals are true and backup is due.
- Corrected requirements traceability by remapping `POR-03` from `Phase 11 Planned` to `Phase 12 Research`.
- Updated Phase 11 roadmap detail to keep cloud portability scope only and explicitly defer browser-extension portability research to Phase 12.

## Task Commits

1. **Task 1 (TDD RED): Scheduler runtime signal permutation tests**
- `565ddc9` (test)

2. **Task 1 (TDD GREEN): Runtime signal adapter and scheduler integration**
- `7cdf94a` (feat)

3. **Task 2: POR-03 traceability remap**
- `c3a2f24` (fix)

## Verification Results

- `flutter test test/features/backup/backup_scheduler_service_integration_test.dart` -> PASS
- `grep -nE "POR-03|Phase 11|Phase 12" .planning/REQUIREMENTS.md .planning/ROADMAP.md` -> PASS
- `flutter analyze` -> PASS (no issues)

## Deviations from Plan

None - plan executed exactly as written.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Found file: `lib/features/backup/services/network_power_signal_service.dart`
- Found file: `test/features/backup/backup_scheduler_service_integration_test.dart`
- Found commit: `565ddc9`
- Found commit: `7cdf94a`
- Found commit: `c3a2f24`
