# Phase 17: Workflow Extraction - Pattern Map

**Mapped:** 2026-06-05
**Files analyzed:** 15 (8 new markdown, 1 extended markdown, 6 modified text/bash)
**Analogs found:** 14 / 15 (one new-tooling category has a strong compositional analog rather than an exact one)

> **Note on phase shape:** This is a **markdown documentation-extraction + bash-tooling** phase, not app code.
> "Role" below means the file's job in the schema architecture (extracted-reference, routing-stub,
> lint-engine, external-doc, evidence-doc); "Data flow" means the direction of content movement
> (text-relocation, pointer-dispatch, structural-scan, one-shot-repoint, desk-check).
>
> **Ground truth correction:** The live `CLAUDE.md` / `AGENTS.md` is **1051 lines** (byte-identical,
> verified `diff -q`), NOT the 1,689 quoted in the milestone brief. Phase 16 already extracted §4/§5/§6/§7/§8/§13/§14/§15
> to `schema/reference/*.md` + `docs/reference/*.md` and replaced them with stubs. The §-line-ranges in the
> Extraction Map (701–1449 etc.) are against the OLD 1,689-line file and DO NOT map onto the current file.
> **Use the current-file line ranges in this document, not the brief's.** Current header line map:
> §9 = L189, §10 = L293, §11.1 = L396, §11.2 = L434, §11.3 = L546, §11.4 = L653, §11.5 = L725,
> §11.6 = L907, §11.7 = L911, §12 = L939, §13 stub = L1039 (file ends L1051).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `schema/workflows/structured-operations.md` | extracted-reference (workflow) | text-relocation (§9 body) | `schema/reference/provenance.md` | exact (structural) |
| `schema/workflows/ingest.md` | extracted-reference (workflow) | text-relocation (§11.1 + folded §10 blocks) | `schema/reference/provenance.md` | exact (structural) |
| `schema/workflows/query.md` | extracted-reference (workflow) | text-relocation (§11.2) | `schema/reference/provenance.md` | exact (structural) |
| `schema/workflows/reflect.md` | extracted-reference (workflow) | text-relocation (§11.4) | `schema/reference/provenance.md` | exact (structural) |
| `schema/workflows/brownfield.md` | extracted-reference (workflow) | text-relocation (§11.5, ~182 lines) | `schema/reference/provenance.md` | exact (structural) |
| `schema/workflows/release.md` | extracted-reference (workflow) | text-relocation (§11.6) | `schema/reference/provenance.md` | exact (structural) |
| `schema/workflows/audit.md` | extracted-reference (workflow) | text-relocation (§11.7 + §1 audit-framing para) | `schema/reference/provenance.md` | exact (structural) |
| `schema/reference/log-format.md` | extracted-reference | text-relocation (§12) | `schema/reference/provenance.md` | exact (structural) |
| `schema/workflows/lint.md` (EXTEND) | extracted-reference (workflow, seeded) | text-relocation (§11.3 merged INTO existing seed) | itself (Phase-16 seed) + provenance.md framing | exact (self) |
| `CLAUDE.md` / `AGENTS.md` (stubs) | routing-stub host | pointer-dispatch | existing §4/§5/§6/§8/§13 stubs (L168–187, L1039) | exact |
| `schema/AGENTS.template.md` (stubs) | routing-stub mirror | pointer-dispatch | existing template stubs (REF-09 mirror) | exact |
| `bin/lint.sh` (`routing` category) | lint-engine extension | structural-scan (forward + inverse) | `linkres` block (L1887–) + `orphan` block (L1184–) | role-match (composite) |
| `bin/lint.sh` (WF-08 drift `info`) | lint-engine extension | structural-scan (line-count delta) | `drift` / DRFT index-coverage finding (`add_finding('info'...)`) | role-match |
| `docs/reference/ci.md`, `CONTRIBUTING.md`, `.github/workflows/lint.yml` | external-doc repoint | one-shot-repoint (§N → path) | existing `§11.3`/`§13` link refs in those files | exact |
| `docs/reference/agent-parity.md` (WF-09 trace) | evidence-doc extension | desk-check + empirical record | itself (existing DEBT-02 rubric + Codex re-run) | exact (self) |

---

## Pattern Assignments

### `schema/workflows/{structured-operations,ingest,query,reflect,brownfield,release,audit}.md` (extracted-reference, text-relocation)

**Analog:** `schema/reference/provenance.md` (the cleanest Phase-16 extracted file — same `# H1` + blockquote-banner + `## See Also` shape). `schema/reference/page-types.md` is a secondary analog with a stronger "this file wins" framing line worth copying.

These seven new files all share ONE template. The load-bearing pieces to copy:

**Header + authoritative-banner pattern** (`provenance.md` L1–4):
```markdown
# Provenance, Epistemics, and Contradiction

> Agent-authoritative reference for inline provenance markers `[prov:...]`, epistemic status markers `[epistemic::]`, and contradiction markers `[contradiction:...]`.
> AGENTS.md §6 (syntax/epistemics portion) points here.
```

**Stronger "this file wins" variant** (`page-types.md` L1–4 — use this framing for workflow files, since they are procedural authority):
```markdown
# Page Types and Templates

> Agent-authoritative reference for wiki page types, section ordering, and authoring conventions.
> AGENTS.md §4 points here. If you find a discrepancy between this file and AGENTS.md, this file wins.
```

**`## See Also` back-link footer** (`provenance.md` L186–190 — every extracted file ends with this; the first bullet ALWAYS back-links the core stub, then sibling files):
```markdown
## See Also

- [AGENTS.md](../../AGENTS.md) — §6 stub (pointer to this file and to lint.md for decay math).
- `schema/workflows/lint.md` — decay rate table, epistemic modifiers, staleness auto-fix rules.
- `schema/reference/frontmatter.md` — frontmatter fields including `epistemic_status`.
```

**Adaptation per file:**
- **Body content** is the verbatim §-body relocated from the current `CLAUDE.md` (NOT the brief's stale line ranges — use the current-file map at the top of this doc): §9 body L202–292 → `structured-operations.md`; §11.1 L396–433 → `ingest.md`; §11.2 L434–504+ → `query.md`; §11.3 L546–652 → `lint.md` (MERGE, see below); §11.4 L653–724 → `reflect.md`; §11.5 L725–906 → `brownfield.md`; §11.6 L907–910 → `release.md`; §11.7 L911–938 → `audit.md` (+ the §1 audit-framing paragraph at L23–31 folds in here per the Extraction Map row "Title+§1").
- **§10 folds (WF-02):** the two substantive §10 blocks — **Claim Granularity Rules** (currently L321–343, the "Pass 2: Extract" granularity table) and **Append-Then-Synthesize** (currently L344–371, "Pass 3: Merge") — fold INTO `ingest.md`. Append-then-synthesize ALSO needs a cross-link from `structured-operations.md` (the UPDATE op definition at current L202–242 already says "see Section 10 Pass 3" — that §-ref must convert to `schema/workflows/ingest.md` per D-05). The §10 pass-narrative (Pass 0/1/4 prose) DELETES; the diagram (1 line) stays resident in core.
- **CRITICAL — abolish-§N (D-05):** every cross-file `§N` / "Section N" reference inside the relocated bodies MUST be rewritten to a path. The provenance.md analog already demonstrates the target form — it says `\`schema/reference/frontmatter.md\`` and `\`schema/workflows/lint.md\``, NEVER "§5" or "§11.3". The §9/§11 bodies are DENSE with `(Section 9)`, `(Section 10 Pass 3)`, `(Section 11.4)`, `§13`, `(Section 5 validation checklist)` — every one converts to its extracted path. The new `routing` lint category (below) enforces this mechanically.
- **Per-workflow bare log-format inline (WF-07):** each workflow currently ends with an inline log-entry block (e.g. ingest step 9 `## [YYYY-MM-DD] ingest | <source title>`; query's "Query Log Entry Format" at current L505–514). Keep those bare formats INLINE in each workflow file; the *consolidated* §12 reference body goes to `log-format.md`. Cross-link both ways.
- **Frontmatter:** NONE. All Phase-16 extracted files are frontmatter-less markdown (verified: `provenance.md`/`page-types.md` start with `# H1`, no `---`). Do NOT add YAML frontmatter — it would make them parse as wiki pages and trip lint/neutrality.

---

### `schema/workflows/lint.md` (EXTEND, not recreate — WF-05)

**Analog:** the file ITSELF (the Phase-16 seed). It currently holds ONLY the decay table + staleness auto-fix (the §6 consumer-split output).

**Current seed structure to preserve** (`lint.md` L1–5 banner — note it explicitly reserves the merge slot for Phase 17):
```markdown
# Lint Reference: Staleness and Decay

> **Note:** This file contains only the decay table and staleness auto-fix rules (seeded by Phase 16).
> The full lint workflow procedure (`bin/lint.sh` steps, severity tiers, CI flags) is added in Phase 17.
> AGENTS.md §6 decay/staleness content points here.
```

**Adaptation:**
- Merge the §11.3 lint-workflow body (current `CLAUDE.md` L546–652: Severity Tiers table, Auto-Fix Boundary, the **CI mode** block, the 15 numbered steps, Categories list, Abort conditions) INTO this file, AFTER the existing decay/staleness content.
- **GUARD (the one non-negotiable for WF-05):** the §11.3 "CI mode" subsection carries a load-bearing framing line — *"Source of truth for Phase 9 / Phase 12.2 CI + local-gate contracts. ... Other docs ... MUST link here rather than restating the policy."* This framing MUST survive the move verbatim, because `docs/reference/ci.md` (L17, L46, L122, L300), `CONTRIBUTING.md` (L114, L132), and `.github/workflows/lint.yml` all point at it. After the move, those external links repoint from `AGENTS.md §11.3` → `schema/workflows/lint.md` (see external-doc row below).
- Update the L1–5 banner: drop "added in Phase 17" reservation; restate the "source of truth for CI contracts" framing at the top so the link target is self-evident.
- Rewrite the existing `## See Also` (L47–50) to add the AGENTS.md §11.3 stub back-link.
- **DO NOT create `schema/workflows/lint-workflow.md` or any second lint file.** One file.

---

### `CLAUDE.md` / `AGENTS.md` routing stubs (routing-stub host, pointer-dispatch)

**Analog:** the EXISTING Phase-16 stubs already in the live file. These are the canonical "bare-pointer-stub, zero reproduced content" pattern (Phase-16 D-01) the §9/§11/§12 stubs must match.

**Reference-stub pattern** (current `CLAUDE.md` L168–187 — quote real existing stubs):
```markdown
## 4. Page Types and Templates

Six page types: **entity**, **concept**, **source**, **comparison**, **overview**, **decision**.

→ See `schema/reference/page-types.md` for section ordering, authoring conventions, and full type details.

## 5. Frontmatter Schema

→ Full frontmatter schema and validation checklist in `schema/reference/frontmatter.md`.

## 6. Provenance, Epistemics, and Staleness

Every factual claim MUST have an inline provenance marker `[prov:source_id#locator]`.

→ Syntax, locator types, epistemic markers, and contradiction markers: `schema/reference/provenance.md`.
→ Decay table and staleness auto-fix: `schema/workflows/lint.md`.

## 8. Wikilink and Graph Conventions

Use `[[id|Title]]` for ALL intra-wiki links — see `schema/reference/wikilinks.md`.
```

**Two-stub shapes to copy:**
1. **Pure pointer** (§5, §8, §13 form): one resident safety/dispatch line (optional) + a `→ See \`path\`` arrow. §13 (L1039–1042) shows a two-line pointer with a primary + secondary link.
2. **Safety-residue + pointer** (§6 form): keeps ONE always-loaded line (`Every factual claim MUST have an inline provenance marker`) then arrows out. This is the exact shape for the §9, §11, §12 residents per the Extraction Map's "resident remnant" column.

**Adaptation per stub (resident remnants per Extraction Map + WF decisions):**
- **§9 stub:** keep ops-vocab table (current L193–200) + `validate-op.sh` pointer + the **locked 2-line solo-op log shape** (`## [date] OP | target` + source/result/reason) + the **WF-01/D-01 solo-op commit-prefix line** (`update:`/`merge:`/`supersede:`/`archive:`). Arrow → `schema/workflows/structured-operations.md`.
- **§11 stub:** keep ONLY the write-back-mandatory line (~3 lines, the "unscriptable judgment" residue). Arrow → the per-workflow files via the routing table.
- **§12 stub:** ~0 resident; one routing-pointer arrow → `schema/reference/log-format.md`.
- **Routing table (L34–61):** the table's "Workflows — STILL INLINE in §11 until Phase 17" block (L52–60) and its temporary 2-column "Where it lives NOW" form is the SCAFFOLD this phase removes. Promote every workflow into the main "Resolvable references" table (L41–50 form: `| When you need this | Go to |` keyed by operation + topic, NEVER §-number — Phase-16 D-05). Delete the L52–60 "future home / Phase 17" hedge entirely.
- **Byte-equality:** every edit lands in BOTH `CLAUDE.md` and `AGENTS.md` in the same commit (pre-commit `bin/sync-claude.sh --check`; verified currently byte-identical).

---

### `schema/AGENTS.template.md` (routing-stub mirror)

**Analog:** Phase-16 REF-09 already mirrored the reference stubs here. The template is the wizard source; every routing stub the planner writes into `CLAUDE.md` must be mirrored here verbatim (minus `{{PLACEHOLDER}}` substitutions). Current sizes: `CLAUDE.md`/`AGENTS.md` = 1051 lines, `AGENTS.template.md` = 1015 lines (the 36-line delta is placeholder/wizard-header divergence — preserve that delta shape, don't try to make them equal).

**Adaptation:** apply the SAME stub edits as the core file. No new render logic (Design Constraint: extracted `schema/workflows/*.md` are copied wholesale by the wizard).

---

### `bin/lint.sh` — NEW `routing` category (lint-engine extension, structural-scan)

**No single exact analog — this is the one NEW-tooling target.** It DECOMPOSES into two existing lint mechanics re-aimed at the `schema/` tree (D-06). Both halves have strong analogs.

**Forward half (dangling pointer → `linkres`-class → severity `error`).** Analog: the `linkres` block at L1887–1971.

Build-a-known-set then gate-by-membership pattern (`linkres` L1894–1904):
```python
    # known_ids: lowercase page ids AND filename stems (id == filename by convention).
    known_ids = set()
    for fpath, fm, body, err in all_pages:
        if fm is None:
            continue
        pid = fm.get('id', '')
        if pid:
            known_ids.add(pid.lower())
        stem = os.path.splitext(os.path.basename(fpath))[0].lower()
        known_ids.add(stem)
```
Adaptation: the routing "known set" is the set of EXISTING files in the `schema/` tree (`schema/reference/*.md` + `schema/workflows/*.md` + the core `AGENTS.md`). The "links" to resolve are: (a) every `→ See \`schema/...\`` pointer + routing-table cell in core, and (b) every cross-file path reference in the extracted files. A reference whose target path does not exist on disk → `add_finding('error', 'routing', <referrer>, ...)`. ALSO (D-05): any cross-file `§N` / "Section N" pattern that still exists is itself a routing error (pattern-prohibition, not resolution).

**Inverse half (orphan file → `orphan`-class → severity `warning`).** Analog: the `orphan` inbound-link block at L1184–1262.

Inbound-link accounting then zero-inbound flag (`orphan` L1214–1262):
```python
    inbound_links = {}  # page_id -> set of linking page_ids
    for pid in page_ids:
        inbound_links[pid] = set()
    ...
    for pid, linkers in inbound_links.items():
        if pid in orphan_exclude:
            continue
        if len(linkers) == 0:
            ...
            add_finding('warning', 'orphan', rel, 'No inbound wikilinks from other wiki pages')
```
Adaptation: an extracted `schema/workflows/foo.md` that NO core routing-table entry points to is an unreachable orphan → `add_finding('warning', 'routing', <orphan-file>, 'extracted file unreachable from core routing table')`.

**Wiring the new category into the existing apparatus** — these are the EXACT insertion points (all in `bin/lint.sh`):
1. **`should_run` guard** (L463–464): wrap the new block in `if should_run('routing'):`.
   ```python
   def should_run(cat):
       return category_filter == 'all' or category_filter == cat
   ```
2. **Severity remap dispatch table** (L316–331): add TWO lines (forward=error, inverse=warning is handled by the `add_finding` severity, but the remap key must exist so `--ci` keeps it):
   ```python
   CI_SEVERITY_REMAP = {
       'yaml':               'error',
       'orphan':             'error',
       ...
       'linkres':            'error',
       ...
   }
   ```
   Add `'routing': 'error',` (forward findings gate CI). Note: inverse findings are emitted at `warning` by `add_finding` directly; since `routing`→error in the remap would PROMOTE warnings, the planner must decide — recommended: emit the inverse as a DISTINCT logical handling (mirror the `drift-external` sub-category trick at L333–350, e.g. a message-prefix the remap leaves at warning) OR keep `routing`→error only for forward and emit inverse under a separate key. **Flag for planner:** reconcile the single-category-single-severity constraint with D-04's bidirectional severity split. The `drift` + `drift-external` two-token pattern (L326 `'drift':'warning'` + L348 prefix-match skip) is the proven template for "one category, two behaviors."
3. **`--category` / `--skip-category` parsing** (L120–127, L155–166): no code change — `routing` flows through automatically once `should_run('routing')` exists. Add `routing` to the usage doc category list (L26–29) and to the `--require-version`-adjacent docs.
4. **`LINT_VERSION`** (L13, `="1.7.0"`): bump MINOR (new non-breaking category) → `1.8.0`. The header comment (L11–12) documents the bump convention.
5. **Empty-wiki-abort BYPASS (D-06):** there is NO script-level empty-wiki abort in `bin/lint.sh` — the abort is a WORKFLOW rule (§11.3 "Wiki is empty ... skip the lint"). The script's corpus is rooted in `WIKI_DIR` (default `wiki-cloud/`, L185/L217). The `routing` category's corpus is the `schema/` tree, which is INDEPENDENT of `WIKI_DIR`. So "bypass the empty-wiki abort" means: the routing scan must walk `schema/` + `AGENTS.md` regardless of how many pages exist under `WIKI_DIR`. Implementation: do NOT gate the routing walk on `all_pages` being non-empty; root it at `REPO_ROOT` (L266/L292, `os.environ.get('LINT_REPO_ROOT', os.getcwd())`) → `schema/`. A fresh template clone (near-empty wiki, full schema tree) is exactly when routing integrity matters most.
6. **JSON emit + exit policy** (L2440–2458): no change — `routing` findings flow through the existing 4-tuple `(severity, category, path, message)` emitter and the `has_error` exit-1 rule automatically once they carry `error` severity.

**`--staged` scope (D-07):** routing is CI-only. The `--staged` local-write-gate stays `provenance`-only (current behavior, AGENTS.md §11.3 "Staged-mode rules"). Do NOT wire `routing` into `--staged` — a whole-tree property can't be seen through a per-added-file diff.

---

### `bin/lint.sh` — WF-08 inclusion-audit drift `info` check (lint-engine extension)

**Analog:** the `drift` "index coverage" finding family (DRFT, emitted via `add_finding('warning'/'info', 'drift', ...)`; the `info`/`brownfield` summary roll-up at L2339 shows the `info`-severity summary-line pattern).

**Adaptation:** read the machine-readable core header comment `<!-- inclusion-audit: <N> lines @ <YYYY-MM-DD> -->` (D-10) from `AGENTS.md`, compare `<N>` against the current `wc -l`-equivalent core line count, and `add_finding('info', 'routing', 'AGENTS.md', 'core drifted +M lines since last inclusion audit (DATE) — re-run WF-08')` once drift exceeds the margin (~+20% / +25 lines, D-11). Severity `info` (non-blocking) — rides the same `--ci`/`--format json`/annotation path. Recommended home: same `routing` category, or a sibling `info`-only check; planner's discretion (Claude's Discretion: "WF-08 drift-check threshold mechanics"). NOT a separate CI step.

---

### `docs/reference/ci.md`, `CONTRIBUTING.md`, `.github/workflows/lint.yml` — one-shot §N → path repoint (external-doc, D-08)

**Analog:** the EXISTING §N link refs in those files (the broken-by-construction referrers). Concrete instances found (`grep -rn '§[0-9]'`):
- `CONTRIBUTING.md` L12 `[AGENTS.md §11.1]` → `schema/workflows/ingest.md`; L28 + L114 + L132 `§11.3` → `schema/workflows/lint.md`; L56 `§13` → `schema/reference/privacy.md`.
- `docs/reference/ci.md` L17, L46, L122, L130, L300 `§11.3` → `schema/workflows/lint.md`; L26 `§6` → `schema/reference/provenance.md`; L93, L300 `§13` → `schema/reference/privacy.md`; L111 `§4.6`, L112 `§4.3/§4.6` → `schema/reference/page-types.md`/`frontmatter.md`.
- `.github/workflows/lint.yml` — sweep for `§` in comments.

**Repoint target pattern** (the LINK shape these files already use, ci.md L17 — keep the "source of truth ... if you find a discrepancy, X wins" framing, just swap the target):
```markdown
> **Source of truth:** The authoritative severity mapping lives in [AGENTS.md §11.3 "CI mode"](../../AGENTS.md). ... the mapping itself must stay in sync with §11.3. If you find a discrepancy, §11.3 wins and this page is the bug.
```
Adaptation: rewrite to `[schema/workflows/lint.md](../../schema/workflows/lint.md)` and drop the `§11.3` anchor (D-05 abolishes cross-file §-refs). The WF-05 lint.md "source of truth for CI contracts" framing is what these links now resolve TO.

**Sequencing (CRITICAL):** this repoint happens DURING WF-05 (when lint.md becomes the source of truth) and the `routing` error-category can only go GREEN once every `§N` is converted — so the `routing` category is BUILT/ENABLED at the END of the phase, after all extraction + this repoint (Phase-16 D-07 ordering; gates the close). An optional WARNING-level repo-wide `grep -rn '§[0-9]' .` sweep in the `routing` category covers the open-ended doc prose (D-08), but the hard `error` guard stays scoped to the `schema/` tree.

---

### `docs/reference/agent-parity.md` — WF-09 desk-check trace + empirical record (evidence-doc)

**Analog:** the file ITSELF (current 97 lines: DEBT-02 structural-equivalence rubric, golden = `examples/kahneman/` prospect-theory subset, Codex re-run procedure with the fail-closed seed guard).

**Existing structure to extend** (`agent-parity.md` L1–6 — the source-of-truth banner already enumerates the §-refs that WF-09 must repoint):
```markdown
# Agent Parity

> Reference documentation for the DEBT-02 agent-parity check: ...

> **Source of truth:** The schema being compared against lives in [AGENTS.md](../../AGENTS.md) (§4 page types, §5 frontmatter, §6 provenance, §11.1 ingest workflow). ...
```

**Adaptation (D-13/D-14/D-15 three-tier evidence):**
- Add a **scoped desk-check trace** section (the GATING floor) covering ONLY the non-mechanized judgment dims (D-14): (1) routing-table prominence/unambiguity — would a foreign agent FOLLOW it; (2) `schema/workflows/ingest.md` content self-sufficiency. CITE the new `routing` guard for resolvability (don't re-prove link-resolution by hand — that's now mechanized).
- Add an **empirical-run record** section (best-effort, NON-gating): Codex/Cursor run on the prospect-theory seed for behavioral discoverability. Record failures VERBATIM (D-15: "a failed run is signal, not a red to suppress"). If the tool is unavailable, close on the floor and document the gap (v1.1 "Codex blocked-on-host-runtime" precedent).
- Repoint this file's own `§4/§5/§6/§11.1/§11.7/§13` refs (L6, L8 banner; L29 "AGENTS.md §6") to the extracted paths (caught by the optional WARNING-level external sweep, D-08).
- Document the trace as a RE-RUNNABLE procedure (matches the file's existing "re-run manual" framing).

---

## Shared Patterns

### Extracted-file skeleton (applies to all 8 new + 1 extended markdown files)
**Source:** `schema/reference/provenance.md` (L1–4 header, L186–190 footer).
```markdown
# <Title>

> Agent-authoritative reference for <scope>.
> AGENTS.md §<N> points here. If you find a discrepancy between this file and AGENTS.md, this file wins.

<body — verbatim relocated §-content, with every cross-file §N rewritten to a path>

## See Also

- [AGENTS.md](../../AGENTS.md) — §<N> stub (pointer to this file).
- `schema/<dir>/<sibling>.md` — <what the sibling owns>.
```
No YAML frontmatter (would make the file parse as a wiki page). Relative back-link is always `../../AGENTS.md` (files live two dirs deep under `schema/{reference,workflows}/`).

### Bare-pointer stub (applies to all core/template stub edits)
**Source:** existing §4/§5/§8 stubs (`CLAUDE.md` L168–187).
Form: optional 1-line resident safety/dispatch residue, then `→ See \`schema/.../<file>.md\` for <what>.` Zero reproduced body (Phase-16 D-01). Lands in BOTH `CLAUDE.md` and `AGENTS.md` (byte-equality) AND mirrored to `schema/AGENTS.template.md`.

### Abolish-§N cross-file reference rule (D-05 — applies EVERYWHERE)
**Source:** `provenance.md` demonstrates the target state (uses `\`schema/workflows/lint.md\``, never "§6"). Every relocated body, every stub, every external doc converts cross-file `§N` / "Section N" → a path. Intra-file numbering in core (its own §1/§2/§3 structure) is allowed; cross-FILE refs must be paths. Mechanically enforced by the new `routing` lint category (forward = path-resolution, plus a `§N`-pattern-prohibition).

### Lint-engine extension points (applies to both `bin/lint.sh` additions)
**Source:** `bin/lint.sh` — `should_run(cat)` gate (L463), `add_finding(severity, category, path, message)` (L442), `CI_SEVERITY_REMAP` table (L316), the `--category`/`--skip-category` parse (L120, L155), `LINT_VERSION` (L13), JSON emit + `has_error` exit (L2440–2458), `REPO_ROOT` env (L266/L292). New categories plug in by: one `should_run` block + one remap-table line + one `LINT_VERSION` MINOR bump + usage-doc line. Everything else (parse, skip, JSON, exit) is automatic.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none — full coverage) | — | — | The `routing` category is the only genuinely-NEW logic, but it composes cleanly from the existing `linkres` (forward) + `orphan` (inverse) + `drift`/`drift-external` two-token-severity blocks. No target lacks an analog. |

---

## Metadata

**Analog search scope:** `schema/reference/` (5 files), `schema/workflows/` (1 seed), `CLAUDE.md`/`AGENTS.md` (1051-line monolith, byte-identical), `schema/AGENTS.template.md`, `bin/lint.sh` (2587 lines), `docs/reference/{ci.md,agent-parity.md}`, `CONTRIBUTING.md`, `.github/workflows/lint.yml`.
**Files scanned:** 11.
**Pattern extraction date:** 2026-06-05.
**Key correction surfaced:** live core is 1051 lines (Phase-16-extracted), not the 1,689 in the milestone brief — the brief's §-line-ranges are stale and MUST be re-derived against the current file (map provided at top).
