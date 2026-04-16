# Phase 8: Two-Track Setup (Wizard + Manual) - Research

**Researched:** 2026-04-16
**Domain:** Bash CLI tooling, template rendering, YAML handling, byte-equality CI testing
**Confidence:** HIGH

## Summary

Phase 8 ships `bin/init-wizard.sh` (bash) and `docs/manual-setup.md` (hand-edit walkthrough) such that both paths produce a byte-identical personalized `AGENTS.md` + `CLAUDE.md` + `.wizard-answers.yaml` + initial decision record. Every architectural decision has already been locked in `08-CONTEXT.md` (D-01..D-26); the planner's job is to sequence the implementation against existing `bin/` conventions, not to re-explore alternatives.

The build is firmly inside the project's "zero new runtime deps" posture: bash + python3 stdlib only, reusing `bin/sync-claude.sh` for AGENTS.md→CLAUDE.md mirroring, mirroring `bin/release.sh`'s `--dry-run` / `--apply`-style flag conventions (inverted: wizard default mutates, `--dry-run` previews), and extending the existing `tests/phase-07/` + `.github/workflows/neutrality.yml` test + CI infrastructure with a new byte-equality fixture test.

**Primary recommendation:** Implement `bin/init-wizard.sh` as a bash entrypoint that (1) pre-flights `git` + `bash >= 4` + `python3`, (2) either prompts interactively or reads `--answers-file` via a python3 inline block, (3) renders `schema/AGENTS.template.md` by 4-token substitution through a python3 block, (4) writes `.wizard-answers.yaml`, AGENTS.md, CLAUDE.md (via `bin/sync-claude.sh`), and `wiki/decisions/dr-<today>-initial-setup.md`. `--dry-run` substitutes the same render pipeline but emits unified `difflib` diffs instead of writing. Commit `schema/fixtures/canonical-answers.yaml` + `schema/fixtures/canonical-AGENTS.md`; the CI byte-equality test runs `bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --dry-run-render-to <tmp>` (or equivalent pure-render mode) and `cmp -s` against the fixture.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Placeholder Set (Area 2)**
- **D-01:** Template stays at **exactly 4 placeholders** (Phase 7 D-08 upheld): `{{PRIMARY_DOMAIN}}`, `{{DEFAULT_PRIVACY}}`, `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`. `{{EXAMPLE_CLUSTER_REF}}` stays rejected; `{{USER_NAME}}` stays out of AGENTS.md and lives only in `.wizard-answers.yaml` + the initial decision record.
- **D-02:** **Amend WZRD-07** in `.planning/REQUIREMENTS.md` to state "exactly 4 placeholders" and drop `{{USER_NAME}}` + `{{EXAMPLE_CLUSTER_REF}}` from its list. Amendment is part of Phase 8; note the change in the phase's decision record.

**Idempotency & Re-run (Area 3)**
- **D-03:** **Initialization signal** is presence of `.wizard-answers.yaml` at repo root (primary, wizard-owned). AGENTS.md at repo root is a secondary sanity check.
- **D-04:** **Re-run behavior (interactive / answers-file, no `--dry-run`):** refuse with clear non-zero exit. Message names the answers file and its setup date, explains no `--force` exists in v1.1, points at "delete `.wizard-answers.yaml` and `AGENTS.md` to re-run from scratch; upgrade flow coming in v1.2."
- **D-05:** **Manual-looking repo without answers file** (AGENTS.md placeholder-free but no `.wizard-answers.yaml`): warn and require deliberate handling. No destructive overwrite. Recommended recovery = follow the manual-setup checklist exit step that writes an `.wizard-answers.yaml` matching the hand-edited state.
- **D-06:** **`--dry-run` is always allowed** to render/preview regardless of initialization state. Pure preview, never mutates.

**Manual Track & Byte-Equality (Area 4)**
- **D-07:** **`docs/manual-setup.md` structure:** prompt-ordered — 6 numbered sections (one per wizard prompt), each with (i) the wizard's question, (ii) the file/line to edit, (iii) an inline minimal diff snippet, (iv) an example value. Ends with wizard-prompt checklist (MANUAL-03), equivalence statement (MANUAL-04), file-touch list (MANUAL-05).
- **D-08:** **Canonical-answers fixture location:** `schema/fixtures/canonical-answers.yaml`. Colocated with `schema/AGENTS.template.md`.
- **D-09:** **Byte-equality test mechanics (MANUAL-06):** commit the expected rendered artifact at `schema/fixtures/canonical-AGENTS.md`. CI runs `bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --dry-run` (or writes to a tempdir) and diffs against `canonical-AGENTS.md`. The manual-setup.md minimal-diff example must land on the same file when followed.
- **D-10:** **Minimal-diff example (MANUAL-02) domain:** `personal-knowledge` (aligns with PROJECT.md; distinct from `examples/kahneman/`). Do NOT reuse Kahneman — would regress NEUT-02/03.

**Prompt Set & Allowed Values (Area 1)**
- **D-11:** **Six prompts in this order:** (1) Maintainer name → `.wizard-answers.yaml` + decision record, default from `git config user.name`. (2) Primary domain → `{{PRIMARY_DOMAIN}}`, `^[a-z0-9-]+$`, default `personal-knowledge`. (3) LLM agent → `{claude-code, codex, other}`, default `claude-code`; resolves `{{AGENT_FILENAME}}` = `CLAUDE.md` for `claude-code`, `AGENTS.md` for `codex`/`other` (both files always written per Phase 7 D-03). (4) Privacy tier → `{local_only, cloud_safe}`, default `local_only`; substituted into `{{DEFAULT_PRIVACY}}`. (5) Decay profile → `{software, science, biography, personal-goals, default}`, default `default` (maps to AGENTS.md §6 decay table). (6) Obsidian browsing → y/n, default y; recorded but does NOT alter generated AGENTS.md.
- **D-12:** **No three-named-profile privacy abstraction in v1.1.** Deferred.
- **D-13:** **Semantic groups (WZRD-02) cover prompts 2–6 in four groups:** Domain (p2) → LLM agent (p3) → Privacy defaults (p4 + p5) → Obsidian conventions (p6). Maintainer name (p1) prints first with its own one-line explainer. Each group prints a one-sentence explainer before its questions.

**Validation & Pre-flight UX (Area 5)**
- **D-14:** **Validation posture is mode-dependent.** Interactive = fail-fast per prompt, re-prompt. `--answers-file` = collect all errors, print summary, exit non-zero. Shared validator returns `{valid: bool, errors: [{field, rule, example}]}`.
- **D-15:** **Pre-flight (WZRD-09) runs before any prompting or file I/O.**
- **D-16:** **Pre-flight error format:** terse one-line-per-missing-tool + pointer to `docs/reference/setup-prerequisites.md`.
- **D-17:** **Invalid-input error (WZRD-04) shape:** `Invalid <field> "<value>". Must match <rule>. Try: <concrete example>.`

**Output & Diff Engine (Area 6)**
- **D-18:** **`--dry-run` output = unified diff per file** via Python `difflib.unified_diff`. Deterministic cross-platform; avoids BSD/GNU `diff` quirks. python3 already in STACK.md scope.
- **D-19:** **Completion summary (WZRD-08) format (real run):** `<path>  (<size>, <short status>)` per file, followed by `Next: bin/ingest.sh <path/to/first/source>` hint. No inline diff on real runs.
- **D-20:** **Color/TTY handling:** colorize when stdout is a TTY; respect `NO_COLOR` env var.

**Initial Decision Record (Area 7)**
- **D-21:** **Path:** `wiki/decisions/dr-YYYY-MM-DD-initial-setup.md` (date = wizard invocation date).
- **D-22:** **`trigger_type: schema-update`** (closest semantic fit). Do NOT widen the enum in v1.1.
- **D-23:** **`affected_pages: []`** — inaugural/infrastructure record.
- **D-24:** **Body is wizard-generated from a deterministic template** — all 7 required sections filled via substitution. No LLM-in-wizard.
- **D-25:** **Captured metadata:** the six answers, wizard version string, ISO timestamp, template git SHA via `git log -1 --format=%H schema/AGENTS.template.md` (emit `<unresolved>` if not in a git checkout).
- **D-26:** **`.wizard-answers.yaml` is the machine-authoritative source.** Decision record narrates in prose, links to it in Sources — no verbatim YAML duplication.

### Claude's Discretion

- Exact wording of semantic-group one-sentence explainers (D-13).
- Concrete prompt prompt-text strings, spacing, in-wizard status formatting.
- Exit code numbers beyond 0/non-zero (distinct codes for pre-flight vs. validation).
- `.wizard-answers.yaml` YAML key names and ordering (snake_case per AGENTS.md §3).
- Whether `--answers-file` reads YAML via a python3 inline block or small bash parser (python3 inline likely cleaner).
- Exact layout of `docs/reference/setup-prerequisites.md` (scoped to bash ≥ 4 + git + python3 install commands across macOS / Debian / Ubuntu / Arch / WSL).
- Whether pre-flight lives inline in `bin/init-wizard.sh` or as a shared helper `bin/_preflight.sh`.

### Deferred Ideas (OUT OF SCOPE)

- `bin/init-wizard.sh --upgrade` (copier-update-style 3-way merge) — v1.2.
- `--force` flag — v1.2.
- Named privacy profiles (`strict`/`mixed`/`open`) — v1.2.
- `bootstrap` trigger_type added to AGENTS.md §4.6 enum — deferred.
- Multi-domain starter presets — deferred.
- GUI wizard / Electron / web form — out of scope.
- LLM-in-wizard — rejected.
- Network-dependent wizard behavior — rejected.
- Doc-parsing byte-equality test (extract snippets from manual-setup.md programmatically) — deferred.
- Platform-specific prerequisite install automation — out of scope.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WZRD-01 | `bin/init-wizard.sh` exists, bash-only, no new deps | Stack: bash 5.2 + python3 3.12 + PyYAML 6.0.1 already in workflow env; zero-new-deps posture upheld via python3 inline blocks (Architecture Pattern 1). |
| WZRD-02 | Semantically grouped prompts with explainers | D-13 locks 4 groups + name; implementation is ~8 `echo` / `printf` blocks. Pattern: see `bin/release.sh` plan output section (lines 108–118) for grouped-section echo idiom. |
| WZRD-03 | `--answers-file <path>` non-interactive mode | Architecture Pattern 3 (YAML read via python3 inline). `bin/check-neutrality.sh` lines 109–388 is the canonical python3-inline-env-var pattern to mirror. |
| WZRD-04 | Input validation (domain slug, agent, privacy tier) | Shared validator returning `{valid, errors[]}`, called per-prompt interactively and once-per-batch from file (D-14). Regex for domain slug: `^[a-z0-9-]+$` — identical pattern already enforced in `bin/ingest.sh:159`. |
| WZRD-05 | Idempotent re-run: refuse with clear message | D-03: check `.wizard-answers.yaml` presence at repo root. D-04: refusal message text and exit non-zero. |
| WZRD-06 | Writes `.wizard-answers.yaml` with inputs | YAML write via python3 inline block; keys: 6 answers + wizard version + ISO timestamp + template git SHA (D-25). |
| WZRD-07 | Renders `schema/AGENTS.template.md` via ≤6 placeholders | **AMEND per D-02** to "exactly 4 placeholders." Existing template verified at 4 placeholders: `{{PRIMARY_DOMAIN}}` (line 588), `{{DEFAULT_PRIVACY}}` (line 589), `{{AGENT_FILENAME}}` (line 32), `{{DECAY_PROFILE}}` (line 848). One line in the template also contains `{{PRIMARY_DOMAIN}}` as an illustrative reference inside the directory-structure comment at line 56 — **verified: this is the same token, 4 distinct tokens total, 5 occurrences**. |
| WZRD-08 | Prints file list + summary diff on completion | D-19: `<path>  (<size>, <short status>)` per file + single `Next:` hint. Unified diff only on `--dry-run`. |
| WZRD-09 | Pre-flight: `git`, `bash >= 4`, actionable message | D-15: runs BEFORE any prompting or file I/O. Check `bash --version` grep for major ≥ 4, `command -v git`. D-16: one-line-per-missing-tool + pointer to `docs/reference/setup-prerequisites.md`. |
| WZRD-10 | Writes initial decision record (DCSN-01) | D-21..D-26: deterministic template substitution into `wiki/decisions/dr-YYYY-MM-DD-initial-setup.md`. `trigger_type: schema-update`, `affected_pages: []`, all 7 sections filled. |
| WZRD-11 | `--dry-run` prints rendered diff without applying | D-18: python3 `difflib.unified_diff` per file. Pattern: compare empty (or existing) file vs. rendered-content string. |
| MANUAL-01 | `docs/manual-setup.md` walks section-by-section through AGENTS.md | D-07: 6 numbered sections = 6 wizard prompts. Each section points at exact file/line in AGENTS.md that changes. |
| MANUAL-02 | Minimal-diff example | D-07 + D-10: neutral `personal-knowledge` setup; concrete before/after snippets embedded in the doc. |
| MANUAL-03 | Checklist one-to-one with wizard prompts | D-07: ends with 6-item checklist. |
| MANUAL-04 | Explicit equivalence statement | D-07: "Manual track and wizard produce byte-identical end state (enforced by CI per MANUAL-06)." |
| MANUAL-05 | Lists every file the wizard touches | D-07: file-touch list = `AGENTS.md`, `CLAUDE.md`, `.wizard-answers.yaml`, `wiki/decisions/dr-YYYY-MM-DD-initial-setup.md`. |
| MANUAL-06 | Byte-equality CI test | D-09: commit `schema/fixtures/canonical-AGENTS.md`; CI renders via `--answers-file schema/fixtures/canonical-answers.yaml` to a tempdir and `cmp -s` or `diff -q` against the committed fixture. |

## Project Constraints (from CLAUDE.md)

CLAUDE.md at repo root is a byte-identical copy of AGENTS.md (TMPL-10 / Phase 7 D-03). The relevant project directives that affect Phase 8:

- **Permitted top-level directories** (AGENTS.md §2): `sources/`, `wiki/`, `schema/`, `examples/`, `docs/`, `.github/`, `bin/`, `.githooks/`. Adding `schema/fixtures/` is within `schema/` (permitted). Adding `.wizard-answers.yaml` at repo root is a NEW top-level file but not a directory — allowed because it's a wizard-authoritative artifact analogous to `.gitignore`. Update `.gitignore` to NOT exclude it (it must commit so users can share/upgrade).
- **Date format** (AGENTS.md §3): ISO 8601 `YYYY-MM-DD`. The decision-record filename + `created_at` + wizard `timestamp` must use this.
- **Frontmatter field names**: `snake_case`. `.wizard-answers.yaml` keys follow the same convention.
- **Commit conventions**: conventional commits. Phase 8 commits will use `schema:` for template/placeholder amendments and… no explicit type exists for wizard tooling; use plain descriptive commits (`docs(manual-setup): …`, `bin(init-wizard): …`) or scope under `schema:` for fixture writes. Planner decides.
- **LLM Navigation Rule / Red Links / What Agents Must NOT Do**: not load-bearing for this phase; the wizard does not edit wiki content.
- **Section 4.6 (Decision records)**: initial decision record must conform — `type: decision`, required fields (`trigger_type`, `affected_pages`), all 7 sections present. Schema verified via existing `schema/templates/decision.md`.
- **Section 13 (Privacy Routing)**: the wizard + generated AGENTS.md + decision record are `cloud_safe`. `.wizard-answers.yaml` contains maintainer name — declare it `cloud_safe` by convention (committed to repo); users with privacy concerns edit by hand before committing. Document this in `docs/manual-setup.md`.
- **File writing discipline**: Never use `cat << EOF` to create files. The wizard IS a script that writes files; it uses `cp` + python3 stdout redirection + explicit write steps. This directive is for agent tool use, not script implementation.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash | 5.2.21 | Script entrypoint, flag parsing, interactive prompts | Matches `bin/release.sh`, `bin/check-neutrality.sh`, `bin/ingest.sh` — uniform across the project. |
| python3 | 3.12.3 | Inline blocks for YAML read/write, template render, difflib | Already required by Phase 7 CI (`actions/setup-python@v6` with `python-version: '3.12'` in `.github/workflows/neutrality.yml`). Zero new runtime deps. |
| git | 2.43.0 | `git config user.name` for name default, `git log -1` for template SHA | Pre-flight requirement; every project contributor already has it. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| PyYAML | 6.0.1 | Reading `.wizard-answers.yaml` and `schema/fixtures/canonical-answers.yaml` | Already installed in neutrality CI step (`pip install pyyaml`). Available locally on dev machine. **Verified version current**: PyYAML 6.0.1 published 2023-07-18 (via `pip show pyyaml`). |
| difflib | stdlib | Unified diff generation for `--dry-run` output | Python stdlib; always available; deterministic output format. |
| cmp / diff -q | GNU coreutils | Byte-equality assertion in CI test | Canonical project pattern — `bin/sync-claude.sh` uses `cmp -s`; MANUAL-06 mirrors. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| PyYAML | Hand-rolled ~15-line key:value parser in python3 stdlib | D-26 / spec locks `.wizard-answers.yaml` as flat, controlled key set. Hand-rolled parser avoids PyYAML as a hard dep (`docs/reference/setup-prerequisites.md` simpler). But PyYAML is already installed in CI and is trivially `pip install`-able. **Recommendation:** use PyYAML when available; fall back to a minimal stdlib parser if absent so the wizard works on fresh dev machines without `pip install pyyaml`. Detect via `try: import yaml; except: <fallback>`. |
| python3 difflib | BSD/GNU `diff -u` | D-18 locks python3 difflib for deterministic cross-platform output (avoids BSD vs. GNU flag differences on macOS vs. Linux). |
| sed / awk template render | python3 `.replace()` | sed special-character escaping nightmares with `{{` `}}`. Template substitution must happen in python3 with literal-string replacement. |

**Installation:**
```bash
# No installation required for normal use; all deps already present in dev + CI.
# User-facing pre-flight enforces: bash >= 4, git, python3.
# Optional for full fidelity: pip install pyyaml (or rely on fallback parser).
```

**Version verification:**
```bash
$ bash --version | head -1   # GNU bash, version 5.2.21(1)-release
$ python3 --version          # Python 3.12.3
$ git --version              # git version 2.43.0
$ python3 -c "import yaml; print(yaml.__version__)"  # 6.0.1
```
All versions current as of 2026-04-16.

## Architecture Patterns

### Recommended Project Structure

```
bin/
├── init-wizard.sh          # NEW — main entrypoint (bash + python3 inline blocks)
├── _preflight.sh           # OPTIONAL — shared pre-flight helper (Claude's discretion D-16)
├── sync-claude.sh          # EXISTING — invoked by init-wizard after AGENTS.md write
├── release.sh              # EXISTING — pattern reference for --dry-run / --apply
├── check-neutrality.sh     # EXISTING — pattern reference for python3 inline blocks
└── ingest.sh               # EXISTING — pattern reference for slug validation
schema/
├── AGENTS.template.md      # EXISTING — 4 placeholders at lines 32, 588, 589, 848
└── fixtures/
    ├── canonical-answers.yaml    # NEW — committed fixture for MANUAL-06
    └── canonical-AGENTS.md       # NEW — expected rendered output for MANUAL-06
docs/
├── manual-setup.md         # STUB → FULL — D-07 prompt-ordered walkthrough
├── guided-setup.md         # STUB → FULL — wizard walkthrough (brief)
├── quickstart.md           # STUB → FULL — populate wizard + ingest sections
└── reference/
    └── setup-prerequisites.md  # NEW (per D-16) — bash/git/python3 install across platforms
tests/phase-08/             # NEW — mirror tests/phase-07/ layout
├── run.sh                   # aggregator — iterates test_*.sh
├── test_wizard_dryrun.sh    # --dry-run never mutates
├── test_wizard_canonical.sh # MANUAL-06 byte-equality
├── test_wizard_idempotent.sh # D-04 re-run refusal
├── test_wizard_validation.sh # D-14 fail-fast + collect-all
├── test_manual_setup_checklist.sh # MANUAL-03 one-to-one mapping
└── fixtures/                # minimal repo skeletons for integration tests
.github/workflows/
└── neutrality.yml          # EXTENDED — add Phase 8 test suite step OR new workflow
.planning/
└── REQUIREMENTS.md         # AMEND — WZRD-07 text per D-02
```

Artifacts written at wizard runtime (target repo, not this repo):
- `AGENTS.md` (rendered from template)
- `CLAUDE.md` (via `bin/sync-claude.sh`)
- `.wizard-answers.yaml` (YAML, authoritative answer set)
- `wiki/decisions/dr-YYYY-MM-DD-initial-setup.md` (decision record)

### Pattern 1: Bash + Python3 Inline Block (canonical project idiom)

**What:** Bash handles flag parsing, user interaction, and control flow. Python3 inline blocks handle anything non-trivial (YAML, regex, diffs, template substitution). Args pass via exported env vars.

**When to use:** Any non-trivial text manipulation. This is THE project convention — `bin/check-neutrality.sh` lines 96–388 and `bin/lint.sh` are the canonical references.

**Example:**
```bash
# Source: bin/check-neutrality.sh:96-110 (project canonical pattern)
export WZRD_ANSWERS_FILE="${ANSWERS_FILE:-}"
export WZRD_MODE="${MODE}"
export WZRD_TEMPLATE="schema/AGENTS.template.md"

set +e
python3 - <<'PYEOF'
import os, sys, re
ANSWERS = os.environ.get("WZRD_ANSWERS_FILE", "")
MODE    = os.environ.get("WZRD_MODE", "interactive")
TEMPLATE = os.environ["WZRD_TEMPLATE"]

# ... work happens here, exits 0/non-zero
PYEOF
PYRC=$?
set -e
exit "$PYRC"
```

### Pattern 2: `--dry-run` / `--apply` Flag Posture (inverted for wizard)

**What:** `bin/release.sh` defaults to `--dry-run` because publishing is destructive. The wizard INVERTS this default — normal invocation mutates (writes AGENTS.md et al.); `--dry-run` previews. The convention is the same; only the default differs.

**When to use:** Any destructive operation. Wizard is destructive in that it writes 4 files on first run. D-06 locks `--dry-run` as always-allowed regardless of initialization state.

**Example:**
```bash
# Source: bin/release.sh:12, :91-:100 (flag-parsing pattern)
DRY_RUN=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --answers-file) ANSWERS_FILE="${2:-}"; shift 2 ;;
        *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
done
```

### Pattern 3: python3 difflib Unified Diff (D-18)

**What:** Cross-platform-deterministic unified diff output. Compares "what the file looks like now" vs. "what the wizard would write." Avoids BSD/GNU `diff` flag fragmentation.

**When to use:** `--dry-run` mode output (WZRD-11).

**Example:**
```python
# Source: docs.python.org/3/library/difflib.html#difflib.unified_diff (HIGH confidence)
import difflib
def render_diff(path, existing_content, new_content):
    a = existing_content.splitlines(keepends=True) if existing_content else []
    b = new_content.splitlines(keepends=True)
    lines = difflib.unified_diff(
        a, b,
        fromfile=f"a/{path}",
        tofile=f"b/{path}",
        lineterm="",
    )
    return "".join(lines)
```

### Pattern 4: Python3 Template Substitution (4-token)

**What:** Straight `str.replace()` on 4 literal tokens. No Jinja, no envsubst. Deterministic, debuggable, zero-dep.

**When to use:** Rendering `schema/AGENTS.template.md` in both real and `--dry-run` modes.

**Example:**
```python
TOKENS = {
    "{{PRIMARY_DOMAIN}}":   answers["primary_domain"],
    "{{DEFAULT_PRIVACY}}":  answers["default_privacy"],
    "{{AGENT_FILENAME}}":   "CLAUDE.md" if answers["agent"] == "claude-code" else "AGENTS.md",
    "{{DECAY_PROFILE}}":    answers["decay_profile"],
}
with open("schema/AGENTS.template.md", "r", encoding="utf-8") as f:
    rendered = f.read()
for tok, val in TOKENS.items():
    rendered = rendered.replace(tok, val)
# Assert no placeholders left (defensive):
import re
leftover = re.findall(r"\{\{[A-Z_]+\}\}", rendered)
if leftover:
    sys.exit(f"ERROR: unrendered placeholders: {leftover}")
```

### Pattern 5: NO_COLOR + TTY detection (D-20)

**What:** Respect the no-color.org convention. Colorize iff stdout is a TTY AND `NO_COLOR` is unset.

**Example:**
```bash
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; RESET=$'\033[0m'
else
    GREEN=''; RED=''; RESET=''
fi
```

### Anti-Patterns to Avoid

- **`eval` on answers file:** Never `eval` YAML content. Use python3 `yaml.safe_load()` or the flat key-value fallback parser. Sanitized input only.
- **sed on template:** sed's special-character handling makes `{{` / `}}` escaping brittle. Use python3 `str.replace()`.
- **Reading AGENTS.md to detect placeholder-free state:** D-03 defines `.wizard-answers.yaml` as the single initialization signal. Don't grep AGENTS.md for `{{.*}}` — false negatives if template tokens legitimately appear in rendered docs.
- **Writing `.wizard-answers.yaml` atomically via truncate+write:** Use `write-to-temp → os.rename` or equivalent so partial writes don't leave a corrupted file. Idiom: python3 `pathlib.Path.write_text(..., newline='\n')`.
- **Forgetting to re-invoke `bin/sync-claude.sh`:** After writing AGENTS.md the wizard MUST sync CLAUDE.md. Either inline the logic (`cp AGENTS.md CLAUDE.md && cmp -s`) or `bash bin/sync-claude.sh` — both are acceptable; `bin/sync-claude.sh` is 35 lines and zero-dep, so invocation is cleanest.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML reading | Custom regex parser | PyYAML (`yaml.safe_load`) with stdlib fallback for controlled key set | PyYAML handles quoting, comments, booleans, Unicode. Only fall back for fresh dev machines; document. |
| Unified diff | Custom diff algorithm | `difflib.unified_diff` | Handles edge cases (trailing newlines, unicode, binary detection); deterministic output format. |
| Cross-platform bash version check | Custom parse of `bash --version` | `((BASH_VERSINFO[0] >= 4))` | Built-in bash variable, zero cost, bulletproof. |
| Template rendering | Hand-rolled token scanner | python3 `str.replace()` in a loop + post-validation regex for leftover `{{...}}` | 4 tokens; literal replacement; trivially verifiable. |
| Atomic file write | `> file` + trust | `tempfile.NamedTemporaryFile(dir=...)` + `os.rename` | Prevents partial-write corruption on Ctrl-C mid-write. |
| CLAUDE.md byte-sync | Reimplement cmp | `bash bin/sync-claude.sh` (existing, 35 lines, zero-dep) | Already shipped + tested in Phase 7. Reuse. |
| Byte-equality CI assertion | File-hash compare | `diff -q` or `cmp -s` + echo on failure | Standard shell idiom; output on failure shows exact diff lines for debugging. |

**Key insight:** Everything non-trivial already exists as a reusable pattern inside `bin/`. Phase 8's implementation cost is mostly *wiring* existing patterns together, not inventing new ones.

## Runtime State Inventory

Phase 8 is **greenfield tooling + config-only edits**; the wizard writes new files and amends existing ones. There is no rename/refactor that would need a Runtime State Inventory. The closest analogue — the one-line amendment of WZRD-07 in `.planning/REQUIREMENTS.md` (D-02) — is a documentation edit with no runtime consequences.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — no databases, no live datastores touched. Wizard writes flat files only. | None |
| Live service config | None — no external services configured in v1.1. CI neutrality workflow is file-based only. | None |
| OS-registered state | None — no cron, systemd, or OS scheduler entries. | None |
| Secrets / env vars | `NO_COLOR` is *read* (D-20) but not set. `RELEASE_EMAIL` used by `bin/release.sh` is out of scope. | None |
| Build artifacts | None — bash scripts are interpreted at runtime; no compile step. | None |

**Nothing to migrate.** The only edit that touches a "state-ish" artifact is `.planning/REQUIREMENTS.md`'s WZRD-07 line, which is a plain-text doc edit committed alongside the phase work and noted in the decision record.

## Common Pitfalls

### Pitfall 1: Wizard/manual-track drift (M-1 / M-3 from research/PITFALLS.md)
**What goes wrong:** Wizard gets updated (new prompt, changed default) but `docs/manual-setup.md` isn't; users on different tracks produce different files.
**Why it happens:** Two sources of truth maintained in parallel by the same human.
**How to avoid:** **MANUAL-06 byte-equality CI test is the mitigation.** Commit `schema/fixtures/canonical-AGENTS.md`; every PR runs `bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml` (or equivalent pure-render mode) and `diff -q` against the fixture. **Additionally**, a separate test should verify that if `docs/manual-setup.md` is edited, `schema/fixtures/canonical-AGENTS.md` is also updated — Phase 8 v1 skips this (doc-parsing test deferred per CONTEXT.md Deferred Ideas); the canonical-AGENTS.md regen cadence is manual.
**Warning signs:** Byte-equality test starts failing after a template edit OR after a manual-setup.md rewording that changed the example value.

### Pitfall 2: Trailing-newline / CRLF byte drift
**What goes wrong:** `cmp -s` fails because the wizard writes `\n`-terminated but the fixture was committed with `\r\n` (Windows editor) or missing final newline.
**Why it happens:** Git `core.autocrlf=true` on some platforms; editor-specific EOL handling.
**How to avoid:** (1) Commit `schema/fixtures/canonical-AGENTS.md` with explicit `.gitattributes` entry: `schema/fixtures/canonical-AGENTS.md text eol=lf`. (2) Wizard python3 block opens files with `newline="\n"`. (3) Always end rendered file with exactly one `\n` (match template).
**Warning signs:** CI fails on Linux but passes locally on macOS, or vice versa.

### Pitfall 3: Incomplete pre-flight causes partial state
**What goes wrong:** Wizard detects missing `git` mid-render, having already written 2 of 4 files. Re-run refuses because `.wizard-answers.yaml` now exists.
**Why it happens:** Pre-flight check too shallow; not all runtime deps verified BEFORE file I/O.
**How to avoid:** D-15 locks "pre-flight runs before any prompting or file I/O." Verify in this order: bash version → git → python3 → PyYAML (warn if missing, fall back) → writability of target paths (`.wizard-answers.yaml`, `AGENTS.md`, `CLAUDE.md`, `wiki/decisions/`). Exit non-zero if any blocker.
**Warning signs:** User reports "wizard got stuck halfway and I can't re-run."

### Pitfall 4: `{{AGENT_FILENAME}}` ambiguity
**What goes wrong:** Template says `{{AGENT_FILENAME}}` as "the canonical agent spec." D-11 resolves this to `CLAUDE.md` for claude-code, `AGENTS.md` for codex/other. But both files are ALWAYS written byte-identical per Phase 7 D-03 / TMPL-10. This is confusing: the placeholder is about which filename appears in the *text*, not which file is written.
**Why it happens:** Conceptual overload of a single placeholder.
**How to avoid:** Document explicitly in `docs/manual-setup.md` that both files are always written; `{{AGENT_FILENAME}}` only controls the self-reference line ("This file (`{{AGENT_FILENAME}}`) is the canonical agent spec…"). The test `test_wizard_canonical.sh` should render with `agent: claude-code` and assert line 32 of output reads `This file (\`CLAUDE.md\`)...`.
**Warning signs:** User reports `AGENTS.md` not getting created, or asks "why do I have both files?"

### Pitfall 5: Git config user.name default silently wrong (D-11 name default)
**What goes wrong:** User has `git config --global user.name "Some Old Name"` from a past project; wizard uses that without asking.
**Why it happens:** D-11 says default from `git config user.name when present`; interactive mode should still display it as the default in `[Default: Some Old Name]` form and allow override. Non-interactive (`--answers-file`) must reject missing `name` field rather than silently grabbing from git.
**How to avoid:** Validator requires `maintainer_name` present in `.wizard-answers.yaml`; interactive mode uses git config as a visible default. Document clearly.

### Pitfall 6: Decision record as "first reflect" when wiki has no prior decisions
**What goes wrong:** `wiki/decisions/` already has `dr-2026-04-14-phase6-decision-type.md` and `dr-2026-04-15-kahneman-to-examples.md` (creator-side). On fresh template clone these are preserved as part of the template shipped content (they explain *why* the template is shaped this way); the wizard then adds `dr-<today>-initial-setup.md` as the adopter's first record. Index.md gets updated by the wizard OR the adopter.
**Why it happens:** The two pre-existing decision records are template history; they document the template's evolution and should ship with it.
**How to avoid:** Verify behavior: on fresh clone, the wizard's initial decision record sits *alongside* the two template-history records. wiki/index.md gets a new entry under Decisions for the initial-setup record. **Decide during planning:** does the wizard also edit `wiki/index.md` to add the new record, or does it leave index.md as the adopter's job? Recommendation: edit index.md — consistency with `/gsd:...` workflows' "one commit per logical operation" principle (AGENTS.md §3).

### Pitfall 7: `.wizard-answers.yaml` committed with creator's real name
**What goes wrong:** `.wizard-answers.yaml` is cloud_safe + committed; it contains `maintainer_name` which could be the user's real name. For users who want pseudonymous collaboration this leaks PII.
**Why it happens:** Default flow assumes user wants their name attributed.
**How to avoid:** `docs/manual-setup.md` mentions that `maintainer_name` gets committed and links to the "edit-before-commit" recovery path. Not a blocker for v1.1 (low-risk, documented).

### Pitfall 8: Template git SHA unresolved when running wizard on a shallow clone
**What goes wrong:** CI runs on `actions/checkout@v6` with default depth=1 (recent Actions versions default to shallow); `git log -1 --format=%H schema/AGENTS.template.md` may return empty or the wrong SHA.
**Why it happens:** Shallow clone excludes file history beyond depth.
**How to avoid:** CI workflow step that runs the wizard must set `fetch-depth: 2` or higher; OR the wizard treats empty output as "<unresolved>" and continues (D-25 permits). Planner decision: which behavior. **Recommendation:** accept `<unresolved>` gracefully; CI test fixture uses a hand-set SHA string to avoid depth-sensitivity.

### Pitfall 9: Testing interactive mode in CI
**What goes wrong:** Interactive prompts hang in CI since there's no TTY. Tests for interactive path need to feed stdin via heredoc.
**Why it happens:** Interactive mode is designed for a human.
**How to avoid:** All CI-runnable tests use `--answers-file` mode. Interactive mode is tested via a dedicated `test_wizard_interactive.sh` that feeds input via `printf "...\n...\n" | bin/init-wizard.sh`. Mark the interactive-path test as runnable but note in header that it's sensitive to prompt wording; update when wording changes.

## Code Examples

### Example 1: Atomic YAML write (`.wizard-answers.yaml`)

```python
# Source: python.org stdlib docs — tempfile + os.replace pattern (HIGH confidence)
import os, sys, tempfile

def atomic_write(path, content):
    dirpath = os.path.dirname(os.path.abspath(path)) or "."
    fd, tmp = tempfile.mkstemp(dir=dirpath, prefix=".wizard-answers.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)
        os.replace(tmp, path)  # atomic on POSIX
    except Exception:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise
```

### Example 2: `.wizard-answers.yaml` canonical shape (recommended)

```yaml
# Generated by bin/init-wizard.sh v1.1.0 on 2026-04-16T14:32:11Z
# Source of truth for the wizard answer set; powers v1.2 `--upgrade`.
wizard_version: "1.1.0"
generated_at: "2026-04-16T14:32:11Z"
template_sha: "a1b2afd4e5f6..."   # or "<unresolved>" per D-25
answers:
  maintainer_name: "Template Maintainer"
  primary_domain: "personal-knowledge"
  agent: "claude-code"
  default_privacy: "local_only"
  decay_profile: "default"
  obsidian: true
```

**Keys + shape locked here** (Claude's discretion per CONTEXT.md; planner may refine). snake_case throughout per AGENTS.md §3.

### Example 3: Shared validator contract (D-14)

```python
# Shared validator: same signature for interactive fail-fast and batch collect-all.
def validate_answer(field: str, value):
    """
    Returns dict: {'valid': bool, 'errors': [{'field', 'rule', 'example'}]}.
    Interactive mode calls per-field and re-prompts on errors.
    --answers-file mode calls for each field, accumulates all errors, exits non-zero if any.
    """
    errors = []
    rules = {
        "maintainer_name":   (lambda v: isinstance(v, str) and len(v.strip()) > 0, "non-empty string", "Alex Doe"),
        "primary_domain":    (lambda v: isinstance(v, str) and bool(__import__('re').match(r'^[a-z0-9-]+$', v)), "^[a-z0-9-]+$", "personal-knowledge"),
        "agent":             (lambda v: v in {"claude-code", "codex", "other"}, "one of {claude-code, codex, other}", "claude-code"),
        "default_privacy":   (lambda v: v in {"local_only", "cloud_safe"}, "one of {local_only, cloud_safe}", "local_only"),
        "decay_profile":     (lambda v: v in {"software", "science", "biography", "personal-goals", "default"}, "one of {software, science, biography, personal-goals, default}", "default"),
        "obsidian":          (lambda v: isinstance(v, bool), "true or false", "true"),
    }
    if field not in rules:
        return {"valid": False, "errors": [{"field": field, "rule": "unknown field", "example": ""}]}
    check, rule_desc, example = rules[field]
    if not check(value):
        errors.append({"field": field, "rule": rule_desc, "example": example})
    return {"valid": not errors, "errors": errors}
```

### Example 4: Pre-flight check (D-15)

```bash
preflight() {
    local errors=()

    # bash >= 4
    if (( BASH_VERSINFO[0] < 4 )); then
        errors+=("bash: need >= 4.0, have ${BASH_VERSION}")
    fi

    # git
    if ! command -v git >/dev/null 2>&1; then
        errors+=("git: not found in PATH")
    fi

    # python3
    if ! command -v python3 >/dev/null 2>&1; then
        errors+=("python3: not found in PATH")
    fi

    if (( ${#errors[@]} > 0 )); then
        printf 'ERROR: pre-flight failed:\n' >&2
        printf '  - %s\n' "${errors[@]}" >&2
        printf 'See: docs/reference/setup-prerequisites.md for install instructions.\n' >&2
        exit 3  # distinct exit code per Claude's discretion
    fi
}
```

### Example 5: Initial decision record template (skeleton for D-24)

```markdown
---
id: dr-{{TODAY}}-initial-setup
title: "Initial Wizard Setup — {{PRIMARY_DOMAIN}}"
type: decision
status: active
summary: "Wizard-driven personalization of the template with {{PRIMARY_DOMAIN}} domain, {{AGENT}} agent, {{DEFAULT_PRIVACY}} privacy tier, {{DECAY_PROFILE}} decay profile, Obsidian browsing {{OBSIDIAN_YN}}."
created_at: {{TODAY}}
updated_at: {{TODAY}}
sources: []
epistemic_status: sourced
tags:
  - meta
  - setup
domains:
  - wiki-infrastructure
privacy: cloud_safe
knowledge_domain: software
supersedes:
superseded_by:
aliases: []
has_contradictions: false
trigger_type: schema-update
affected_pages: []
---

## TL;DR

Wizard-driven template personalization produced this repo's AGENTS.md from schema/AGENTS.template.md with 6 recorded answers.

## Decision

Adopted domain `{{PRIMARY_DOMAIN}}`, LLM agent `{{AGENT}}` (AGENT_FILENAME = `{{AGENT_FILENAME}}`), default privacy tier `{{DEFAULT_PRIVACY}}`, decay profile `{{DECAY_PROFILE}}`, Obsidian browsing `{{OBSIDIAN_YN}}`. Maintainer: `{{MAINTAINER_NAME}}`.

## Why

The framing adopted is "one canonical personalized AGENTS.md driven by a machine-authoritative answer set (.wizard-answers.yaml)." The framing it replaces is "ad-hoc hand-edits with no reproducible upgrade path." This record + `.wizard-answers.yaml` enable v1.2's `--upgrade` flow (3-way merge on schema version bumps).

## Alternatives Considered

- **Primary domain alternatives rejected:** [list other common domains and why this one was chosen, or state "user-selected from free-form input"].
- **Agent alternatives rejected:** [list codex/other if claude-code chosen, or vice versa].
- **Privacy tier alternatives rejected:** [state the other tier and brief rationale].
- **Decay profile alternatives rejected:** [list other profiles].
- **Hand-editing template:** Rejected in favor of wizard reproducibility + `.wizard-answers.yaml` provenance.

## Consequences

- `AGENTS.md` personalized at template SHA `{{TEMPLATE_SHA}}`.
- `CLAUDE.md` kept byte-identical via `bin/sync-claude.sh`.
- `.wizard-answers.yaml` committed as the machine-authoritative source.
- Upgrade path in v1.2 will use `.wizard-answers.yaml` + template SHA for 3-way merge.

## Affected Pages

None. This is an inaugural infrastructure record.

## Sources

- `.wizard-answers.yaml` — machine-authoritative answer set (see file at repo root for the full YAML).
- `schema/AGENTS.template.md` at git SHA `{{TEMPLATE_SHA}}` — the template rendered.
- `AGENTS.md §4.6` — schema this record conforms to.
- Wizard: `bin/init-wizard.sh` v`{{WIZARD_VERSION}}`, invoked `{{GENERATED_AT}}`.
```

### Example 6: Re-run refusal message (D-04)

```
ERROR: This repo is already initialized.
       Found .wizard-answers.yaml (setup date: 2026-04-16).

       The wizard does not re-render on an initialized repo. v1.1 does not
       include a --force or --upgrade flag.

       To re-run from scratch:
         rm .wizard-answers.yaml AGENTS.md
         bash bin/init-wizard.sh

       To preview what would be written (no mutation):
         bash bin/init-wizard.sh --dry-run

       Upgrade flow is planned for v1.2 (copier-style 3-way merge).

Exit 4
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Copier / cookiecutter full dep chain | Bash + python3 stdlib inline render | Phase 7 STACK.md decision (2026-04-15) | Zero new runtime deps; portability across fresh dev machines. |
| sed-based template substitution | python3 `str.replace()` + `difflib` | Phase 8 D-18 (2026-04-16) | Deterministic cross-platform output; no sed escaping hazards. |
| No byte-equality CI between wizard + manual | `schema/fixtures/canonical-AGENTS.md` + `diff -q` in CI | Phase 8 D-09 (2026-04-16) | Mechanical drift prevention (M-1/M-3 mitigation). |
| Decision records as overview pages | `type: decision` page type (Phase 6 D-01) | 2026-04-14 | Dedicated schema + CI validation hooks. |
| Single AGENTS.md file | AGENTS.md + byte-identical CLAUDE.md mirror | Phase 7 D-03 (2026-04-15) | Agent-agnostic from filename up; enforced via `.githooks/pre-commit` + `bin/sync-claude.sh --check`. |

**Deprecated/outdated:**
- Manual `sed -i 's/{{TOKEN}}/value/g'` rendering — replaced by python3 inline.
- `{{USER_NAME}}` placeholder in AGENTS.md — rejected per D-01; lives only in `.wizard-answers.yaml` + decision record.
- `{{EXAMPLE_CLUSTER_REF}}` placeholder — rejected per D-01.

## Open Questions

1. **Does the wizard edit `wiki/index.md` to add the initial decision record?** (cross-references Pitfall 6)
   - What we know: existing `wiki/index.md` is a skeleton with no decisions section. AGENTS.md §12 says "index is updated on every ingest and every query that creates or modifies pages." The initial decision record is a create.
   - What's unclear: whether the wizard is allowed to edit `wiki/index.md` as a *fifth* written artifact beyond AGENTS.md/CLAUDE.md/.wizard-answers.yaml/decision-record.
   - Recommendation: YES — wizard appends a "Decisions" subsection to wiki/index.md (create if absent) with a single entry pointing at the initial-setup record. This maintains the "write-back on page creation" convention. Add to MANUAL-05 file-touch list.

2. **Should `schema/fixtures/canonical-answers.yaml` opt in to `cloud_safe` privacy explicitly?**
   - What we know: fixture is neutral; CONTEXT.md specifies `{name: "Template Maintainer", domain: "personal-knowledge", agent: "claude-code", privacy: "local_only", decay: "default", obsidian: true}`.
   - What's unclear: does a `local_only` fixture answer mean the rendered `canonical-AGENTS.md` is `local_only` (and might violate neutrality CI paths scan for `privacy: local_only`)?
   - Note: `bin/release.sh:160` has a regex `^privacy:[[:space:]]*local_only[[:space:]]*(#.*)?$` that matches actual frontmatter, NOT schema doc lines. AGENTS.md itself has `privacy: local_only|cloud_safe` (enum doc) which the regex correctly skips. But the wizard-rendered AGENTS.md has `knowledge_domain: "personal-knowledge"` + `privacy_default: local_only` — the latter matches the release.sh regex.
   - Recommendation: **fixture should use `privacy: cloud_safe`** for `default_privacy` answer OR the release.sh regex needs another exemption. Planner to confirm: does the rendered `privacy_default: local_only` line legitimately need to ship in the public template, or does it violate CI-07 / privacy-leak scans?
   - **Action for planner:** Resolve by running `bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --dry-run` during Wave 0 against a throwaway fixture, then grep the output against `^privacy:[[:space:]]*local_only` (release.sh pattern) to verify no match. If match, set fixture to `cloud_safe`.

3. **Where does `--dry-run` write its rendered output for the CI byte-equality check?**
   - What we know: D-09 says "`--dry-run` or writes to a tempdir"; D-18 says `--dry-run` output is a unified diff per file.
   - What's unclear: a unified diff of "no file → new file" is different from the rendered content itself. CI needs the rendered content to `cmp -s` against the fixture.
   - Recommendation: Add a `--render-to <dir>` mode (or `--dry-run --output-dir <dir>`) that writes rendered files to a tempdir without mutating the real repo. CI uses this; interactive users never need it. Document as a CI-only flag if minimizing surface. **OR** keep `--dry-run` as diff-only and have the CI test parse/apply the diff to reconstruct the output — strictly worse (parsing diffs). **Recommendation: add `--render-to <dir>` flag, accept Claude's discretion expansion beyond CONTEXT.md.**

4. **Does the wizard run `bin/sync-claude.sh` or inline the `cp` logic?**
   - What we know: `bin/sync-claude.sh` is 35 lines, zero-dep, tested in Phase 7.
   - What's unclear: invoking sibling scripts from inside a script has a minor portability risk (relative path issues if someone runs `bin/init-wizard.sh` from outside the repo).
   - Recommendation: invoke `bash "$(dirname "$0")/sync-claude.sh"` — the standard pattern. Test it explicitly in Wave 0.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | `bin/init-wizard.sh`, pre-flight (WZRD-09) | ✓ | 5.2.21 | — |
| git | `git config user.name` for default, `git log -1 --format=%H` for template SHA | ✓ | 2.43.0 | Pre-flight fails fast (D-15/D-16) |
| python3 | All inline blocks: YAML, difflib, template render | ✓ | 3.12.3 | Pre-flight fails fast |
| PyYAML | `.wizard-answers.yaml` read/write | ✓ | 6.0.1 | Minimal python3 stdlib fallback parser (spec permits; controlled key set) |
| difflib | python3 stdlib | ✓ | stdlib | — |
| sha256sum / shasum | NOT required by Phase 8 (used by `bin/ingest.sh` only) | n/a | — | — |
| GitHub Actions `ubuntu-latest` + `actions/checkout@v6` + `actions/setup-python@v6` | MANUAL-06 CI test | ✓ (already wired in `.github/workflows/neutrality.yml`) | — | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** PyYAML is present on the dev machine and in CI, but not guaranteed on every fresh clone. Fallback = 15-line stdlib key:value parser handling the controlled `.wizard-answers.yaml` schema (specific per CONTEXT.md).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Bash test scripts aggregated via `tests/phase-08/run.sh` (mirror of `tests/phase-07/run.sh`) |
| Config file | None — convention-based: files matching `tests/phase-08/test_*.sh` run by aggregator |
| Quick run command | `bash tests/phase-08/run.sh` |
| Full suite command | `bash tests/phase-08/run.sh --full` (reserved for future; no-op in P1, matching Phase 7 convention) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WZRD-01 | `bin/init-wizard.sh` exists, executable, zero new deps | unit | `bash tests/phase-08/test_wizard_exists.sh` | ❌ Wave 0 |
| WZRD-02 | Prompts grouped semantically with explainers | integration | `bash tests/phase-08/test_wizard_interactive.sh` (stdin fed) | ❌ Wave 0 |
| WZRD-03 | `--answers-file` non-interactive mode works | integration | `bash tests/phase-08/test_wizard_answers_file.sh` | ❌ Wave 0 |
| WZRD-04 | Input validation rejects bad slug/agent/privacy | unit | `bash tests/phase-08/test_wizard_validation.sh` | ❌ Wave 0 |
| WZRD-05 | Idempotent re-run refuses with clear message | integration | `bash tests/phase-08/test_wizard_idempotent.sh` | ❌ Wave 0 |
| WZRD-06 | `.wizard-answers.yaml` written with all fields | integration | `bash tests/phase-08/test_wizard_answers_yaml.sh` | ❌ Wave 0 |
| WZRD-07 | Template rendered via 4 placeholders | unit | `bash tests/phase-08/test_wizard_template_render.sh` | ❌ Wave 0 |
| WZRD-08 | Completion summary lists files + diff | integration | `bash tests/phase-08/test_wizard_summary.sh` | ❌ Wave 0 |
| WZRD-09 | Pre-flight: git/bash>=4 checks | unit | `bash tests/phase-08/test_wizard_preflight.sh` (PATH manipulation) | ❌ Wave 0 |
| WZRD-10 | Initial decision record written | integration | `bash tests/phase-08/test_wizard_decision_record.sh` | ❌ Wave 0 |
| WZRD-11 | `--dry-run` prints diff without mutation | integration | `bash tests/phase-08/test_wizard_dryrun.sh` | ❌ Wave 0 |
| MANUAL-01 | manual-setup.md walks section-by-section | smoke | `bash tests/phase-08/test_manual_setup_sections.sh` (grep 6 numbered sections) | ❌ Wave 0 |
| MANUAL-02 | Minimal-diff example present | smoke | `bash tests/phase-08/test_manual_setup_example.sh` (grep for personal-knowledge block) | ❌ Wave 0 |
| MANUAL-03 | Wizard-prompt checklist | smoke | `bash tests/phase-08/test_manual_setup_checklist.sh` (6 checklist items mapped) | ❌ Wave 0 |
| MANUAL-04 | Equivalence statement | smoke | `bash tests/phase-08/test_manual_setup_equivalence.sh` (grep) | ❌ Wave 0 |
| MANUAL-05 | File-touch list | smoke | `bash tests/phase-08/test_manual_setup_file_list.sh` (grep) | ❌ Wave 0 |
| MANUAL-06 | Byte-equality wizard ↔ fixture | integration | `bash tests/phase-08/test_canonical_byte_equality.sh` + CI step | ❌ Wave 0 |

Manual-only verification items: none for this phase (all requirements mechanically testable).

### Sampling Rate
- **Per task commit:** `bash tests/phase-08/run.sh` (runs all Phase 8 tests; Phase 7 suite unaffected — separate directory)
- **Per wave merge:** `bash tests/phase-07/run.sh && bash tests/phase-08/run.sh` (cumulative)
- **Phase gate:** Both suites green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/phase-08/run.sh` — aggregator skeleton (copy from phase-07)
- [ ] `tests/phase-08/test_*.sh` — 17 test files covering WZRD-01..11 + MANUAL-01..06
- [ ] `tests/phase-08/fixtures/` — minimal repo skeletons for integration tests (empty wiki, template present, etc.)
- [ ] `schema/fixtures/canonical-answers.yaml` — committed
- [ ] `schema/fixtures/canonical-AGENTS.md` — committed
- [ ] `.gitattributes` entry for `schema/fixtures/canonical-AGENTS.md` (eol=lf) — prevents CRLF drift
- [ ] `.github/workflows/neutrality.yml` OR new `init-wizard.yml` — add Phase 8 test step
- Framework install: no new install needed; bash + python3 + PyYAML already present in CI

## Sources

### Primary (HIGH confidence)
- **`.planning/phases/08-two-track-setup-wizard-manual/08-CONTEXT.md`** — all 26 locked decisions (D-01..D-26), specifics, deferred items. Authoritative.
- **`.planning/REQUIREMENTS.md`** lines 38–58, 183–199 — WZRD-01..11 and MANUAL-01..06 definitions + traceability.
- **`.planning/ROADMAP.md`** §Phase 8 — 5 success criteria, dependency on Phase 7, UI hint yes.
- **`.planning/STATE.md`** — Phase 7 completion + accumulated Phase 7 decisions relevant to byte-equality and AGENTS.md neutralization.
- **`AGENTS.md`** (= CLAUDE.md, byte-identical per TMPL-10) §3 (commit conventions, snake_case, dates), §4.6 (decision page type schema), §6 (decay profile table), §13 (privacy routing).
- **`schema/AGENTS.template.md`** — inspected lines 32, 56, 588, 589, 848 to verify exactly 4 placeholders (WZRD-07 amendment target).
- **`bin/release.sh`** (197 lines) — flag-parsing pattern, dry-run/apply inversion model, trap cleanup idiom, RELEASE_EMAIL .invalid convention.
- **`bin/sync-claude.sh`** (35 lines) — byte-copy idiom invoked by wizard; zero-dep, tested.
- **`bin/check-neutrality.sh`** — canonical python3-inline-via-env-var pattern; exemption handling precedent.
- **`bin/ingest.sh`** — slug validation regex `^[a-z0-9-]+$` (matches D-11 primary_domain rule).
- **`tests/phase-07/`** — test harness shape to mirror; `test_agents_template_placeholders.sh` verifies the 4-placeholder contract.
- **`wiki/decisions/dr-2026-04-14-phase6-decision-type.md`** — inaugural decision record exemplar; `affected_pages: []` precedent for D-23.
- **`.github/workflows/neutrality.yml`** — existing CI structure to extend (pull_request hard gate + push advisory).

### Secondary (MEDIUM confidence)
- **Python stdlib docs** (`docs.python.org/3/library/difflib.html`, `tempfile`, `os.replace`) — deterministic diff + atomic-write patterns. Consulted conceptually, not fetched this session.
- **no-color.org** convention (D-20) — `NO_COLOR` env var respected.
- **Phase 7 REVIEWS.md artifacts** (referenced in STATE.md) — fresh-temp-dir staging, exemption patterns, single-commit history verification.

### Tertiary (LOW confidence)
- **Copier update semantics** (D-25 references, for v1.2 upgrade flow planning) — not relevant to v1.1 implementation; listed for planner context only.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — bash/python3/git/PyYAML versions directly verified on this machine and in CI config.
- Architecture: HIGH — every pattern has a concrete precedent in existing `bin/` scripts; CONTEXT.md locks all decisions.
- Pitfalls: HIGH — drawn from research/PITFALLS.md (cited in CONTEXT.md) plus direct inspection of Phase 7 CI + existing release.sh regex.
- Requirements mapping: HIGH — all 17 REQ-IDs mapped 1:1 to concrete artifacts or tests; traceability verified against REQUIREMENTS.md.

**Research date:** 2026-04-16
**Valid until:** 2026-05-16 (30 days — project is mid-migration-velocity but Phase 7 substrate is stable)
