# Phase 18: Skills Overlay - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Generate four thin Claude Code skill routers — `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` — from a deterministic template via `bin/gen-skills.sh`, with a regenerate-diff `--check` gate. Each skill body is a ≤3-line pointer to its `schema/workflows/{op}.md` file and adds zero authoritative content. This is the optional Claude-specific accelerator layer the v1.2 design deferred to last; markdown remains the sole source of truth for behavior.

</domain>

<spec_lock>
## Requirements (locked via SPEC.md)

**6 requirements are locked.** See `18-SPEC.md` for full requirements, boundaries, acceptance criteria, and the two-layer Source-of-Truth Model.

Downstream agents MUST read `18-SPEC.md` before planning or implementing. Requirements are not duplicated here.

**In scope (from SPEC.md):**
- `bin/gen-skills.sh` — deterministic skill generator with `--check` regenerate-diff mode
- Four generated `SKILL.md` routers: `ingest`, `query`, `lint`, `reflect`
- Thin-body (≤3 lines / pointer-only) + directory-purity enforcement, delivered via the generator's `--check` gate
- Wiring `--check` into the existing local/CI gate posture consistently with `sync-claude --check`

**Out of scope (from SPEC.md):**
- Skills for `audit` / `brownfield` / `release` / `structured-operations` — not the four core operations (minimalism)
- Extra convenience skills (`author-wiki-page`, `validate-frontmatter`, etc.) — minimalism (Phase 8 WZRD-07/D-02)
- Authoring the skills via a generic AI **skill-creator** / interactive scaffolder — would violate SKILL-01/02
- `disable-model-invocation: true` — declined; model invocation is allowed
- A behavioral eval harness / Claude-A-writes-for-Claude-B loop — heavyweight for trivial routers
- Wizard/installer copying `.claude/skills/` into an adopter's repo — handled by the existing release flow
- Moving or copying any workflow content *into* the skills — skills stay pure pointers

</spec_lock>

<decisions>
## Implementation Decisions

### Generator data layout
- **D-01:** All generator inputs live **inline in `bin/gen-skills.sh`** — a pure-bash associative array `DESC[<op>]="<description>"` for the four per-op description strings, plus a heredoc body template parameterized by `{op}`. Zero external deps, single file = single artifact source-of-truth, mirrors `bin/sync-claude.sh`'s zero-dep minimalism. No separate `schema/skills/` template file or data manifest.
- **D-02:** The op list is the fixed quartet `ingest query lint reflect`, iterated in the script. Adding/removing ops is a deliberate code edit to this list (not config-driven).

### `--check` wiring & drift behavior
- **D-03:** `gen-skills.sh --check` runs in **two places**: (a) `.githooks/pre-commit` — inserted immediately AFTER the existing `sync-claude --check` step and BEFORE the `lint --strict --staged` write-gate; (b) a **CI check** in `.github/workflows/lint.yml` that hard-fails the PR on drift.
- **D-04:** **Pre-commit drift behavior mirrors `sync-claude` exactly:** on drift, regenerate the skill files, `git add` them, print "skills resynced and re-staged — re-run commit", and `exit 1` (auto-fix + ask-to-rerun). CI behavior is **hard-fail only** (no auto-fix in CI).
- **D-05:** `--check` exit semantics follow `sync-claude`: `0` = OK, non-zero = drift. Pure `cmp`/diff-based, zero deps.

### Thinness / SKILL-02 enforcement depth
- **D-06:** `gen-skills.sh --check` performs BOTH the regenerate-diff AND **independent structural assertions** (all inside the one script, no separate lint category): each `SKILL.md` body is ≤3 lines; each skill directory contains **only** `SKILL.md`; each `description` contains no first-person pronoun (`I`, `I'll`, `we`); model-invocation is not disabled.
- **D-07:** Rationale for the independent asserts (not diff-only): a *fattened template* would still pass a pure regenerate-diff (committed == fattened-template), so the structural asserts are the real guard that the template itself stays thin. This is the load-bearing reason D-06 isn't redundant with D-03.

### Spec / governance visibility
- **D-08:** **No line is added to the resident `AGENTS.md`/`CLAUDE.md` core.** Skills are pointers (not authoritative content), so they do not belong in the routing table, and omitting them protects the v1.2 core-shrink goal.
- **D-09:** Author a **decision record** `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md` (trigger_type: schema-update or equivalent) recording why the overlay exists, the two-layer SOT model, and the model-invocation choice; register it in `wiki-cloud/index.md`.
- **D-10:** Add `.claude/skills/` to `bin/check-neutrality.sh`'s scanned template-public surface (cheap defense; bodies are provably neutral by construction but the scan guards the description strings).
- **D-11:** Document the overlay for adopters in a **`docs/reference/` page** (e.g. `docs/reference/skills.md`) — end-user-facing, explaining what the skills are, that they're generated, and that `SKILL.md` files are not hand-edited.

### Claude's Discretion
- Exact wording of the per-op `description` strings (third-person, what+when, tight ~1–2 sentences) — planner/executor drafts them; the SPEC's authoring rules constrain them.
- Exact filename of the docs page (`docs/reference/skills.md` suggested) and the DR slug date-stamp.
- Whether the structural asserts emit one aggregated error or per-file errors (UX detail).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked requirements (read first)
- `.planning/phases/18-skills-overlay/18-SPEC.md` — Locked requirements, boundaries, acceptance criteria, and the two-layer Source-of-Truth Model. **MUST read before planning.**

### Patterns to mirror (the generator + gate)
- `bin/sync-claude.sh` — the exact `--check` idiom to mirror: `CHECK_ONLY` flag, exit 0 = OK / exit 2 = DRIFT, pure-bash, zero-dep, idempotent `cp`. `gen-skills.sh` is its structural twin.
- `.githooks/pre-commit` — current composition (`sync-claude --check` → `lint --strict --staged`); insert the skills `--check` between these two steps (D-03).
- `bin/install-hooks.sh` — hook activation; no change expected unless the hook gains the new step.
- `bin/check-neutrality.sh` — extend its scanned surface to include `.claude/skills/` (D-10).
- `.github/workflows/lint.yml` — host for the CI `--check` job (D-03/D-04).

### Behavioral source of truth (skills point here)
- `schema/workflows/ingest.md`, `schema/workflows/query.md`, `schema/workflows/lint.md`, `schema/workflows/reflect.md` — the four canonical workflow files each `SKILL.md` body points to (behavioral SOT).

### Design lineage
- `.planning/phases/999.4-v1-2-schema-architecture-progressive-disclosure-refactor/CONTEXT-NOTES.md` §"Phase C — Claude Skills Overlay" — the original thin-wrapper design, advisor rejection of skills-first vendor coupling, and the one-paragraph pointer-body pattern.
- `schema/AGENTS.template.md` — the template/generated-artifact precedent (considered and rejected for the body template in D-01; relevant if the planner revisits data layout).

### Wiki best-practices (authoring SKILL.md)
- `wiki-cloud/concepts/progressive-disclosure.md` — L1 metadata always-loaded (~100 tok/skill); L2 loads ALL top-level `.md` in a skill dir (drives the only-`SKILL.md`-per-dir constraint).
- `wiki-cloud/sources/src-2026-05-06-anthropic-agent-skills-best-practices.md` — third-person what+when descriptions; forward-slash paths; naming conventions.
- `wiki-cloud/entities/claude-code.md` — `.claude/skills/` project-scope mount; filesystem discovery at session start (drives committed-not-gitignored).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/sync-claude.sh`: copy its argument-parsing, `--check` drift-reporting, and idempotency structure wholesale into `bin/gen-skills.sh`. Same exit-code contract.
- `.githooks/pre-commit`: the sync-claude block is a ready-made template for the skills auto-fix+restage block (D-04).

### Established Patterns
- **Generated-artifact + `--check` drift gate** is an established repo idiom (`AGENTS.md`→`CLAUDE.md`). Skills are a third instance of it; reuse the mental model and UX verbatim.
- **Pure-bash, zero-dep `bin/` scripts** — no Python/node for the generator (consistent with sync-claude / check-neutrality).
- **Template-public neutrality gate** (`bin/check-neutrality.sh`) already governs shipped files; `.claude/skills/` joins that surface (D-10).

### Integration Points
- Pre-commit hook (between sync-claude and the write-gate) — D-03.
- CI `lint.yml` — new hard-fail `--check` step — D-03/D-04.
- `wiki-cloud/index.md` + `wiki-cloud/decisions/` — DR registration — D-09.
- `bin/check-neutrality.sh` scanned-path list — D-10.

</code_context>

<specifics>
## Specific Ideas

- Pointer body form (from SPEC / CONTEXT-NOTES): *"You have been invoked to {op}. Read `schema/workflows/{op}.md` and follow it verbatim."*
- Drift UX should read like the existing sync-claude message: "skills resynced and re-staged. Re-run commit." (D-04)
- The structural asserts exist specifically to catch a fattened *template*, not just hand-edited committed files (D-07) — call this out in the script comments so a future maintainer doesn't "simplify" them away as redundant.

</specifics>

<deferred>
## Deferred Ideas

- Skills for `audit` / `brownfield` / `release` / `structured-operations`, and convenience skills (`author-wiki-page`, `validate-frontmatter`) — out of scope by SPEC; revisit only if a future phase justifies expanding the overlay.
- Wizard/installer materializing `.claude/skills/` in an adopter's repo — deferred to the release/template-shipping workstream.
- A `bin/sync-claude.sh --check-tree` that diffs the whole `schema/` tree (raised in CONTEXT-NOTES rec #8) — broader schema-drift tooling, not this phase.

### Reviewed Todos (not folded)
- `phase-14-lint-mask-fence-edge-cases` (harden `bin/lint.sh mask_markdown` for fence edge cases) — reviewed and **kept deferred**; it's unrelated Phase-14 lint-masking residue that only coincidentally keyword-matched. Stays in `.planning/todos/pending/`.

</deferred>

---

*Phase: 18-skills-overlay*
*Context gathered: 2026-06-08*
