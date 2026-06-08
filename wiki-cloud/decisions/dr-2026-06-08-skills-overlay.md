---
id: dr-2026-06-08-skills-overlay
title: "Skills Overlay: Four Generated SKILL.md Routers + bin/gen-skills.sh Drift Gate"
type: decision
status: active
summary: "Introduces four thin .claude/skills/{op}/SKILL.md pointer routers generated deterministically by bin/gen-skills.sh from a single body template; guards them with a --check regenerate-diff + structural-assertion gate; records the two-layer Source-of-Truth model (behavioral SOT = schema/workflows/{op}.md; artifact SOT = the generator template + description data) and the model-invocation-enabled choice."
created_at: 2026-06-08
updated_at: 2026-06-08
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-06-08-skills-overlay
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

# Skills Overlay: Four Generated SKILL.md Routers + bin/gen-skills.sh Drift Gate

## TL;DR

Phase 18 adds the optional Claude Code accelerator layer that the v1.2 design deferred to last: four thin `.claude/skills/{op}/SKILL.md` pointer routers for the core operations (ingest, query, lint, reflect). Each skill body is a ≤3-line invocation pointer to its corresponding `schema/workflows/{op}.md` file and encodes zero authoritative content. The files are generated deterministically by `bin/gen-skills.sh` and guarded by a `--check` regenerate-diff + structural-assertion gate wired into both the pre-commit hook and CI. Markdown remains the sole source of truth for behavior.

## Decision

Add a `.claude/skills/` overlay of exactly four skill routers — ingest, query, lint, reflect — generated from a single parameterized body template by `bin/gen-skills.sh`, with:

1. **Four SKILL.md files** at `.claude/skills/{ingest,query,lint,reflect}/SKILL.md`, each containing YAML frontmatter (`name`, `description`) and a ≤3-line pointer body: `"You have been invoked to {op}. Read \`schema/workflows/{op}.md\` and follow it verbatim."`
2. **Generator as artifact SOT** (`bin/gen-skills.sh`): deterministic, idempotent, zero external deps; a structural twin of `bin/sync-claude.sh`.
3. **`--check` gate**: regenerates to a temp dir, diffs with `cmp -s`, plus independent structural assertions (≤3 body lines, directory purity, no first-person pronoun, no `disable-model-invocation: true`). Exits 0 on match, 1 on any drift.
4. **Gate wiring**: pre-commit auto-fix + restage between sync-claude and lint; CI hard-fail (no auto-fix) as a required status check.
5. **Model invocation enabled**: `description` carries the what+when discovery signal; no `disable-model-invocation: true` key set.

## Why

**Design lineage:** Two independent advisors in the v1.2 design phase rejected a skills-first extraction as "vendor coupling disguised as progressive disclosure." The adopted framing: markdown is the primary substrate; skills come last as thin wrappers / runtime accelerators, never the source of truth. Phase 18 is the last step in the v1.2 schema-architecture trajectory (after Phases 15–17 established the markdown-authoritative schema tree).

**Two-layer Source-of-Truth Model:**

| Layer | Source of truth | Status of the SKILL.md file |
|-------|-----------------|-------------------------------|
| **Behavior** (what the operation does) | `schema/workflows/{op}.md` | body is a pointer; encodes zero behavior |
| **Artifact text** (the bytes of the skill file) | `bin/gen-skills.sh` template + description data | generated copy; `--check` guarded |

This mirrors the existing `AGENTS.md → CLAUDE.md` derived-artifact relationship: hand-edits to CLAUDE.md are wrong; hand-edits to SKILL.md files are equally wrong and are caught by `--check`.

**Why model invocation is enabled:** The `description` field carries the what+when signal at L1 (~100 tokens/skill, always loaded). Requiring explicit invocation (`disable-model-invocation: true`) reduces ergonomics without improving safety — the body is a pure pointer and the structural assertions enforce inertness mechanically. Description economy is preserved by the ≤1024-char constraint and the structural assertion that no first-person pronoun appears.

**Why four skills and not more:** Minimalism precedent (Phase 8 WZRD-07/D-02). The four core operations (ingest, query, lint, reflect) map 1:1 to the four schema/workflows/{op}.md files. Audit, brownfield, release, and structured-operations are operator/maintenance workflows, not user-facing operations.

## Alternatives Considered

**Alternative A: Skip the overlay entirely.** The skill routers add ~400 tokens of permanent ambient cost. Rejected: the ergonomic benefit (model auto-invocation + `/ingest`-style dispatch) was committed as Phase C of the v1.2 design and is small in scope.

**Alternative B: Hand-author each SKILL.md file.** Rejected: hand-authored files diverge over time; a fattened body would violate SKILL-02 without a mechanical gate. The generator pattern is the established repo idiom (see `sync-claude.sh`).

**Alternative C: Use a generic AI skill-creator skill to author the skill files.** Rejected explicitly in the SPEC: a skill-creator would produce non-uniform, non-thin bodies with authoritative content, directly violating SKILL-01/SKILL-02.

**Alternative D: Extra skills for audit/brownfield/release.** Rejected: minimalism precedent (WZRD-07/D-02); those are operator workflows not warranting always-loaded ambient cost.

## Consequences

- Four new committed files under `.claude/skills/` (tracked by changing the `.gitignore` ignore line to the `.claude/*` file-glob form plus the negations `!.claude/skills/` + `!.claude/skills/*/` + `!.claude/skills/*/SKILL.md`; a `.claude/` DIRECTORY ignore cannot re-include descendants, so the file-glob form is required — verified by direct test).
- One new `bin/gen-skills.sh` script (~100 lines, pure bash, zero new deps).
- `.githooks/pre-commit` gains a skills block between sync-claude and lint.
- CI `lint.yml` gains a `skills-check` required status check job.
- `bin/check-neutrality.sh` `PUBLIC_PATHS` extended with `.claude/skills` (D-10).
- No change to `AGENTS.md`/`CLAUDE.md` resident core (D-08 — skills are pointers, not authoritative content).
- No change to any `schema/workflows/` file — behavioral SOT is read-only from skills' perspective.

## Affected Pages

None. This is an infrastructure decision record (cf. `dr-2026-06-05-workflow-extraction`, `affected_pages: []`). The `wiki-cloud/index.md` Decisions-section entry is a catalog registration, not a content page that gained a `decision_history` backlink.

## Sources

- `18-SPEC.md` — locked requirements (SKILL-01, SKILL-02) and two-layer SOT model
- `18-CONTEXT.md` — implementation decisions D-01 through D-11
- Design lineage: `.planning/phases/999.4-v1-2-schema-architecture-progressive-disclosure-refactor/CONTEXT-NOTES.md` §"Phase C — Claude Skills Overlay"
