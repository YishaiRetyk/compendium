# Phase 14: Graph Link Resolution - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 14-graph-link-resolution
**Areas discussed:** Red-link discrimination, Variant fix direction, Severity & gating, --fix scope

---

## Red-link discrimination (LINK-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Normalized-match heuristic | Normalize (casefold + depluralize + strip parens/punct); unique match → bug, no match → red link | ✓ (refined) |
| Strict near-match only | Tight edit-distance only; conservative, may miss parens/word-order variants | |
| Flag all unresolved, tier by confidence | Report everything, split into likely-bug vs likely-red-link tiers | |

**User's choice:** Option 1, with a refinement that splits the buckets across categories: no-match unresolved links stay in the existing `gap` category, NOT `linkres`. This gives `linkres` a gateable contract. Five-way classification table (OK / title-or-id unreachable=bug / unique normalized match=bug / multi-match=ambiguous warning / no-match=gap red-link candidate).
**Notes:** Normalization must strip parenthesis *characters*, not parenthetical *content* (`Hack (Agentive Stack)` → `hack agentive stack`). Conservative singular map (contexts→context, policies→policy, contracts→contract); no word reordering, no synonyms, no substring, NO edit distance on the gating path (edit distance stays in `duplicate`). Plan implications: `orphan` must stop using `title` as resolver; `gap` switches to Obsidian-accurate resolution but stays informational; `--fix` self-aliases only; CI can gate because no-match red links are excluded.

---

## Variant fix direction (LINK-08)

| Option | Description | Selected |
|--------|-------------|----------|
| Edit the link text | Rewrite call sites to canonical title; honors §8, keeps aliases minimal | (default rule) |
| Add alias to target page | Add variant as alias; less call-site churn but grows alias lists | (narrow use) |
| Case-by-case at remediation | Per-variant triage during Wave 2, logged | ✓ |

**User's choice:** Option 3, with an explicit default. Default = edit the call site for mechanical variants (`[[Bounded Contexts]]` → `[[Bounded Context]]s`); use aliases ONLY for real alternate names/acronyms. Remediation table by variant type (plural/casing/punctuation → edit link; already-canonical parenthetical → self-alias; real alternate name → alias; ambiguous → manual, documented).
**Notes:** Aliases must stay meaningful — "not a garbage drawer for every grammatical form." Keeps policy coherent: `--fix` = self-aliases only; LINK-08 Wave 2 = manual body-link cleanup; CI gates resolution defects; prose stays readable.

---

## Severity & gating (LINK-04/05)

| Option | Description | Selected |
|--------|-------------|----------|
| error (gates CI) | linkres → error in --ci, like orphan/crossref | ✓ (narrow contract) |
| warning (visible, non-blocking) | linkres → warning, like duplicate/contradiction | |
| Split: title-unreachable=error, link-variant=warning | Two severities by sub-check certainty | (rejected) |

**User's choice:** Option 1 with a narrow contract — error/gating ONLY for high-confidence defects (title/id unreachable; unique normalized match). No-match → `gap` info; multi-match → warning (manual triage). Explicitly NOT "all unresolved links are errors."
**Notes:** Rejected the title-vs-variant split (Option 3): after the unique-match rule, a unique variant IS a real graph-integrity defect; warning-only would let the breakage recur. Phase 14 must prevent regression, not just fix today's data.

---

## --fix scope (LINK-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Self-alias backfill only | --fix injects title + id into aliases idempotently, nothing else | ✓ |
| Self-alias + unambiguous link rewrites | Also auto-rewrite unique-match body links | |

**User's choice:** Option 1. `--fix` strictly mechanical: ensure aliases exists, add title/id if missing, preserve existing, idempotent, do NOT rewrite body links.
**Notes:** Even a unique-normalized-match body rewrite is editorial (`[[Bounded Contexts]]` might become `[[Bounded Context]]s` or need rephrasing) → belongs in LINK-08 Wave 2 with judgment recorded. Clean boundary: `--fix` repairs page reachability; humans/agents reconcile prose.

## Claude's Discretion

- `bin/lint.sh` code structure for `linkres` (function decomposition, shared resolution-map/normalization helper, LINT_VERSION MINOR bump, `--category`/`--skip-category` wiring).
- Exact §8 rewrite prose + §5 checklist item wording + template/schema self-alias wording (neutrality rules apply).
- DR slug + `affected_pages` for the LINK-03 schema-update decision record.
- Test decomposition under `tests/`.
- Whether the pluralization map is a literal dict or tiny rule set (must stay explicit/conservative).

## Deferred Ideas

- Auto-rewrite of body-link variants — permanently out of `--fix` (editorial).
- Synonym / edit-distance / substring matching for `linkres` — excluded to keep CI trustworthy; edit distance stays in `duplicate`.
- General stemmer for pluralization — rejected for a small explicit map.
- v1.2 schema progressive-disclosure refactor (backlog 999.4) — sequenced after this phase.
