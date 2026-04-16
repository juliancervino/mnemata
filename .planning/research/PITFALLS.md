# Domain Pitfalls

**Domain:** Flutter cross-platform knowledge manager hardening (cloud backup/restore + verification reliability)
**Project:** Mnemata v1.1 Reliability & Verification
**Researched:** 2026-04-16

## v1.1 Working Phase Ownership (for risk routing)

- **Phase 15: Runtime Cloud Validation**
  - Human-in-the-loop real-device, real-account validation for backup/restore/scheduler runtime behavior.
- **Phase 16: Integration Hardening**
  - Deterministic integration/regression coverage for portability and intelligence-critical flows.
- **Phase 17: Verification Quality Gates**
  - Release-readiness checks, evidence quality enforcement, and anti-backfill process guardrails.

## Critical Pitfalls

### Pitfall 1: Treating emulator/passive test success as cloud runtime proof
**What goes wrong:** Team closes cloud reliability tasks after local/integration tests pass, but real Google account/device runtime still has edge failures (auth revocation, account switch, background restrictions).
**Why it happens:** Existing tests over-index on mocks and deterministic lab conditions.
**Consequences:** POR-style gaps reappear; milestone closes with unresolved runtime risk.

- **Warning signs**
  - "Works in tests" but no dated real-device validation transcript/screenshots/log captures.
  - Validation notes omit account lifecycle events (sign-out, token expiry, account switch).
  - Scheduler outcomes are asserted only in mocked environments.
- **Prevention**
  - Make runtime validation a required exit criterion with explicit scenarios and evidence artifacts.
  - Require at least one full backup->cloud->restore cycle on a physical device and real Drive account.
  - Include negative-path runtime scenarios (revoked auth, network drop during upload/download, low battery constraints where applicable).
- **Phase owner:** **Phase 15**

### Pitfall 2: Happy-path-only restore verification
**What goes wrong:** Restore appears reliable in normal flow, but corrupted/incomplete archives or checksum mismatches are not consistently rejected in production-like runs.
**Why it happens:** Test suites focus on success path and do not actively validate safety abort behavior under corruption.
**Consequences:** Potential data loss or partial restores despite existing safety design.

- **Warning signs**
  - Few/no tests covering checksum mismatch, missing required entries, incompatible schema payloads.
  - No assertions that apply flow aborts before mutation.
  - Manual QA scripts skip corruption tests.
- **Prevention**
  - Add integration fixtures for corrupted zip, stale manifest, and missing critical files.
  - Require explicit assertions for all-or-nothing apply semantics.
  - Track restore failure reason codes and verify user-visible diagnostics for each failure class.
- **Phase owner:** **Phase 16**

### Pitfall 3: Non-deterministic scheduler tests that create flaky confidence
**What goes wrong:** Backup scheduler behavior appears unstable because tests depend on wall-clock timing/platform state without isolation.
**Why it happens:** Runtime signal checks (network/power/background constraints) are hard to model deterministically.
**Consequences:** Team ignores flaky tests; true scheduler regressions slip.

- **Warning signs**
  - Intermittent CI failures around auto-backup cadence/skip reasons.
  - Test retries become standard practice.
  - Scheduler diagnostics fields are present but not asserted in regression suites.
- **Prevention**
  - Introduce injectable clock/runtime signal providers in integration seams.
  - Assert persisted skip/failure reason codes as primary outcomes, not timing side effects.
  - Separate deterministic policy tests from human runtime validation tests.
- **Phase owner:** **Phase 16**

### Pitfall 4: Reintroducing startup ordering regressions (share listener vs backup bootstrap)
**What goes wrong:** Reliability hardening changes startup flow and accidentally regresses earlier cold-start/share-intent fixes.
**Why it happens:** Startup orchestration is cross-cutting and fragile when adding new background checks.
**Consequences:** User-visible ingestion failures at app launch, especially from share intents.

- **Warning signs**
  - Startup sequence changes in `main.dart` without integration smoke coverage.
  - New async startup hooks are added without strict ordering expectations.
  - Reports of missed shared content after app cold starts.
- **Prevention**
  - Add launch-order integration tests covering share-intent ingestion plus non-blocking scheduler bootstrap.
  - Require startup-sequence checklist in PR verification notes.
  - Keep startup hooks idempotent and fail-open for non-critical services.
- **Phase owner:** **Phase 16**

## Moderate Pitfalls

### Pitfall 5: Over-mocking provider boundaries and missing real auth failure modes
**What goes wrong:** Provider abstraction tests pass, but production fails on OAuth/account permission edge cases.
**Why it happens:** Mock responses are too idealized and do not reflect real provider behavior.

- **Warning signs**
  - Near-zero tests for auth cancellation/revocation/re-consent flows.
  - Integration coverage stops at abstraction boundary.
- **Prevention**
  - Keep abstraction-level unit tests, but add bounded end-to-end runtime scripts for auth lifecycle.
  - Maintain deterministic error mapping tests for known provider error classes.
- **Phase owner:** **Phase 15** (runtime auth reality) and **Phase 16** (mapping regression)

### Pitfall 6: Test fixture drift from real Drift schema/storage layout
**What goes wrong:** Portability tests validate fixtures that no longer match production schema/file conventions.
**Why it happens:** Schema evolves but fixture builders are not version-locked.

- **Warning signs**
  - Integration tests use handcrafted DB/files not produced by current app code.
  - Failing restores in production despite green portability tests.
- **Prevention**
  - Generate fixtures from app runtime export path, not synthetic SQL only.
  - Add schema-version assertion in backup manifest tests.
  - Include migration-version checks in restore preflight tests.
- **Phase owner:** **Phase 16**

### Pitfall 7: Flaky async tests caused by unawaited background/intelligence tasks
**What goes wrong:** Regression tests pass locally but fail in CI due to race conditions in indexing/summarization/background queues.
**Why it happens:** Async jobs outlive test lifecycle; deterministic completion signals are missing.

- **Warning signs**
  - Intermittent failures around semantic/indexing/search assertions.
  - `pumpAndSettle` or sleep-based waits proliferate.
- **Prevention**
  - Add explicit completion hooks/probes for background jobs.
  - Replace time-based waits with state/event-based await conditions.
  - Quarantine and fix flaky tests instead of retry masking.
- **Phase owner:** **Phase 16**

## Process Pitfalls (Verification Debt)

### Pitfall 8: Evidence generated retrospectively (backfill pattern repeats)
**What goes wrong:** Verification files are postponed until audit time, causing traceability holes and expensive recovery.
**Why it happens:** Implementation completion is treated as done; verification artifacts are optionalized.

- **Warning signs**
  - PRs merge without requirement-to-evidence references.
  - Verification directories lag one or more phases behind implementation.
  - Milestone audit uncovers orphan requirements.
- **Prevention**
  - Define "done" as code + tests + verification artifact in the same phase.
  - Add phase exit checklist with requirement IDs and concrete evidence links.
  - Reject phase closure when evidence matrix is incomplete.
- **Phase owner:** **Phase 17**

### Pitfall 9: Soft release gates that do not block on reliability regressions
**What goes wrong:** Known reliability checks are informative only; release can proceed with failing or skipped validations.
**Why it happens:** Gate criteria are documented but not enforced.

- **Warning signs**
  - "Known flaky" reliability tests are allowed without ticketed waivers.
  - No explicit red/green gate for cloud runtime validation completion.
- **Prevention**
  - Implement mandatory pre-release gate matrix (runtime validation, integration pack, artifact completeness).
  - Require waiver process with owner, expiry, and mitigation for any temporary exceptions.
- **Phase owner:** **Phase 17**

### Pitfall 10: Requirement traceability breaks between PROJECT/ROADMAP/verification artifacts
**What goes wrong:** Requirement IDs and status diverge across planning files, making audit conclusions unreliable.
**Why it happens:** Planning/state updates are manual and late.

- **Warning signs**
  - Requirement appears active in one file and closed in another.
  - Evidence references do not map cleanly to current requirement IDs.
- **Prevention**
  - Add a milestone-level traceability sync pass at each phase transition.
  - Maintain a single source of truth table for requirement status and evidence pointers.
  - Include traceability diff review in phase closeout.
- **Phase owner:** **Phase 17**

## Phase-Specific Warnings Matrix

| Phase Topic | Likely Pitfall | Early Warning | Mitigation |
|-------------|---------------|---------------|------------|
| Runtime cloud validation | Emulator confidence mistaken for runtime proof | No real-device evidence pack | Mandatory real-account scenario matrix and signed validation run |
| Restore reliability | Happy-path restore only | No corruption/abort tests | Add corruption fixtures + all-or-nothing assertions |
| Scheduler reliability | Flaky timing-driven tests | Frequent retry-only CI outcomes | Inject clock/signals, assert reason codes |
| Startup reliability | Share listener ordering regression | Cold-start share ingestion complaints | Startup-order integration smoke tests |
| Verification process | Retrospective backfill debt | Missing requirement-to-evidence mapping at phase close | Gate phase closure on artifact completeness |

## How v1.1 can prevent repeat debt accumulation

1. Treat reliability work as a product feature with explicit acceptance criteria, not support work.
2. Split deterministic integration evidence (Phase 16) from real-runtime human validation evidence (Phase 15), and require both.
3. Enforce a hard phase-close gate in Phase 17: no closure without linked requirement IDs, test evidence, and runtime validation artifacts.
4. Keep verification artifacts incremental per phase to avoid another milestone-scale backfill.

## Confidence

- **Repository-specific risks:** HIGH (derived from v1.0 residual risk and documented closure/backfill history).
- **Flutter reliability hardening patterns:** MEDIUM (based on established testing/reliability practice, needs project-specific calibration during execution).

## Sources

- Internal: `.planning/PROJECT.md` (v1.1 goals and active requirements)
- Internal: `.planning/STATE.md` (residual risk context and verification backfill history)
- Internal: `.planning/MILESTONES.md` (v1.0 completed reliability work and remaining runtime validation gap)
- Internal: `.planning/ROADMAP.md` (phase continuity and prior cloud/intelligence closure paths)
