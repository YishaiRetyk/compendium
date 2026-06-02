# Agent Parity

> Reference documentation for the DEBT-02 agent-parity check: the structural-equivalence tolerance rubric, how to re-run the Codex parity diff against the golden reference cluster, and how to read the diff-presentation table.

## TL;DR

Agent parity asks a simple question: when a *different* coding agent (e.g. Codex) ingests the same raw source under the same wiki schema, does it produce a structurally equivalent wiki? "Structurally equivalent" is a deliberately loose bar — same page set, same page types, same provenance source IDs and locator targets, valid frontmatter. Claim **prose may differ freely**; only structure is graded. This structural equivalence bar is the DEBT-02 tolerance contract — this page documents that rubric and the exact re-run procedure.

> **Source of truth:** The schema being compared against lives in [AGENTS.md](../../AGENTS.md) (§4 page types, §5 frontmatter, §6 provenance, §11.1 ingest workflow). The verifier-locality and privacy contracts that govern the cloud subprocess live in [AGENTS.md §11.7](../../AGENTS.md) and [§13](../../AGENTS.md). The recorded run outcome lives in the phase verification record; this page is the re-run manual.

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

The rationale: two faithful agents reading the same source should extract the same *facts* anchored at the same *locators*, even if they phrase them differently. Prose variance is expected and is recorded as an observation, not a defect (AGENTS.md §6 support-type model).

## Golden reference

The golden is the committed `examples/kahneman/` cluster. Full live composition (page-type subdirectories only): **1 entity, 3 concepts, 1 comparison, 1 overview, 2 sources**. (`README.md` and `log.md` carry `type: overview` in their own frontmatter but are NOT wiki pages — never count them.)

**Single-source caveat (important):** a single seeded source cannot reproduce a two-source synthesis. The golden cluster's multi-source synthesis pages each cite BOTH source summaries, so they are structurally impossible to regenerate from one seeded source. A single-source re-ingest is therefore compared against the **prospect-theory SUBSET** of the golden — the pages a single seeded source can plausibly produce — NOT the full two-source multiset. The substantive seeded source is the `prospect-theory` raw source at `examples/kahneman/sources/` (its raw file under `sources/2026/2026-04/`), which is `privacy: cloud_safe` and therefore admissible to a cloud subprocess. The copyright-placeholder source and any `local_only` journal source are NEVER seeded.

**Claude vs Codex is the primary reproducible verdict** — comparing two agent runs to each other removes the single-source-vs-golden asymmetry entirely.

## How to re-run the Codex parity diff

### 1. codex = CLOUD egress by default (§11.7)

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
   source at <relative-path-to-source> into the wiki/ tree following the §11.1 ingest
   workflow: create a source summary page plus the entity and concept pages this single
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

## See also

- [AGENTS.md](../../AGENTS.md) — §11.1 ingest workflow, §11.7 audit/verifier-locality, §13 privacy routing.
- [examples.md](examples.md) — the `examples/kahneman/` golden cluster and `examples/dataview-fixtures/`.
- [privacy-model.md](privacy-model.md) — the fail-closed precedence the seed guard enforces.
- [ci.md](ci.md) — the structural lint categories used in the frontmatter-valid check.
- [../README.md](../README.md)
- [index.md](index.md)
