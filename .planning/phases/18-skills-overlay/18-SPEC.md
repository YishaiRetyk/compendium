# Phase 18: Skills Overlay — Specification

**Created:** 2026-06-07
**Ambiguity score:** 0.12 (gate: ≤ 0.20)
**Requirements:** 6 locked

## Goal

Four model-invocable Claude Code skill routers exist at `.claude/skills/{ingest,query,lint,reflect}/SKILL.md`, each a ≤3-line pointer to its `schema/workflows/{op}.md` file, **generated deterministically from a single template** by `bin/gen-skills.sh` with a `--check` regenerate-diff gate — adding zero authoritative content beyond the workflow files.

## Background

Phase 17 extracted all eight `schema/workflows/*.md` files (`structured-operations`, `ingest`, `query`, `lint`, `reflect`, `brownfield`, `release`, `audit`) — markdown is now the sole authoritative home for every workflow procedure. **No `.claude/skills/` directory exists in this repo at all.** This phase adds the optional Claude-specific accelerator layer the v1.2 design lineage deferred to last: thin skill routers so a user can invoke `/ingest`, `/query`, `/lint`, `/reflect` (or let the model auto-invoke) and be dispatched to the canonical workflow file.

Design lineage (`.planning/phases/999.4-…/CONTEXT-NOTES.md`): two independent advisors rejected a skills-first extraction as "vendor coupling disguised as progressive disclosure." The adopted framing — **markdown is the primary substrate; skills come last as thin wrappers / runtime accelerators, never the source of truth.** The minimalism precedent (Phase 8 WZRD-07/D-02, which cut the template placeholder set 6→4) governs scope: exactly the four core operations, no extras.

Wiki-grounded authoring facts (`wiki-cloud/`: `progressive-disclosure`, `src-2026-05-06-anthropic-agent-skills-best-practices`, `claude-code`): a Claude Code skill is a directory containing `SKILL.md` (YAML frontmatter + body); Level-1 metadata (`name`+`description`) is always loaded (~100 tokens/skill); Level-2 loads **all** `.md` files in the skill's top-level directory when triggered; descriptions must be third-person stating *what* and *when*; reference paths use forward slashes.

## Requirements

1. **Skill generator (`bin/gen-skills.sh`)**: A deterministic, idempotent emitter produces all four skill files from one body template + the op list.
   - Current: No generator and no `.claude/skills/` directory exist.
   - Target: `bash bin/gen-skills.sh` writes `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` from a single parameterized body template (`{op}`) plus a per-op `description` string; re-running overwrites identically (idempotent).
   - Acceptance: On a clean tree, one run creates exactly four `SKILL.md` files at the expected paths; an immediate second run produces zero `git diff`.

2. **Regenerate-diff check (`--check`)**: The generator self-verifies committed files against template output, mirroring `bin/sync-claude.sh --check` semantics. This is the mechanical gate that satisfies SKILL-02.
   - Current: No mechanical guarantee that skill files match a template or stay thin.
   - Target: `bash bin/gen-skills.sh --check` regenerates to a temp location, diffs against the committed `.claude/skills/` files, exits 0 on match and 1 on any drift.
   - Acceptance: With committed files matching the template, `--check` exits 0; after manually editing any committed `SKILL.md` body, `--check` exits 1; reverting restores exit 0.

3. **Four skill files exist with correct path, format, and directory purity**.
   - Current: No `.claude/skills/` directory.
   - Target: `.claude/skills/{ingest,query,lint,reflect}/SKILL.md`, each with YAML frontmatter (`name`, `description`) and a body. Each skill directory contains **only** `SKILL.md`.
   - Acceptance: All four files exist at the exact paths; each skill directory contains exactly one file (`SKILL.md`) — no stray `.md` or other files (Claude Code Level-2 loads every top-level `.md`, so extras would leak content).

4. **Pointer-only thin body (SKILL-01)**: Each body is a ≤3-line invocation pointer with no procedural content.
   - Current: N/A (no skills).
   - Target: Each body is at most 3 lines and contains only the pointer form — *"You have been invoked to {op}. Read `schema/workflows/{op}.md` and follow it verbatim."* — using a forward-slash path.
   - Acceptance: The gate asserts every body is ≤3 lines and contains the literal substring `schema/workflows/{op}.md`; no body line encodes a workflow step, rule, or branch.

5. **Model-invocable description (third-person, what + when)**: Descriptions carry the discovery load since model-invocation is enabled.
   - Current: N/A.
   - Target: Each `SKILL.md` `description` is third-person and states both what the operation does and when to invoke it; model invocation is allowed (no `disable-model-invocation` key set to true).
   - Acceptance: Every frontmatter has `name` and a non-empty `description`; no description contains a first-person pronoun ("I", "I'll", "we"); no `disable-model-invocation: true` key is present.

6. **Markdown remains the sole authority (SKILL-02)**: Skills add zero behavior not already in the workflow file.
   - Current: `schema/workflows/{op}.md` is authoritative; nothing duplicates or overrides it.
   - Target: A skill body contributes no rule, step, default, or branch absent from its `schema/workflows/{op}.md`; the description names *when* to invoke but encodes no *how*.
   - Acceptance: A verifier desk-check (plus grep for imperative/procedural verbs in bodies) confirms each body is a pure pointer; removing all four skills would change invocation ergonomics only, not any documented behavior.

## Boundaries

**In scope:**
- `bin/gen-skills.sh` — deterministic skill generator with `--check` regenerate-diff mode
- Four generated `SKILL.md` routers: `ingest`, `query`, `lint`, `reflect`
- Thin-body (≤3 lines / pointer-only) + directory-purity enforcement, delivered via the generator's `--check` gate
- Wiring `--check` into the existing local/CI gate posture consistently with `sync-claude --check`

**Out of scope:**
- Skills for `audit` / `brownfield` / `release` / `structured-operations` — these are operator/maintenance workflows, not the four core operations; excluded by the minimalism precedent.
- Extra convenience skills (`author-wiki-page`, `validate-frontmatter`, etc.) — minimalism (Phase 8 WZRD-07/D-02); not required by SKILL-01.
- Authoring the skills via a generic AI **skill-creator** / interactive scaffolder — would produce non-uniform, non-thin bodies with authoritative content, directly violating SKILL-01/SKILL-02. The deterministic generator *is* the project's skill creator.
- `disable-model-invocation: true` — explicitly declined; model invocation is allowed (user decision).
- A behavioral eval harness / Claude-A-writes-for-Claude-B loop — heavyweight for trivial routers; at most an optional manual smoke test, never a gate.
- Wizard/installer copying `.claude/skills/` into an adopter's repo — template-shipping is handled by the existing release/orphan-branch flow; not a Phase 18 deliverable.
- Moving or copying any workflow content *into* the skills — skills stay pure pointers; the workflow files remain the only home for procedure.

## Constraints

- **Directory purity:** each `.claude/skills/<op>/` contains only `SKILL.md`; Claude Code Level-2 loads all top-level `.md` in the directory, so stray files would inflate context (wiki: `progressive-disclosure`).
- **Description economy:** Level-1 metadata (name + description) is always loaded at ~100 tokens/skill — four skills add ~400 tokens of permanent ambient cost; descriptions must be tight (one to two sentences) and third-person (wiki: `agent-skills-best-practices`).
- **Inert bodies:** no executable code, network calls, or tool invocation in skill bodies — skills run with full machine access in Claude Code, and pure pointers minimize the trust surface (wiki: `claude-code` security note).
- **Forward-slash paths** in all pointers (`schema/workflows/{op}.md`), never backslashes (cross-platform; wiki best-practice).
- **Generator semantics** mirror `bin/sync-claude.sh`: deterministic output, idempotent re-run, `--check` exits 1 on drift.
- **Naming deviation (documented):** short op-names (`ingest`/`query`/`lint`/`reflect`) mirror the `schema/workflows/{op}.md` filenames 1:1 rather than the gerund form best-practice recommends; the `description` field compensates by carrying the full what/when discovery signal.
- **Template-public neutrality:** skill files ship in the repo (template-public surface, AGENTS.md §3). Pointer bodies + workflow paths contain no private vault terms by construction; confirm `bin/check-neutrality.sh` either covers `.claude/skills/` or that the generated content is provably neutral.
- **No regression** to existing gates: `sync-claude --check`, `check-neutrality`, `check-privacy`, and `lint --ci` (incl. `routing`) stay green.

## Acceptance Criteria

- [ ] `bash bin/gen-skills.sh` creates `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` (exactly 4 files)
- [ ] `bash bin/gen-skills.sh` is idempotent — a second run produces no `git diff`
- [ ] `bash bin/gen-skills.sh --check` exits 0 when committed files match the template, and exits 1 after any manual edit to a committed `SKILL.md`
- [ ] Every `SKILL.md` body is ≤ 3 lines and contains the literal `schema/workflows/{op}.md` pointer with a forward-slash path
- [ ] Every skill directory contains exactly one file (`SKILL.md`) — no stray `.md` or other files
- [ ] Every `SKILL.md` frontmatter has `name` + a non-empty third-person `description` (no first-person pronoun); no `disable-model-invocation: true` key
- [ ] No skill body encodes a step/rule/default absent from its `schema/workflows/{op}.md` (verifier desk-check + grep)
- [ ] Existing gates remain green: `sync-claude --check`, `check-neutrality`, `check-privacy`, `lint --ci` (incl. `routing`)

## Ambiguity Report

| Dimension          | Score | Min  | Status | Notes                                                        |
|--------------------|-------|------|--------|--------------------------------------------------------------|
| Goal Clarity       | 0.90  | 0.75 | ✓      | 4 generated routers, dir+SKILL.md, short names, model-invocable |
| Boundary Clarity   | 0.87  | 0.70 | ✓      | skill-creator + extra ops + wizard-shipping explicitly excluded |
| Constraint Clarity | 0.88  | 0.65 | ✓      | dir-purity, 3rd-person descriptions, inert bodies, fwd-slash (wiki-grounded) |
| Acceptance Criteria| 0.87  | 0.70 | ✓      | regenerate-diff + line-count + dir-purity + description-format all falsifiable |
| **Ambiguity**      | 0.12  | ≤0.20| ✓      |                                                              |

Status: ✓ = met minimum, ⚠ = below minimum (planner treats as assumption)

## Interview Log

| Round | Perspective     | Question summary                                  | Decision locked                                                                 |
|-------|-----------------|---------------------------------------------------|---------------------------------------------------------------------------------|
| 1     | Researcher      | What exists today vs. the target?                 | All 8 `schema/workflows/*.md` exist; no `.claude/skills/` — build 4 thin routers |
| 1     | Boundary Keeper | Skill packaging format + naming?                  | Dir + `SKILL.md`, short op-names (`ingest`/`query`/`lint`/`reflect`) mirroring workflow files |
| 1     | Boundary Keeper | Model-invocable or explicit-trigger-only?         | Allow model invocation (no `disable-model-invocation`); `description` becomes load-bearing |
| 1     | Failure Analyst | SKILL-02 falsifiable check for "zero content"?    | Mechanical gate — `bin/gen-skills.sh --check` regenerate-diff + body line-count  |
| 1b    | Seed Closer     | *How* are the skills created?                      | Generated-from-template (`bin/gen-skills.sh`), not hand-authored; `--check` is the gate |
| 1c    | Seed Closer     | Will a generic skill-creator skill be used?       | No — excluded; would violate SKILL-01/02. The deterministic generator is the creator |
| —     | Research        | Best practices for `bin/gen-skills.sh` / SKILL.md | Browsed `wiki-cloud/`: 3rd-person what+when descriptions, only-`SKILL.md`-per-dir (L2 loads all `.md`), L1 ~100 tok/skill, forward-slash paths, inert bodies |

---

*Phase: 18-skills-overlay*
*Spec created: 2026-06-07*
*Next step: /gsd-discuss-phase 18 — implementation decisions (template body wording, exact per-op description strings, where `--check` wires into CI/pre-commit, neutrality coverage of `.claude/skills/`)*
