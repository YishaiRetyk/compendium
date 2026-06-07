# Agent Parity

> Reference documentation for the DEBT-02 agent-parity check: the structural-equivalence tolerance rubric, how to re-run the Codex parity diff against the golden reference cluster, and how to read the diff-presentation table.

## TL;DR

Agent parity asks a simple question: when a *different* coding agent (e.g. Codex) ingests the same raw source under the same wiki schema, does it produce a structurally equivalent wiki? "Structurally equivalent" is a deliberately loose bar — same page set, same page types, same provenance source IDs and locator targets, valid frontmatter. Claim **prose may differ freely**; only structure is graded. This structural equivalence bar is the DEBT-02 tolerance contract — this page documents that rubric and the exact re-run procedure.

> **Source of truth:** The schema being compared against lives in [AGENTS.md](../../AGENTS.md) (page types: `schema/reference/page-types.md`; frontmatter: `schema/reference/frontmatter.md`; provenance: `schema/reference/provenance.md`; ingest workflow: `schema/workflows/ingest.md`). The verifier-locality and privacy contracts that govern the cloud subprocess live in `schema/workflows/audit.md` and `schema/reference/privacy.md`. The recorded run outcome lives in the phase verification record; this page is the re-run manual.

## Structural-equivalence tolerance rubric

A parity run **PASSES** when the candidate wiki matches the golden on every structural dimension below, regardless of wording:

| Dimension | PASS criterion | Tolerance |
|-----------|----------------|-----------|
| Page set | Same set of pages produced (by semantic role) | Exact, for the single-source-derivable core |
| Page types | Same `type:` distribution (entity / concept / source / comparison / overview) | Exact |
| Provenance source IDs | Claims cite the same `[prov:<source-id>...]` source IDs | Exact |
| Provenance locator targets | Claims point at the same `#sec:` / `#p` / `#para` locator targets | Exact |
| Frontmatter valid | All pages pass `bin/lint.sh --category yaml,provenance` | Zero errors |
| Claim prose / wording | TL;DR phrasing, Key-Facts ordering, claim sentences | **May differ freely — noted, never a failure** |

The rationale: two faithful agents reading the same source should extract the same *facts* anchored at the same *locators*, even if they phrase them differently. Prose variance is expected and is recorded as an observation, not a defect (provenance support-type model — see `schema/reference/provenance.md`).

## Golden reference

The golden is the committed `examples/kahneman/` cluster. Full live composition (page-type subdirectories only): **1 entity, 3 concepts, 1 comparison, 1 overview, 2 sources**. (`README.md` and `log.md` carry `type: overview` in their own frontmatter but are NOT wiki pages — never count them.)

**Single-source caveat (important):** a single seeded source cannot reproduce a two-source synthesis. The golden cluster's multi-source synthesis pages each cite BOTH source summaries, so they are structurally impossible to regenerate from one seeded source. A single-source re-ingest is therefore compared against the **prospect-theory SUBSET** of the golden — the pages a single seeded source can plausibly produce — NOT the full two-source multiset. The substantive seeded source is the `prospect-theory` raw source at `examples/kahneman/sources/` (its raw file under `sources/2026/2026-04/`), which is `privacy: cloud_safe` and therefore admissible to a cloud subprocess. The copyright-placeholder source and any `local_only` journal source are NEVER seeded.

**Claude vs Codex is the primary reproducible verdict** — comparing two agent runs to each other removes the single-source-vs-golden asymmetry entirely.

## How to re-run the Codex parity diff

### 1. codex = CLOUD egress by default (see `schema/workflows/audit.md` verifier-locality model)

`codex exec` runs on remote infrastructure: anything it reads becomes cloud context. `-s/--sandbox workspace-write` confines only LOCAL shell writes and `-C <dir>` is a working directory — **neither bounds network egress.** The single mandatory egress defense is a **fail-closed seed guard** over `$SCRATCH/sources`: every seeded source file must declare `^privacy:[[:space:]]*cloud_safe$`, and anything else (missing frontmatter, other value, directory-only signal) fails closed and aborts the run BEFORE any `codex exec`. Do NOT use `--dangerously-bypass-approvals-and-sandbox`.

### 2. Seed a scratch tree and run the guard

Create scratch dirs with `mktemp -d` and a `trap 'rm -rf "$S1" "$S2"' EXIT INT TERM`. Seed ONLY the one `cloud_safe` raw source by full path (never a month-glob). Run the seed guard over `$SCRATCH/sources/**/*.md`; require exit 0 before proceeding.

### 3. Invoke `codex exec`

```bash
# (after seed_guard passed; stdin redirected from /dev/null so exec starts a turn)
<absolute-path-to>/codex exec \
  -C "$S2" -s workspace-write --skip-git-repo-check \
  -o "$S2/.codex-last-message.txt" \
  "Read CLAUDE.md (the wiki schema authority in this directory). Ingest the single raw
   source at <relative-path-to-source> into the wiki/ tree following the ingest workflow
   (schema/workflows/ingest.md): create a source summary page plus the entity and concept pages this single
   source supports, each with full base frontmatter and inline [prov:source_id#locator]
   markers using #sec: locators. Use source_id <source-id>. Do NOT create comparison or
   overview pages. Do not touch any file outside this directory. Write the files directly
   to disk, then stop." \
  </dev/null
```

The `</dev/null` redirect is required — without it, `codex exec` hangs on its "Reading additional input from stdin..." prompt and never starts a turn.

### 4. Structural diff

Compare the candidate scratch wiki against the golden subset (or against the Claude scratch wiki) with two helpers:

- **`pagetypes(dir)`** — enumerate page `type:` values across the wiki. It MUST branch on whether `$1/wiki` exists: the golden cluster is FLAT (page-type subdirectories directly under `examples/kahneman/`, no `wiki/` subdir), while a scratch ingest nests pages under `wiki/`. Walk `$1/wiki` if it exists, else `$1`.
- **`provtargets(dir)`** — extract the sorted set of `[prov:<source-id>#<locator>]` source-ID + locator-target pairs across all pages.

Diff the sorted outputs (`diff <(provtargets A) <(provtargets B)`). A clean diff on `provtargets` is the strongest single D-07 signal.

## Diff-presentation table

Rows are the rubric dimensions; columns are the three comparisons; cells are `MATCH` / `DIFFERS (noted)` / `blocked-on-host-runtime`. This template mirrors the recorded run — the Codex column is rendered `blocked-on-host-runtime (AppArmor apparmor_restrict_unprivileged_userns=1)` because the recorded Codex run was **blocked on a host runtime sandbox pathology: the live AppArmor `apparmor_restrict_unprivileged_userns=1` restriction prevents Codex's bubblewrap sandbox from creating user namespaces, producing 0 wiki pages**. That is a host runtime-environment limitation, NOT a parity failure — so it is recorded honestly as blocked-on-host-runtime, never fabricated as a measured MATCH.

| Dimension | Claude vs golden-subset | Codex vs golden-subset | Claude vs Codex |
|-----------|-------------------------|------------------------|-----------------|
| Page set (single-source-derivable core) | MATCH | blocked-on-host-runtime (AppArmor apparmor_restrict_unprivileged_userns=1) | blocked-on-host-runtime — Codex produced 0 pages |
| Page types | MATCH (1 entity, 2 concepts, 1 source) | blocked-on-host-runtime (AppArmor apparmor_restrict_unprivileged_userns=1) | blocked-on-host-runtime |
| Provenance source IDs | MATCH | blocked-on-host-runtime (AppArmor apparmor_restrict_unprivileged_userns=1) | blocked-on-host-runtime |
| Provenance locator targets | **EXACT MATCH** (all 6 `#sec:` targets) | blocked-on-host-runtime (AppArmor apparmor_restrict_unprivileged_userns=1) | blocked-on-host-runtime |
| Frontmatter valid | MATCH (`lint --category yaml,provenance` → 0/0/0) | blocked-on-host-runtime (AppArmor apparmor_restrict_unprivileged_userns=1) | blocked-on-host-runtime |

**Recorded outcome (mirror of the phase verification record):** the Claude-side scratch ingest produced 4 pages (1 entity, 2 concepts, 1 source summary) whose provenance-locator-target set is an **exact match** of the golden prospect-theory subset (all 6 `#sec:` targets). The difference between the Claude scratch (4 pages) and the full golden subset (which additionally carries the 3 multi-source synthesis pages) is exactly those 3 pages, each citing a second source not seeded — structurally not reproducible from one source, as expected. The Codex column is recorded as **blocked-on-host-runtime via the live AppArmor `apparmor_restrict_unprivileged_userns=1` user-namespace restriction** (Codex's bubblewrap sandbox cannot create user namespaces); the Claude-vs-golden-subset EXACT structural-diff carries the parity verdict, and NO Codex re-run was performed (per Phase 13.2 D-02 the runtime block is accepted, not remediated). Prose variance between the Claude scratch and the golden was observed and, per the rubric, counted as expected rather than a failure.

## Scratch teardown

Both scratch dirs are `mktemp -d`, torn down by absolute path after diff capture (`rm -rf "$S1" "$S2"`; assert `test ! -d`). No scratch output is committed — confirm with `git status --porcelain | grep -iE 'scratch|\.codex|tmp\.'` returning empty.

## Routing Desk-Check (gating floor)

This desk-check covers the two judgment dimensions that the mechanical routing lint (`bash bin/lint.sh --category routing`) cannot resolve: routing-table prominence/unambiguity and content self-sufficiency of the extracted workflow file. Resolvability (do the `path` references in the routing table actually exist on disk?) is mechanized — run `bash bin/lint.sh --category routing` and it exits 0 if all referenced files resolve. Do NOT re-prove resolvability by hand.

### Dimension 1 — Routing-table prominence and unambiguity

**Question:** Is the IMPORTANT routing table positioned and worded such that a foreign agent given only AGENTS.md would follow it to `schema/workflows/ingest.md`?

**Verdict: PASS**

Trace:
- The routing table sits immediately after the overview (before any multi-paragraph prose) as an `IMPORTANT:` blockquote at the top of the AGENTS.md core.
- It is labeled "Reference Routing Table" and reads "Read the target file before acting — do not rely on the stub alone."
- The ingest workflow row points directly to `schema/workflows/ingest.md` as a resolvable reference (the Phase-17 migration is complete — the prior "Future home / (Phase 17)" annotation is gone).
- A foreign agent reading the routing table would find the ingest row and follow the path before reading the inline workflow content.

### Dimension 2 — Content self-sufficiency of schema/workflows/ingest.md

**Question:** Does `schema/workflows/ingest.md` contain everything needed to ingest without reading the monolith?

**Verdict: PASS**

Trace:
- `schema/workflows/ingest.md` contains: Pass 0–4 step list with all sub-steps, abort conditions, claim granularity table, Append-Then-Synthesize policy, compilation-tracking field instructions, and contributor attribution rules (steps 9a).
- Cross-references to type/frontmatter/provenance/wikilinks are dispatches to their own authoritative leaf files; an agent follows those hops rather than returning to the monolith.
- Phase 17 completed the move: the inline workflow content was extracted out of AGENTS.md, the `schema/workflows/ingest.md` routing-table row is now unconditional, and an agent reading AGENTS.md is dispatched to the leaf file rather than to resident inline text.

### Mechanical resolvability

```bash
bash bin/lint.sh --category routing --format json
# Expected: exit 0, no error-severity findings for schema/workflows/ingest.md
```

This check is CI-gated (routing maps to `error` in the CI severity remap) — routing failures block merge.

## Empirical Agent Run (best-effort, non-gating)

> **NON-GATING.** This section records an empirical re-run attempt using Codex on the prospect-theory seed. The re-run is best-effort; a blocked-on-host-runtime outcome is acceptable and honest, never padded with fabricated results. The gating floor is the Routing Desk-Check above.

**Re-run status: blocked-on-host-runtime**

The Codex empirical run was attempted but remains blocked by the same host runtime sandbox pathology recorded in the diff-presentation table above: `AppArmor apparmor_restrict_unprivileged_userns=1` prevents Codex's bubblewrap sandbox from creating user namespaces. This is a host-environment limitation, not a parity failure. No Codex wiki pages were produced; no fabricated MATCH/DIFFERS cells are recorded.

**What this means:** the routing discoverability question (would Codex follow the routing table to `schema/workflows/ingest.md`?) cannot be answered empirically from this environment. The desk-check above provides the gating evidence — mechanical resolvability via `bin/lint.sh --category routing` and judgment-layer analysis of the routing table structure. A future re-run on a host where Codex can create user namespaces would add behavioral evidence; the desk-check verdict does not depend on it.

**Recorded as:** blocked-on-host-runtime (AppArmor `apparmor_restrict_unprivileged_userns=1`), consistent with the Phase 13.2 D-02 acceptance decision.

## See also

- [AGENTS.md](../../AGENTS.md) — routing table; ingest: `schema/workflows/ingest.md`; audit/verifier-locality: `schema/workflows/audit.md`; privacy: `schema/reference/privacy.md`.
- [examples.md](examples.md) — the `examples/kahneman/` golden cluster and `examples/dataview-fixtures/`.
- [privacy-model.md](privacy-model.md) — the fail-closed precedence the seed guard enforces.
- [ci.md](ci.md) — the structural lint categories used in the frontmatter-valid check.
- [../README.md](../README.md)
- [index.md](index.md)
