# Feature Landscape: Mnemata v1.1 Reliability & Verification

**Domain:** Personal knowledge app with cloud portability and AI-assisted reading
**Milestone:** v1.1 Reliability & Verification
**Researched:** April 16, 2026
**Overall Confidence:** HIGH (project-scoped reliability priorities)

## Table Stakes

These are baseline expectations for a reliability-focused release. If these are weak or missing, users will not trust cloud portability or intelligence outputs.

| Feature | Why Expected for v1.1 | Complexity | Dependencies on Existing System Behavior |
|---------|------------------------|------------|------------------------------------------|
| **End-to-end cloud backup/restore validation on real accounts/devices** | Reliability claims are not credible without real runtime evidence beyond mocks. | Medium | Depends on existing Google Drive auth/upload/download integration, deterministic archive manifest/checksum pipeline, and restore apply confirmation gate. |
| **Backup diagnostics with actionable reason codes** | Users expect to know whether auto backup ran, skipped, or failed, and why. | Medium | Depends on current scheduler diagnostics persistence and deterministic skip/failure reason mapping in settings state. |
| **Deterministic restore integrity enforcement** | Portability must be safe: no partial or corrupted restore should apply. | Low-Medium | Depends on existing staged all-or-nothing restore flow and apply-time checksum re-validation behavior. |
| **Cross-platform portability regression coverage** | Reliability requires proving the same backup artifact can move between supported platforms and still restore correctly. | High | Depends on existing versioned manifest schema, required-entry validation, and stable local secure storage mapping across iOS/Android/Web boundaries. |
| **Release verification artifact completeness** | Teams expect auditable evidence that reliability-critical flows were tested before shipping. | Low | Depends on existing verification artifact conventions and requirement-to-evidence traceability process from v1.0 closure. |
| **Intelligence flow safety-net integration tests** | AI features must fail safely and predictably under key/runtime errors. | Medium | Depends on API-key gating, deterministic provider error mapping, persisted intelligence contracts, and fallback behavior already implemented in v1.0. |

## Differentiators

These features move v1.1 beyond "works in ideal paths" into "trustworthy under real-world conditions," which is uncommon in personal knowledge tools.

| Feature | Value Proposition | Complexity | Dependencies on Existing System Behavior |
|---------|-------------------|------------|------------------------------------------|
| **Reliability confidence scorecard in Settings** | Gives users and maintainers a visible confidence snapshot (last successful backup age, restore readiness, scheduler health). | Medium | Depends on existing persisted diagnostics fields and backup history metadata; requires derived health evaluation rules. |
| **Cloud restore readiness preview with risk flags** | Before apply, users see explicit warnings (missing entries, stale backup age, schema mismatch risk) and can abort safely. | Medium | Depends on existing restore preview pipeline, manifest inspection, and confirmation gating UX. |
| **Verification-first release gate (must-pass reliability suite)** | Converts milestone quality from subjective to objective with a strict, repeatable pass threshold. | Medium | Depends on integration test harness and current planning verification artifact workflow. |
| **Operational drill mode (simulate failure classes)** | Proactively validates behavior for token expiration, network loss, and interrupted restore without waiting for production incidents. | High | Depends on cloud provider abstraction seams, scheduler policy hooks, and deterministic error mapping already present. |
| **Audit-ready evidence bundle export** | Enables milestone audits without retrospective reconstruction; improves team throughput and external confidence. | Low-Medium | Depends on existing verification artifacts and milestone traceability structure in planning docs. |

## Anti-Features

These are attractive but harmful for this milestone because they dilute reliability and verification outcomes.

| Anti-Feature | Why Avoid in v1.1 | What to Do Instead |
|--------------|--------------------|-------------------|
| **New AI capability expansion (new generation modes, new model integrations)** | Expands surface area and introduces new failure modes before reliability baseline is proven. | Keep existing intelligence scope stable; focus on failure-path coverage and deterministic fallback verification. |
| **New sync providers beyond Google Drive** | Multiplies auth, conflict, and portability permutations while current provider still needs runtime confidence closure. | Fully validate Google Drive path end-to-end first, then treat additional providers as future milestone work. |
| **Large UX redesign in reliability milestone** | Visual churn creates regression risk and verification noise unrelated to trust outcomes. | Limit UI work to reliability observability surfaces (diagnostics, readiness warnings, evidence visibility). |
| **Background automation complexity jump (aggressive smart scheduling)** | Hard-to-debug scheduler heuristics can reduce predictability during a verification-driven milestone. | Keep deterministic scheduler policy and improve observability/tests around current decision rules. |
| **Schema/platform refactor without reliability need** | Refactors increase migration risk and undermine portability validation comparability. | Preserve schema/runtime contracts; only make minimal changes required for verification instrumentation. |

## Milestone Dependency Map

```text
Cloud auth + provider error mapping
    -> Backup upload/download runtime validation
    -> Scheduler diagnostics confidence

Versioned manifest + checksum pipeline
    -> Restore preview risk flags
    -> Deterministic restore integrity enforcement
    -> Cross-platform portability regressions

API-key gate + intelligence persistence contracts
    -> Intelligence failure-path tests
    -> Verification-first release gate

Verification artifact conventions
    -> Audit-ready evidence bundle
    -> Milestone pass/fail confidence review
```

## Recommended v1.1 Prioritization

1. **Runtime reliability proof for cloud backup/restore/scheduler** (table stake)
2. **Portability and intelligence integration regression safety nets** (table stake)
3. **Verification artifact quality and release gate hardening** (table stake)
4. **Reliability confidence scorecard + restore risk signaling** (differentiator)

Defer until after v1.1 reliability closure:
- New AI feature breadth
- Additional cloud providers
- Non-essential UX/system refactors

## Sources

- `.planning/PROJECT.md` (v1.1 goal, active requirements)
- `.planning/MILESTONES.md` (v1.0 shipped capabilities and residual risk context)
- `.planning/STATE.md` (current status, key decisions, and reliability-relevant constraints)
