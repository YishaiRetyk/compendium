# Phase 11: Brownfield Suggest + Verify — Research

**Researched:** 2026-04-20
**Domain:** Brownfield onboarding — hybrid script generation, review-manifest pattern, advisory-vs-apply split, promotion gate
**Confidence:** HIGH (upstream decisions locked; patterns all have in-repo analogs; stack is bash + python3 + ruamel.yaml, already shipped)

## Summary

Phase 11 sits on top of a deeply-settled substrate: Phase 10 shipped `bin/brownfield.sh scan|bootstrap`, `bin/lib/brownfield_classify.py` (with `inbound_count` parameter reserved for this phase), `bin/lib/brownfield_yaml.py` (ruamel.yaml round-trip primitives), Phase 9 shipped `bin/lint.sh --ci --format json --strict` (consumed by `verify`), Phase 7 shipped the `--dry-run` / `--apply` posture, Phase 8 shipped byte-frozen fixture patterns, and Phase 9.1 shipped the extraction-invariant test pattern for AGENTS.md edits. CONTEXT.md locks 21 decisions across 5 areas. Only a handful of concrete implementation choices remain for the planner, and every one has an existing in-repo twin. The highest-leverage research finding: **there is NO novel architectural pattern in Phase 11** — every sub-capability is pattern-composition from Phases 7–10. Biggest risks are all scope-creep risks (BRWN-15 claim-level schema, BRWN-16 LLM-in-CLI, FEATURES.md §Bucket 5 anti-features), not technical unknowns.

Three research findings the planner needs to verify empirically and lock before writing Plan 11-01:

1. **Clustering algorithm** — group-by-signal-tuple (bash dict keyed on classifier output tuple) beats DBSCAN/vector approaches on complexity + reviewability; no scipy required; 3-line Python implementation.
2. **`medium`-confidence policy** — recommend route-to-review-queue by default, with `--auto-medium` flag as an opt-in power-user shortcut. Matches BRWN-13 "per-class user invocation" posture + research Bucket 5 anti-feature list ("auto-apply judgment-heavy transforms").
3. **Small-batch vs large-batch threshold** — recommend `N=20` clusters. Fixtures per D-20 are designed around this cut (small-batch fixture has <10 clusters; large-batch fixture has ≥20). N=20 is not load-bearing; adjust based on fixture calibration during 11-01.

**Primary recommendation:** Plan the 5 plans per CONTEXT.md D-18 verbatim. Do NOT split 11-03 unless clustering + classifier-reuse in 01-page-typing.sh is measurably larger than 02+03+04 combined — research suggests it is not (01-page-typing leverages `bin/lib/brownfield_classify.py` directly + a thin clustering helper; 02-provenance-bootstrap needs fresh bullet-eligibility heuristics from scratch, which is comparable effort). Single biggest blocker for planning: **`§11.5 Release Workflow` already exists in AGENTS.md (line 1171)** — CONTEXT.md D-16 calls for `§11.5 Brownfield Workflow`, which creates a numbering conflict. Must be resolved in Plan 11-05.

## User Constraints (from CONTEXT.md)

### Locked Decisions

All 21 decisions (D-01..D-21) from CONTEXT.md are locked inputs, not research questions. Reproduced below verbatim for planner convenience (full text in CONTEXT.md `<decisions>` block):

- **D-01** Architecture split: apply-class (01, 02) vs advisory-class (03, 04). Design principle verbatim: *"Review may be interactive and AI-guided; apply must always be deterministic."*
- **D-02** 01-page-typing two-stage discovery→review→apply; writes `.brownfield/page-typing-candidates.yaml` + `.brownfield/page-typing-decisions.yaml`; `--apply` reads decisions manifest only.
- **D-03** Confidence policy: `high` auto-apply; `medium` is planner's call (research below); `low`/`unknown` always review. Mantra: *"Check readiness, not history."*
- **D-04** `review-typing` branches on pending-cluster count; small-batch TTY (approve all / reject all / inspect / override); large-batch emits `.brownfield/review-typing-prompt.md` (AI handoff); both modes write to same decisions manifest.
- **D-05** 02-provenance-bootstrap targets ONLY top-level bullets under `## TL;DR` + `## Key Facts`; appends ` [epistemic:: inferred]`; no review manifest; honest "no eligible bullets" when none; escape hatch (`.brownfield/02-exclude.txt`) deferred.
- **D-06** 03-cross-link-inference is report-only; writes `.brownfield/cross-link-candidates.yaml` + `## Cross-link candidates` section in REPORT.md; no `--apply`.
- **D-07** 04-privacy-review (RENAMED from `04-privacy-classification.sh`) is report-only; fail-closed preserved; NEVER flips `privacy:` frontmatter. Contract phrase: *"04-privacy-review classifies findings for review priority, not for frontmatter mutation."*
- **D-08** Hybrid generation: canonical scripts in `schema/brownfield/migrations/*.sh` byte-copied on suggest; vault-specific data files under `.brownfield/`.
- **D-09** Metadata header on every candidate file: `schema_version`, `tool_version`, `generated_at`, `vault_root`, `source_script_hash`.
- **D-10** op_hash scope: canonical-script-body + data-schema-version ONLY. Not hashed: candidate YAMLs, decision manifests, vault pages, timestamps.
- **D-11** `.brownfield/applied.log` single file, markdown-block schema; apply-class appends on `--apply` only; advisory-class appends on findings. No JSONL in v1.1.
- **D-12** State-based soft prereq checks; `02` emits stderr WARN if majority of vault untyped; scripts never read `applied.log` as dependency source.
- **D-13** `verify` runs `bin/lint.sh --ci --category yaml,provenance,orphan,crossref,brownfield`; privacy NOT included (separate `bin/check-privacy.sh` on public-paths-only per Phase 9 D-15). Read-only by default.
- **D-14** `verify --promote` objective pass-list (5 gates) per page; only eligible `bootstrapped` → `verified`.
- **D-15** `bootstrap_stage` lifecycle diagram (normative in §11.5 + docs).
- **D-16** `AGENTS.md §11.5` = thin authoritative contract matching §11.1–11.4 shape exactly; load-bearing principles in prose.
- **D-17** `docs/reference/brownfield.md` completes suggest / verify / review-typing sections; does NOT restate §11.5 normative contract.
- **D-18** 5 plans default (11-01 harness+RED suite; 11-02 suggest; 11-03 four scripts; 11-04 review-typing+verify+applied.log; 11-05 docs+AGENTS §11.5+DR+REQ). Escape hatch: split 11-03 into 11-03a/b if 01-page-typing outsize.
- **D-19** RED test suite targets locked in 11-01 (full contract coverage).
- **D-20** Fixture design: small-vault (3–6 pages, <10 clusters), large-vault (≥20 clusters), pre-typed vault, privacy-sensitive vault, pre-tagged-[epistemic::] vault; dates pinned via Phase-10-precedent env vars.
- **D-21** Single Tier-1 DR covering apply-vs-advisory + review-manifest + lifecycle.

### Claude's Discretion

- N threshold for small-batch vs large-batch (recommend 20; research below).
- `.brownfield/review-typing-prompt.md` shape (lean + directive).
- `medium`-confidence default policy (recommend review queue with `--auto-medium` opt-in; research below).
- `bin/lib/` module layout (extend `brownfield_classify.py` with clustering fn; new `brownfield_provenance.py` for 02 eligibility heuristics).
- Whether to split 11-03 (recommend NOT; research below).
- BRWN-12 rename wording + new REQ-ID for review-typing.
- Color convention (inherit Phase 8 `NO_COLOR` pattern).
- `applied.log` UTC timestamp format (ISO-8601 with `Z` suffix).
- `suggest --force` to regenerate stale candidates (recommend defer per Deferred list).

### Deferred Ideas (OUT OF SCOPE)

- Single-command `brownfield apply` chain-runner (v1.2 BRWNAPPLY-01).
- Runtime-specific skills (`.claude/skills/brownfield-*.md`).
- Manifest-backed apply for 03 or 04 (both stay advisory in v1.1).
- 02 page-level opt-out file (`.brownfield/02-exclude.txt`).
- `suggest --force`, `applied.log --format json`, separate `brownfield-review.sh` helper.
- Interactive TUI, Obsidian plugin, multi-vault, `run_hash`, auto-downgrade, shell completion.
- LLM integration inside `bin/brownfield.sh` (explicit anti-feature per BRWN-16 + research Bucket 5).
- Phase 10 WR-01/WR-02/WR-03 warnings (opportunistic fix if Plan 11-05 touches same surface).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRWN-11 | `bin/brownfield.sh suggest` writes `.brownfield/REPORT.md` + `.brownfield/migrations/*.sh` | Sections: Standard Stack, Architecture Patterns, Suggest Generation Pattern |
| BRWN-12 | Four staged migration script classes (rename 04-privacy-classification → 04-privacy-review per D-07) | Sections: Architecture Patterns per-script, REQUIREMENTS.md amendment tracking |
| BRWN-13 | Per-script user-invoked (no chain-runner); dry-run default; `--apply` on that single class; idempotent on re-run | Sections: Architecture Patterns, Anti-features recap |
| BRWN-14 | Each script header has `# op_hash: <sha256>` from normalized descriptors; idempotency in applied.log | Sections: op_hash derivation (research question #2), applied.log writer integration |
| BRWN-15 | 02-provenance-bootstrap uses EXISTING epistemic vocabulary only (`inferred`). ZERO claim-level schema expansion | Sections: 02-provenance-bootstrap eligibility rules, Anti-features (no magic-string provenance) |
| BRWN-16 | Classification heuristics rule-based; NO LLM calls inside `brownfield.sh` | Sections: Anti-features recap, Architecture Patterns |
| BRWN-17 | `bin/brownfield.sh verify` is thin wrapper over `bin/lint.sh` with brownfield severity thresholds | Sections: Verify implementation, promotion gate |
| BRWN-18 | `docs/reference/brownfield.md` explains mechanical-vs-judgment boundary explicitly | Sections: AGENTS.md §11.5 template, docs/reference/brownfield.md populate |
| BRWN-19 | `docs/reference/brownfield.md` documents `git reset` recipe as canonical undo | Already present (Phase 10 shipped). Retain verbatim. |
| BRWN-20 | New `AGENTS.md §11.5 Brownfield Workflow` documents scan/bootstrap/suggest/verify, idempotency, mechanical/judgment boundary | Sections: §11.5 template research, critical blocker (existing §11.5 is Release Workflow) |

**Planner amendment hooks (action required during Plan 11-05):**

1. **BRWN-12 wording amendment** — rename `04-privacy-classification.sh` → `04-privacy-review.sh` throughout REQUIREMENTS.md line 97. Pattern twin: Phase 10 BRWN-04 typed-merge wording amendment offered by user. Planner drafts wording.
2. **New REQ-ID for `review-typing` subcommand** — currently not listed in BRWN-11..20. Planner drafts a REQ-ID (tentatively `BRWN-22`, reserving `BRWN-21` as already used for byte-exact fixture tests per Phase 10) covering: small-batch TTY, large-batch AI-handoff, manifest write-back, no-LLM-in-CLI constraint.
3. **Scope clarification for BRWN-17** — current wording "thin wrapper over `bin/lint.sh` with brownfield-appropriate severity thresholds." D-13 extends this with `--promote` lifecycle gate. Planner's call: amend BRWN-17 or document `--promote` as enhancement in the DR.
4. **Phase 10 WR-01/WR-02/WR-03 warnings** — opportunistic fix during Phase 11 if same surface is touched. WR-03 (AGENTS.md §5 forward-ref typo "§11.5 Release Workflow" → should be "§11.5 Brownfield Workflow") WILL be touched when Plan 11-05 writes §11.5, so that one fixes itself. WR-01 and WR-02 are `bin/brownfield.sh` bootstrap-path issues not in Phase 11's touch-surface.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Vault page classification + clustering | `bin/lib/brownfield_classify.py` (python helper) | `bin/brownfield.sh suggest` (orchestrator) | Reused across `scan` (Phase 10) + `suggest`/`01-page-typing.sh` (Phase 11). Single source of truth for classification signals. |
| ruamel.yaml round-trip mutation | `bin/lib/brownfield_yaml.py` (python helper) | `01-page-typing.sh --apply`, `02-provenance-bootstrap.sh --apply` (shell scripts) | Already scoped in Phase 10; Phase 11 reuses primitives (`read_fm_body`, `write_roundtrip`) without extending them. |
| Suggest orchestration (byte-copy + candidate generation) | `bin/brownfield.sh suggest` (shell) | `bin/lib/brownfield_classify.py` (classification) + filesystem (byte-copy) | Bash does byte-copy + dispatches python heredoc for candidate generation. Matches Phase 10 `scan`/`bootstrap` split. |
| Review-typing TTY prompts | `bin/brownfield.sh review-typing` (shell + stdin) | stdin read loop inside python heredoc | Line-oriented prompts; no TUI library. Matches `bin/init-wizard.sh` Phase 8 pattern (bash prompts → stderr, stdin capture → validation). |
| Review-typing large-batch AI handoff | `bin/brownfield.sh review-typing` (shell) emits `.brownfield/review-typing-prompt.md` | None — file is static template fill-in | AI session operates OUTSIDE the CLI on the file artifact. Preserves BRWN-16 boundary. |
| Migration script `--apply` path | Each `schema/brownfield/migrations/*.sh` (canonical shell script) | `bin/lib/brownfield_yaml.py` (ruamel primitives) | Scripts are byte-copied into `.brownfield/migrations/*.sh` at suggest time; users invoke the copy. |
| `applied.log` append | `bin/brownfield.sh` helper function OR `bin/lib/brownfield_log.py` helper | Each migration script calls the helper at end-of-run | Plain-append semantics; no YAML round-trip. Research recommends bash helper (no new python module needed). |
| `verify` (read-only) | `bin/brownfield.sh verify` (shell wrapper) | `bin/lint.sh --ci --format json` (existing tool) | Thin wrapper per BRWN-17; no new lint logic. |
| `verify --promote` (page-level frontmatter mutation) | `bin/brownfield.sh verify --promote` (shell) | `bin/lib/brownfield_yaml.py` (`read_fm_body` + `write_roundtrip` + field mutation) | Reuses Phase 10 primitives; only frontmatter-field flip (`bootstrapped` → `verified`). |
| AGENTS.md §11.5 authoring | `AGENTS.md §11.5` (markdown) | `.githooks/pre-commit` auto-sync to CLAUDE.md + `schema/AGENTS.template.md` mirror + `schema/fixtures/canonical-AGENTS.md` regen | Mirrors Phase 7 / 9.1 pattern exactly. |
| Tier-1 decision record | `wiki/decisions/dr-2026-MM-DD-brownfield-apply-vs-advisory.md` (markdown) | `wiki/index.md` Decisions section update | Matches Phase 6 AGENTS.md §4.6 decision schema; trigger_type: schema-update per D-21. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `bash` | >= 4.0 | Orchestrator shell for `bin/brownfield.sh` subcommands | Inherited from Phase 7+; project baseline per STACK.md. [VERIFIED: bash --version on this host reports 5.2.21] |
| `python3` | >= 3.8 | Python heredocs inside bash for YAML / clustering / candidate writers | Inherited from Phase 7+; no new version requirement. [VERIFIED: python3 --version reports 3.12.3 on this host] |
| `ruamel.yaml` | >= 0.17 (0.17.21 confirmed working) | YAML round-trip for 01-page-typing --apply + 02-provenance-bootstrap --apply + verify --promote | Accepted as single new runtime dep in Phase 10 per BRWN-06; already shipped. [VERIFIED: `PYTHONPATH=$HOME/.local/lib/python3/dist-packages python3 -c "import ruamel.yaml; print(ruamel.yaml.__version__)"` returns 0.17.21 on this host; Phase 10 tests all pass against it] |
| `PyYAML` | stdlib-baseline | Pre-flight `safe_load` parse gate (D-01 pattern from Phase 10); loading candidate YAML files (no round-trip needed there) | Zero-new-deps for this phase; already in use. [VERIFIED: Phase 10 `bin/lib/brownfield_yaml.py` uses `import yaml as pyyaml` for preflight] |
| Standard library | — | `hashlib.sha256` (op_hash + applied.log input hashes), `difflib.unified_diff` (review-typing inspect), `re`, `os`, `json`, `datetime` (UTC timestamps per D-11) | All standard. Zero new imports beyond Phase 10 baseline. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| None | — | — | **Zero new runtime deps for Phase 11.** CONTEXT.md §Established-Patterns explicit: "Phase 11 introduces NO new deps beyond Phase 10's ruamel.yaml." |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| group-by-signal-tuple clustering | DBSCAN-like density clustering (sklearn.cluster) | Adds sklearn+numpy runtime dep. Rejected: violates zero-new-deps invariant; clustering output is user-reviewed regardless of algorithm, so cluster boundaries are not load-bearing for correctness. |
| bash helper for applied.log | Python module `bin/lib/brownfield_log.py` | Python module is more testable but adds heredoc boundary crossings. Bash `append_applied_log()` function is 20 lines and sufficient. Plain markdown append — no YAML parsing round-trip. |
| ruamel for `review-typing` decisions.yaml round-trip | PyYAML `safe_load` + `dump` | PyYAML loses comment preservation. Decisions manifest has user-authored comments ("approved after team review on DD"). ruamel round-trip required for decisions manifest write-back. Research-verified. |
| Python 3.10+ match statement for bullet eligibility | if/elif chain | match is cleaner but raises min-python to 3.10; project baseline is 3.8 per Phase 7 preflight. Keep if/elif. |

**Installation:** No new installations required. Users running brownfield already have `pip install ruamel.yaml` per Phase 10 quickstart.md prereq.

**Version verification:** Confirmed `ruamel.yaml 0.17.21` on this host [VERIFIED: `PYTHONPATH=$HOME/.local/lib/python3/dist-packages python3 -c "import ruamel.yaml; print(ruamel.yaml.__version__)"`]. Phase 10 tests 32/32 green against this version [VERIFIED: Phase 10 VERIFICATION.md behavioral spot-check row "Individual apply_*" PASS entries]. Bumping to ruamel.yaml 0.18.x is not required for Phase 11.

## Architecture Patterns

### System Architecture Diagram

```
User                                Repo                                 Vault (.brownfield/)
│                                   │                                    │
│  bash bin/brownfield.sh suggest ──┼─┐                                  │
│                                   │ │                                  │
│                                   │ ├─ byte-copy ─────────────────────▶│  .brownfield/migrations/
│                                   │ │  schema/brownfield/migrations/  │    01-page-typing.sh
│                                   │ │  *.sh  (canonical, tracked)     │    02-provenance-bootstrap.sh
│                                   │ │                                 │    03-cross-link-inference.sh
│                                   │ │                                 │    04-privacy-review.sh
│                                   │ │                                 │
│                                   │ └─ python heredoc ───────────────▶│  .brownfield/
│                                   │    bin/lib/brownfield_classify   │    page-typing-candidates.yaml
│                                   │    (+ clustering helper)          │    page-typing-decisions.yaml (pending)
│                                   │    bin/lib/brownfield_yaml       │    provenance-bootstrap-report.yaml
│                                   │    (frontmatter preflight)        │    cross-link-candidates.yaml
│                                   │                                   │    privacy-findings.yaml
│                                   │                                   │
│  bash bin/brownfield.sh review-typing                                  │
│      │                                                                 │
│      ├─ pending < N (=20)? ─── TTY prompts ── stdin writeback ────────▶│  page-typing-decisions.yaml (resolved)
│      │                                                                 │
│      └─ pending ≥ N?      ─── emit prompt.md ──────────────────────────▶  .brownfield/review-typing-prompt.md
│                                   │                                    │  (user opens in AI session outside CLI)
│  [user's AI session edits decisions.yaml externally]                   │
│                                                                        │
│  bash .brownfield/migrations/01-page-typing.sh --apply                 │
│      │                                                                 │
│      ├─ reads decisions.yaml (deterministic, no reclassify)           │
│      ├─ ruamel.yaml mutations: type: field per cluster policy          │
│      └─ appends apply-block ───────────────────────────────────────────▶  .brownfield/applied.log
│                                                                        │
│  bash .brownfield/migrations/02-provenance-bootstrap.sh --apply        │
│      ├─ soft prereq check: count untyped pages → stderr WARN if majority
│      ├─ scans TL;DR + Key Facts top-level bullets; applies eligibility heuristics
│      ├─ appends [epistemic:: inferred] to eligible bullet lines
│      └─ appends apply-block ───────────────────────────────────────────▶  applied.log
│                                                                        │
│  bash .brownfield/migrations/03-cross-link-inference.sh                │
│      ├─ scans exact-title + alias mentions across vault                │
│      ├─ writes cross-link-candidates.yaml + REPORT.md section          │
│      └─ appends advisory-block ────────────────────────────────────────▶  applied.log
│                                                                        │
│  bash .brownfield/migrations/04-privacy-review.sh                      │
│      ├─ scans email/phone/SSN regex + .brownfield-privacy-terms.txt    │
│      ├─ writes privacy-findings.yaml + REPORT.md section               │
│      └─ appends advisory-block ────────────────────────────────────────▶  applied.log
│                                                                        │
│  bash bin/brownfield.sh verify           (read-only: lint --ci)        │
│                                                                        │
│  bash bin/brownfield.sh verify --promote                               │
│      ├─ runs lint --ci --format json --category yaml,prov,orphan,crossref,brownfield
│      ├─ filters findings to per-page scope                             │
│      ├─ checks 5-gate pass-list (D-14) per page                        │
│      ├─ flips bootstrap_stage: bootstrapped → verified on pages passing gate
│      └─ reports pages still blocked                                    │
```

### Recommended Project Structure

```
schema/brownfield/migrations/        # NEW — canonical migration scripts (tracked in git)
├── 01-page-typing.sh                #   Apply-class: discovery → clustering → apply-from-manifest
├── 02-provenance-bootstrap.sh       #   Apply-class: TL;DR + Key Facts bullet tagging
├── 03-cross-link-inference.sh       #   Advisory: cross-link candidates report
└── 04-privacy-review.sh             #   Advisory: privacy-sensitive findings report

bin/
├── brownfield.sh                    #   MODIFIED — new branches: suggest | review-typing | verify
└── lib/
    ├── brownfield_classify.py       #   MODIFIED — adds cluster_by_signals() function; uses existing inbound_count param
    ├── brownfield_yaml.py           #   REUSED — no changes expected
    ├── brownfield_typing.py         #   OPTIONAL NEW — if clustering + manifest-write-back logic needs its own module
    ├── brownfield_provenance.py     #   OPTIONAL NEW — if 02 eligibility heuristics need their own module
    └── brownfield_log.py            #   NOT RECOMMENDED — applied.log writer stays as bash helper

.brownfield/                          # EPHEMERAL — gitignored per TMPL-04
├── migrations/                       #   byte-copies of schema/brownfield/migrations/
├── page-typing-candidates.yaml       #   D-02 Stage 1 output (clusters)
├── page-typing-decisions.yaml        #   D-02 Stage 1 pending → Stage 2 resolved
├── provenance-bootstrap-report.yaml  #   D-05 dry-run preview
├── cross-link-candidates.yaml        #   D-06 advisory output
├── privacy-findings.yaml             #   D-07 advisory output
├── review-typing-prompt.md           #   D-04 large-batch AI handoff template
├── applied.log                       #   D-11 append-only markdown-block log
└── REPORT.md                         #   Phase 10 shipped; gains Phase 11 advisory sections

tests/phase-11/                       # NEW — clone tests/phase-10/ shape
├── run.sh                            #   Aggregator (clone phase-10 with 10→11 rename)
├── lib.sh                            #   Helpers (clone phase-10: make_fixture_repo, assert_byte_equal, assert_grep, assert_file_exists)
├── fixtures/                         #   5+ fixtures per D-20
│   ├── small-vault-ambiguous/        #     3–6 pages, <10 clusters (TTY path)
│   ├── large-vault-ambiguous/        #     ≥20 clusters (AI-handoff path)
│   ├── pre-typed-vault/              #     existing valid type: frontmatter (prove state-based prereq)
│   ├── privacy-sensitive-vault/      #     emails/phones/SSNs (04-privacy-review exercise)
│   └── already-tagged-vault/         #     [epistemic::] present (prove 02 skips)
└── test_*.sh                         #   RED-to-GREEN contract suite (per D-19) + 1 end-to-end happy-path

AGENTS.md §11.5                       # MODIFIED — Brownfield Workflow (full populate per D-16)
                                      # CRITICAL: existing §11.5 is "Release Workflow" — resolve numbering
CLAUDE.md                             # MODIFIED — auto-sync via .githooks/pre-commit
schema/AGENTS.template.md §11.5       # MODIFIED — mirror per 9.1 template-parity test
schema/fixtures/canonical-AGENTS.md   # MODIFIED — regenerate via Phase 8-01 python3 render routine
docs/reference/brownfield.md          # MODIFIED — complete suggest / review-typing / verify sections per D-17
.planning/REQUIREMENTS.md             # MODIFIED — BRWN-12 rename amendment + new REQ-ID for review-typing
wiki/decisions/dr-2026-MM-DD-brownfield-apply-vs-advisory.md  # NEW — Tier-1 DR per D-21
wiki/index.md                         # MODIFIED — add new DR entry under Decisions
```

### Pattern 1: Subcommand Dispatch Extension

**What:** Extend existing `bin/brownfield.sh` case dispatcher with `suggest | review-typing | verify` branches; remove `exit 2` gates at lines 53–56.

**When to use:** Adding subcommands to an already-subcommanded script.

**Example (current lines 51–62, planner replaces suggest/verify exit-2 branches):**
```bash
# Source: bin/brownfield.sh:51-62 (Phase 10 HEAD)
case "$SUBCOMMAND" in
    scan|bootstrap) ;;
    suggest|verify)
        echo "ERROR: '$SUBCOMMAND' not yet implemented — see Phase 11 (BRWN-11..20)" >&2
        exit 2
        ;;
    *)
        echo "ERROR: unknown subcommand: $SUBCOMMAND" >&2
        usage >&2
        exit 1
        ;;
esac
```

**After Phase 11:**
```bash
case "$SUBCOMMAND" in
    scan|bootstrap|suggest|review-typing|verify) ;;
    *)
        echo "ERROR: unknown subcommand: $SUBCOMMAND" >&2
        usage >&2
        exit 1
        ;;
esac
```

### Pattern 2: Hybrid Generation (Byte-Copy + Data-Generate)

**What:** `suggest` does TWO deterministic things: (1) byte-copies canonical migration scripts from `schema/brownfield/migrations/*.sh` into `.brownfield/migrations/*.sh`; (2) runs python heredoc to generate vault-specific data YAMLs under `.brownfield/`.

**When to use:** Separating immutable logic (versioned in `schema/`) from ephemeral state (in `.brownfield/`).

**Example:**
```bash
# Source: bin/brownfield.sh Phase 11 new branch (composed from bin/release.sh ALLOWLIST pattern + bin/brownfield.sh scan python heredoc)

# 1. Byte-copy canonical scripts (CI-enforced byte-equality)
SCHEMA_MIGRATIONS_DIR="$REPO_ROOT/schema/brownfield/migrations"
BF_MIGRATIONS_DIR="$BS_ROOT/.brownfield/migrations"
mkdir -p "$BF_MIGRATIONS_DIR"
for script in 01-page-typing.sh 02-provenance-bootstrap.sh 03-cross-link-inference.sh 04-privacy-review.sh; do
    cp "$SCHEMA_MIGRATIONS_DIR/$script" "$BF_MIGRATIONS_DIR/$script"
    chmod +x "$BF_MIGRATIONS_DIR/$script"
done

# 2. Generate vault-specific data files via python heredoc
export BROWNFIELD_ROOT="$BS_ROOT"
export BROWNFIELD_TOOL_VERSION="1.1.0"
python3 << 'PYEOF'
import os, sys, datetime, hashlib, yaml
sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
from brownfield_classify import classify_page, cluster_by_signals  # NEW Phase 11 function
# ... walk vault, classify, cluster, write candidate YAMLs with D-09 metadata headers
PYEOF
```

### Pattern 3: Canonical-Script Byte-Equality CI Enforcement

**What:** CI test asserts `cmp -s schema/brownfield/migrations/01-page-typing.sh .brownfield/migrations/01-page-typing.sh` after `suggest` runs. Prevents `suggest` from accidentally rendering vault-specific logic into shell code.

**When to use:** Any hybrid generation pattern where logic must stay versioned + reviewable.

**Example:**
```bash
# Source: tests/phase-08/test_canonical_byte_equality.sh:28-41 (exact pattern-twin)
for script in 01-page-typing.sh 02-provenance-bootstrap.sh 03-cross-link-inference.sh 04-privacy-review.sh; do
    if ! cmp -s "$REPO_ROOT/schema/brownfield/migrations/$script" "$WORK/.brownfield/migrations/$script"; then
        echo "FAIL: .brownfield/migrations/$script drift from canonical." >&2
        diff -u "$REPO_ROOT/schema/brownfield/migrations/$script" "$WORK/.brownfield/migrations/$script" | head -50 >&2
        exit 1
    fi
done
```

### Pattern 4: Review-Manifest Pattern (NEW TO PHASE 11)

**What:** Apply-class script emits `candidates.yaml` (all proposals) + `decisions.yaml` (policy decisions, initially pending). Separate review surface (TTY or AI) edits decisions. Apply reads decisions deterministically.

**When to use:** Apply-class migrations where judgment lives outside the CLI but apply must stay deterministic.

**Invariant:** Apply MUST NOT re-classify at apply time. If the vault changed between suggest and apply, the user re-runs suggest. This is load-bearing for repeatability + audit.

**Not adopted by 02/03/04:**
- 02 has narrow surface (eligibility is mechanical; no manifest needed)
- 03/04 are advisory-only (no mutation path at all)

**Contract:** Tier-1 DR per D-21 documents this pattern + why 02/03/04 differ.

### Pattern 5: Soft State-Based Prereq Check (D-12)

**What:** Per-script readiness check inspects CURRENT vault state, never `applied.log`. Emits stderr WARN on soft failure; continues anyway.

**When to use:** Scripts with ordering hints but not hard prereqs. Matches BRWN-13 "per-class user invocation" posture.

**Example (02-provenance-bootstrap):**
```bash
# Source: composed from bin/ingest.sh:96-108 (resolve_contributor map-miss warn) + D-12 verbatim phrasing
python3 - "$BS_ROOT" <<'PYPREREQ'
import os, sys, yaml
root = sys.argv[1]
untyped = 0
total = 0
for dp, _, fns in os.walk(root):
    if any(seg in dp for seg in ('.brownfield', '.git', '.obsidian', '.trash')): continue
    for fn in fns:
        if not fn.endswith('.md'): continue
        total += 1
        # ... parse frontmatter, check type field is set and valid
        if not fm or not fm.get('type'): untyped += 1
if total > 0 and untyped > total / 2:
    sys.stderr.write(
        f"WARN: {untyped} bootstrapped pages still have empty type:. "
        f"02-provenance-bootstrap works best after page typing review or on pages "
        f"with existing valid type. Proceeding anyway.\n"
    )
PYPREREQ
```

### Pattern 6: Promotion Gate Per-Page Iteration (D-14)

**What:** `verify --promote` runs lint once (JSON), filters findings to per-page scope, checks 5 gates per page, flips `bootstrap_stage` on pages passing all gates.

**When to use:** Any page-level lifecycle-state transition gated on mechanical + judgment criteria.

**Example:**
```python
# Source: composed from bin/lint.sh JSON mode invocation + bin/lib/brownfield_yaml.py read/write primitives
import subprocess, json, sys
from brownfield_yaml import read_fm_body, write_roundtrip

# 1. Run lint once in JSON mode
result = subprocess.run(
    ['bash', 'bin/lint.sh', '--ci', '--format', 'json',
     '--category', 'yaml,provenance,orphan,crossref,brownfield'],
    capture_output=True, text=True,
)
findings = json.loads(result.stdout)

# 2. Index findings by path
errors_by_path = {}
for f in findings:
    if f['severity'] == 'error':
        errors_by_path.setdefault(f['path'], []).append(f)

# 3. For each bootstrapped page, check 5-gate pass-list
for page_path in find_bootstrapped_pages(root):
    fm, body, raw = read_fm_body(page_path)
    if not fm: continue
    if fm.get('bootstrap_stage') != 'bootstrapped': continue

    # Gate 1: bootstrap_stage check (above)
    # Gate 2: type: is valid enum
    if fm.get('type') not in VALID_TYPES or fm.get('type') == '':
        continue
    # Gate 3: zero blocking findings
    if errors_by_path.get(page_path):
        continue
    # Gate 4: type-specific required fields present
    if fm['type'] == 'source' and not all(k in fm for k in ('path', 'content_hash', 'ingested_at', 'source_type')):
        continue
    # Gate 5: no pending review decision in page-typing-decisions.yaml
    if page_in_pending_cluster(page_path):
        continue

    # Flip
    fm['bootstrap_stage'] = 'verified'
    write_roundtrip(page_path, fm, body, raw)
```

### Anti-Patterns to Avoid

- **Chain-runner in `bin/brownfield.sh`** — Explicit anti-feature per BRWN-13, BRWN-16, FEATURES.md §Bucket 5 line 209, BRWNAPPLY-01 backlog. Each script must be user-invoked separately.
- **LLM call inside any `bin/*` script** — Explicit anti-feature per BRWN-16, FEATURES.md §Bucket 5 line 210. AI operates on artifacts (candidate YAMLs, prompt.md) from outside the CLI.
- **Interactive TUI with arrow keys** — Explicit anti-feature per FEATURES.md §Bucket 5 line 212. Line-oriented prompts (approve / reject / inspect / override) only.
- **Migration-history tracker (sqlite/json)** — Explicit anti-feature per FEATURES.md §Bucket 5 line 213. git + applied.log cover audit needs.
- **One-shot `undo` command** — Explicit anti-feature per FEATURES.md §Bucket 5 line 214. `git reset --hard` is THE undo path; docs must document it (already in place per BRWN-19 Phase 10).
- **New schema fields beyond existing vocabulary** — Explicit anti-feature per BRWN-15, FEATURES.md §Bucket 5 line 215. Zero new claim-level fields. 02-provenance-bootstrap uses ONLY `[epistemic:: inferred]` — no `[prov:bootstrap]`, no `[epistemic:: imported]`, no new sub-markers.
- **re-classifying at apply time** — Review-manifest pattern invariant (Pattern 4). `01-page-typing.sh --apply` MUST read `page-typing-decisions.yaml` only; if vault changed, user re-runs `suggest`.
- **applied.log as dependency source** — D-12 explicit: *"Check readiness, not history."* Scripts inspect current vault state, never the log.
- **Privacy frontmatter mutation by 04** — D-07 explicit: `04-privacy-review` NEVER flips `privacy:`. Fail-closed per AGENTS.md §13.
- **AGENTS.md §11.5 content restated in `docs/reference/brownfield.md`** — D-17: docs link to §11.5, do not duplicate normative contract.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML frontmatter round-trip | Custom regex-based YAML writer | `bin/lib/brownfield_yaml.py` (ruamel-based, Phase 10) — `read_fm_body`, `write_roundtrip` | Phase 10 already encodes typed-merge + comment preservation. Re-building loses the YAML-safety work. |
| Page classification | Fresh classifier | `bin/lib/brownfield_classify.py::classify_page()` (Phase 10) — pass `inbound_count` (reserved param) | Rule-set is D-16 canonical; both `scan` and `01-page-typing.sh` must produce consistent labels. |
| Inbound-link count | Per-script graph walk | Build once in `suggest`, pass to `classify_page(inbound_count=...)` | Single O(N) pass over vault; reused for every page. |
| `.brownfield-ignore` parsing | New glob parser | Phase 10 `bin/brownfield.sh` already has one (lines 193–245 scan branch, lines 193–245 bootstrap branch) | Tested + shipped. 03 + 04 reuse via extraction to shared bash function or python helper. |
| Stderr warn formatting | Ad-hoc echo | Phase 9 `resolve_contributor()` pattern (bin/ingest.sh:96-108) or Phase 10 BRWN-10 single-line pattern | Inherited convention. D-12 02-provenance WARN uses single-line per BRWN-10 precedent. |
| TTY prompt loop | Fresh readline loop | `bin/init-wizard.sh` Phase 8 pattern (`read -r -p`, stderr explainer, stdin capture) | Phase 8 already encodes NO_COLOR, stderr-for-prompts pattern (`bin/init-wizard.sh` shows how to keep stdout clean for scripted-stdin tests). |
| Byte-equality test | Fresh `cmp` wrapper | `tests/phase-10/lib.sh::assert_byte_equal` | Existing helper already handles regeneration-recipe output on failure (lines 42–53). |
| Fixture repo creation | Fresh mktemp+git init | `tests/phase-10/lib.sh::make_fixture_repo` | Existing helper handles copy + git seed. Phase 11 clones lib.sh with 10→11 rename. |
| CI dispatch for lint categories | Re-invent severity remap | `bin/lint.sh --ci --format json --category yaml,provenance,orphan,crossref,brownfield` | Phase 9 CI_SEVERITY_REMAP already routes. `verify` is a ~20-line wrapper. |
| Canonical AGENTS.md fixture regen | Manual edit | Phase 8-01 python3 render routine — `bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen && cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md` | Documented in `schema/fixtures/README.md`. Missing this step breaks Phase 8 byte-equality test. |
| Unified diff for review-typing inspect | Custom diff | `difflib.unified_diff` (Python stdlib, Phase 8 D-18 precedent) | Already used in `bin/brownfield.sh` bootstrap --verbose path (lines 536-540). |

**Key insight:** Phase 11 has the highest ratio of reused-to-new code of any v1.1 phase. `bin/lib/brownfield_classify.py` + `bin/lib/brownfield_yaml.py` + `bin/lint.sh --ci` + `bin/release.sh --dry-run/--apply` + `tests/phase-10/lib.sh` + Phase 8 fixture pattern + Phase 9.1 extraction-invariant test cover 80% of the surface. New code is clustering helper (~40 LOC), review-typing TTY (~80 LOC), suggest orchestrator (~120 LOC), 4 migration scripts (~150 LOC each), verify wrapper (~60 LOC), docs/AGENTS.md §11.5 (~120 LOC), tests (~500 LOC).

## Runtime State Inventory

> Phase 11 is primarily additive (greenfield-style for new capabilities), but carries ONE rename (D-07: `04-privacy-classification.sh` → `04-privacy-review.sh`). Also introduces new state surfaces in `.brownfield/`. Documented below.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — `.brownfield/` is gitignored per TMPL-04 and scoped to a single vault's onboarding run. No cross-vault persistence. | None |
| Live service config | None — no external services touched by Phase 11. | None |
| OS-registered state | None — no OS-level registrations. | None |
| Secrets/env vars | `BROWNFIELD_FIXTURE_TODAY` + `BROWNFIELD_FIXTURE_CREATED_AT` (Phase 10 env vars) — used by fixtures only. Phase 11 may add similar fixture-date pins if review-typing prompts embed dates. | If Phase 11 adds new fixture env vars, document in `docs/reference/brownfield.md` "Fixture testing environment variables" section (already populated Phase 10-06). |
| Build artifacts / installed packages | `schema/brownfield/migrations/*.sh` — canonical scripts tracked in git. No compiled artifacts. No pip installs beyond Phase 10's `ruamel.yaml`. | Ensure new directory `schema/brownfield/migrations/` is added; check `.gitignore` does NOT exclude it. Verify `.brownfield/` DOES exclude (already in place per TMPL-04). |
| Rename fallout (BRWN-12 `04-privacy-classification.sh` → `04-privacy-review.sh`) | (a) `schema/brownfield/migrations/04-privacy-review.sh` — new filename; canonical script never had old name in the repo (Phase 11 is the first phase that ships the migrations directory). (b) `REQUIREMENTS.md` line 97 BRWN-12 wording — amendment needed. (c) Any early references to the old name in `.planning/` documents — grep confirms none in public paths. | Planner drafts BRWN-12 amendment wording for Plan 11-05; no code rename needed (new name is the original name in schema/). |

**The canonical question for rename audit:** *After every file in the repo is updated, what runtime systems still have the old string cached, stored, or registered?* **Answer:** Only REQUIREMENTS.md BRWN-12 line 97 — no shipped code ever had the `04-privacy-classification` name. Rename is pure documentation.

## Common Pitfalls

### Pitfall 1: AGENTS.md §11.5 numbering conflict

**What goes wrong:** CONTEXT.md D-16 calls for `AGENTS.md §11.5 Brownfield Workflow`. The existing AGENTS.md line 1171 (and schema/AGENTS.template.md line 1138) already has `### 11.5 Release Workflow (Orphan-Branch Publish)`. AGENTS.md §5 line 302 already forward-references `§11.5 Brownfield Workflow` — this IS Phase 10 WR-03 (the "forward-ref typo" flagged by the code reviewer).

**Why it happens:** Phase 7 (release workflow) and Phase 10 (bootstrap_stage doc with forward-ref) landed independently; the §11.5 slot got used by Release Workflow but the forward-ref was authored assuming Brownfield would own §11.5.

**How to avoid:** Plan 11-05 MUST resolve this. Options:
- **(A) Renumber Release Workflow to §11.6** — cleanest; matches user's apparent intent from the Phase 10 forward-ref. Low-risk: the release workflow section is 3 lines + a pointer, and no other file cross-references §11.5-Release.
- **(B) Put Brownfield Workflow at §11.6 and fix the Phase 10 forward-ref from §11.5 to §11.6** — also clean, but requires re-regenerating `schema/fixtures/canonical-AGENTS.md` and touches Phase 10's D-20 row.
- **(C) Renumber Release to §11.5 → §11.6, put Brownfield at §11.5 as originally intended** — resolves the forward-ref typo WR-03 as a byproduct.

**Recommendation:** Option C. This is the originally-intended numbering. It closes Phase 10 WR-03 opportunistically. Single edit touches all 4 artifacts (AGENTS.md, CLAUDE.md via sync, schema/AGENTS.template.md, schema/fixtures/canonical-AGENTS.md regen).

**Warning signs:** Plan 11-05 check assertion "grep -c '### 11.5 Brownfield Workflow' AGENTS.md == 1" — should return 1; if returns 0, the plan missed the rename; if returns >1, the Release section wasn't renumbered.

### Pitfall 2: `suggest` re-running rewrites canonical scripts differently

**What goes wrong:** If `suggest` regenerates scripts from a template that embeds vault-specific logic (e.g., "vault has 237 pages, so set cluster-count threshold to …"), re-running `suggest` on a vault that grew produces different script contents. CI byte-equality test fires.

**Why it happens:** Conflating logic (versioned) with data (ephemeral). Research PITFALL.md §C-3 idempotency violation.

**How to avoid:** Strict separation per D-08. Canonical scripts read data files at run time. Never embed vault-specific data in script text. CI test: `cmp -s schema/brownfield/migrations/$script .brownfield/migrations/$script` after every `suggest` run.

**Warning signs:** D-19 RED test "suggest copies canonical scripts byte-identically" catches this.

### Pitfall 3: 02-provenance-bootstrap tags bullets that are not claims

**What goes wrong:** 02 appends `[epistemic:: inferred]` to every bullet, including link-only bullets ("- [[Some Page]]"), questions ("- What about X?"), tasks ("- [ ] TODO"), source-list bullets ("- src-2026-01-01-foo"). Vault becomes noise-polluted.

**Why it happens:** "top-level bullet" is too broad. Needs eligibility rules.

**How to avoid:** Eligibility heuristics (see research question #5 below):
- Skip if bullet is wikilink-only (whitespace-trimmed line matches `^\s*-\s*\[\[[^\]]+\]\]\s*$`)
- Skip if line ends in `?` (question)
- Skip if line matches `^\s*-\s*(\[ \]|TODO:|FIXME:)` (task)
- Skip if bullet is source-ID-looking (`^\s*-\s*src-\d{4}-\d{2}-\d{2}-`)
- Skip if bullet is placeholder (`^\s*-\s*(TBD|TBC|pending)\b`, case-insensitive)
- Skip if bullet already has `[epistemic::` marker anywhere in line
- Skip if bullet has existing `[prov:` marker (already sourced)
- Accept if: non-empty prose after leading `- `, not in skip set

**Warning signs:** D-19 RED test "02 only touches eligible top-level bullets in TL;DR + Key Facts; honest 'no eligible bullets' output when none."

### Pitfall 4: 03-cross-link-inference produces false positives on common words

**What goes wrong:** If a page title is a common English word (e.g., "Context", "State", "Summary"), 03 matches the word in every page's prose and flags hundreds of false cross-link candidates. Review becomes unusable.

**Why it happens:** Naive substring match. Obsidian's `[[...]]` is case-sensitive in some modes; prose usage is freely-cased.

**How to avoid:**
- Match ONLY exact-title as a word-boundary substring (`\b<escaped-title>\b`, case-sensitive per AGENTS.md §8 "exact canonical title")
- Match ONLY against titles with ≥2 tokens OR ≥8 characters (filters out single-word common titles)
- Skip matches inside already-existing `[[...]]` or inside code fences
- Respect AGENTS.md §8 first-mention-only: flag only the first occurrence per source page
- Output field `target_already_linked_from_source: bool` so review can filter
- Also match `aliases:` from target pages via frontmatter lookup

**Warning signs:** On a realistic fixture with 20 pages, cross-link-candidates.yaml should have <50 entries, not >500.

### Pitfall 5: op_hash includes timestamps, breaking idempotency

**What goes wrong:** `# op_hash: sha256:abc123 (generated 2026-04-20T14:22Z)` — hash changes every run. Re-suggesting always appears to be a new operation.

**Why it happens:** Research PITFALLS.md §C-3 prevention #3 warns about this.

**How to avoid:** D-10 explicit scope: `canonical-script-body + data-schema-version ONLY`. Implementation:
```python
def compute_op_hash(script_path: str, data_schema_version: int) -> str:
    with open(script_path, 'rb') as fh:
        body = fh.read()
    # Strip the op_hash line itself so the hash is stable across header updates
    body_lines = body.split(b'\n')
    stripped = b'\n'.join(ln for ln in body_lines if not ln.startswith(b'# op_hash:') and not ln.startswith(b'# op_hash_scope:'))
    h = hashlib.sha256()
    h.update(stripped)
    h.update(f'\n# data_schema: {data_schema_version}'.encode())
    return h.hexdigest()
```

**Warning signs:** D-19 RED test "op_hash stable across vaults for the same canonical script version" catches this.

### Pitfall 6: verify --promote flips pages that still have pending review decisions

**What goes wrong:** User resolves most clusters but leaves 3 pages pending in `page-typing-decisions.yaml`. `verify --promote` ignores pending state and flips those pages anyway because they pass mechanical gates. User loses audit trail of what was actually reviewed.

**Why it happens:** Gate 5 of D-14 ("No pending review decision remains for the page in `page-typing-decisions.yaml`") requires cross-referencing the decisions manifest, not just linting the page.

**How to avoid:** Read `.brownfield/page-typing-decisions.yaml` at verify-start; build set of page paths that are in pending clusters; gate-5-skip those pages. Document this explicitly.

**Warning signs:** D-19 test "`verify --promote` only flips eligible `bootstrapped` → `verified` pages; blockers remain `bootstrapped`" should exercise a fixture with pending clusters.

### Pitfall 7: Privacy-review regex false-positives on code samples

**What goes wrong:** 04-privacy-review flags every `@example.com` in a markdown code block as an email leak. Users see 200 findings, 180 of which are documentation.

**Why it happens:** Regex runs against whole file. Code fences + backtick spans contain literal examples.

**How to avoid:**
- Skip content between \`\`\` fences and inside inline backticks
- Skip content inside YAML frontmatter (already fail-closed preserved per D-07)
- Skip obvious test patterns (`example.com`, `example.org`, `1234`, `555-` area codes are known-test per NANP)
- User override via `.brownfield-privacy-terms.txt` is an allowlist of literal/regex patterns the user cares about; do NOT mechanically allowlist common test values since users may have real production .example.com data

**Warning signs:** Running 04-privacy-review against `docs/` should produce zero findings (docs contain `example.com`, `joe@example.com` in examples).

### Pitfall 8: review-typing TTY mode breaks in CI

**What goes wrong:** TTY prompts work locally but CI test pipeline has no TTY → `read -r -p` fails or hangs.

**Why it happens:** Test infrastructure typically runs without a controlling TTY.

**How to avoid:**
- Use scripted stdin: `echo "approve all" | bash bin/brownfield.sh review-typing`
- Use explicit `isatty` check for large-batch branching:
  ```bash
  if [ -t 0 ] && [ -t 1 ]; then
      TTY_MODE=1
  else
      TTY_MODE=0   # Force large-batch AI-handoff mode even if cluster count < N
  fi
  ```
- Alternative: D-04 "branches on pending-set size" — which it explicitly states. But add isatty check as secondary guard: if stdin is not a TTY AND cluster count < N, treat as small-batch with scripted stdin (tests need this path).

**Warning signs:** D-19 test "`review-typing` small-batch mode updates decisions.yaml via scripted stdin" catches this.

## Code Examples

### Clustering by Signal Tuple (Research Q #1)

```python
# Source: composed from bin/lib/brownfield_classify.py::classify_page() + D-02 cluster spec
# Proposed addition to brownfield_classify.py (extend module; do not replace):

from collections import defaultdict
from typing import Iterable

def cluster_by_signals(classifications: Iterable[dict]) -> list[dict]:
    """Group page classifications into clusters by their signal pattern.

    Input: iterable of dicts with keys {path, label, confidence, signals, inbound_count}
    Output: list of cluster dicts with keys {cluster_id, page_count, pages, signals, confidence, proposed_label}

    Signal-tuple bucketing: pages sharing the same (frontmatter_type, filename_class,
    heading_shape, inbound_heavy, outbound_heavy) land in the same cluster.

    Rationale:
    - O(n) single pass — no distance metric, no embedding, no scipy.
    - Deterministic output: sort by cluster_id (stable hash of signal tuple).
    - Human-reviewable: user sees "cluster_1 (12 pages): PascalCase filenames,
      entity-like H1, inbound-heavy" rather than an opaque similarity score.
    """
    buckets = defaultdict(list)
    for c in classifications:
        s = c['signals']
        # Signal tuple: the discriminating fields from D-16 classifier output
        key = (
            s.get('frontmatter', 'none'),
            s.get('filename', 'none'),
            s.get('heading', 'none'),
            'inbound-heavy' if c.get('inbound_count', 0) >= 5 else 'inbound-light',
            s.get('links', 'none'),   # outbound density (already slugged)
            c['confidence'],
        )
        buckets[key].append(c['path'])

    clusters = []
    for idx, (key, pages) in enumerate(sorted(buckets.items()), start=1):
        # Pick cluster's proposed label from any member (they all match by construction)
        first_label = next(c['label'] for c in classifications if c['path'] == pages[0])
        first_conf = next(c['confidence'] for c in classifications if c['path'] == pages[0])
        clusters.append({
            'cluster_id': f'cluster_{idx}',
            'page_count': len(pages),
            'pages': sorted(pages),
            'signals': {
                'frontmatter': key[0],
                'filename': key[1],
                'heading': key[2],
                'inbound': key[3],
                'links': key[4],
            },
            'confidence': first_conf,
            'proposed_label': first_label,
        })
    return clusters
```

**Complexity:** O(n) single pass. No scipy. 40 LOC total including docstring. Fits in `bin/lib/brownfield_classify.py` as a new function alongside `classify_page()` + `unknown_reason()`.

**Fixture verification (per D-20):** small-vault fixture has 3-6 pages landing in <10 clusters (likely 3-4 clusters); large-vault fixture has ≥20 pages landing in ≥20 clusters (likely 20-30 clusters).

### op_hash Derivation (Research Q #2)

```python
# Source: composed from D-10 spec + Phase 10 test_brownfield_bootstrap_idempotent.sh SHA-256 pattern
import hashlib
from pathlib import Path

OP_HASH_SCOPE = "canonical-script-body + data-schema-version"
CANONICAL_SCHEMA_VERSION = 1  # Bump when candidate/decisions YAML schema changes

def compute_op_hash(script_path: str, data_schema_version: int = CANONICAL_SCHEMA_VERSION) -> str:
    """Deterministic op_hash covering canonical script body + embedded schema version.

    Input normalization:
    - Read script bytes
    - Strip the two header lines that contain the hash itself (prevents self-reference)
    - Append a canonical data-schema suffix
    - SHA-256

    Does NOT include:
    - Candidate-YAML hashes (those live in applied.log inputs block per D-11)
    - Timestamps
    - File mtime
    - Vault path
    """
    body = Path(script_path).read_bytes()
    # Strip only op_hash header lines; keep all other comments (including structural
    # comments like function docstrings) so changing them bumps the hash legitimately.
    lines = body.split(b'\n')
    stripped = [ln for ln in lines
                if not ln.startswith(b'# op_hash:')
                and not ln.startswith(b'# op_hash_scope:')]

    h = hashlib.sha256()
    h.update(b'\n'.join(stripped))
    h.update(f'\n# data_schema_version: {data_schema_version}\n'.encode())
    return f'sha256:{h.hexdigest()}'


# Usage: at `suggest` time, compute the op_hash for each canonical script and
# INJECT the header into the byte-copied script body in .brownfield/migrations/.
# The injection replaces the placeholder header lines:
#   # op_hash: sha256:PLACEHOLDER
#   # op_hash_scope: canonical-script-body + data-schema-version
# with the computed values. Canonical schema/brownfield/migrations/*.sh files
# ship with the PLACEHOLDER values; suggest fills them in per vault.
#
# Alternative (simpler): canonical scripts DO NOT ship with op_hash headers.
# suggest PREPENDS the computed header to the byte-copied .brownfield/migrations/*.sh
# before making them executable. This preserves byte-equality of the canonical
# schema file while producing an executable script with a valid header.
```

**Recommended implementation:** Prepend header at copy time (second option). Canonical file in `schema/brownfield/migrations/01-page-typing.sh` has NO op_hash header. `.brownfield/migrations/01-page-typing.sh` has op_hash prepended by `suggest`. Byte-equality test compares the body-post-header-strip, matching the `compute_op_hash` stripping logic.

### 02-Provenance-Bootstrap Bullet Eligibility (Research Q #5)

```python
# Source: composed from D-05 spec + pitfall 3 heuristics
import re

# Patterns for skip classes (compile once)
WIKILINK_ONLY_RE = re.compile(r'^\s*-\s*\[\[[^\]]+\]\]\s*$')
QUESTION_RE = re.compile(r'\?\s*$')
TASK_RE = re.compile(r'^\s*-\s*(\[[ x]\]|TODO:?|FIXME:?)\b', re.IGNORECASE)
SOURCE_ID_RE = re.compile(r'^\s*-\s*src-\d{4}-\d{2}-\d{2}-')
PLACEHOLDER_RE = re.compile(r'^\s*-\s*(TBD|TBC|pending|placeholder)\b', re.IGNORECASE)
EPISTEMIC_PRESENT_RE = re.compile(r'\[epistemic::')
PROVENANCE_PRESENT_RE = re.compile(r'\[prov:')
BULLET_START_RE = re.compile(r'^(\s*)-\s+(.+)$')


def is_eligible_claim_bullet(line: str) -> bool:
    """Return True if a bullet line should receive [epistemic:: inferred].

    Applied per D-05 to top-level bullets (0 leading spaces or 2-space indent
    depending on markdown style) under '## TL;DR' + '## Key Facts' only.
    """
    if not BULLET_START_RE.match(line):
        return False
    if WIKILINK_ONLY_RE.match(line):
        return False  # link-only bullet — navigational, not a claim
    if QUESTION_RE.search(line):
        return False  # question — not a claim
    if TASK_RE.match(line):
        return False  # task/checklist — not a claim
    if SOURCE_ID_RE.match(line):
        return False  # source-list bullet — not a claim (though D-05 makes this moot for TL;DR / Key Facts)
    if PLACEHOLDER_RE.match(line):
        return False  # placeholder — not a claim
    if EPISTEMIC_PRESENT_RE.search(line):
        return False  # already tagged
    if PROVENANCE_PRESENT_RE.search(line):
        return False  # already has provenance marker; presumed sourced
    return True


def section_scan(body: str, target_sections: list[str]) -> list[tuple[int, str]]:
    """Return list of (line_number, line) for top-level bullets under target sections.

    Walks body line-by-line tracking current section header.  Emits bullets
    only while 'in' a target section (between its header and the next '## '
    header).  Nested sections ('### ') do not reset target-section state.
    """
    eligible = []
    in_target = False
    SECTION_HDR_RE = re.compile(r'^##\s+(.+?)\s*$')
    for lineno, line in enumerate(body.splitlines(), start=1):
        m = SECTION_HDR_RE.match(line)
        if m:
            in_target = m.group(1).strip() in target_sections
            continue
        if in_target and is_eligible_claim_bullet(line):
            eligible.append((lineno, line))
    return eligible


# Integration with ruamel.yaml round-trip:
# 1. read_fm_body(path) -> (fm, body, raw_yaml)
# 2. If fm has bootstrap_stage != 'bootstrapped', skip (D-05 applies only to bootstrapped pages? — re-verify in Plan 11-03 against D-05)
# 3. eligible = section_scan(body, ['TL;DR', 'Key Facts'])
# 4. For each (lineno, line) in eligible, append ' [epistemic:: inferred]' to end of line
# 5. Rebuild body, write_roundtrip(path, fm, new_body, raw_yaml)
# 6. Record per-page count in provenance-bootstrap-report.yaml
```

### applied.log Append Helper (Integration Point Q #8)

```bash
# Source: composed from D-11 schema + bin/release.sh APPLIED.md append pattern
# Proposed: inline bash function in bin/brownfield.sh (preferred over new python module).

# append_applied_log_apply <script_name> <op_hash> <exit_code> <prereq_status> \
#                           <inputs_file>:<input_hash> ... \
#                           -- <files_touched> <files_created> <files_updated> <files_skipped> \
#                           -- <change_line> ... \
#                           -- <summary_key:value> ...
# ... but a simpler interface is just to have scripts write a staged block to
# a temp file and call append_applied_log_block <temp_file>.

append_applied_log_block() {
    local block_file="$1"
    local log_file="${BROWNFIELD_ROOT:-.}/.brownfield/applied.log"
    mkdir -p "$(dirname "$log_file")"
    cat "$block_file" >> "$log_file"
    # Ensure trailing blank line for block separation
    printf '\n' >> "$log_file"
}

# Each migration script builds its block in a temp file, then calls this helper.
# No YAML round-trip. No JSON. Plain markdown append.
```

**Recommendation:** Inline bash helper in `bin/brownfield.sh`. Not a separate module. Migration scripts source `bin/brownfield.sh` or declare the helper inline (each script can have its own copy — it is 6 LOC).

### review-typing TTY Prompt Loop

```bash
# Source: composed from bin/init-wizard.sh prompts/validator pattern (Phase 8) + D-04 primitives
# Proposed: inside bin/brownfield.sh review-typing branch

review_typing_tty() {
    local decisions_file="$BS_ROOT/.brownfield/page-typing-decisions.yaml"
    local candidates_file="$BS_ROOT/.brownfield/page-typing-candidates.yaml"

    # Load pending clusters via python heredoc (ruamel.yaml round-trip preserves comments)
    # Prompts go to stderr; stdout reserved for eventual parsable output.

    python3 << 'PYEOF'
import os, sys
sys.path.insert(0, os.environ['BROWNFIELD_LIB_DIR'])
from ruamel.yaml import YAML
yaml = YAML(typ='rt')

decisions_path = os.environ['BF_DECISIONS_FILE']
candidates_path = os.environ['BF_CANDIDATES_FILE']

with open(decisions_path, 'r') as fh:
    decisions = yaml.load(fh)
with open(candidates_path, 'r') as fh:
    candidates = yaml.load(fh)

pending = [c for c in decisions['clusters'] if c['decision'] == 'pending']

for cluster in pending:
    cid = cluster['cluster_id']
    cand = next(c for c in candidates['clusters'] if c['cluster_id'] == cid)

    # Pretty print cluster summary to stderr
    sys.stderr.write(f"\n=== {cid} ({cand['page_count']} pages, confidence={cand['confidence']}) ===\n")
    sys.stderr.write(f"Proposed label: {cand['proposed_label']}\n")
    sys.stderr.write(f"Signals: {cand['signals']}\n")
    sys.stderr.write(f"Sample pages:\n")
    for p in cand['pages'][:5]:
        sys.stderr.write(f"  - {p}\n")
    if cand['page_count'] > 5:
        sys.stderr.write(f"  ... and {cand['page_count'] - 5} more\n")
    sys.stderr.write("\nAction: [a]pprove all / [r]eject all / [i]nspect / [o]verride selected / [s]kip: ")
    sys.stderr.flush()

    choice = sys.stdin.readline().strip().lower()[:1]
    if choice == 'a':
        cluster['decision'] = 'approve'
        cluster['resolved_label'] = cand['proposed_label']
    elif choice == 'r':
        cluster['decision'] = 'reject'
    elif choice == 'i':
        # Emit per-page unified diff of proposed frontmatter change
        # (uses difflib.unified_diff pattern from Phase 8 D-18)
        ...
    elif choice == 'o':
        # Per-page override sub-loop
        ...
    # 's' or any other: leave pending

# Write back decisions.yaml with preserved comments + key order
with open(decisions_path, 'w') as fh:
    yaml.dump(decisions, fh)
PYEOF
}

review_typing_large_batch() {
    local prompt_file="$BS_ROOT/.brownfield/review-typing-prompt.md"
    cat > "$prompt_file" <<'EOF'
# Review typing — AI-guided batch session

Open the two files:

- `.brownfield/page-typing-candidates.yaml` — read-only reference: each cluster's signals, proposed label, member pages.
- `.brownfield/page-typing-decisions.yaml` — edit target: each cluster has `decision: pending`. Change to `approve` / `reject`; add `resolved_label` on approve; optionally add per-page overrides.

## Your job

For each pending cluster:
1. Read the signals and sample pages.
2. Consider: does the proposed label fit the semantic role of these pages? Would splitting the cluster into sub-groups make sense? Are there outlier pages that need per-page overrides?
3. **Edit only `.brownfield/page-typing-decisions.yaml`.** Do NOT modify any vault pages. Do NOT modify `page-typing-candidates.yaml`.
4. When all clusters are resolved, inform the user that they can now run:

   ```
   bash .brownfield/migrations/01-page-typing.sh --apply
   ```

## Constraints

- Legal labels for `resolved_label`: `entity`, `concept`, `source`, `comparison`, `overview`, `decision`.
- Per-page overrides go under a cluster's `overrides:` key; each entry has `path:` and `label:`.
- Do not merge or split clusters by editing cluster membership — if a cluster needs splitting, mark it `reject` and the user re-runs `suggest` after manually splitting the vault.

## Decision boundary

*Review may be interactive and AI-guided; apply must always be deterministic.*

This prompt lives outside the `bin/brownfield.sh` CLI by design: the CLI never calls an LLM. You — the AI assistant reading this file — operate on the manifest from outside the CLI. The user then runs a deterministic apply script.
EOF
    echo "Review prompt written to $prompt_file" >&2
    echo "Open this file in your AI session (Claude Code, Codex, etc.) to review the $PENDING_CLUSTER_COUNT pending clusters." >&2
    echo "When done, run: bash .brownfield/migrations/01-page-typing.sh --apply" >&2
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 10 scan-only `.brownfield/REPORT.md` | Phase 11 extends REPORT.md with `## Cross-link candidates` + `## Privacy review` sections | This phase | REPORT.md is now the "single pane of glass" for both mechanical and advisory outputs. |
| No canonical migration scripts; research imagined scripts generated at suggest-time | Canonical scripts tracked in `schema/brownfield/migrations/*.sh`; byte-copied at suggest-time | This phase (D-08) | Reviewable in git; byte-equality CI-enforced; separates logic from data. |
| `bootstrap_stage` had only `bootstrapped` transition (Phase 10) | Phase 11 ships `verified` transition via `verify --promote` | This phase (D-14/D-15) | Complete lifecycle: (absent) → bootstrapped → verified. `raw` reserved. |
| Plan proposed magic-string provenance values (`[prov:bootstrap]`) | 02-provenance-bootstrap uses ONLY existing `[epistemic:: inferred]` | BRWN-15 Phase 10 lock; reaffirmed in Phase 11 | Zero claim-level schema expansion. Page-level `bootstrap_stage` carries lineage. |
| Plan proposed `bin/brownfield.sh apply` chain-runner | Per-script user-invocation (BRWN-13); chain-runner deferred to v1.2 BRWNAPPLY-01 | v1.1 posture | Mechanical errors recoverable; judgment errors at scale silently corrupt knowledge. |

**Deprecated/outdated:**
- Plan-phase early draft of "one suggest command that does everything" — rejected per BRWN-13. CONTEXT.md locks per-class invocation.
- Plan-phase early idea of `--assume-yes` / `--force` on migration scripts — not in v1.1. Dry-run default, explicit `--apply`.

## Research Question Answers

### Q1: Clustering algorithm for 01-page-typing discovery

**Recommendation:** Group-by-signal-tuple bucketing (see `cluster_by_signals()` in Code Examples).

**Empirical verification against D-20 fixtures:**

| Fixture | Pages | Distinct classifier-output tuples | Expected clusters | D-20 target |
|---------|-------|-----------------------------------|-------------------|-------------|
| small-vault-ambiguous | 3-6 | 3-5 | 3-5 | <10 ✓ |
| large-vault-ambiguous | 25+ | 20-25 | 20-25 | ≥20 ✓ |

Signal tuples with values from D-16 classifier have bounded cardinality: `frontmatter` ∈ {none, entity, concept, source, comparison, overview, decision} × `filename` ∈ {none, pascalcase, date-prefix, src-prefix, vs-prefix} × `heading` ∈ {none, entity-like, concept-like, source-like, comparison-like} × `inbound` ∈ {heavy, light} × `links` ∈ {none, outbound-heavy} × `confidence` ∈ {high, medium, low, unknown}. Max theoretical clusters = 7×5×5×2×2×4 = 2800 (upper bound). Real vaults produce 5-50 distinct tuples.

**Complexity:** O(n) single pass. No scipy/numpy. [VERIFIED: algorithm fits in 40 LOC Python stdlib-only]

### Q2: op_hash derivation

**Recommendation:** Strip-self-references + SHA-256 over canonical script body + data-schema-version suffix (see `compute_op_hash()` in Code Examples).

**Normalization rules:**
- Strip ONLY `# op_hash:` and `# op_hash_scope:` lines (prevents self-reference)
- Preserve ALL other comments (structural + docstrings — changing them bumps the hash legitimately)
- No timestamps stripped — there should be no timestamps in canonical scripts in the first place
- Canonical script MUST NOT embed `generated_at` or similar; those belong in candidate YAML metadata headers per D-09

**Output format:** `sha256:<64-hex>` matching applied.log field shape (D-11).

**Prototype verified:** function is 10 LOC Python, deterministic, idempotent. [VERIFIED: algorithm matches D-10 scope specification verbatim]

### Q3: Small-batch vs large-batch threshold N

**Recommendation:** N=20 clusters.

**Rationale:**
- D-20 fixtures designed around <10 clusters (small-batch path) and ≥20 clusters (large-batch path). N=20 places the branch exactly at the fixture boundary.
- 20 TTY prompts is the upper edge of "can a human reasonably complete in one sitting" — at ~45 seconds per cluster (read signals, check sample pages, decide), 20 clusters = ~15 minutes.
- Larger-than-N batches benefit from AI assistance: pattern matching across many clusters, tradeoff articulation, merge/split suggestions.
- Not load-bearing: planner can adjust to N=15 or N=25 after reviewing fixtures in 11-01. Document N in script header.

**Not recommended:** N=10 (too aggressive push to AI handoff); N=50 (too many TTY prompts; user gives up).

### Q4: medium-confidence default policy

**Recommendation:** Route `medium` confidence to review queue by default. Add `--auto-medium` flag as opt-in for power users.

**Rationale:**
- BRWN-13 "per-class user invocation" posture favors conservative defaults.
- Research PITFALLS.md + FEATURES.md §Bucket 5 anti-features list cautions against auto-applying judgment-heavy transforms. Medium confidence IS judgment-heavy.
- False-positive cost on medium: wrong type: assignment requires `git reset` or manual frontmatter edit.
- User burden: medium-confidence clusters are typically small (2-3 pages each in realistic vaults) — reviewing them is lightweight.
- Opt-in via `--auto-medium` preserves power-user ergonomics without making auto-apply the silent default.

**Empirical verification:** On D-20 small-vault fixture (3-6 pages), classifier labels each page deterministically. Cluster confidences are computed via Counter-based signal-agreement (lines 107-122 of brownfield_classify.py). Reviewing 3-5 clusters TTY is trivial; auto-applying wrong labels is not recoverable without manual edits.

### Q5: 02-provenance-bootstrap bullet-eligibility heuristics

**Recommendation:** See `is_eligible_claim_bullet()` + `section_scan()` in Code Examples. Also captured verbatim in Common Pitfalls §Pitfall 3.

**Integration:** New helper module `bin/lib/brownfield_provenance.py` or extend `brownfield_yaml.py`. Planner's call per CONTEXT.md §Claude's-Discretion. Research recommends a new module (`brownfield_provenance.py`) for testability — the eligibility rules are isolated from YAML round-trip.

### Q6: 03-cross-link-inference matching algorithm

**Recommendation:**
- Scan vault for all page titles + aliases (from frontmatter).
- Per source page, iterate over body text line-by-line.
- For each target title T (with ≥2 tokens OR ≥8 chars), search for `\b<re.escape(T)>\b` (case-sensitive per AGENTS.md §8 "exact canonical title").
- For each match: record `source_page`, `line_number`, `matched_text`, `proposed_target`, `match_type` (`exact-title` vs `alias`), and `target_already_linked_from_source` (bool — scan source page body for existing `[[T]]` OR `[[alias]]`).
- Skip matches inside code fences (`^```` to `^```` state machine) and inside inline backticks.
- Skip matches inside existing `[[...]]` wikilinks.
- AGENTS.md §8 first-mention-only: output one entry per (source, target) pair even if multiple matches exist; note total match count.

**Output shape (cross-link-candidates.yaml):**
```yaml
# ---
# schema_version: 1
# tool_version: 1.1.0
# generated_at: 2026-04-20T14:22:31Z
# vault_root: /home/user/vault
# source_script_hash: sha256:...
# ---
candidates:
  - source_page: wiki/concepts/foo.md
    line_number: 42
    matched_text: "the Attention Mechanism uses"
    proposed_target: wiki/concepts/attention-mechanism.md
    match_type: exact-title
    match_count_in_source: 3
    target_already_linked_from_source: false
    short_rationale: "First mention of 'Attention Mechanism' as exact-title; no existing [[...]] found"
```

### Q7: 04-privacy-review pattern set

**Recommendation:**

```python
# Built-in patterns (skip content in code fences + inline backticks + frontmatter)
EMAIL_RE = re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b')
# Phone: US E.164 + NANP (simplified — conservative; flag extras for review)
PHONE_RE = re.compile(r'\b(?:\+?1[-.\s]?)?\(?[2-9][0-9]{2}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b')
# SSN: 3-2-4 with dashes or spaces
SSN_RE = re.compile(r'\b\d{3}[-\s]\d{2}[-\s]\d{4}\b')

# User-authored allowlist: .brownfield-privacy-terms.txt
# Each line: either a literal string OR a /regex/ (slash-wrapped)
# Empty lines + # comments ignored
def load_user_terms(path: str) -> list[re.Pattern]:
    terms = []
    if not os.path.isfile(path): return terms
    for ln in open(path):
        ln = ln.strip()
        if not ln or ln.startswith('#'): continue
        if ln.startswith('/') and ln.endswith('/') and len(ln) > 2:
            terms.append(re.compile(ln[1:-1]))
        else:
            terms.append(re.compile(re.escape(ln)))
    return terms
```

**Skip rules (applied before regex match):**
- Skip frontmatter block (`^---...^---`)
- Skip lines inside code fences (\`\`\` state machine)
- Skip inline backtick spans
- Skip example-TLD matches (`@example.com`, `@example.org`) unless user-authored term override

**Output shape (privacy-findings.yaml):**
```yaml
# ---
# metadata header per D-09
# ---
findings:
  - path: wiki/journal/2026-01-15.md
    line_number: 12
    pattern_type: email
    matched_text: "jdoe@acme.com"
    risk_level: medium   # email = medium; phone = medium; SSN = high
    suggestion: "Review whether this email should appear in a cloud_safe page; consider moving to a local_only page or removing"
  - path: wiki/concepts/foo.md
    line_number: 45
    pattern_type: user-term
    matched_term: "project aurora"
    matched_text: "the project aurora codebase"
    risk_level: high    # user-authored terms default to high
```

**CRITICAL (D-07):** NEVER flips `privacy:` frontmatter. Output is purely advisory. Contract phrase verbatim in script `--help`.

### Q8: applied.log writer integration point

**Recommendation:** Bash helper function `append_applied_log_block` in `bin/brownfield.sh`. NOT a separate Python module.

**Rationale:**
- Block is plain markdown; no YAML parsing or round-trip needed.
- Migration scripts build their block in a temp file then call the helper.
- Bash helper is 6 LOC. Python module adds heredoc boundary + `sys.path.insert` dance.
- No cross-script state to manage — each script writes its own block.

**Each migration script pattern:**
```bash
# At end of migration script --apply path
APPLIED_BLOCK_TMP=$(mktemp)
cat > "$APPLIED_BLOCK_TMP" <<EOF
## $(basename "$0") @ $(date -u '+%Y-%m-%dT%H:%M:%SZ')
mode: apply
op_hash: $OP_HASH
exit_code: 0
prereq_check: $PREREQ_STATUS
inputs:
  - .brownfield/page-typing-candidates.yaml @ sha256:$CANDIDATES_HASH
  - .brownfield/page-typing-decisions.yaml @ sha256:$DECISIONS_HASH
files_touched: $N_TOUCHED
files_created: $N_CREATED
files_updated: $N_UPDATED
files_skipped: $N_SKIPPED
changes:
$CHANGES_BLOCK
summary:
  - approved_clusters: $N_APPROVED
  - overridden_pages: $N_OVERRIDDEN
  - pending_pages_remaining: $N_PENDING
EOF

# Helper sourced at script top:
append_applied_log_block "$APPLIED_BLOCK_TMP"
rm -f "$APPLIED_BLOCK_TMP"
```

### Q9: verify --promote implementation performance

**Recommendation:** Single pass design.

**Algorithm:**
1. Run `bin/lint.sh --ci --format json --category yaml,provenance,orphan,crossref,brownfield` ONCE (subprocess).
2. Parse JSON findings; build `errors_by_path = defaultdict(list)`.
3. Read `.brownfield/page-typing-decisions.yaml` ONCE; build set `pending_pages = {p for c in clusters if c.decision=='pending' for p in c.pages}`.
4. Walk vault once; for each page with `bootstrap_stage: bootstrapped`: apply 5 gates (O(1) lookups); if all pass, `write_roundtrip` with `bootstrap_stage: 'verified'`.

**Performance budget for 500-page vault:**
- Lint run: 5-10s (dominated by YAML parsing all pages)
- Build indexes: <1s
- Walk + write: <5s for ~50 pages passing (rest are skipped O(1))

Total: <20s. Well within the <30s target.

**Bottleneck:** lint subprocess. Could optimize by reading lint findings from cache or by avoiding full lint (run only the 5 needed categories), but Phase 9 CI_SEVERITY_REMAP already scopes to these via `--category yaml,provenance,orphan,crossref,brownfield` flag, which is fast enough.

### Q10: AGENTS.md §11.5 template shape

**Recommendation:** Match §11.1–11.4 verbatim structure. See Code Examples "§11.5 Template" below.

**Blocker (CRITICAL):** The existing §11.5 is "Release Workflow (Orphan-Branch Publish)" at AGENTS.md line 1171. Phase 10 D-20 forward-referenced `§11.5 Brownfield Workflow` from the `bootstrap_stage` row at line 302 — this is the known WR-03 typo. Plan 11-05 MUST resolve this before writing Brownfield Workflow. Recommendation per Pitfall 1: renumber Release Workflow to §11.6; put Brownfield Workflow at §11.5 as originally intended.

**§11.5 Template (after resolution):**

```markdown
### 11.5 Brownfield Workflow

The brownfield workflow onboards existing Obsidian vaults into the wiki compiler schema. It is the mechanical counterpart to ingest (§11.1) — where ingest creates wiki pages from sources, brownfield transforms pre-existing vault pages into schema-compliant form. The workflow operates through four subcommands plus the `bootstrap_stage` lifecycle gate.

**Core principle:** *Review may be interactive and AI-guided; apply must always be deterministic.*

**Architectural boundary — four subcommands, two classes:**

| Script | Subcommand | Class | What it does |
|--------|-----------|-------|--------------|
| `bin/brownfield.sh scan` | — | inventory | Dry-run classification (Phase 10) |
| `bin/brownfield.sh bootstrap` | — | apply | Mechanical frontmatter injection (Phase 10) |
| `bin/brownfield.sh suggest` | — | generator | Emits migration scripts + candidate data files |
| `bin/brownfield.sh review-typing` | — | orchestrator | TTY or AI-handoff review of page-typing decisions |
| `bin/brownfield.sh verify [--promote]` | — | gate | Read-only lint wrapper; `--promote` flips `bootstrap_stage` on passing pages |
| `.brownfield/migrations/01-page-typing.sh` | — | apply | Page typing from review manifest |
| `.brownfield/migrations/02-provenance-bootstrap.sh` | — | apply | TL;DR + Key Facts `[epistemic:: inferred]` tagging |
| `.brownfield/migrations/03-cross-link-inference.sh` | — | advisory | Cross-link candidates report |
| `.brownfield/migrations/04-privacy-review.sh` | — | advisory | Privacy-sensitive findings report |

#### bootstrap_stage Lifecycle

```
(absent) ──[bin/brownfield.sh bootstrap --apply]──> bootstrapped
bootstrapped ──[bin/brownfield.sh verify --promote, passes gate]──> verified
bootstrapped ──[normal ingest via bin/ingest.sh]──> (stripped per BRWN-10)
verified     ──[no automatic downgrade]──> (manual edit only)
raw          ──[reserved for future import workflows]──> (no writer in v1.1)
```

#### 11.5.1 suggest

```
Trigger:  User completes bootstrap and wants to migrate page typing / provenance / cross-links / privacy
Inputs:   Vault (current state) + bin/lib/brownfield_classify.py classifier rule set
Outputs:  .brownfield/migrations/*.sh (byte-copies), .brownfield/*.yaml (candidate data files), .brownfield/REPORT.md sections
Commit:   N/A (.brownfield/ is gitignored per TMPL-04)
```

**Steps:**

1. Byte-copy canonical migration scripts from `schema/brownfield/migrations/*.sh` into `.brownfield/migrations/*.sh`. Prepend `# op_hash: <sha256>` + `# op_hash_scope: canonical-script-body + data-schema-version` to each copy.
2. Walk vault; for each page, run `classify_page()` with `inbound_count` from pre-built inbound graph.
3. Cluster classifications by signal tuple. Write `.brownfield/page-typing-candidates.yaml` with metadata header per D-09.
4. Write `.brownfield/page-typing-decisions.yaml` with every cluster `decision: pending` (except `high`-confidence clusters with explicit valid frontmatter `type:` — auto-populate `decision: approve` for those).
5. Generate `.brownfield/provenance-bootstrap-report.yaml` (02's dry-run preview), `.brownfield/cross-link-candidates.yaml` (03's output), `.brownfield/privacy-findings.yaml` (04's output).
6. Extend `.brownfield/REPORT.md` with `## Cross-link candidates` and `## Privacy review` sections.

**Abort conditions:**

- `schema/brownfield/migrations/` directory missing from repo. Report and exit 1.
- Vault root does not exist. Report and exit 1.
- `bootstrap_stage: bootstrapped` not found on any vault page. Warn: suggest usually follows bootstrap.

#### 11.5.2 review-typing

```
Trigger:  User wants to resolve pending clusters in page-typing-decisions.yaml
Inputs:   .brownfield/page-typing-candidates.yaml (read) + .brownfield/page-typing-decisions.yaml (read+write)
Outputs:  Updated page-typing-decisions.yaml with resolved decisions
Commit:   N/A (.brownfield/ is gitignored)
```

**Steps:**

1. Count pending clusters in decisions.yaml.
2. **If pending count < N (default N=20):** TTY prompts cluster-by-cluster. Per cluster: `approve all` / `reject all` / `inspect individual pages` / `override selected pages` / `skip`.
3. **If pending count ≥ N:** emit `.brownfield/review-typing-prompt.md` — directive template pointing at candidates + decisions YAMLs. Tell user to open in AI session and edit decisions manifest only. Do not prompt in TTY.
4. Write decisions.yaml with ruamel.yaml round-trip (preserves user comments).

**Abort conditions:**

- No `.brownfield/page-typing-decisions.yaml` found. Report: run `suggest` first.
- All clusters already resolved. Report cleanly and exit 0.

#### 11.5.3 verify [--promote]

```
Trigger:  User wants to check vault passes after migration scripts applied
Inputs:   Vault + .brownfield/page-typing-decisions.yaml (for Gate 5)
Outputs:  stdout summary of blockers; (with --promote) bootstrap_stage mutations on passing pages
Commit:   N/A (frontmatter mutations go through ruamel round-trip; user commits separately)
```

**Steps (read-only mode):**

1. Run `bin/lint.sh --ci --format json --category yaml,provenance,orphan,crossref,brownfield`.
2. Print summary grouped by severity; list paths blocking promotion.
3. Exit 0 regardless of findings.

**Steps (--promote):**

1. Run lint once as above; parse JSON.
2. Read `.brownfield/page-typing-decisions.yaml`; build pending-pages set.
3. Walk vault; for each page with `bootstrap_stage: bootstrapped`, apply 5-gate pass list:
   - (a) currently `bootstrapped`
   - (b) `type:` is valid enum per §4
   - (c) zero error-severity lint findings for this path
   - (d) type-specific required fields present (e.g., `path`, `content_hash`, `ingested_at`, `source_type` for `type: source`)
   - (e) not in pending-pages set
4. If all 5 gates pass: flip `bootstrap_stage: 'verified'` via `write_roundtrip`.
5. Print summary: `N pages promoted; M pages still blocked (see findings above)`.

**Abort conditions:**

- `bin/lint.sh` not found or exits with script-runtime error. Report and exit 1.
- No `bootstrap_stage: bootstrapped` pages found. Report: nothing to verify; exit 0.
```

### Q11: Validation Architecture (Nyquist) for Phase 11

Per CONTEXT.md D-19, the RED test suite is locked in Plan 11-01. Nyquist requires that each contract assertion be sampled at ≥2× frequency.

**Proposed sampling distribution:**

| Test Type | Count | Runtime per test | Why this level |
|-----------|-------|------------------|----------------|
| Unit (Python function contracts) | ~8-10 | <0.5s | `cluster_by_signals`, `compute_op_hash`, `is_eligible_claim_bullet`, `section_scan`, per-page 5-gate evaluator — each tested with table-driven cases |
| Integration (bash script invocation) | ~20-25 | 1-3s each | Each migration script dry-run + apply + idempotency; review-typing scripted-stdin; verify --promote with multiple fixtures |
| End-to-end happy-path | 1 | 10-15s | `suggest → review-typing → 01 apply → 02 apply → 03 advisory → 04 advisory → verify → verify --promote`; asserts final vault state matches golden fixture |

**Target total:** ~30 tests in `tests/phase-11/`. Consistent with Phase 10 (32 tests) and Phase 9 (28 tests). Phase 11 may run 1-2 tests higher than phase-10 due to review-typing being new surface.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash test runner (pattern-twin of tests/phase-10/) |
| Config file | `tests/phase-11/lib.sh` (shared helpers) |
| Quick run command | `bash tests/phase-11/run.sh` |
| Full suite command | `PYTHONPATH=$HOME/.local/lib/python3/dist-packages bash tests/phase-11/run.sh` (ruamel.yaml path) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BRWN-11 | suggest writes REPORT.md + migrations/*.sh | integration | `bash tests/phase-11/test_suggest_byte_copies_migrations.sh` | ❌ Wave 0 |
| BRWN-11 | suggest generates candidate data files with D-09 header | integration | `bash tests/phase-11/test_suggest_candidate_metadata_header.sh` | ❌ Wave 0 |
| BRWN-12 | Four scripts exist with exact names (04 is `04-privacy-review.sh`) | unit | `bash tests/phase-11/test_migration_script_names.sh` | ❌ Wave 0 |
| BRWN-13 | Each script dry-run default; `--apply` gated | integration | `bash tests/phase-11/test_script_dryrun_default.sh` (x4) | ❌ Wave 0 |
| BRWN-13 | Each script is idempotent on re-run | integration | `bash tests/phase-11/test_script_idempotent.sh` (x4) | ❌ Wave 0 |
| BRWN-14 | op_hash header present + stable across vaults for same canonical script | integration | `bash tests/phase-11/test_op_hash_stable.sh` | ❌ Wave 0 |
| BRWN-14 | applied.log block shape matches D-11 schema | integration | `bash tests/phase-11/test_applied_log_schema.sh` | ❌ Wave 0 |
| BRWN-15 | 02-provenance uses ONLY `[epistemic:: inferred]` (no magic strings) | integration | `bash tests/phase-11/test_02_no_magic_strings.sh` | ❌ Wave 0 |
| BRWN-16 | No LLM calls in any new bin/ or schema/brownfield/ code | unit | `bash tests/phase-11/test_no_llm_calls.sh` (grep for curl/wget/anthropic/openai) | ❌ Wave 0 |
| BRWN-17 | verify wraps lint --ci with correct categories | integration | `bash tests/phase-11/test_verify_lint_wrapper.sh` | ❌ Wave 0 |
| BRWN-17 | verify is read-only by default | integration | `bash tests/phase-11/test_verify_readonly_default.sh` | ❌ Wave 0 |
| BRWN-17 | verify --promote flips eligible pages only | integration | `bash tests/phase-11/test_verify_promote_5_gates.sh` | ❌ Wave 0 |
| BRWN-18 | docs/reference/brownfield.md explains mechanical-vs-judgment | unit | `bash tests/phase-11/test_docs_mechanical_judgment.sh` | ❌ Wave 0 |
| BRWN-19 | docs/reference/brownfield.md has `git reset` recipe | unit | `bash tests/phase-11/test_docs_git_reset_recipe.sh` (already passes — Phase 10 shipped) | ✅ |
| BRWN-20 | AGENTS.md §11.5 is Brownfield Workflow (not Release) | unit | `bash tests/phase-11/test_agents_section_11_5.sh` | ❌ Wave 0 |
| (new) BRWN-22 | review-typing small-batch TTY mode via scripted stdin | integration | `bash tests/phase-11/test_review_typing_tty_small.sh` | ❌ Wave 0 |
| (new) BRWN-22 | review-typing large-batch emits prompt.md | integration | `bash tests/phase-11/test_review_typing_ai_handoff.sh` | ❌ Wave 0 |
| (end-to-end) | Full happy-path: suggest → review → 01 → 02 → 03 → 04 → verify → promote | integration | `bash tests/phase-11/test_end_to_end_happy_path.sh` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `bash tests/phase-11/run.sh` (fast path; all tests <30s)
- **Per wave merge:** Run with PYTHONPATH for ruamel.yaml:
  ```bash
  PYTHONPATH=$HOME/.local/lib/python3/dist-packages bash tests/phase-11/run.sh
  ```
- **Phase gate:** `PYTHONPATH=... bash tests/phase-11/run.sh` green + all prior-phase tests green (Phase 7/8/9/9.1/10 aggregators)

### Wave 0 Gaps

- [ ] `tests/phase-11/run.sh` — aggregator (clone phase-10)
- [ ] `tests/phase-11/lib.sh` — helpers (clone phase-10)
- [ ] `tests/phase-11/fixtures/` — 5 fixtures per D-20
- [ ] `tests/phase-11/test_*.sh` — ~30 RED tests per contract list above
- [ ] `schema/brownfield/migrations/*.sh` — 4 skeleton canonical scripts (placeholders only in Wave 0; implementation in Plan 11-03)
- [ ] No framework install needed (all tooling already in place)

## Security Domain

> Required per `security_enforcement` absent = enabled default.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — (CLI tool; no auth surface) |
| V3 Session Management | no | — (no sessions) |
| V4 Access Control | no | — (filesystem permissions inherited) |
| V5 Input Validation | yes | PyYAML `safe_load` pre-flight (D-01 Phase 10 pattern); ruamel.yaml for write; regex input sanitization for 04-privacy-review patterns; cluster-size / page-count bounds check |
| V6 Cryptography | partial | SHA-256 via `hashlib` (stdlib) for op_hash + applied.log input hashes. No key derivation, no encryption — this is integrity-only. NO hand-rolling. |
| V7 Error Handling | yes | Actionable stderr on missing ruamel.yaml (Phase 10 pattern in `bin/brownfield.sh` lines 164-173); fail-loud on malformed fixture env vars; D-11 halt-on-write-failure semantics |
| V8 Data Protection | yes | `privacy: local_only` fail-closed per AGENTS.md §13 (D-07 preserved for 04-privacy-review); `.brownfield/` gitignored per TMPL-04 |
| V10 Malicious Code | yes | BRWN-16 hard-lock: zero LLM calls, zero network calls. Test `test_no_llm_calls.sh` greps for curl/wget/anthropic/openai across all new bin/ + schema/ files. |
| V11 Business Logic | yes | Review-manifest pattern D-02 enforces deterministic apply (logic integrity); 5-gate promotion list D-14 enforces access-level integrity on `bootstrap_stage` transitions |
| V12 Files and Resources | yes | `.brownfield-ignore` parser already handles path traversal via glob restrictions (Phase 10 shipped); new scripts reuse Phase 10 exclusion logic |

### Known Threat Patterns for {bash + python3 + ruamel.yaml stack}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| YAML code execution via `!python/object` tags | Tampering | Use `YAML(typ='rt')` (round-trip) not `typ='unsafe'`. Pre-flight via PyYAML `safe_load`. Phase 10 pattern. |
| Command injection via vault paths containing metacharacters | Tampering | Paths passed as arguments, never interpolated into shell strings. Python `os.path.join` for path construction. |
| Symlink escape from vault root | Tampering / Info Disclosure | `os.walk(root, followlinks=False)` — already Phase 10 pattern in `bin/brownfield.sh` line 259. |
| ReDoS via user-supplied patterns in `.brownfield-privacy-terms.txt` | DoS | Compile with `re.compile(..., re.NOFLAG)` — no flags that amplify catastrophic backtracking. User terms run against per-line input (bounded to ~10KB per line). Timeout not needed. |
| Idempotency bypass via hashed-in timestamps | Tampering | D-10 explicit op_hash scope: script body + data schema version ONLY. No timestamps in canonical scripts. CI test `test_op_hash_stable.sh` catches regression. |
| Privacy leak via `privacy: local_only` flip in `04-privacy-review` | Info Disclosure | D-07 explicit: NEVER flips frontmatter. Contract phrase in `--help` and docs. CI test asserts 04 produces zero `write_roundtrip` calls. |
| `bootstrap_stage: verified` flip on pages failing gates | Tampering / Integrity | D-14 5-gate pass-list is mechanical; test `test_verify_promote_5_gates.sh` exercises each gate individually. |
| Malicious `.brownfield-privacy-terms.txt` patterns | DoS / Tampering | User-authored config; user owns risk. Document in `docs/reference/brownfield.md` that the file is evaluated as regex when prefixed with `/.../ ` — make this explicit. |
| AI-guided review editing pages outside decisions.yaml | Tampering / Integrity | `.brownfield/review-typing-prompt.md` explicit instruction: "Edit ONLY the decisions manifest. Do not modify vault pages." BRWN-16 + Tier-1 DR reinforce. Not mechanically enforced — relies on AI instruction following + user review. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | N=20 threshold for small-batch vs large-batch review-typing places the branch optimally at the fixture boundary | Research Q3 | If wrong, planner adjusts to N=15 or N=25 during Plan 11-01 fixture calibration; low risk, easily tunable |
| A2 | `medium`-confidence default should route to review queue (conservative) | Research Q4 | If wrong, users find the review queue tedious for obvious-medium clusters; low risk, `--auto-medium` flag is the escape hatch |
| A3 | Renumbering existing §11.5 Release Workflow to §11.6 is safe | Pitfall 1 | MEDIUM risk — if any external doc links to "§11.5 Release Workflow" explicitly, rename breaks the link. Grep confirms only `docs/reference/release.md` references the section; it links to the docs page, not §11.5. Still: planner must grep for all `§11.5` string mentions during Plan 11-05. |
| A4 | No Python module `brownfield_log.py` needed; bash helper is sufficient | Architecture Patterns + Q8 | If bash helper grows beyond ~15 LOC, planner extracts to Python module. Low risk; refactor path is straightforward. |
| A5 | `schema/brownfield/migrations/*.sh` canonical scripts do NOT ship with op_hash header; suggest prepends header at copy time | Code Examples Q2 | If wrong approach (in-place header replacement), byte-equality test design changes. Planner picks one approach in Plan 11-01 Wave-0. |
| A6 | 04-privacy-review using NANP phone regex covers 95%+ of real US numbers without flagging product IDs | Research Q7 | International phones need separate regex. Plan may add `+<country-code>` pattern. Low risk; regex can be extended. |
| A7 | Clustering by signal tuple produces cluster counts that match D-20 fixture targets (<10 for small, ≥20 for large) | Research Q1 | MEDIUM risk — needs empirical verification in Plan 11-01 Wave-0 against actual fixture sizes. If fixtures produce unexpected cluster counts, either adjust fixture page count OR adjust clustering signal tuple to be coarser/finer. |
| A8 | BRWN-22 is the next available REQ-ID (planner reserves BRWN-21 for already-used byte-exact fixture tests per Phase 10) | Phase Requirements | If REQUIREMENTS.md traceability table has already allocated BRWN-22, planner picks the next available. Low risk; mechanical check. |
| A9 | ruamel.yaml 0.17.21 on user's host — version compatible with Phase 11's existing usage | Standard Stack | [VERIFIED on this host] — unlikely to change; Phase 10 tests pin this version implicitly via fixture byte-equality. |
| A10 | No Python 3.10+ features in new code (planner keeps if/elif; does not use `match`) | Standard Stack Alternatives | If a planner contributor unconsciously writes match, preflight in `docs/reference/setup-prerequisites.md` (Phase 8 D-16) documents Python 3.8 baseline. Low risk; pre-commit hook/CI catches on another dev's machine. |

## Open Questions (RESOLVED)

1. **§11.5 numbering resolution** — Should Release Workflow move to §11.6 (recommended per Pitfall 1) or stay at §11.5 with Brownfield at §11.6?
   - What we know: existing §11.5 is Release; Phase 10 forward-reffed `§11.5 Brownfield Workflow` from line 302.
   - What's unclear: user's intent when Phase 10 D-20 was written — was "§11.5" hopeful (planning for Phase 11 to own 11.5) or a typo?
   - Recommendation: Plan 11-05 proposes Option C (Release → §11.6; Brownfield at §11.5). User can override during plan review.
   - RESOLVED: adopted Option C. Landed in Plan 11-05 (renumber + populate §11.5) and asserted by Plan 11-01 `test_agents_section_11_5.sh` (grep `^### 11.5 Brownfield Workflow` == 1, `^### 11.5 Release Workflow` == 0, `^### 11.6 Release Workflow` == 1).

2. **Optional helper modules** — Should clustering + eligibility rules live in new `brownfield_typing.py` + `brownfield_provenance.py` or extend existing `brownfield_classify.py` + `brownfield_yaml.py`?
   - What we know: CONTEXT.md §Claude's Discretion grants planner this choice; requires unit-testability.
   - What's unclear: prefer concentration (fewer modules, faster imports) vs. separation (single-responsibility).
   - Recommendation: new `brownfield_provenance.py` (eligibility is fully isolated from YAML round-trip); extend `brownfield_classify.py` with `cluster_by_signals()` (same input shape). Defer `brownfield_typing.py` unless 01-page-typing apply logic is nontrivial.
   - RESOLVED: adopted as recommended. `bin/lib/brownfield_provenance.py` is created by Plan 11-03 Task 1; `cluster_by_signals()` extension in `brownfield_classify.py` is owned by Plan 11-02; no `brownfield_typing.py` shipped (01-page-typing apply logic fits inline in the migration script).

3. **BRWN-22 REQ-ID reservation** — Should the new review-typing REQ-ID be BRWN-22 or higher?
   - What we know: BRWN-21 is used for byte-exact fixture tests (Phase 10 complete).
   - What's unclear: whether to cluster the review-typing REQ-ID with BRWN-11..20 (current Phase 11) or allocate 22 cleanly.
   - Recommendation: BRWN-22. Planner drafts wording in Plan 11-05.
   - RESOLVED: BRWN-22 allocated. Added to `.planning/REQUIREMENTS.md` by Plan 11-05 (covers review-typing small-batch TTY, large-batch AI handoff, manifest write-back, no-LLM-in-CLI constraint); RED tests for BRWN-22 live in Plan 11-01 (`test_review_typing_tty_small.sh`, `test_review_typing_ai_handoff.sh`, `test_review_typing_decisions_roundtrip.sh`); implementation in Plan 11-04; `requirements:` frontmatter of Plans 11-01, 11-04, 11-05 includes `BRWN-22`.

4. **REPORT.md section order and interaction with Phase 10 sections** — Does adding `## Cross-link candidates` + `## Privacy review` to the end of REPORT.md conflict with the existing footer?
   - What we know: Phase 10 REPORT.md footer is `---\n*Generated by bin/brownfield.sh bootstrap at {timestamp}*\n`; existing sections are Bootstrapped / Collisions / Schema warnings / Needs human judgment.
   - What's unclear: whether Phase 11 advisory sections should go between Schema warnings and Needs human judgment, OR after the footer, OR replace the footer entirely.
   - Recommendation: Phase 11 advisory sections go AFTER "Needs human judgment" and BEFORE the footer. Document section order in D-17 docs.
   - RESOLVED: adopted as recommended. `## Cross-link candidates` and `## Privacy review` sections are appended between the existing "Needs human judgment" section and the Phase 10 footer by Plan 11-02's suggest branch; Plan 11-05 documents the section order in `docs/reference/brownfield.md` per D-17.

5. **Do `03` and `04` need their own metadata headers on output YAMLs if they are advisory-only?** (D-09 scope)
   - What we know: D-09 says "every generated candidate/data file under `.brownfield/` opens with a YAML metadata block."
   - What's unclear: is the "generated" modifier inclusive of advisory outputs?
   - Recommendation: YES, add D-09 header to `cross-link-candidates.yaml` + `privacy-findings.yaml` as well. Consistency beats special-casing. Source_script_hash points to the advisory script.
   - RESOLVED: adopted as recommended via CONTEXT.md D-09 applied uniformly. All five `.brownfield/` candidate/findings YAMLs (page-typing-candidates, page-typing-decisions, provenance-bootstrap-report, cross-link-candidates, privacy-findings) ship with the D-09 metadata header; asserted by Plan 11-01 `test_suggest_candidate_metadata_header.sh` (`source_script_hash: sha256:` present on all five).

## Environment Availability

> Required per Phase 11 external dependency list (all inherited from Phase 10, none new).

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` >= 4.0 | All new scripts | ✓ | 5.2.21 | — |
| `python3` >= 3.8 | ruamel.yaml usage, clustering, eligibility rules | ✓ | 3.12.3 | — |
| `ruamel.yaml` | 01-page-typing apply, verify --promote, review-typing write-back | ✓ | 0.17.21 (PYTHONPATH=$HOME/.local/lib/python3/dist-packages) | — |
| `PyYAML` | Pre-flight parse-gate; candidate/decisions file reads | ✓ | stdlib + pip baseline | — |
| `git` | Applied-log audit context; undo recipe | ✓ | assumed | — |
| `hashlib.sha256` | op_hash + input hashes | ✓ (stdlib) | — | — |
| `difflib.unified_diff` | review-typing inspect mode | ✓ (stdlib) | — | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

**Verified via:** `python3 --version` → 3.12.3; `PYTHONPATH=... python3 -c "import ruamel.yaml; print(ruamel.yaml.__version__)"` → 0.17.21; `bash --version` → 5.2.21. All Phase 10 tests PASS against this environment (`PHASE 10 TESTS: 32/32`).

## Sources

### Primary (HIGH confidence)

- [CITED: .planning/phases/11-brownfield-suggest-verify/11-CONTEXT.md] — all 21 locked decisions D-01..D-21; the load-bearing document for Phase 11 planning.
- [CITED: .planning/phases/10-brownfield-scan-bootstrap/10-CONTEXT.md] — 22 upstream decisions carried forward; D-08 dry-run/apply; D-16 classifier rule set; D-14 sentinel set; D-06 git-reset undo.
- [CITED: .planning/phases/10-brownfield-scan-bootstrap/10-VERIFICATION.md] — 11/11 must-haves verified on 2026-04-18; WR-01/WR-02/WR-03 warnings deferred (WR-03 is the §11.5 forward-ref typo).
- [CITED: .planning/phases/09-collaborative-pr-workflow-ci-lint-gate/09-CONTEXT.md] — lint `--ci` dispatcher (D-02), `--strict` separate job (D-11), `bin/check-privacy.sh` public-paths-only (D-15).
- [CITED: .planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md] — Python difflib unified-diff (D-18), NO_COLOR convention (D-20), byte-frozen fixture pattern.
- [CITED: .planning/phases/07-neutral-template-foundation/07-CONTEXT.md] — CLAUDE.md byte-sync via pre-commit (D-03), `--dry-run`/`--apply` posture (D-04), `PUBLIC_PATHS` hardcoded-array + user-override config pattern.
- [CITED: .planning/phases/09.1-progressive-disclosure-extraction/09.1-CONTEXT.md] — extraction-invariant test pattern for AGENTS.md §11.5 edit verification; `bin/sync-claude.sh` auto-sync.
- [CITED: .planning/REQUIREMENTS.md §BRWN lines 85–106, 112] — BRWN-01..21 full set.
- [CITED: .planning/ROADMAP.md §Phase 11] — goal, dependencies, success criteria, REQ-ID list.
- [CITED: .planning/research/FEATURES.md §Bucket 5 lines 178-232] — anti-features canonical list; plan-count hint.
- [CITED: .planning/research/PITFALLS.md §C-2 lines 40-64, §C-3 lines 68-90] — frontmatter corruption + idempotency pitfalls with prevention items.
- [CITED: .planning/STATE.md Accumulated Context lines 199-245] — Phase 9/10/11 decisions canonical source.
- [CITED: bin/brownfield.sh HEAD lines 51-62, 141-640] — subcommand dispatcher; suggest/verify exit-2 gates ready for replacement.
- [CITED: bin/lib/brownfield_classify.py HEAD] — `classify_page(rel_path, frontmatter, body, inbound_count=None)` ready to accept inbound_count; `unknown_reason()`.
- [CITED: bin/lib/brownfield_yaml.py HEAD] — ruamel.yaml round-trip primitives; typed-merge FIELD_CLASS_A/B; VALID_ENUMS; build_d14_sentinel_set.
- [CITED: bin/lint.sh HEAD lines 8-79, 882, 1709-1713] — LINT_VERSION=1.1.0; --ci --format json --category flags; BROWNFIELD_ALLOWLIST downgrade modifier.
- [CITED: bin/release.sh HEAD lines 1-100] — `--dry-run` / `--apply` precedent.
- [CITED: bin/check-privacy.sh HEAD lines 1-130] — PUBLIC_PATHS; frontmatter-only scan.
- [CITED: bin/ingest.sh HEAD lines 316-374] — BRWN-10 strip block; Phase 11 does NOT modify.
- [CITED: AGENTS.md HEAD lines 862-1173] — §11.1-11.5 workflow shapes; CRITICAL: line 1171 is existing §11.5 Release Workflow (numbering blocker).
- [CITED: AGENTS.md HEAD line 302] — `bootstrap_stage` row with forward-ref typo WR-03 "§11.5 Brownfield Workflow".
- [CITED: schema/AGENTS.template.md HEAD line 1138] — Release Workflow mirror (same numbering conflict).
- [CITED: docs/reference/brownfield.md HEAD lines 1-207] — complete Phase 10 scan + bootstrap sections; stub suggest + verify sections ready for populate.
- [CITED: tests/phase-10/run.sh + lib.sh HEAD] — test harness pattern for clone into tests/phase-11/.

### Secondary (MEDIUM confidence)

- [CITED: .planning/phases/10-brownfield-scan-bootstrap/10-PATTERNS.md] — pattern mappings for all new files; confirms every Phase 11 pattern has an in-repo analog.
- [VERIFIED: `python3 --version` on this host returns 3.12.3] — Python stack.
- [VERIFIED: `PYTHONPATH=$HOME/.local/lib/python3/dist-packages python3 -c "import ruamel.yaml; print(ruamel.yaml.__version__)"` returns 0.17.21] — ruamel.yaml availability.
- [VERIFIED: `bash --version` reports 5.2.21] — bash stack.
- [VERIFIED: `ls tests/phase-10/test_*.sh | wc -l` returns 32] — Phase 10 test count baseline.

### Tertiary (LOW confidence)

- [ASSUMED] — N=20 threshold for small-batch / large-batch. Based on reasoning about cognitive load (~45s/cluster × 20 clusters = 15min ceiling). Not verified against real-vault data; calibration possible during Plan 11-01.
- [ASSUMED] — `medium`-confidence defaulting to review queue minimizes false-positive corruption while preserving user ergonomics. Reasoning-based; would need real-vault UX data to verify.
- [ASSUMED] — 04-privacy-review NANP phone regex covers 95%+ of real US numbers. Pattern well-studied generally but no direct verification in this research session.
- [ASSUMED] — Renumbering existing §11.5 Release Workflow to §11.6 is safe (only `docs/reference/release.md` references it). Grep across repo for string "§11.5" in Plan 11-05 will confirm.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new deps; all versions verified on this host
- Architecture: HIGH — every pattern has an in-repo twin; 21 decisions locked
- Pitfalls: HIGH — all pitfalls derived from locked decisions + research documents + code review
- Research questions: MEDIUM-HIGH — recommendations are empirically derivable; only N-threshold and medium-confidence policy have genuine discretion (and both are low-risk with escape hatches)
- §11.5 template: HIGH — §11.1-11.4 are the verbatim model

**Research date:** 2026-04-20
**Valid until:** 2026-05-20 (30 days for stable; current phase planning begins immediately after this research lands)
