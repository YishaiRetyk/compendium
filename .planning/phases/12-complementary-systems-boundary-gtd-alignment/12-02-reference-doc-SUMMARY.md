---
phase: 12
plan: 02
plan_id: 12-02-reference-doc
subsystem: docs
tags: [docs, reference, gtd, boundary, BOUND-02]
requires:
  - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-SPEC.md
  - .planning/phases/12-complementary-systems-boundary-gtd-alignment/12-CONTEXT.md
  - .planning/notes/2026-04-24-agentic-gtd-boundary.md
  - .planning/notes/2026-04-24-openbrain-vs-compendium-critique.md
provides:
  - "BOUND-02: operator-facing 3-layer model reference doc"
  - "Routing rules for capture / clarify / organize / review"
  - "Anti-features list (canonical exclusions)"
affects:
  - docs/reference/three-layer-model.md
tech-stack:
  added: []
  patterns:
    - "operator-facing reference doc (no YAML frontmatter, plain markdown)"
    - "markdown 4-column routing table"
    - "explicit anti-features list per BOUND-02 acceptance"
key-files:
  created:
    - docs/reference/three-layer-model.md
  modified: []
decisions:
  - "Filename locked at docs/reference/three-layer-model.md (D-01)"
  - "Section order: opening paragraph -> The Three Layers -> Routing Rules -> Anti-features -> See also (D-02)"
  - "Routing table uses 4 verbs (capture/clarify/organize/review) — engage folded out, reflect folded into review (D-04)"
  - "BOUND-01 DR cited by both bare ID and relative-path link to support both grep audit forms"
metrics:
  duration: ~5 min
  completed: 2026-05-01
  tasks_completed: 1
  files_changed: 1
requirements:
  - BOUND-02
---

# Phase 12 Plan 02: Reference Doc Summary

Created `docs/reference/three-layer-model.md` — the operator-facing reference for the BOUND-02 boundary. Documents the 3-layer model (task / working-memory / wiki-compiler), the 4-verb routing table (capture / clarify / organize / review), and the canonical anti-features list, citing the BOUND-01 decision record by both ID and relative path.

## What was built

Single new reference doc at `docs/reference/three-layer-model.md` (no YAML frontmatter — operator-facing reference style matching `docs/reference/privacy-model.md` and `docs/reference/brownfield.md`):

1. **H1 + opening framing paragraph** — declares compendium as the wiki-compiler layer and frames the 4-verb scope (engage operationally task-only; reflect folded into review).
2. **`## The Three Layers`** — bullets for task / working-memory / wiki-compiler, each naming what it owns and citing original framing in `.planning/notes/2026-04-24-agentic-gtd-boundary.md`.
3. **`## Routing Rules`** — locked 1-line caption (D-08) above a 4-column markdown table (Verb | Belongs in | Compendium role | Out of scope) with rows for capture / clarify / organize / review per D-05/D-06/D-07.
4. **`## Anti-features`** — explanatory sentence + 7 explicit bullets covering every SPEC-required exclusion (`inbox`, `next-action`, `calendar`, `reminder`, `rapid transactional`, `high-churn waiting-for`, `Slack / ticket / event-stream`), closing with the BOUND-01 DR pointer by ID.
5. **`## See also`** — links to AGENTS.md, the BOUND-01 DR by relative path, and the README entry point.

## Acceptance criteria — verification results

All 18 plan acceptance criteria verified post-write:

| Criterion | Result |
|---|---|
| File exists at locked path | PASS |
| 4 H2 sections (`grep -c '^## ...'` == 4) | PASS — exactly 4 |
| H1 title `# The Three-Layer Model` | PASS — 1 match |
| No YAML frontmatter (`head -1` not `---`) | PASS — 0 matches |
| 4 verb rows in routing table | PASS — 4 matches |
| Routing table header exact match | PASS — 1 match |
| `capture` -> working-memory layer | PASS |
| `clarify` -> working-memory layer | PASS |
| `organize` -> task layer | PASS |
| `review` -> all three layers | PASS |
| Anti-features bullet: `inbox` | PASS |
| Anti-features bullet: `next-action` | PASS |
| Anti-features bullet: `calendar` | PASS |
| Anti-features bullet: `reminder` | PASS |
| Anti-features bullet: `rapid transactional` | PASS |
| Anti-features bullet: `high-churn waiting-for` | PASS |
| Anti-features bullet: `slack/ticket/event-stream` | PASS |
| BOUND-01 DR by bare ID | PASS — 2 matches (closing sentence + see-also link) |
| BOUND-01 DR by relative path | PASS — 1 match |
| Routing-table caption (D-08 pattern) | PASS — 1 match |
| `task layer` in Three Layers section | PASS |
| `working-memory layer` in Three Layers section | PASS |
| `wiki-compiler layer` in Three Layers section | PASS |
| Plan `<verify>` command (4 H2 + 4 verbs) | PASS — exits 0 |

## Locked decisions honored

- **D-01:** Filename `docs/reference/three-layer-model.md`.
- **D-02:** Section order: opening paragraph -> The Three Layers -> Routing Rules -> Anti-features -> See also.
- **D-03:** TL;DR-style 1-paragraph opening framing (verbatim suggested wording).
- **D-04:** 4-column routing table with verbs in capture/clarify/organize/review order.
- **D-05:** Belongs-in mapping per locked verb-to-layer routing.
- **D-06:** Compendium-role cells use concrete actions per verb (without erasing durable-knowledge contribution).
- **D-07:** Out-of-scope cells are per-verb specific entries (no shared pointer).
- **D-08:** 1-line caption above the routing table explaining the 4-column reading order.

## Deviations from Plan

None — plan executed exactly as written. The single task (write the reference doc) completed in one pass. All locked CONTEXT.md decisions and SPEC acceptance criteria honored verbatim.

## Wave-1 cross-reference state

Per the `<wave_1_coordination_note>` in the plan: this doc cites BOUND-01 (`wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md`) by relative path and bare ID. If Plan 12-02 commits before Plan 12-01, the relative-path link is transiently red. This is acceptable because:

1. The reference is a markdown link with `.md` extension (NOT an Obsidian wikilink), so AGENTS.md §6 provenance lint will not flag it as a broken wikilink.
2. Lint runs only in Plan 12-04 (after both Wave-1 commits land), so no CI impact.
3. The orchestrator merges both Wave-1 plans into the same wave/PR window, so the red-link state is short-lived.

## Self-Check: PASSED

**File existence check:**
- `docs/reference/three-layer-model.md` — FOUND

**Commit existence check:**
- `8c32651` (`docs(12-02): add three-layer-model reference doc (BOUND-02)`) — FOUND in `git log`

**Acceptance criteria check:** all 18 criteria from the plan PASS (see verification table above).

## Threat Flags

None. Pure docs phase — single new markdown file under `docs/reference/`, no executable code paths, no API surface, no new attack surface introduced. Existing CI gates (neutrality, privacy-leak, lint) operate on content, not file boundaries, and continue to apply unchanged.
