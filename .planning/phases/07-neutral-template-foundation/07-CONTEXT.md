# Phase 7: Neutral Template Foundation - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship a public, shareable template repo that a stranger can clone and use: Kahneman content relocated to `examples/`, `AGENTS.md` neutralized, four-track `/docs/` skeleton, LICENSE/README/PRIVACY/CLAUDE.md in place, CI neutrality + personal-content denylist gates enforced, orphan-branch release runbook + script ready, and `bin/requirements-sync.sh` mechanical traceability check. No wizard, no brownfield, no contributor workflow — those are Phases 8–11.

**Out of scope for Phase 7:** wizard (`bin/init-wizard.sh`), brownfield commands, lint `--format json` / `--ci` severity, contributor Dataview field, Obsidian/Codex render verification. `docs/quickstart.md` ships as a Phase-8-aware stub; `docs/reference/` files ship with stubs to be populated in Phase 12.

</domain>

<decisions>
## Implementation Decisions

### Repo Identity, License, Release
- **D-01:** License: **MIT** (TMPL-03). Ships as top-level `LICENSE`.
- **D-02:** Public GitHub org/repo name deferred to release time. README, docs, and CI config use `<org>/<repo>` placeholders; orphan-branch script accepts target remote as a flag/argument — it is not baked into committed files.
- **D-03:** CLAUDE.md (TMPL-10) is a **byte-identical duplicate** of AGENTS.md (not a symlink, not a shim). AGENTS.md is the canonical authoring source. `bin/sync-claude.sh` mechanically copies AGENTS.md → CLAUDE.md. A local **pre-commit hook** runs the sync (or fails with a clear message on drift). CI runs a byte-equality check and **blocks merge on drift**. Rationale: Windows/cross-platform safety without symlink config friction.
- **D-04:** Orphan-branch release (TMPL-11) uses **`bin/release.sh` + `docs/reference/release.md` runbook**, maintainer-invoked. Runbook covers prerequisites, what the script publishes, rollback. Script is **dry-run by default** (prints branch/worktree, files/history, refs/tags it would publish); `--apply` executes with an interactive confirmation prompt (reserve `--yes` for later automation).

### Neutrality & Denylist
- **D-05:** NEUT-08 denylist is **auto-derived, then human-reviewed**. Process: (1) enumerate `privacy: local_only` pages in current `wiki/`; (2) extract candidate distinctive tokens (page slugs, aliases, proper names, unusual domain terms — prefer multi-word phrases, avoid common words); (3) generate proposed `.neutrality-denylist.txt`; (4) human prunes false positives before committing; (5) CI enforces against public control-plane paths. Planner must surface the candidate list for human review as an explicit task step, not bypass it.
- **D-06:** Enforcement lives in **`bin/check-neutrality.sh` + `.neutrality-denylist.txt`** (one term/phrase per line; supports `#` comments and blank lines). Script scans only the defined public/control-plane paths (`AGENTS.md`, `CLAUDE.md`, `README.md`, `PRIVACY.md`, `/docs/**`, `.github/**`, `wiki/**`, `bin/**`); excludes `examples/**`. Exits non-zero with offending path + matching term on match. NEUT-06 (Kahneman neutrality grep) and NEUT-08 (personal-content denylist) both run through this same script, reading the same kind of list file (may be two files or one — planner's call).

### AGENTS.md Neutralization & Placeholders
- **D-07:** Neutralization style (NEUT-02/03): **generic placeholders inline + explicit `See: examples/kahneman/<page>.md` pointer** at the end of each illustrative section. AGENTS.md stays readable standalone; concrete reference is one click away. Do NOT use pure pointer-style (readers/agents skip pointers) and do NOT invent a fictional inline domain cluster (drifts from the real example).
- **D-08:** `AGENTS.template.md` carries **exactly four placeholders**: `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`. Any additional placeholder proposed by the planner requires a documented justification; the research-recommended `{{EXAMPLE_CLUSTER_REF}}` is **dropped** in favor of hardcoded `See: examples/kahneman/...` pointers (per D-07).

### Examples Directory Semantics
- **D-09:** NEUT-04 authority hierarchy: **`examples/` directory path is the primary/authoritative exclusion signal; `example: true` frontmatter is an explicit fallback** for out-of-tree pages (tutorial/worked examples in `docs/`, or pages a user copies into `wiki/`). Lint behavior:
  - Pages under `examples/` (via `EXCLUDE_DIRS`): **excluded from normal wiki health checks**; basic file integrity still runs.
  - Pages with `example: true` anywhere else: same treatment — skipped by health checks.
  - If an example page is copied into `wiki/` with `example: true`, lint continues skipping it until the user removes the flag (safe adoption ramp — copied content doesn't spam findings).

### README & Onboarding Docs
- **D-10:** `README.md` voice (TMPL-02): **technical Obsidian user, plainspoken, architecture-first, low-fluff**. Concrete "what this is" + "who it is for" + repo shape + first step + link to `docs/quickstart.md`. No "why not RAG" framing in the top pitch (that belongs in `idea.md` or later prose). Honest about prerequisites (bash, python3, git, Obsidian).
- **D-11:** `docs/quickstart.md` (TMPL-06) canonical flow is **fork → `bin/init-wizard.sh` → first `bin/ingest.sh` → open in Obsidian**. Phase 7 ships a **short stub** naming that intended flow but marking wizard/ingest sections as "filled in Phase 8". Full quickstart body is Phase 8's responsibility — do not duplicate manual-setup.md content here.
- **D-12:** `PRIVACY.md` (TMPL-09) is a **short user-facing explainer**. Contents: privacy tiers (`local_only`, `cloud_safe`), operational meaning of each, what must never be committed to public/template surfaces, short pointer to AGENTS.md for canonical enforcement semantics. **Do not** copy CI grep logic, detailed lint behavior, or enforcement edge cases — AGENTS.md remains the canonical behavioral spec.
- **D-13:** `examples/kahneman/README.md` (NEUT-05) is a **reference-example explainer**. Contents: what the cluster demonstrates (ingest, synthesis, cross-linking, provenance, contradiction handling), why it's preserved, how to read it, which AGENTS.md sections it illustrates, explicit "do not edit — reference material" note. Not a tutorial walkthrough; not a one-paragraph stub.

### .gitignore Scope
- **D-14:** `.gitignore` (TMPL-04) covers four categories: Obsidian noise (`.obsidian/workspace*.json`, `.obsidian/cache`, `.trash/`), brownfield artifacts (`.brownfield/`), planning directory (`.planning/`), and OS/editor noise (`.DS_Store`, `Thumbs.db`, `*.swp`, `.idea/`, `.vscode/`).

### requirements-sync Behavior (DEBT-03)
- **D-15:** Enforcement mode: **advisory by default, blocking on `--strict`**. PR CI runs default mode (exits 0, prints findings). Milestone-close / Phase-12 verification workflow runs `--strict` (exits non-zero on any drift). Active-phase drift is expected within a branch; hard-blocking every PR creates busywork.
- **D-16:** Output format: **markdown table to stdout by default; `--format json` for CI automation**. Default columns: `REQ-ID | REQUIREMENTS.md | VERIFICATION.md | Drift` (optional `Note` column if a reason is inferable). No committed report artifact.
- **D-17:** Scope: **global by default (all REQ-IDs across all phase VERIFICATION.md files)**; `--phase N` flag for focused local runs. Future `--milestone vX.Y` left as a forward-compatible hook, not implemented in Phase 7.

### Claude's Discretion
- Exact CI workflow file name(s) and structure under `.github/workflows/` (single `lint.yml` vs split) — planner's call, consistent with research.
- Whether the pre-commit hook for CLAUDE.md sync (D-03) ships as a committed `.githooks/` dir with an install script, or a documented manual install step — planner decides.
- Concrete markdown schema of `docs/reference/release.md` (D-04) and `docs/reference/*.md` stubs (TMPL-08) — planner drafts, user reviews at verification.
- Exact stdout formatting, exit codes, and flag parsing conventions in `bin/check-neutrality.sh`, `bin/sync-claude.sh`, `bin/release.sh`, `bin/requirements-sync.sh` — follow existing `bin/lint.sh` conventions.
- Whether NEUT-06 (Kahneman grep) and NEUT-08 (denylist) share one `.neutrality-denylist.txt` file or use two files (e.g., `.kahneman-denylist.txt` + `.personal-denylist.txt`) — planner's call; single file with categorized comments is acceptable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements (authoritative scope)
- `.planning/ROADMAP.md` §Phase 7 — goal, dependencies, success criteria (1–5), full REQ-ID list.
- `.planning/REQUIREMENTS.md` — TMPL-01..11, NEUT-01..08, DEBT-03 definitions; traceability table.
- `.planning/MILESTONES.md` — v1.1 Shareability framing.
- `.planning/PROJECT.md` — project vision, non-negotiables, out-of-scope list.

### Research (informs architecture; not re-litigated)
- `.planning/research/SUMMARY.md` — milestone-wide synthesis (pitfalls C-1/C-2/C-3, zero-new-deps posture).
- `.planning/research/STACK.md` — confirmed tech choices (bash, python3, GitHub Actions `ubuntu-latest`, `actions/checkout@v6`).
- `.planning/research/ARCHITECTURE.md` — seven integration decisions, including `examples/kahneman/` move semantics, `EXCLUDE_DIRS` extension, placeholder set, orphan-branch release posture.
- `.planning/research/FEATURES.md` §B1, §B6 — must-have bucket definitions.
- `.planning/research/PITFALLS.md` — C-1 (creator-content leakage) prevention checklist; this phase implements C-1 mitigations.

### Retrospective & Prior State
- `.planning/RETROSPECTIVE.md` — v1.0 retrospective lessons; DEBT-03 origin.
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md` — gaps carried into v1.1 that Phase 7 begins closing.
- `.planning/notes/2026-04-09-agents-md-size-risk.md` — AGENTS.md size/placeholder scope considerations for neutralization work.

### Existing Code Surface (read before editing)
- `AGENTS.md` (repo root) — canonical schema to be neutralized into `AGENTS.template.md`.
- `bin/lint.sh` — `EXCLUDE_DIRS` must be extended (NEUT-04); existing flag/exit/output conventions are the reference for new scripts.
- `bin/ingest.sh`, `bin/search.sh`, `bin/validate-op.sh` — bash conventions reference.
- `wiki/` (all subdirs: comparisons, concepts, entities, sources, overviews, decisions, maintenance, index.md, log.md) — Kahneman content currently located here; 7 pages to move per NEUT-01.
- `idea.md` (repo root) — founder-voice framing; informs README tone (D-10) but not content.

### External Specs (for planner's reference only)
- Diátaxis framework (https://diataxis.fr) — referenced by TMPL-07; no local doc.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`bin/lint.sh`** — extension point for `EXCLUDE_DIRS`/`example: true` (NEUT-04). Established conventions for flag parsing, stdout formatting, exit codes that new Phase 7 scripts should mirror (`bin/check-neutrality.sh`, `bin/sync-claude.sh`, `bin/release.sh`, `bin/requirements-sync.sh`).
- **`bin/ingest.sh`, `bin/search.sh`, `bin/validate-op.sh`** — pattern library for bash tooling (heredoc args, python3 inline blocks, env-var passing).
- **`AGENTS.md`** — canonical schema; placeholder substitution operates over this file verbatim to produce `AGENTS.template.md`.

### Established Patterns
- **Zero new runtime deps** (STACK.md) — Phase 7 must add none. All new scripts are bash + python3 inline.
- **Mechanical-first, human-review-second** — pattern applied to denylist derivation (D-05): auto-generate candidates, human prunes before committing.
- **Safe-by-default flags** — `--dry-run` / `--apply` split (D-04) matches brownfield pattern already planned for Phases 10–11.
- **Single python3 heredoc for multi-check scripts** (Phase 05 decision) — likely applicable to `bin/requirements-sync.sh` parsing both REQUIREMENTS.md and VERIFICATION.md files.
- **Structured ops / decision records** — NEUT-07 requires `dr-YYYY-MM-DD-kahneman-to-examples.md` (SUPERSEDE-class) per `AGENTS.md §11.4`.

### Integration Points
- **Top-level files** added: `README.md`, `LICENSE`, `PRIVACY.md`, `CLAUDE.md`, `.gitignore`.
- **New directories**: `docs/` (with `quickstart.md`, `guided-setup.md`, `manual-setup.md`, `reference/index.md`, `reference/schema-tour.md`, `reference/brownfield.md`, `reference/privacy-model.md`, `reference/ci.md`, `reference/examples.md`, `reference/release.md`), `examples/kahneman/` (target for 7 Kahneman pages + sources), `schema/` (houses `AGENTS.template.md`), `.github/` (workflows, CODEOWNERS, PR/issue templates, CONTRIBUTING.md, SECURITY.md), `.neutrality-denylist.txt` (or equivalent file(s) per D-05/D-06).
- **New scripts in `bin/`**: `check-neutrality.sh`, `sync-claude.sh`, `release.sh`, `requirements-sync.sh`.
- **Modified files**: `bin/lint.sh` (EXCLUDE_DIRS / `example: true` support); `AGENTS.md` (neutralization → inline placeholders + `See: examples/kahneman/...` pointers; add `example: true` and orphan-release documentation to §5/§11).
- **Deleted/moved from `wiki/`**: Kahneman cluster pages — `wiki/entities/daniel-kahneman.md`, `wiki/concepts/prospect-theory.md`, `wiki/concepts/loss-aversion.md`, `wiki/concepts/cognitive-biases.md`, `wiki/comparisons/system-1-vs-system-2.md`, and Kahneman-related `wiki/sources/src-*.md`. Wikilinks preserved across move (NEUT-01).

</code_context>

<specifics>
## Specific Ideas

- `{{EXAMPLE_CLUSTER_REF}}` placeholder proposed by research is **rejected** — use hardcoded `See: examples/kahneman/...` pointers (keeps four placeholders: `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`).
- `docs/quickstart.md` explicitly labels wizard + ingest sections as "Phase 8" pending, so Phase 8 has a clean target to populate.
- `bin/release.sh --dry-run` output must print: target branch/worktree, file tree being published, refs/tags to create. `--apply` requires interactive y/N confirmation (no `--yes` short-circuit in v1.1).
- Denylist derivation workflow (D-05) should be runnable locally as `bin/check-neutrality.sh --suggest-denylist` (or equivalent), producing a candidate list the maintainer curates before committing the final `.neutrality-denylist.txt`.
- Byte-equality CI check for CLAUDE.md ↔ AGENTS.md (D-03) can piggyback on the neutrality CI job — same workflow, separate step.
- NEUT-07 decision record filename is fixed: `wiki/decisions/dr-2026-04-15-kahneman-to-examples.md` (or the actual Phase-7 execution date). SUPERSEDE-class, per §11.4.

</specifics>

<deferred>
## Deferred Ideas

- **Hosted docs site** (MkDocs/Docusaurus) — already deferred per PROJECT.md out-of-scope and STACK.md's maintenance-mode finding for MkDocs Material.
- **`bin/upgrade.sh`** for template-fork upgrades — deferred to v1.2; document the ownership boundary now (where? likely `docs/reference/release.md` footer or `PROJECT.md`).
- **`--yes` flag on `bin/release.sh`** (non-interactive automation path) — deferred; v1.1 release stays interactive-confirm.
- **GitHub Actions `workflow_dispatch` for orphan-branch publish** — deferred; maintainer-local execution in v1.1.
- **Multi-domain example stubs / second-domain starter cluster** — explicitly deferred per research.
- **`--milestone vX.Y` flag on `bin/requirements-sync.sh`** — left as a forward-compatible name; not implemented in Phase 7.
- **Light "example hygiene" lint mode** for `examples/` pages (basic file integrity beyond normal health-check skip) — noted but not scoped for Phase 7; planner may add a TODO in `bin/lint.sh`.
- **Attribution/copyright line** (beyond MIT boilerplate) — not chosen; default MIT template applies until user requests otherwise.

</deferred>

---

*Phase: 07-neutral-template-foundation*
*Context gathered: 2026-04-15*
