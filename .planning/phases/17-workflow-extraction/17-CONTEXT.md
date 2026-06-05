# Phase 17: Workflow Extraction - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Extract every **workflow/operation section** of the `CLAUDE.md` / `AGENTS.md`
monolith into standalone `schema/workflows/*.md` files, replacing each in core
with a routing stub, and verify the resident core section-by-section against the
**inclusion test**. This is Phase B of v1.2 — the medium-risk counterpart to
Phase 16's (low-risk) reference extraction.

**Targets (per the Extraction Map — single source of truth for exact line ranges):**
- §9 structured ops → `schema/workflows/structured-operations.md`; core keeps the
  ops-vocab table + `validate-op.sh` pointer + the locked 2-line solo-op log shape (WF-01).
- §10 pipeline → **diagram stays (1 line), NO `pipeline.md`** (LOCKED); the two
  substantive blocks fold into the relevant workflow files; pass-narrative deletes (WF-02).
- §11.1 ingest → `schema/workflows/ingest.md` (+ folded §10 claim-granularity rules) (WF-03).
- §11.2 query → `schema/workflows/query.md`; core keeps **only the write-back-mandatory line** (WF-04).
- §11.3 lint → `schema/workflows/lint.md` (extends the Phase-16 decay/staleness seed already
  in that file); **preserve its "source of truth for CI contracts" framing** (WF-05).
- §11.4 reflect, **§11.5 brownfield (the 182-line miss)**, §11.6 release, §11.7 audit
  → `schema/workflows/*.md` (WF-06).
- §12 formats → `schema/reference/log-format.md`; bare log format **inlined per-workflow**;
  core resident ~0 (WF-07).
- Verify core against the inclusion test (WF-08); manual agent-parity check (WF-09).

**Plus the deferred Phase-16 tooling hook:** build the `--check-tree` routing-integrity
guard at the **END of this phase** (Phase-16 D-07/D-08), now scoped per the decisions below.

**Covers:** WF-01..WF-09 (+ the Phase-16 D-07/D-08 `--check-tree` carry-over).

**Depends on:** Phase 16 (created `schema/reference/` + seeded `schema/workflows/lint.md`;
established the routing-table + bare-pointer-stub conventions this phase reuses). Phase 16 shipped.

**Out of scope (firm boundaries):**
- Any **behavioral change** to lint/validate/privacy/neutrality logic. Extraction relocates
  *text*, not logic; all CI gates must pass unchanged in behavior. (The one *additive* exception
  is the new `routing` lint category + the WF-08 drift `info` check — these are NEW checks over
  the NEW schema tree, not modifications to existing check logic.)
- Skills overlay (Phase 18/`SKILL`) and Wizard fold-in (Phase D, deferred to backlog 999.3).
- Hardening `bin/lint.sh` mask_markdown for fence edge cases — a behavioral lint change
  (`phase-14-lint-mask-fence-edge-cases` todo, reviewed-not-folded; see Deferred).

</domain>

<decisions>
## Implementation Decisions

### WF-01 — Solo structured-op commit prefix (closes Open Q9)
- **D-01: Solo structured ops get lowercased per-op commit prefixes — `update:` / `merge:` /
  `supersede:` / `archive:`.** Symmetric with the four workflow prefixes (`ingest/query/lint/reflect`)
  AND with the §12 log operation types (which already render `## [date] MERGE | page`). Two surfaces,
  one vocabulary: the log says `## [date] MERGE | page`, the commit says `merge(page): …`.
- **D-02: Within a workflow, ops still roll up under the workflow prefix; only a *solo* op
  (a standalone structural action with no workflow wrapping) gets its own per-op prefix.** No
  conflict with "one commit per logical operation." The rejected alternative — routing solo
  MERGE/SUPERSEDE under `reflect:` because they often spawn a Tier-1 DR — is non-uniform; avoid it.

### `--check-tree` routing-integrity guard (Phase-16 D-07/D-08 carry-over; built END of Phase 17)
This is the one piece of NEW tooling in the phase. Phase-16 D-08 locked the *seed* semantics
("every routing-stub target resolves to a file that exists"); discussion expanded it to a
**bidirectional reachability guard** and chose its home.

- **D-03: Scope → BROAD.** The guard resolves **all cross-file references** in the `schema/` tree,
  not just the ~15 stub targets. Rationale: post-extraction, every cross-file `§N` reference dangles
  *by construction* (§-numbers exist only in the monolith — the moment §10 becomes
  `workflows/ingest.md`, every "see §10 Pass 3" points at a number that no longer names anything).
  A narrow existence-check would pass green over a tree full of dead cross-refs.
- **D-04: Directionality → BIDIRECTIONAL.** Two dual silent failure modes, both must be caught:
  - **Forward (dangling pointer):** a stub/cross-ref points to a file/section that doesn't exist
    → `linkres`-class → severity **error**.
  - **Inverse (orphan file):** an extracted `workflows/foo.md` exists but nothing in core's routing
    table points to it → unreachable → silently lost → `orphan`-class → severity **warning**.
- **D-05: §-ref policy → ABOLISH, don't resolve.** Extraction converts every cross-file reference
  from `§N` to a path (`see schema/workflows/ingest.md`); the guard **forbids** any cross-file
  `§N` / "Section N" reference from existing (pattern-prohibition + path-resolution, not a §-number
  resolver). Intra-file numbering in core (its own structure) is allowed — the rule is *cross-file
  refs must be paths*. Resolve-by-forbidding > resolve-by-checking: permanently kills the §-fragility
  that drove the 1,412→1,689 drift, and keeps the guard simple. (Generalizes Phase-16 D-05's rejection
  of §-number routing-table keying.)
- **D-06: Home → fold into `bin/lint.sh` as a `routing` category** (rejected: extend
  `bin/sync-claude.sh`; rejected: standalone `bin/check-routing.sh`). The guard decomposes into two
  *existing* lint mechanics — forward = `linkres`, inverse = `orphan` — re-aimed at `schema/`; reuses
  the whole `--ci` severity-remap / `--format json` → CI-annotation / `LINT_VERSION` / `--category`
  apparatus the alternatives would rebuild. Two conditions: (a) corpus = the `schema/` tree (core
  `AGENTS.md` + `schema/workflows/*.md` + `schema/reference/*.md`), a distinct category with its own
  resolution logic; (b) must **bypass lint's empty-wiki abort** — a fresh template clone has a
  near-empty wiki but a full schema tree, which is exactly when routing integrity matters most.
- **D-07: Enforcement → CI-only for the routing error-checks; `--staged` stays `provenance`-only.**
  Routing integrity is a *whole-tree* property: a dangling ref's two ends needn't both be in the
  staged diff, and deleting a file core points to may stage neither end. The `--staged` per-added-file
  scope structurally can't see those → wiring it in gives false confidence. Full-tree CI + manual
  `lint` is the correct scope.
- **D-08: Concern B (external corpus) → handled SEPARATELY from the hard guard.** Real breakage exists
  in `docs/reference/ci.md`, `CONTRIBUTING.md`, `.github/workflows/lint.yml` (they reference `§11.3`
  etc.). Fix via a **one-shot repoint during WF-05** (`grep -rn '§[0-9]' .` repo-wide, fix the
  referrers), optionally backed by a **WARNING-level** (non-blocking) sweep in the `routing` category.
  The hard **error**-level guard stays scoped to the `schema/` tree — don't make it scan open-ended
  doc prose.

### WF-08 — Inclusion-test tripwire (delta-from-baseline, not absolute ceiling)
- **D-09: Tripwire realized as BOTH surfaces, measured as delta against a recorded baseline — never
  an absolute line threshold.** An absolute "core ≤ N" ceiling is a budget wearing a warning's
  clothes → Goodhart (reviewers check the number instead of re-running the test). A comment-only note
  relies on the precise discipline that already failed (silent 1,412→1,689 drift). Delta-from-baseline
  threads both: there is no number to hit, so it can't become a target — the literal realization of
  the brief's "line tripwire (not target)."
- **D-10: Single shared artifact = a machine-readable core header comment**
  `<!-- inclusion-audit: <N> lines @ <YYYY-MM-DD> -->`, where `<N>` = the core line count at the last
  full section-by-section re-verification against the 3 clauses. This comment doubles as the
  **preventive** surface (an agent about to add resident lines reads "justify against the 3 clauses or
  extract").
- **D-11: Detective surface = a non-blocking lint `info` check** that reads the baseline, compares to
  current core size, and emits `core drifted +M lines since last inclusion audit (DATE) — re-run WF-08`
  once drift exceeds a margin (**~+20% / +25 lines**). Rides the same `--ci`/`--format json`/annotation
  path as the `routing` category — no separate CI step.
- **D-12: Baseline initializes to the ACTUAL post-extraction core line count** recorded by the WF-08
  closing audit (drop the guessed "~145"/"175"). Re-running the audit resets the baseline. Margin
  (the +20%) is the only tunable — a drift *tolerance*, not a budget.
- **Honest residual (accepted):** a dishonest baseline bump without re-auditing isn't fully preventable
  by a self-reported in-file gate; mitigated because the baseline update is a WF-08 *deliverable* tied
  to its commit/DR trail, so a bare number-bump with no audit artifact is review-visible. Same trust
  model as any self-reported check.

### WF-09 — Agent-parity evidence (three-tier reachability stack)
- **D-13: Evidence = three tiers; the documented desk-check is the gating floor, the empirical run is
  best-effort non-gating.** The desk-check assumes an agent *follows* a resolvable pointer, so it
  structurally cannot validate WF-09's actual claim — **behavioral discoverability** (the Vercel-56%
  finding: resolvable-in-principle ≠ actually-followed). The real run is therefore the *only* evidence
  for the headline claim, but it **cannot gate** closure (v1.1 "Codex blocked-on-host-runtime"
  precedent: never gate a milestone on external-tool availability).

  | Tier | Evidence | Cadence | Gating |
  |------|----------|---------|--------|
  | **Mechanical** | Area-B `routing` guard (bidirectional resolvability) | every CI run | yes (error) |
  | **Documented** | scoped desk-check trace — judgment dims only: routing-table prominence/unambiguity + target-file *content* self-sufficiency (cite the guard for resolvability; don't re-prove by hand) | reproducible on demand | yes (floor) |
  | **Empirical** | Codex/Cursor run on the prospect-theory seed — behavioral discoverability | best-effort snapshot | **no** |

- **D-14: Scope the desk-check to the non-mechanized judgment dimensions only.** The "no-dangling-refs /
  all-reachable" half of a naive desk-check is now redundant with the Area-B `routing` guard (mechanized,
  always-on). What's left for the trace: is the routing table prominent/unambiguous enough that an agent
  would *follow* it, and is `workflows/ingest.md` self-sufficient in *content* (not just link-resolution)?
  Document in `docs/reference/agent-parity.md` as a re-runnable procedure.
- **D-15: A failed empirical run is signal, not a red to suppress.** A real "foreign agent didn't follow
  the router to `ingest.md`" result is the Vercel-56% failure caught in the wild — a finding to act on
  (strengthen the `IMPORTANT:` cue / restructure the routing table). Record failures verbatim; don't
  fish for a green. If the tool is unavailable, the phase closes on the floor and the gap is documented
  honestly (exactly what v1.1 did).

### Claude's Discretion
- All plan-time mechanics: exact stub wording; per-workflow file naming/granularity (one file each for
  reflect/brownfield/release/audit per the `workflows/*.md` map); how the §10 substantive blocks
  (claim-granularity → `ingest.md`; append-then-synthesize → `ingest.md`/`structured-operations.md`)
  are folded and framed; the extraction/move sequencing and commit structure; how WF-05 merges the
  §11.3 lint body with the Phase-16 decay/staleness seed already in `schema/workflows/lint.md` while
  preserving its "source of truth for CI contracts" framing; the bare per-workflow log-format inlining;
  the `routing` category's exact implementation (severity remap entry, corpus walk, empty-wiki-abort
  bypass); the WF-08 drift-check threshold mechanics; the `--check-tree` ↔ `routing`-category naming
  reconciliation; and the `agent-parity.md` desk-check trace format. The Extraction Map's exact line
  ranges + the decisions above are sufficient direction.
- **D-07 pre-commit wiring** is a light steer (CI-only), not a hard pin — the planner reaches the same
  place via lint's `--staged` conventions if it prefers to derive it.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design source of truth (extraction map + locked decisions)
- `.planning/milestones/v1.2-MILESTONE-BRIEF.md` — **the single source of truth** for exact line
  ranges, target files, and resident remnants per section. Read in full:
  - §"Extraction Map — Inclusion-Test Disposition" (lines ~132–214) — per-section line ranges, the
    resident-core composition table, and the **Locked decisions** block (commit table extract +
    1 resident line; **solo-op 2-line log shape + the explicit Open-Q9 commit-prefix gap**; §10
    diagram-only / no `pipeline.md` / fold substantive blocks / delete pass-narrative; §12 ~0 resident
    + bare-format-inline).
  - The **inclusion test** (lines ~138–148) — ambient / unscriptable-AND-unacceptable-miss / dispatch.
    This is the governing rule WF-08 verifies the core against section-by-section.
  - §"Design Constraints (Non-Negotiable)" (lines ~216–231) — markdown-authoritative, byte-equality,
    wizard pipeline preserved, **always-loaded safety core stays resident** (provenance requirement,
    MUST-NOT verbatim, write-back-mandatory, structured-op vocab — privacy NO LONGER in this list),
    CI gates unchanged in behavior.
  - §"Decisions Required" item 9 (Open Q9 → D-01/D-02) and item 10 (mutation→log coupling gate —
    **recommended REJECTED**, do NOT adopt; logged for traceability only).
- `.planning/REQUIREMENTS.md` — WF-01..WF-09 text + Out-of-Scope table + traceability.
- `.planning/ROADMAP.md` §"Phase 17: Workflow Extraction" — Goal line.

### Prior-phase context (Phase 16 — gates this phase, establishes the conventions reused)
- `.planning/phases/16-reference-extraction/16-CONTEXT.md` — the bare-pointer-stub rule (D-01 there),
  safety-core-stays-resident distinction (D-02 there), the two-axis routing table (D-05 there: keyed by
  operation + topic, NOT §-number — directly supports this phase's D-05 abolish-§N), and the
  **`--check-tree` carry-over** (D-06/07/08 there → expanded here into D-03..D-08). The §6 consumer-split
  seam: `schema/workflows/lint.md` already holds the decay/staleness math; WF-05 extends that same file.

### The file being refactored (`CLAUDE.md` ≡ `AGENTS.md`, byte-identical)
- `CLAUDE.md` / `AGENTS.md` — the live monolith. Every §9/§10/§11/§12 edit lands in BOTH
  (pre-commit `bin/sync-claude.sh --check`).
- `schema/AGENTS.template.md` — wizard source; every routing stub mirrors here (cf. Phase-16 REF-09).
- `schema/workflows/lint.md` — already created/seeded by Phase 16 with the §6 decay table + staleness
  auto-fix; WF-05 merges the §11.3 lint body INTO this file (do not create a second lint file).
- `schema/reference/` — Phase-16 output (`page-types.md`, `frontmatter.md`, `provenance.md`,
  `wikilinks.md`, `privacy.md`); §12 log-format lands as a sibling `log-format.md` (WF-07).

### Tooling / gates that must stay green (behavior unchanged) + extended here
- `bin/lint.sh` (3-job CI) — gains the NEW `routing` category (D-04/D-06) and the WF-08 drift `info`
  check (D-11); existing categories/behavior unchanged. Its §11.3 CI-mode block is the **"source of
  truth for CI contracts"** — preserve that framing on extraction (WF-05 guard).
- `bin/sync-claude.sh` — `--check` byte-equality gate stays; the `--check-tree` idea is realized as
  the lint `routing` category (D-06), NOT a new sync-claude flag.
- `bin/validate-op.sh`, `bin/check-privacy.sh`, `bin/check-neutrality.sh` — operate on content, must
  pass over the new `schema/workflows/*.md` tree.
- `docs/reference/agent-parity.md` — already holds the DEBT-02 structural-equivalence rubric + golden
  (`examples/kahneman/` prospect-theory subset) + Codex re-run procedure. WF-09's desk-check trace +
  empirical-run record land here (D-13/D-14/D-15).
- `docs/reference/ci.md`, `CONTRIBUTING.md`, `.github/workflows/lint.yml` — external referrers to
  `§11.3` etc.; one-shot repoint to paths during WF-05 (D-08).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/lint.sh` — already a general structural-integrity engine, not a wiki-only linter: `linkres`
  resolves `[[id|Title]]` targets; `orphan` does inbound-link checks; `drift` (DRFT-01..04) walks
  `sources/`, reads git, checks index coverage. The new `routing` category = `linkres` + `orphan`
  re-aimed at the `schema/` tree. Inherits `--ci` severity remap, `--format json` → CI annotations,
  `--category`/`--skip-category`, `LINT_VERSION`, the pre-commit invocation.
- `bin/sync-claude.sh` — small `--check`-only script (`CHECK_ONLY` flag, case-based parse ~line 11);
  byte-equality gate only. NOT extended with `--check-tree` (D-06 routes that to lint).
- `docs/reference/agent-parity.md` — full DEBT-02 rubric + golden + Codex re-run procedure already
  written; WF-09 extends it rather than starting fresh.
- `schema/workflows/lint.md` — exists (Phase-16 decay/staleness seed); WF-05 extends, not recreates.

### Established Patterns
- **`CLAUDE.md` ≡ `AGENTS.md` byte-equality** (pre-commit `sync-claude --check`) — every section edit
  lands in both copies in the same commit.
- **Bare-pointer stubs + two-axis routing table** (Phase 16 D-01/D-05) — workflow stubs follow the same
  zero-reproduced-content rule; the routing table (operation + topic keyed, never §-number) is the
  dispatch artifact this phase's D-05 abolish-§N rule reinforces.
- **DR-at-execution precedent** (`dr-2026-06-03-uniform-piped-links`, `dr-…-privacy-asymmetric-two-dir`)
  — schema-update decision records written when the change ships. Phase 17's structural DRs follow this.
- **Layered prevent+detect** (resident guidance + automatic signal) recurs in C (comment + drift check)
  and D (desk-check + empirical run) — the same model used across the project.

### Integration Points
- **`schema/workflows/lint.md` is the cross-phase seam:** Phase 16 seeded decay/staleness; WF-05 merges
  the §11.3 lint body in. Must preserve the "source of truth for CI contracts" framing so
  `docs/reference/ci.md` / `CONTRIBUTING.md` / `lint.yml` can link here rather than restate.
- **The §10 fold points:** claim-granularity rules → `workflows/ingest.md`; append-then-synthesize →
  `workflows/ingest.md` (and the structured-op incremental-update policy cross-link in
  `structured-operations.md`). Diagram (1 line) stays resident; everything else in §10 deletes.
- **Routing guard ↔ extraction ordering:** the `routing` category can only go green once every
  cross-file `§N` is converted to a path — so the guard is built/enabled at the END of the phase
  (Phase-16 D-07), after all extraction + the WF-05 external repoint, gating the close.

</code_context>

<specifics>
## Specific Ideas

- **Solo-op prefix (D-01), user's framing:** "the log says `## [date] MERGE | page` and the commit says
  `merge(page): …` — same vocabulary, two surfaces." Within a workflow, ops roll up under the workflow
  prefix; only solo ops get their own. Avoid the non-uniform `reflect:`-for-MERGE alternative.
- **Abolish-§N (D-05), user's framing:** "resolve-by-forbidding beats resolve-by-checking" — the guard
  forbids any cross-file `§N`/"Section N"; extraction converts each to a path. Permanently kills the
  §-fragility that drove the 1,412→1,689 drift.
- **Tripwire (D-09), user's framing:** "a budget is a target wearing a warning's clothes" — measure
  **delta against a recorded baseline**, not distance from a fixed ceiling. "The check never says 'too
  big' — only 'you've grown since you last verified.'"
- **Agent-parity (D-13), user's framing:** "resolvable-in-principle ≠ actually-followed — that gap IS
  the 56% finding." Desk-check = gating floor; real run = the only evidence for the headline claim, but
  non-gating. "A failed run is the most valuable outcome, not a regrettable one."

</specifics>

<deferred>
## Deferred Ideas

- **Mutation→log coupling gate** (Open Q10) — a pre-commit check forcing every `wiki/` mutation to carry
  a log entry. **Recommended REJECTED** (milestone brief): adds a gate with false-positive surface for a
  low-miss-cost hygiene rule, and `schema:`/`docs:`/`bin:` commits are legitimately outside workflows.
  Logged for traceability; do NOT adopt in this phase.
- **`bin/sync-claude.sh --check-tree` as a sync-claude flag** — superseded: the routing-integrity check
  is realized as the `bin/lint.sh` `routing` category instead (D-06). The Phase-16 D-07/D-08 intent is
  satisfied; the flag itself is not built.

### Reviewed Todos (not folded)
- `phase-14-lint-mask-fence-edge-cases` ("Harden `bin/lint.sh` mask_markdown for fence edge cases",
  area: tooling, score 0.6) — **reviewed, NOT folded** (third consecutive review; same call as Phases 15
  and 16). It is a *behavioral* change to lint's markdown-masking logic; Phase 17 is **text extraction**,
  and the milestone's firm boundary forbids behavioral changes to lint/validate logic. Belongs to a
  standalone quick task or a future lint-hardening pass. Remains in `.planning/todos/pending/`.

</deferred>

---

*Phase: 17-workflow-extraction*
*Context gathered: 2026-06-05*
