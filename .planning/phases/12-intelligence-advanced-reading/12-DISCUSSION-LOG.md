# Phase 12: Intelligence & Advanced Reading - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in 12-CONTEXT.md.

**Date:** 2026-04-14
**Phase:** 12-intelligence-advanced-reading
**Mode:** autonomous (`--auto` equivalent)
**Areas discussed:** AI Summaries, Semantic Search, Highlights and Annotations, Text-to-Speech, Reliability and Privacy

---

## AI Summaries

| Option | Description | Selected |
|--------|-------------|----------|
| On-demand summary generation | Generate summary when user requests in Reader View; cache result | ✓ |
| Precompute on ingestion | Generate summary at save time for all items | |
| Batch background generation | Queue generation for recently opened items | |

**User's choice:** `[auto]` On-demand summary generation with per-item cache.
**Notes:** Recommended for cost control, deterministic UX, and alignment with existing local-first ingestion speed.

---

## Semantic Search

| Option | Description | Selected |
|--------|-------------|----------|
| Separate semantic search screen | Keep keyword search untouched; add dedicated semantic route | |
| Hybrid mode in current search bar | Add keyword/semantic mode toggle in existing search entrypoint | ✓ |
| Always semantic-first | Replace current FTS behavior with semantic retrieval | |

**User's choice:** `[auto]` Hybrid mode in current search bar.
**Notes:** Preserves known UX and existing `searchItems` fallback path while introducing concept search.

---

## Highlights and Annotations

| Option | Description | Selected |
|--------|-------------|----------|
| Text selection with anchored highlights + optional notes | Save quote + positional anchor in DB and show inline in Reader | ✓ |
| Freeform notes only | Per-item notes without text anchors | |
| External-only annotation export | Do not persist local annotations | |

**User's choice:** `[auto]` Anchored highlights with optional notes.
**Notes:** Best fit for Reader-centered workflow and persistent revisit value.

---

## Text-to-Speech

| Option | Description | Selected |
|--------|-------------|----------|
| Reader-integrated TTS controls | Playback controls inside Reader with resume state | ✓ |
| External handoff to system reader | Launch external apps only | |
| Background-only podcast export | Pre-render audio files | |

**User's choice:** `[auto]` Reader-integrated TTS controls with progress persistence.
**Notes:** Minimizes flow disruption and matches in-app reading behavior.

---

## Reliability and Privacy

| Option | Description | Selected |
|--------|-------------|----------|
| Feature flags + service boundary | Toggle AI features in settings and isolate provider calls in service layer | ✓ |
| Hard-enable all intelligence features | No user toggles | |
| Experimental hidden mode | No production guardrails | |

**User's choice:** `[auto]` Feature flags plus provider boundary.
**Notes:** Supports safe rollout, graceful degradation, and explicit error mapping.

---

## the agent's Discretion

- Prompt design and summary style tuning.
- Semantic model/provider selection details.
- Exact visual treatment for highlight chips and annotation panel.

## Deferred Ideas

- Browser extension implementation remains deferred from this context pass.

---

## Revision Round (User Additions)

**Date:** 2026-04-14
**Trigger:** User requested a second discuss pass to add constraints and scope changes.

### New/Updated Decisions

- LLM-powered features are user-funded through a user-provided API key.
- API key is mandatory for AI Summaries and Semantic Search; without key, those features are unavailable.
- Add tag suggestion capability, but suggestions must use existing tags only (no new-tag proposals in this phase).
- Remove Text-to-Speech from Phase 12 scope and defer to a later phase.

### Scope Impact

- Supersedes prior TTS inclusion for this phase.
- Expands intelligence scope with constrained tag suggestions.
- Adds explicit credential/billing boundary requirements for AI services.
