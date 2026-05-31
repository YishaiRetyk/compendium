# Phase 13: Claim Faithfulness Audit — Research

**Researched:** 2026-05-31
**Domain:** Source-grounded semantic verification of wiki claims (bash + python3 + pyyaml + git); pluggable verifier; review-only, privacy fail-closed
**Confidence:** HIGH (architecture is LOCKED in `13-CONTEXT.md` D-01..D-16; this research confirms it against the live code and produces the test/validation strategy the design notes do not settle)

## Summary

The architecture for Phase 13 is fully settled by two pre-existing artifacts: `13-DESIGN-NOTES.md` (authoritative pre-planning design — ragas `faithfulness` mapping, locator→passage table, privacy chokepoint, output schema, Don't-Hand-Roll, pitfalls) and `13-CONTEXT.md` (16 locked decisions D-01..D-16 resolving every open question). This research does **not** re-derive that architecture. It does three things the design does not: (1) grounds every "reuse this" claim against the live `bin/lint.sh` / `bin/check-privacy.sh` (the CONTEXT line numbers have drifted — `lint.sh` is now **2058 lines**, not 1895), (2) surfaces two facts that change the plan, and (3) produces the concrete `## Validation Architecture` test strategy for `tests/phase-13/`.

**Two facts that change the plan (both verified against live code):**

1. **No §13 three-level privacy resolver exists yet.** `bin/check-privacy.sh` is a *leak guard* — it greps `privacy: local_only` in frontmatter of `PUBLIC_PATHS` and exits 2 on a hit (148 lines). It does NOT implement the frontmatter→enclosing-dir→`local_only`-default precedence (§13). The D-02 fail-closed resolver must be **built**, not reused. It is the strongest candidate to factor into `bin/lib/` (e.g. `bin/lib/privacy_resolve.py`). [VERIFIED: bin/check-privacy.sh lines 86-141 — only a regex grep, no dir-default/fail-closed logic; grep across bin/ for "precedence"/"enclosing" returns nothing]

2. **The lint finding tuple is a 4-tuple `(severity, category, path, message)` with NO `line` slot.** The JSON emitter (line 1911-1922) intentionally OMITS `line`. The audit's required 6-field output (path, line, source_id, locator, verdict, rationale — FAITH-03/SC-4) cannot be expressed by extending the lint tuple in place; the audit needs its **own richer finding record** that is *JSON-superset-compatible* with lint's (SC-6 means "lint/report tooling can consume both", i.e. shares the `severity/category/path/message` keys and adds more — not "reuse the same Python tuple"). [VERIFIED: bin/lint.sh line 403-404 `add_finding(severity, category, path, message)`; line 1906-1908 comment "The 4-tuple ... has no line slot, so `line` is OMITTED"]

Everything else in the design is confirmed reusable as written.

**Primary recommendation:** Build `bin/audit-claims.sh` as a new bash-arg-parse → single-python3-block script mirroring `bin/lint.sh`'s structure. **Copy** (do not import) lint's frontmatter parser (`parse_frontmatter`, line 406), prov regex (`PROV_RE`, line 385), source-registry build (line 977-981), hash-drift signal (line 1225-1238), and inbound-link map (line 1107-1136) — these are embedded in lint's monolithic python heredoc and are not currently importable modules. Build a NEW §13 privacy resolver (no existing one), placing the shared logic in `bin/lib/`. Use lint's own 5-key JSON-compatible finding dict as the output base, adding `line/source_id/locator/verdict/rationale`. Ship the agent-in-the-loop default + documented `--verifier <cmd>` subprocess contract (no bundled verifier — D-01). Checkpoint at `wiki/maintenance/audit-state.md` (the `reflect-state.md` pattern-twin — note: **`reflect-state.md` does not yet exist on disk**, so model it from AGENTS.md §11.4, not from a live file).

## User Constraints (from 13-CONTEXT.md)

### Locked Decisions (D-01..D-16 — research THESE, no alternatives)

- **D-01 Contract-only verifier.** Agent-in-the-loop default; documented `--verifier <cmd>` contract (stdin `{claim, passage, support_type}` → stdout `{verdict, rationale, sub_claims:[...]}`). **Ship NO bundled verifier script.**
- **D-02 Fail-closed `local_only` egress, MECHANICALLY enforced.** Resolve each claim's *source* privacy via §13 precedence BEFORE the verdict step. By default **withhold `local_only` passages from the emitted worklist** → mark `skipped-privacy`. Including them requires explicit opt-in (`--verifier` local cmd, or an `--allow-local`-style flag). A cloud model *mechanically* never receives `local_only` passages. **This is the load-bearing requirement.**
- **D-03 `skipped-privacy` is acceptable UX.** A local-heavy vault emitting `skipped-privacy` for every `local_only` claim is the accepted default. Do NOT treat high `skipped-privacy` counts as failure or pad coverage.
- **D-04 Ship the page-marker convention in v1** (override of design-note v1.2 deferral).
- **D-05 Marker syntax = `<!-- page: N -->`** HTML comment at page boundaries. Obsidian-invisible, grep-able, no `[prov:]` grammar change. `#p8` slices from `page: 8` marker to `page: 9` marker; `#p12-14` spans `page: 12` to `page: 15` (exclusive).
- **D-06 Optional, with `insufficient-locator` fallback.** Markers optional; absent → `#p` degrades to `insufficient-locator` (NOT an error).
- **D-07 Document now, helper later.** Convention in AGENTS.md §6 (+ mirrors) in v1; hand-marked; auto-insertion deferred to v1.2.
- **D-08 Cadence = on-demand + non-binding reflect-tier suggestion** (`audit recommended: ...`, §11.4 Tier-2 pattern).
- **D-09 Default `--sample 20`, priority-ranked union.** Union 4 selectors, dedupe, order **stale-source → inferred/tentative → recently-modified → high-fanout**, cap 20. **Always log selected-vs-skipped counts.**
- **D-10 Defined, human-approved `contradicts`→marker handoff.** Audit stays report-only; document a separate explicit op to add `[epistemic:: tentative]` or `[contradiction:...]`. Never automatic.
- **D-11 Verify against raw source file at `path:`**, NEVER the source-summary's `## Extracted Claims` (circular — highest-severity pitfall).
- **D-12 Four-way verdict** `supports`/`weak`/`contradicts`/`insufficient` (ragas-adapted) + operational `insufficient-locator`/`skipped-privacy`/`skipped-nontext`. `insufficient` (passage doesn't address claim) ≠ `insufficient-locator` (couldn't extract a passage).
- **D-13 Zero new claim-level vocabulary.** Reuse `[epistemic::]` as selectors; no magic-string prov values.
- **D-14 Output = lint finding + `verdict/line/source_id/locator/rationale`.** Human report `wiki/maintenance/audit-report.md` grouped by verdict. **No wiki page ever mutated.** Severity: `contradicts`→warning; `weak`/`insufficient`/`skipped-*`/`insufficient-locator`→info; `supports`→info-or-omitted. **No `error`** — never a v1 gate.
- **D-15 Checkpoint `wiki/maintenance/audit-state.md`** (frontmatter `last_audit_commit`, `last_audit_at`, `last_sample_size`); control-plane, not indexed; advances even on no-finding run.
- **D-16 Separate script, NOT a `bin/lint.sh` category.** MAY share JSON schema.

### Claude's Discretion
- Exact arg surface (`--since`, `--sample N`, `--select`, `--format json|report`, `--emit-worklist`, `--apply-verdicts <f>`, `--verifier <cmd>`, `--allow-local` name).
- Agent loop shape: "emit worklist → agent writes report" vs "→ `--apply-verdicts <file>`".
- §6 prose/placement of `<!-- page: N -->` (syntax + slice semantics fixed; wording open).
- High-fanout computation (reuse lint inbound-link pass vs dedicated count).
- Reflect-tier suggestion host (lint workflow / reflect workflow / both).
- `13-VERIFICATION.md` evidence layout (follow 12.1/12.2 mirror format).

### Deferred Ideas (OUT OF SCOPE)
Auto-insertion of page markers at ingest; bundled reference verifiers; required page markers; periodic/post-ingest auto-trigger; auto-promotion of `contradicts`; embedding/ragas/SQLite/full-vault-default; elevating Audit to a 5th top-level operation (planner's call, default: document as a workflow without churning the four-operation framing).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FAITH-01 | Sample recently-modified + high-risk claims (inferred/tentative, stale-source, high-fanout) | Selectors all grep/git/inbound-link computable from live `bin/lint.sh` primitives (PROV_RE line 385, EPISTEMIC_INLINE_RE line 391, hash-drift line 1225-1238, inbound_links line 1107). Priority-rank + cap-20 per D-09. |
| FAITH-02 | Resolve `[prov:source_id#locator]` to cited passage; 4-way verdict | `source_registry[source_id]['path']` (line 977-981) → read raw file at repo-root/path (D-11). Locator slicing: `#sec:`/`#para`/`#t` clean; `#p` via `<!-- page: N -->` markers (D-05) or `insufficient-locator`; `#img`→`skipped-nontext`. Verdict via pluggable verifier (D-01/D-12). |
| FAITH-03 | Structured review-only output: path, line, source_id, locator, verdict, rationale; no auto-edits | Own 9-key finding dict (lint 4-key superset). Report `wiki/maintenance/audit-report.md`. No page mutation (D-14/SC-5). |
| FAITH-04 | `local_only` claims never sent to cloud; local verifier OR explicit skipped/privacy finding | NEW §13 resolver (none exists) → fail-closed worklist partition (D-02). `local_only` withheld by default → `skipped-privacy`. Single chokepoint at verdict-dispatch step. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Claim selection (FAITH-01) | `bin/audit-claims.sh` python block (deterministic) | git (recency), lint primitives (regex/inbound-link) | Pure-local file+git read; no judgment, no egress |
| Locator→passage resolution (FAITH-02 det. half) | `bin/audit-claims.sh` python block | raw source file at `path:` (D-11) | Deterministic string-slicing; the crux of the script |
| Privacy resolution (FAITH-04) | NEW `bin/lib/privacy_resolve.py` (§13) | invoked by audit-claims pre-verdict | Fail-closed; shared logic; the single gate before egress |
| Verdict / entailment (FAITH-02 judgment half) | Pluggable **verifier** (agent-in-loop default; `--verifier <cmd>`) | — | The ONLY judgment step AND the ONLY privacy egress |
| Findings emit (FAITH-03) | `bin/audit-claims.sh` python block | `wiki/maintenance/audit-report.md` + JSON stdout | Review-only; lint-JSON-superset for SC-6 |
| Checkpoint | `wiki/maintenance/audit-state.md` | — | Control-plane, not indexed (D-15) |
| Page-marker convention (D-04/05) | `AGENTS.md §6` (+ `schema/AGENTS.template.md` + `CLAUDE.md`) | hand-authored in raw sources | Schema-surface, consumed read-only by resolver |

The deterministic core (select→resolve→privacy-route→emit) sends nothing anywhere. Egress happens at exactly one place: verdict dispatch. This is the FAITH-04 enforcement boundary.

## Standard Stack

### Core (all in-repo, zero new dependencies — VERIFIED)
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| bash | system | arg-parse, subprocess orchestration | Same runtime as all `bin/*.sh` |
| python3 | **3.12.3** [VERIFIED: `python3 --version`] | single-block select/resolve/privacy/emit | Same as `bin/lint.sh` heredoc pattern |
| pyyaml | **6.0.1** [VERIFIED: `python3 -c "import yaml"`] | frontmatter parse | `parse_frontmatter` line 406-422 uses `yaml.safe_load` |
| git | system | recency selector (`git diff <checkpoint>...HEAD -- wiki/`) | Mirrors `strict_added_epistemic_claims` line 463-490 |

**Zero-new-dependency constraint CONFIRMED satisfiable:** every FAITH selector and resolver primitive already exists in `bin/lint.sh`'s python block. No ragas/datasets/nltk/SQLite/embeddings needed — borrow the *algorithm* (decompose→entailment→aggregate), not the library.

### Verifier (the one new moving part — D-01 contract-only)
- **Default: agent-in-the-loop** — script emits worklist; operating LLM produces verdicts. No API key, no network call from the script.
- **Optional: `--verifier <cmd>`** — subprocess contract: stdin JSON `{claim, passage, support_type}` per claim (or a JSON array — planner's call), stdout JSON `{verdict, rationale, sub_claims:[...]}`. **No bundled script.**

### Alternatives Considered (LOCKED-rejected — do not explore)
| Instead of | Rejected alternative | Why |
|------------|---------------------|-----|
| Borrow ragas algorithm | Import ragas/datasets/nltk | Drags heavy deps; violates markdown-first + no-SQLite non-goals (D-16, non-goals) |
| Read raw source at `path:` | Verify against summary `## Extracted Claims` | Circular — same extraction pass that erred (D-11; highest-severity pitfall) |
| Separate `bin/audit-claims.sh` | `bin/lint.sh` category | lint is fast/offline; faithfulness is slow/sampled/judgment (D-16) |
| Build new §13 resolver | "reuse `check-privacy.sh`" | check-privacy is a leak-grep, not a precedence resolver — does not exist to reuse |

**No `npm install` / no new deps.** Installation is zero.

## Architecture Patterns

### System Architecture Diagram

```
operator: bin/audit-claims.sh --since <ckpt> --sample 20 [--verifier cmd] [--allow-local]
   │
   ▼
[bash arg-parse] ──exports env──▶ [single python3 block]
                                        │
   (1) LOAD ─────────────────────────────┤  reuse parse_frontmatter (lint:406)
       all_pages + source_registry       │  reuse source_registry build (lint:977-981)
                                        │
   (2) SELECT (FAITH-01) ────────────────┤  git diff (recency) ∪ EPISTEMIC_INLINE_RE (lint:391)
       4 selectors → union → dedupe      │  ∪ hash-drift (lint:1225-1238) ∪ inbound_links (lint:1107)
       → priority-rank → cap @ --sample  │  → emit info finding: selected=N skipped=M  (D-09)
                                        │
   (3) RESOLVE (FAITH-02 det.) ──────────┤  source_id → source_registry[id]['path']
       for each claim:                   │  read RAW file @ repo_root/path  (D-11, NOT summary)
         PROV_RE (lint:385) → src,loc    │  slice by locator type ↓
         #sec:/#para/#t  → passage       │
         #p + <!-- page:N --> → passage   │  (D-05 marker slice)
         #p, no marker → insufficient-locator
         #img → skipped-nontext
         no passage → insufficient-locator
                                        │
   (4) PRIVACY-ROUTE (FAITH-04) ─────────┤  NEW bin/lib/privacy_resolve.py (§13 precedence,
       resolve SOURCE privacy            │  fail-closed). local_only + no local verifier
       → partition worklist              │  → WITHHOLD passage, verdict=skipped-privacy (D-02)
                                        │      ╔══════════════════════════════════════╗
   (5) VERDICT (judgment) ════════════════╪═════▶║ SOLE EGRESS POINT                     ║
       cloud_safe → verifier             │      ║ agent-in-loop | --verifier cmd        ║
       local_only → local verifier|skip  │      ║ NOTHING local_only reaches a cloud cmd║
                                        │      ╚══════════════════════════════════════╝
   (6) EMIT (FAITH-03) ──────────────────┤  9-key finding dict → JSON stdout (SC-6)
       no page mutation (SC-5)           │  + wiki/maintenance/audit-report.md (grouped by verdict)
                                        │
   (7) CHECKPOINT ───────────────────────┘  advance wiki/maintenance/audit-state.md (D-15)
```

Steps 1-4 are pure-local (read files, extract passages) and egress nothing. Step 5 is the only place content can leave; D-02's worklist partition guarantees `local_only` passages are not in the set step 5 dispatches to a cloud command.

### Recommended Project Structure
```
bin/
├── audit-claims.sh          # NEW: bash arg-parse → single python3 block (mirrors lint.sh)
└── lib/
    └── privacy_resolve.py    # NEW: §13 three-level fail-closed resolver (none exists today)
wiki/maintenance/
├── audit-report.md          # NEW (generated): findings grouped by verdict (pattern-twin of lint-report.md)
└── audit-state.md           # NEW (generated): checkpoint (pattern-twin of reflect-state.md)
tests/phase-13/
├── run.sh                   # aggregator (copy tests/phase-12.2/run.sh shape)
├── lib.sh                   # helpers (make_bare_repo + write_page + a fake-verifier helper)
├── fixtures/                # raw source files + page+source fixtures (self-contained)
└── test_*.sh                # one per verdict path + privacy partition + sampling + verifier contract
AGENTS.md §6                 # + <!-- page: N --> convention (+ schema/AGENTS.template.md + CLAUDE.md mirror)
```

### Pattern 1: bash-arg-parse → single python3 heredoc (mirror lint.sh)
**What:** bash parses flags, exports them as env vars, then `python3 - <<'PYEOF'` reads `os.environ`. **When:** the whole script. **Example (verified live shape):**
```bash
# Source: bin/check-privacy.sh:74-79, bin/lint.sh:259-284
export AUDIT_FORMAT="$FORMAT"
export AUDIT_SAMPLE="$SAMPLE"
set +e
python3 - <<'PYEOF'
import os, re, sys, json, subprocess
FORMAT = os.environ.get('AUDIT_FORMAT', 'report')
# ... copy parse_frontmatter / PROV_RE / source_registry build ...
PYEOF
PYRC=$?
set -e
exit "$PYRC"
```

### Pattern 2: source_id → raw passage (the FAITH-02 crux, D-11)
**What:** resolve a claim's source to its RAW file, never the summary. **Example (verified registry build):**
```python
# Source: bin/lint.sh:977-981 (registry) + :382 (SOURCE_EXTRA_FIELDS includes 'path')
source_registry = {}
for sp, sfm, sbody in source_pages:
    if sfm and 'id' in sfm:
        source_registry[sfm['id']] = sfm
# resolve:
sfm = source_registry.get(source_id)
raw_path = os.path.join(repo_root, sfm['path'])   # e.g. sources/2026/2026-04/...-slug/source.md
raw_text = open(raw_path, encoding='utf-8').read()  # NOT the summary page body
passage = resolve_locator(raw_text, locator)        # slice; None → insufficient-locator
```
Note: `path:` is repo-root-relative (verified: `examples/kahneman/sources/...md` → `path: sources/2026/2026-04/.../source.md`). A missing raw file (the examples cluster ships summaries but not raw sources — verified) must degrade gracefully, not crash — emit `insufficient-locator` or a distinct "raw-source-missing" note.

### Pattern 3: `<!-- page: N -->` slice (D-05)
**What:** `#p8` → slice from line containing `<!-- page: 8 -->` to line before `<!-- page: 9 -->`; `#p12-14` → `page: 12` marker to `page: 15` marker (exclusive). Absent markers → `insufficient-locator`. Grep-able, Obsidian-invisible. The convention is documented in AGENTS.md §6 with **abstract placeholders** (CLAUDE.md §3 neutrality rule — no real vault terms in template-public files).

### Anti-Patterns to Avoid
- **Feeding the whole document when `#p` can't bound** → false `supports`/`contradicts` at cost + privacy surface. Make `insufficient-locator` first-class (pitfall #2).
- **Any pre-verdict egress** → FAITH-04 unenforceable. Keep step 5 the sole egress (pitfall #3).
- **Mutating wiki pages** → violates SC-5. `contradicts` produces a finding; promotion is a separate human op (D-10).
- **Importing lint.sh's python** — it is a monolithic heredoc, not an importable module. **Copy** the needed primitives.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Frontmatter parse | new YAML reader | copy `parse_frontmatter` (lint.sh:406-422) | Battle-tested; handles unterminated FM |
| Claim detection / src+loc extract | new regex | copy `PROV_RE` (lint.sh:385-390), `PROVENANCE_PRESENCE_RE` (:307) | Exact grammar match (§6) |
| Epistemic selector | new marker scan | copy `EPISTEMIC_INLINE_RE` (lint.sh:391) | `inferred`/`tentative` already captured |
| source_id → path | new registry | copy registry build (lint.sh:977-981) + `SOURCE_EXTRA_FIELDS` (:382) | `path` field already in scope |
| Stale-source selector | new hash diff | copy `content_hash != compiled_against_hash` (lint.sh:1225-1238) | Already computed |
| High-fanout selector | new link graph | copy `inbound_links` map (lint.sh:1107-1136); `len(inbound_links[pid])` = fanout | Already built for orphan/crossref |
| Recency selector | new git wrapper | copy `git diff <ref>...HEAD -- wiki/` (lint.sh:463-490) | `--strict`/reflect precedent |
| JSON finding emit | new schema | lint's 5-key dict (lint.sh:1911-1922) as a SUPERSET base | SC-6 compatibility |
| Checkpoint mechanics | new format | AGENTS.md §11.4 `reflect-state.md` spec (file not yet on disk) | D-15 pattern-twin |
| Exclusion dirs | new list | `EXCLUDE_DIRS = {'maintenance','examples'}` (lint.sh:395), `example: true` skip (lint.sh:971) | Consistent skip semantics |

**Build NEW (no reuse exists):** the §13 three-level privacy resolver (`check-privacy.sh` is a leak-grep, not a resolver). Factor to `bin/lib/privacy_resolve.py`. **Key insight:** the audit is ~80% copied lint primitives + 20% genuinely new (privacy resolver, locator→passage slicer, verifier dispatch). The new 20% is exactly the part that needs the most tests.

## Runtime State Inventory

Not a rename/refactor phase — greenfield additive. Section omitted per researcher rules.

## Common Pitfalls

(Carried verbatim from `13-DESIGN-NOTES.md` §Common Pitfalls — all LOCKED; reproduced for the planner's verification steps.)

### Pitfall 1: Circular verification (highest severity, D-11)
**What goes wrong:** auditing against the summary's `## Extracted Claims` validates the wiki against itself. **Avoid:** always read raw `path:`. **Warning sign:** the resolver opens a `wiki/sources/*.md` file instead of the raw `sources/**` file.

### Pitfall 2: Silent locator failure
**What goes wrong:** feeding the whole document when `#p` can't bound → false verdict at cost + privacy surface. **Avoid:** `insufficient-locator` first-class. **Warning sign:** any code path passes >1 section to the verifier for a `#p` locator with no markers.

### Pitfall 3: Privacy leak through the verifier (FAITH-04 raison d'être)
**What goes wrong:** any pre-verdict step egresses → FAITH-04 unenforceable. **Avoid:** step 5 sole egress; fail-closed on unknown privacy (§13 default `local_only`). **Warning sign:** a network/subprocess call anywhere in steps 1-4; or a `local_only` passage present in the worklist a cloud verifier reads.

### Pitfall 4: Silent sampling cap → "looks audited"
**What goes wrong:** a green audit on a capped sample reads as a green vault. **Avoid:** log selected-vs-skipped (D-09). **Warning sign:** no `info` finding stating `selected=N skipped=M`.

### Pitfall 5: Non-determinism read as regression
**What goes wrong:** LLM verdicts vary run-to-run; a flipped verdict mistaken for new drift. **Avoid:** review-only, log rationale, never gate; say so in the workflow doc.

### Pitfall 6: Scope creep into auto-fix
**What goes wrong:** "fixing" a `contradicts`. **Avoid:** propose, never rewrite (SC-5, D-10). **Warning sign:** the script writes to any `wiki/{entities,concepts,...}` page.

## Code Examples

### Verified §13 resolver shape (NEW — to build in bin/lib/)
```python
# §13 three-level precedence, fail-closed. Source: AGENTS.md §13 Privacy Decision Table.
# NOTE: no existing implementation — check-privacy.sh only greps PUBLIC_PATHS.
def resolve_source_privacy(source_fm, source_path):
    # 1. explicit frontmatter wins
    fm_priv = (source_fm or {}).get('privacy')
    if fm_priv in ('local_only', 'cloud_safe'):
        explicit = fm_priv
    else:
        explicit = None
    # 2. enclosing-dir default
    dir_priv = None
    if '/local-only/' in source_path or source_path.startswith('local-only/'):
        dir_priv = 'local_only'
    elif '/cloud-safe/' in source_path:
        dir_priv = 'cloud_safe'
    # 3. system default + stricter-wins resolution
    candidates = [p for p in (explicit, dir_priv) if p]
    if not candidates:
        return 'local_only'                      # fail-closed default
    return 'local_only' if 'local_only' in candidates else 'cloud_safe'  # stricter wins
```

### Verified finding superset (extends lint JSON — SC-6)
```python
# lint emits {severity, category, path, message} (lint.sh:1916-1921).
# Audit adds 5 keys; lint/report tooling reads the shared 4, ignores the rest.
finding = {
    "severity": "warning",          # contradicts→warning; else info (D-14); NO error
    "category": "faithfulness",
    "path": "wiki/concepts/foo.md",
    "message": rationale_one_line,   # SC-4 rationale
    "line": 42,
    "source_id": "src-2026-04-15-x",
    "locator": "#sec:intro",
    "verdict": "weak",               # supports|weak|contradicts|insufficient|insufficient-locator|skipped-privacy|skipped-nontext
    "rationale": rationale_one_line,
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `[prov:]` presence + locator-syntax validation only (lint provenance check) | + semantic faithfulness audit (does the claim follow from the passage) | Phase 13 | Closes the "error compounding" gap; review-only, no gate |
| Privacy = leak-grep on public paths (`check-privacy.sh`) | + full §13 three-level resolver for source privacy (new `bin/lib/`) | Phase 13 | First mechanical §13 precedence implementation in the repo |
| ragas `faithfulness` (library, heavy deps) | borrowed algorithm only (decompose→entailment→aggregate) in a pluggable verifier | Phase 13 | Zero new deps |

**Deprecated/outdated in CONTEXT vs live code:** CONTEXT cites `bin/lint.sh` as "1895 lines"; it is now **2058 lines** and `LINT_VERSION="1.3.0"`. All cited symbols still exist but line numbers drifted (corrected throughout this doc). `reflect-state.md` is referenced as a live pattern-twin but **does not exist on disk** — model the checkpoint from AGENTS.md §11.4 spec.

## Validation Architecture

> `nyquist_validation: true` in `.planning/config.json` — this section is REQUIRED and feeds VALIDATION.md.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash test scripts + per-phase aggregator (project convention — NO pytest/jest) |
| Config file | none — `tests/phase-13/run.sh` iterates `test_*.sh` (copy `tests/phase-12.2/run.sh`, verified lines 27-40) |
| Helpers | `tests/phase-13/lib.sh` — copy `make_bare_repo` + `write_page` + `assert_exit_code` + `cleanup_fixture_repo` from `tests/phase-12.2/lib.sh` (verified lines 15-69); ADD a `make_fake_verifier` helper |
| Quick run command | `bash tests/phase-13/run.sh` |
| Full suite command | `bash tests/phase-13/run.sh` (single aggregator; no `--full` split needed) |

### The deterministic-testability insight (load-bearing for this phase)

The verdict step is non-deterministic (LLM). **Everything else is deterministic and must be tested without invoking any model.** The mechanism: a **fake/stub `--verifier`** — a tiny bash/python script that reads the contract stdin and echoes a canned `{verdict, rationale}` per a lookup keyed on the claim text. This makes the entire pipeline deterministic end-to-end:

```bash
# tests/phase-13/lib.sh — make_fake_verifier writes a stub honoring the D-01 contract.
# Reads {claim,passage,support_type} on stdin, emits a canned verdict.
# A test seeds the mapping so each verdict path is reproducible.
make_fake_verifier() {  # $1=repo $2=verdict $3=rationale
    cat > "$1/fake-verifier.sh" <<EOF
#!/usr/bin/env bash
read -r _input   # consume contract JSON
printf '{"verdict":"%s","rationale":"%s","sub_claims":[]}\n' "$2" "$3"
EOF
    chmod +x "$1/fake-verifier.sh"
    echo "$1/fake-verifier.sh"
}
```
With the fake verifier, `supports`/`weak`/`contradicts`/`insufficient` are reproducible; with NO verifier or an `--allow-local`-less run, `skipped-privacy` is reproducible; the resolver decides `insufficient-locator`/`skipped-nontext` with no verifier at all.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FAITH-01 | recency selector picks git-diff-changed claims | unit | `bash tests/phase-13/test_select_recency.sh` | ❌ Wave 0 |
| FAITH-01 | inferred/tentative selector | unit | `test_select_epistemic.sh` | ❌ Wave 0 |
| FAITH-01 | stale-source selector (hash mismatch) | unit | `test_select_stale_source.sh` | ❌ Wave 0 |
| FAITH-01 | high-fanout selector (inbound-link count) | unit | `test_select_high_fanout.sh` | ❌ Wave 0 |
| FAITH-01 | priority-rank order + cap-20 + `selected/skipped` log | unit | `test_sampling_cap_logging.sh` | ❌ Wave 0 |
| FAITH-02 | `#sec:` slices heading→next-heading from RAW file (not summary) | unit | `test_resolve_sec.sh` | ❌ Wave 0 |
| FAITH-02 | `#para` n-th paragraph | unit | `test_resolve_para.sh` | ❌ Wave 0 |
| FAITH-02 | `#p8` with `<!-- page: N -->` markers → bounded passage (D-05) | unit | `test_resolve_p_marked.sh` | ❌ Wave 0 |
| FAITH-02 | `#p8` UNMARKED source → `insufficient-locator` (D-06) | unit | `test_resolve_p_unmarked.sh` | ❌ Wave 0 |
| FAITH-02 | `#img` → `skipped-nontext` | unit | `test_resolve_img.sh` | ❌ Wave 0 |
| FAITH-02 | raw-source-missing → graceful degrade (no crash) | unit | `test_resolve_missing_raw.sh` | ❌ Wave 0 |
| FAITH-02 | D-11: resolver reads `path:` raw file, never summary `## Extracted Claims` | unit | `test_no_circular_verify.sh` | ❌ Wave 0 |
| FAITH-02 | each verdict path via fake verifier: supports/weak/contradicts/insufficient | unit | `test_verdict_paths.sh` | ❌ Wave 0 |
| FAITH-03 | output carries all 6 fields (path,line,source_id,locator,verdict,rationale) | unit | `test_output_schema.sh` | ❌ Wave 0 |
| FAITH-03 | JSON output is lint-superset (4 shared keys present) | unit | `test_json_lint_compat.sh` | ❌ Wave 0 |
| FAITH-03 | NO wiki page mutated after a run (SC-5) | unit | `test_no_page_mutation.sh` | ❌ Wave 0 |
| FAITH-04 | **fail-closed partition**: cloud verifier MECHANICALLY never receives `local_only` passage (D-02) | unit (load-bearing) | `test_privacy_partition_fail_closed.sh` | ❌ Wave 0 |
| FAITH-04 | `local_only` + no local verifier → `skipped-privacy` finding (D-03) | unit | `test_skipped_privacy.sh` | ❌ Wave 0 |
| FAITH-04 | §13 resolution: frontmatter / dir-default / system-default + stricter-wins | unit | `test_privacy_resolve_precedence.sh` | ❌ Wave 0 |
| FAITH-04 | `--allow-local`/local `--verifier` opt-in admits `local_only` to worklist | unit | `test_allow_local_optin.sh` | ❌ Wave 0 |
| D-01 | `--verifier <cmd>` contract: stdin `{claim,passage,support_type}` → stdout `{verdict,rationale,sub_claims}` | unit | `test_verifier_contract.sh` | ❌ Wave 0 |
| D-15 | checkpoint advances even on no-finding run | unit | `test_checkpoint_advance.sh` | ❌ Wave 0 |

### How to test the load-bearing fail-closed partition (FAITH-04 / D-02)
The strongest test asserts the **negative**: a `local_only` passage NEVER reaches the cloud verifier. Make the fake verifier **record every passage it receives** to a sentinel file, then assert the sentinel never contains the `local_only` source's distinctive text:
```bash
# test_privacy_partition_fail_closed.sh skeleton
# Fixture: one cloud_safe source + one local_only source, each with a claim.
# Fake verifier appends its stdin to "$REPO/verifier-saw.log".
# Run WITHOUT --allow-local and with the fake verifier as a CLOUD verifier.
bash bin/audit-claims.sh --verifier "$REPO/recording-verifier.sh" --format json ...
# ASSERT 1: verifier-saw.log contains the cloud_safe passage's marker text.
# ASSERT 2: verifier-saw.log does NOT contain the local_only passage's marker text.
# ASSERT 3: JSON output has a {verdict:"skipped-privacy", source_id:<local one>} finding.
```
This proves enforcement (the passage is absent from the dispatched worklist), not a documented promise — exactly D-02's "mechanically, not a promise."

### Fixture realism note
The `examples/kahneman/` cluster ships source SUMMARY pages whose `path:` points at raw `sources/**` files that are **not on disk** (verified). Therefore `tests/phase-13/fixtures/` must be **self-contained**: each fixture writes BOTH the `wiki/sources/<id>.md` summary page (with `path:` + `content_hash` + `compiled_against_hash`) AND the raw source file at that `path:`, with real `## headings` / blank-line paragraphs / `<!-- page: N -->` markers to slice against. Use `write_page` for both. The `local_only` privacy fixture is realistic — every current `wiki/sources/*.md` is `local_only` (verified), i.e. the D-03 local-heavy-vault default is the real production state.

### Sampling Rate
- **Per task commit:** `bash tests/phase-13/run.sh` (fast — all deterministic, fake verifier, no model calls).
- **Per wave merge:** `bash tests/phase-13/run.sh` + `bash bin/lint.sh --category yaml` over the new control-plane files.
- **Phase gate:** full `tests/phase-13/run.sh` green; `bash bin/requirements-sync.sh --strict --phase 13` exit 0; `bash bin/requirements-sync.sh --require-complete --phase 13` exit 0 after `13-VERIFICATION.md` lands.

### Wave 0 Gaps
- [ ] `tests/phase-13/run.sh` — aggregator (copy `tests/phase-12.2/run.sh`)
- [ ] `tests/phase-13/lib.sh` — `make_bare_repo`/`write_page`/`assert_exit_code`/`cleanup_fixture_repo` (copy 12.2) + NEW `make_fake_verifier` + NEW `make_recording_verifier`
- [ ] `tests/phase-13/fixtures/` — self-contained page+source+raw-file fixtures (marked + unmarked + cloud_safe + local_only + img + missing-raw)
- [ ] No framework install needed — bash is the framework (project convention, verified across phase-07..12.2)

## Security Domain

> `security_enforcement` is not set in config; the relevant security surface here is the **privacy boundary**, which is the phase's central design constraint (FAITH-04 / D-02), already covered above. ASVS categories below limited to what this phase actually touches.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Locator parse via fixed `PROV_RE` (lint.sh:385); unknown locator → operational verdict, never crash. `--verifier` stdout must be parsed defensively (malformed JSON → finding, not exception). |
| V6 Cryptography | no (read-only `content_hash` comparison) | reuse existing SHA-256 hash compare (lint.sh:1225); no new crypto |
| Data egress / privacy boundary | **yes (central)** | §13 fail-closed resolver + single-chokepoint worklist partition (D-02). The whole-phase threat model. |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `local_only` content leaks to a cloud verifier | Information Disclosure | Fail-closed §13 resolution + mechanical worklist partition (D-02); negative test asserts absence from dispatched set |
| Path traversal via crafted `path:` field | Tampering | `path:` comes from in-repo source pages under version control; resolve under repo-root; a `..`-escaping path should be rejected/skipped (add a guard + test) |
| Malicious/malformed `--verifier` stdout | Tampering / DoS | Parse verifier stdout defensively; treat unparseable output as a finding, never `eval` |
| Subprocess command injection via `--verifier <cmd>` | Elevation | Operator-supplied cmd is trusted-by-construction (they run their own machine); do NOT shell-interpolate claim/passage into the command line — pass via stdin only (the D-01 contract) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `bin/lint.sh`'s python primitives are best **copied** (not imported) because the heredoc is not an importable module | Don't Hand-Roll, Pattern 2 | If the planner prefers extracting lint internals into `bin/lib/` shared modules, that's a larger refactor — flag as a scope decision. Low risk; copying is the conservative path and matches how phases 9-12.2 reused lint logic. |
| A2 | `--verifier` contract passes claim/passage via **stdin only** (never argv) | Security Domain | If argv is used, command-injection surface opens. D-01 specifies stdin JSON, so this is well-grounded, not assumed — but the exact framing (one JSON object per claim vs a JSON array batch) is Claude's-discretion. |
| A3 | The §13 dir-default signal is `local-only/` / `cloud-safe/` path segments (per §13 Decision Table rows 1-7) | Code Examples (resolver) | §13 names these example dirs but a real vault may use other conventions; fail-closed default covers the gap. Low risk. |

## Open Questions

1. **Worklist exchange shape for agent-in-the-loop (Claude's discretion, D-01).**
   - Known: "emit worklist → agent writes report" and "emit worklist → `--apply-verdicts <file>`" both satisfy D-01.
   - Unclear: which the planner picks.
   - Recommendation: `--emit-worklist` (JSON to stdout/file) + `--apply-verdicts <file>` (read verdicts back, emit final report) — symmetric with the `--verifier` path and trivially testable with a static verdicts file.

2. **Where the D-08 reflect-tier "audit recommended" suggestion lives (lint vs reflect vs both).**
   - Known: §11.4 Tier-2 `reflect recommended: ...` is the pattern.
   - Recommendation: emit from the lint workflow when high-risk-claim counts cross a threshold (lint already computes stale/epistemic/orphan signals) — cheapest host, no new scan. Keep it a log-line note, non-binding (D-08).

3. **§6 marker placement + AGENTS.md/CLAUDE.md/template mirror (Claude's discretion, D-05).**
   - Known: syntax + slice semantics fixed; must mirror to `schema/AGENTS.template.md` + `CLAUDE.md` (byte-equal via `.githooks/pre-commit` sync) + the canonical fixture (Phase 11-05 regenerate path).
   - Recommendation: add a "Page-marker convention" subsection right after the §6 Locator Types table; use **abstract placeholders only** (CLAUDE.md §3 neutrality rule — `<!-- page: N -->` with `<source-id>`-style examples, no real vault terms). Verify with `bin/check-neutrality.sh`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| python3 | core python block | ✓ | 3.12.3 | — |
| pyyaml | frontmatter parse | ✓ | 6.0.1 | — |
| git | recency selector | ✓ | system | wiki-wide scan if no checkpoint (mirror lint's origin/main fallback) |
| bash | script + tests | ✓ | system | — |
| LLM verifier | verdict step | n/a (pluggable) | — | agent-in-the-loop (default) OR `skipped-privacy`/`insufficient` — never blocks |

**Missing dependencies with no fallback:** none. **Missing with fallback:** none blocking — the verifier is pluggable by design.

## Sources

### Primary (HIGH confidence — live code, verified this session)
- `bin/lint.sh` (2058 lines, `LINT_VERSION=1.3.0`): `parse_frontmatter`:406-422, `PROV_RE`:385-390, `PROVENANCE_PRESENCE_RE`:307, `EPISTEMIC_INLINE_RE`:391, `SOURCE_EXTRA_FIELDS`:382, `EXCLUDE_DIRS`:395, `add_finding`:403-404, source_registry build:977-981, hash-drift:1225-1238, inbound_links:1107-1136, JSON emitter:1911-1922, git-diff helper:463-490.
- `bin/check-privacy.sh` (147 lines): leak-grep only (`PRIVACY_LOCAL_ONLY_RE`:87, `PUBLIC_PATHS`:71, exit 0/1/2) — confirms NO §13 resolver exists.
- `tests/phase-12.2/lib.sh` (`make_bare_repo`, `write_page`):15-69; `tests/phase-12.2/run.sh` aggregator:27-40; `tests/phase-09/lib.sh` `make_fixture_repo`:13-31.
- `AGENTS.md` §6 locator table:410-418, §13 Privacy Decision Table, §11.4 reflect checkpoint.
- `.planning/REQUIREMENTS.md`:135-141 (FAITH-01..04), `.planning/ROADMAP.md`:226-244 (SC-1..6, non-goals), `.planning/config.json` (`nyquist_validation: true`, `branching_strategy: none`).
- `13-DESIGN-NOTES.md` (146 lines) + `13-CONTEXT.md` (D-01..D-16) — authoritative locked design.

### Secondary (MEDIUM)
- `examples/kahneman/sources/*.md` — confirmed `path:` points at raw files NOT on disk (fixture-realism implication).
- `.planning/phases/12.2-local-wiki-write-gate/12.2-VERIFICATION.md` — VERIFICATION.md mirror format.

### Tertiary (LOW)
- none — all claims grounded in live code or locked planning docs.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every primitive verified present in live code; zero-dep constraint confirmed satisfiable.
- Architecture: HIGH — LOCKED in CONTEXT; confirmed against code; two corrections surfaced (no §13 resolver; 4-tuple has no line slot).
- Pitfalls: HIGH — carried verbatim from locked design notes.
- Validation Architecture: HIGH — test harness pattern verified against phase-12.2/09; fake-verifier strategy makes the full pipeline deterministically testable.

**Research date:** 2026-05-31
**Valid until:** ~2026-06-30 (stable in-repo target; re-confirm lint.sh line numbers if it changes — they have already drifted once since CONTEXT was written)
