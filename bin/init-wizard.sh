#!/usr/bin/env bash
# bin/init-wizard.sh -- Template personalization wizard (Phase 08 Plan 02 core).
#
# Lands the deterministic core: pre-flight (D-15), 6-prompt flow (D-11), D-13
# semantic-group explainers, shared validator contract (D-14 / D-17), 4-token
# template render against schema/AGENTS.template.md, --dry-run unified diff
# (D-18), --render-to <dir> (CI/testing-only) mode, and idempotency guard
# (D-03 / D-04). Real-run repo-root writes are Plan 03 scope; Plan 02 returns
# exit 2 with a "not yet implemented" message in that code path (review
# concern #6).
#
# Modes:
#   (default)               Interactive. Prompts for 6 answers. Plan 02 returns
#                           exit 2 ("not yet implemented -- Plan 03 pending").
#   --answers-file <path>   Non-interactive YAML answers; fails with summary on
#                           validation errors.
#   --dry-run               Preview unified diff to stdout; mutates nothing.
#                           Always allowed regardless of init state (D-06).
#   --render-to <dir>       (internal -- CI/testing only) Write rendered files
#                           to <dir> rather than repo root. Used by tests/CI.
#
# Exit codes:
#   0  success
#   1  generic failure (bad arg, write error)
#   2  not yet implemented (Plan 02 real-run without --render-to or --dry-run)
#   3  pre-flight failure (missing bash >= 4 / git / python3)
#   4  refused (already initialized)
#   5  validation failure (invalid input or --answers-file errors)
#
# Environment:
#   WIZARD_GENERATED_AT   ISO 8601 override for tests
#   WIZARD_TEMPLATE_SHA   Template SHA override for tests
#   NO_COLOR              When set non-empty, disables ANSI escapes

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repo root + template path (relative to this script).
# Use pure-bash parameter expansion for dirname so pre-flight (which may run
# with an intentionally stripped PATH in tests) doesn't print a spurious
# "dirname: command not found" to stderr before our own pre-flight message.
# ---------------------------------------------------------------------------
_script_path="${BASH_SOURCE[0]}"
_script_dir="${_script_path%/*}"
# Handle the edge case where BASH_SOURCE has no slash (invoked as `bash wizard`):
if [ "$_script_dir" = "$_script_path" ]; then
    _script_dir="."
fi
SCRIPT_DIR="$(cd "$_script_dir" 2>/dev/null && pwd || echo "$_script_dir")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || echo "$SCRIPT_DIR/..")"
TEMPLATE_PATH="$REPO_ROOT/schema/AGENTS.template.md"

# ---------------------------------------------------------------------------
# Flags (defaults).
# ---------------------------------------------------------------------------
DRY_RUN=0
ANSWERS_FILE=""
RENDER_TO=""

# ---------------------------------------------------------------------------
# usage() -- printed on --help and on bad args.
# ---------------------------------------------------------------------------
usage() {
    cat <<'EOF'
Usage: bin/init-wizard.sh [--answers-file <path>] [--dry-run] [--render-to <dir>]

Modes:
  (default)               Interactive. Prompts for 6 answers, writes AGENTS.md, CLAUDE.md,
                          .wizard-answers.yaml, and an initial decision record at repo root.
                          (Plan 02 returns exit 2 until Plan 03 wires the repo-root writes.)
  --answers-file <path>   Non-interactive. Reads answers from YAML file, validates all
                          fields up front, exits non-zero with summary on validation errors.
  --dry-run               Preview-only. Renders all files and prints unified diff per file
                          to stdout. Mutates nothing. Always allowed regardless of init state.
  --render-to <dir>       (internal — CI/testing only) Write rendered files to <dir> instead
                          of repo root. Used by tests and CI; not intended as a user-facing
                          flag. Combine with --answers-file for non-interactive.
  --help, -h              Show this help and exit.

Exit codes:
  0  success
  1  generic failure (bad arg, write error)
  2  not yet implemented (Plan 02: real-run without --render-to or --dry-run; removed in Plan 03)
  3  pre-flight failure (missing bash >= 4 / git / python3)
  4  refused (repo already initialized; .wizard-answers.yaml present and not --dry-run)
  5  validation failure (invalid input or --answers-file errors)

Environment variables (CI/testing — internal):
  WIZARD_GENERATED_AT   ISO 8601 timestamp; overrides datetime.utcnow() for reproducible tests
  WIZARD_TEMPLATE_SHA   Overrides `git log -1 schema/AGENTS.template.md` SHA lookup
  NO_COLOR              When set (non-empty), disables ANSI escape codes in output

See: docs/reference/setup-prerequisites.md, docs/manual-setup.md
EOF
}

# ---------------------------------------------------------------------------
# Parse flags FIRST so --help works without any other tool present.
# Any other validation (incl. pre-flight) runs after this.
# ---------------------------------------------------------------------------
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --answers-file)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                echo "ERROR: --answers-file requires a path argument" >&2
                usage >&2
                exit 1
            fi
            ANSWERS_FILE="$2"
            shift 2
            ;;
        --render-to)
            if [ "$#" -lt 2 ] || [ -z "${2:-}" ]; then
                echo "ERROR: --render-to requires a directory argument" >&2
                usage >&2
                exit 1
            fi
            RENDER_TO="$2"
            shift 2
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Pre-flight (D-15). Runs BEFORE prompting or file I/O but AFTER --help.
# ---------------------------------------------------------------------------
preflight() {
    local errors=()

    if (( BASH_VERSINFO[0] < 4 )); then
        errors+=("bash: need >= 4.0, have ${BASH_VERSION}")
    fi

    if ! command -v git >/dev/null 2>&1; then
        errors+=("git: not found in PATH")
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        errors+=("python3: not found in PATH")
    fi

    if (( ${#errors[@]} > 0 )); then
        printf 'ERROR: pre-flight failed:\n' >&2
        printf '  - %s\n' "${errors[@]}" >&2
        printf 'See: docs/reference/setup-prerequisites.md for install instructions.\n' >&2
        exit 3
    fi
}

preflight

# ---------------------------------------------------------------------------
# Color / NO_COLOR detection (D-20). Emit nothing before this point that
# includes ANSI escapes (usage() is plain).
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    CLR_GREEN=$'\033[32m'
    CLR_RED=$'\033[31m'
    CLR_DIM=$'\033[2m'
    CLR_BOLD=$'\033[1m'
    CLR_RESET=$'\033[0m'
else
    CLR_GREEN=""
    CLR_RED=""
    CLR_DIM=""
    CLR_BOLD=""
    CLR_RESET=""
fi

# ---------------------------------------------------------------------------
# Idempotency guard (D-03, D-04). --dry-run always allowed (D-06).
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ] && [ -f "$REPO_ROOT/.wizard-answers.yaml" ]; then
    # Best-effort setup date from mtime; fall back to "<unknown>".
    SETUP_DATE="<unknown>"
    if command -v stat >/dev/null 2>&1; then
        # GNU stat (Linux) uses -c; BSD stat (macOS) uses -f. Try both.
        SETUP_DATE=$(stat -c '%y' "$REPO_ROOT/.wizard-answers.yaml" 2>/dev/null \
                     | cut -d' ' -f1 \
                     || stat -f '%Sm' -t '%Y-%m-%d' "$REPO_ROOT/.wizard-answers.yaml" 2>/dev/null \
                     || echo "<unknown>")
        [ -z "$SETUP_DATE" ] && SETUP_DATE="<unknown>"
    fi
    cat >&2 <<EOF
ERROR: This repo is already initialized.
       Found .wizard-answers.yaml (setup date: ${SETUP_DATE}).

       The wizard does not re-render on an initialized repo. v1.1 does not
       include a --force or --upgrade flag.

       To re-run from scratch:
         rm .wizard-answers.yaml AGENTS.md
         bash bin/init-wizard.sh
         (or delete .wizard-answers.yaml and AGENTS.md manually)

       To preview what would be written (no mutation):
         bash bin/init-wizard.sh --dry-run

       Upgrade flow is planned for v1.2 (copier-style 3-way merge).
EOF
    exit 4
fi

# ---------------------------------------------------------------------------
# Validator + answers collection (shared between interactive + --answers-file).
# Implemented in a single python3 block so the contract lives in one place
# and the interactive path can call back into it per-prompt via a helper.
# ---------------------------------------------------------------------------

# Collect answers -> temp YAML-ish file, then pass to render step.
# Two paths:
#   A. --answers-file: python3 reads the YAML, validates ALL fields, on any
#      error prints a summary and exits 5; on success writes answers to
#      $ANSWERS_NORMALIZED.
#   B. Interactive: bash prompts 6 fields (D-11 order) with D-13 explainers,
#      per-prompt fail-fast validation (re-prompt on invalid). Writes to
#      $ANSWERS_NORMALIZED.
# The normalized file is a KEY=VALUE shell-sourceable fragment (tests use
# --answers-file path; the interactive path also funnels through this
# contract so the render step is identical for both).
# ---------------------------------------------------------------------------

ANSWERS_NORMALIZED="$(mktemp -t wizard-answers-normalized.XXXXXX)"
trap 'rm -f "$ANSWERS_NORMALIZED"' EXIT INT TERM

if [ -n "$ANSWERS_FILE" ]; then
    # ----- Path A: --answers-file -----
    if [ ! -f "$ANSWERS_FILE" ]; then
        echo "ERROR: --answers-file not found: $ANSWERS_FILE" >&2
        exit 1
    fi

    export WZRD_ANSWERS_FILE="$ANSWERS_FILE"
    export WZRD_NORMALIZED="$ANSWERS_NORMALIZED"

    set +e
    python3 - <<'PYEOF'
import os
import re
import sys

ANSWERS_FILE = os.environ["WZRD_ANSWERS_FILE"]
NORMALIZED = os.environ["WZRD_NORMALIZED"]


def load_yaml_controlled(path):
    """Load the controlled flat answers YAML.

    Tries PyYAML first; falls back to a minimal stdlib parser that handles
    the documented schema only (flat key:value under `answers:` mapping,
    string | bool | int scalars, no flow / no multi-line).
    """
    try:
        import yaml  # type: ignore

        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    except ImportError:
        pass

    data = {}
    in_answers = False
    answers = {}
    with open(path, "r", encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\n")
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if not line.startswith(" ") and stripped.endswith(":"):
                # top-level block key -> values follow indented
                key = stripped[:-1].strip()
                if key == "answers":
                    in_answers = True
                else:
                    in_answers = False
                continue
            if ":" in stripped:
                key, _, val = stripped.partition(":")
                key = key.strip()
                val = val.strip()
                # strip inline comment (naive: ignore if inside quotes)
                if val and val[0] not in ("'", '"'):
                    hashpos = val.find("#")
                    if hashpos != -1:
                        val = val[:hashpos].strip()
                # strip surrounding quotes
                if len(val) >= 2 and ((val[0] == val[-1]) and val[0] in ("'", '"')):
                    val = val[1:-1]
                # coerce bool
                if val.lower() == "true":
                    pyval = True
                elif val.lower() == "false":
                    pyval = False
                else:
                    pyval = val
                if line.startswith(" ") and in_answers:
                    answers[key] = pyval
                else:
                    data[key] = pyval
    if answers:
        data["answers"] = answers
    return data


RULES = {
    "maintainer_name":
        ("non-empty string", "Alex Doe",
         lambda v: isinstance(v, str) and len(v.strip()) > 0),
    "primary_domain":
        ("^[a-z0-9-]+$", "personal-knowledge",
         lambda v: isinstance(v, str) and re.match(r"^[a-z0-9-]+$", v) is not None),
    "agent":
        ("one of {claude-code, codex, other}", "claude-code",
         lambda v: v in {"claude-code", "codex", "other"}),
    "default_privacy":
        ("one of {local_only, cloud_safe}", "local_only",
         lambda v: v in {"local_only", "cloud_safe"}),
    "decay_profile":
        ("one of {software, science, biography, personal-goals, default}", "default",
         lambda v: v in {"software", "science", "biography", "personal-goals", "default"}),
    "obsidian":
        ("true or false", "true",
         lambda v: isinstance(v, bool)),
}


def fmt_err(field, raw_value, rule, example):
    return f'Invalid {field} "{raw_value}". Must match {rule}. Try: {example}.'


try:
    data = load_yaml_controlled(ANSWERS_FILE)
except Exception as exc:
    print(f"ERROR: failed to parse --answers-file {ANSWERS_FILE!r}: {exc}", file=sys.stderr)
    sys.exit(5)

answers = data.get("answers") if isinstance(data, dict) else None
if not isinstance(answers, dict):
    print(
        "ERROR: --answers-file must contain a top-level `answers:` mapping "
        "with 6 keys (maintainer_name, primary_domain, agent, default_privacy, "
        "decay_profile, obsidian).",
        file=sys.stderr,
    )
    sys.exit(5)

errors = []
for field, (rule, example, check) in RULES.items():
    if field not in answers:
        errors.append(fmt_err(field, "(missing)", rule, example))
        continue
    val = answers[field]
    if not check(val):
        errors.append(fmt_err(field, val, rule, example))

if errors:
    print(f"Found {len(errors)} validation error(s):", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    sys.exit(5)

# Write normalized key=value file (bash-safe: no embedded quotes in validated values).
with open(NORMALIZED, "w", encoding="utf-8") as f:
    f.write(f'maintainer_name={answers["maintainer_name"]}\n')
    f.write(f'primary_domain={answers["primary_domain"]}\n')
    f.write(f'agent={answers["agent"]}\n')
    f.write(f'default_privacy={answers["default_privacy"]}\n')
    f.write(f'decay_profile={answers["decay_profile"]}\n')
    f.write(f'obsidian={"true" if answers["obsidian"] else "false"}\n')

sys.exit(0)
PYEOF
    PY_RC=$?
    set -e
    if [ "$PY_RC" -ne 0 ]; then
        exit "$PY_RC"
    fi
else
    # ----- Path B: Interactive -----
    # Determine maintainer default (review concern #11: empty user.name -> "unknown").
    RAW_UNAME="$(git config user.name 2>/dev/null || true)"
    # Strip whitespace.
    TRIMMED_UNAME="$(printf '%s' "$RAW_UNAME" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
    if [ -z "$TRIMMED_UNAME" ]; then
        MAINTAINER_DEFAULT="unknown"
    else
        MAINTAINER_DEFAULT="$TRIMMED_UNAME"
    fi

    # Prompt helpers. Each prompt uses the shared validator contract via a
    # python3 sub-invocation for consistency with Path A.
    validate_one() {
        # validate_one <field> <value> -> 0 if valid, 1 otherwise; prints
        # the D-17 error to stderr on failure.
        local field="$1" value="$2"
        export WZRD_VFIELD="$field"
        export WZRD_VVALUE="$value"
        python3 - <<'PYEOF'
import os
import re
import sys

RULES = {
    "maintainer_name":
        ("non-empty string", "Alex Doe",
         lambda v: isinstance(v, str) and len(v.strip()) > 0),
    "primary_domain":
        ("^[a-z0-9-]+$", "personal-knowledge",
         lambda v: isinstance(v, str) and re.match(r"^[a-z0-9-]+$", v) is not None),
    "agent":
        ("one of {claude-code, codex, other}", "claude-code",
         lambda v: v in {"claude-code", "codex", "other"}),
    "default_privacy":
        ("one of {local_only, cloud_safe}", "local_only",
         lambda v: v in {"local_only", "cloud_safe"}),
    "decay_profile":
        ("one of {software, science, biography, personal-goals, default}", "default",
         lambda v: v in {"software", "science", "biography", "personal-goals", "default"}),
    "obsidian":
        ("true or false", "true",
         lambda v: isinstance(v, bool)),
}

field = os.environ["WZRD_VFIELD"]
raw = os.environ["WZRD_VVALUE"]
rule, example, check = RULES[field]

if field == "obsidian":
    # Accept y/yes/true/1 and n/no/false/0 case-insensitively.
    low = raw.strip().lower()
    if low in {"y", "yes", "true", "1"}:
        value = True
    elif low in {"n", "no", "false", "0"}:
        value = False
    else:
        print(f'Invalid {field} "{raw}". Must match {rule}. Try: {example}.', file=sys.stderr)
        sys.exit(1)
else:
    value = raw

if not check(value):
    print(f'Invalid {field} "{raw}". Must match {rule}. Try: {example}.', file=sys.stderr)
    sys.exit(1)

sys.exit(0)
PYEOF
    }

    prompt_once() {
        # prompt_once <field> <default>
        # reads one answer, applies default on empty, validates; re-prompts
        # on invalid input (fail-fast per prompt). Prompt text goes to stderr
        # (FD 2) so callers capturing stdout get only the raw answer value.
        local field="$1" default="$2"
        local value
        while true; do
            printf '  %s [Default: %s]: ' "$field" "$default" >&2
            if ! read -r value; then
                # EOF: fall back to default for non-interactive stdin that
                # was shorter than the number of prompts (tests do this).
                value=""
            fi
            if [ -z "$value" ]; then
                value="$default"
            fi
            if validate_one "$field" "$value"; then
                printf '%s\n' "$value"
                return 0
            fi
        done
    }

    # D-13 semantic groups. Group headers + explainers go to stderr so tests
    # that capture stdout via $() see only validated answer values.
    echo >&2
    echo "${CLR_BOLD}Wiki Compiler Template Setup${CLR_RESET}" >&2
    echo "${CLR_DIM}6 questions. Press Enter to accept defaults.${CLR_RESET}" >&2
    echo >&2

    # Prompt 1 standalone.
    echo "${CLR_BOLD}Maintainer${CLR_RESET}" >&2
    echo "  ${CLR_DIM}Recorded in the initial decision record for attribution.${CLR_RESET}" >&2
    maintainer_name="$(prompt_once maintainer_name "$MAINTAINER_DEFAULT")"

    echo >&2
    echo "${CLR_BOLD}Domain${CLR_RESET}" >&2
    echo "  ${CLR_DIM}Your primary knowledge domain seeds the staleness decay rate and AGENTS.md frontmatter examples.${CLR_RESET}" >&2
    primary_domain="$(prompt_once primary_domain "personal-knowledge")"

    echo >&2
    echo "${CLR_BOLD}LLM agent${CLR_RESET}" >&2
    echo "  ${CLR_DIM}Determines which file the canonical-spec self-reference points at; both AGENTS.md and CLAUDE.md are always written byte-identical.${CLR_RESET}" >&2
    agent="$(prompt_once agent "claude-code")"

    echo >&2
    echo "${CLR_BOLD}Privacy defaults${CLR_RESET}" >&2
    echo "  ${CLR_DIM}Default privacy tier applied to new pages, and how fast claims decay if their source is not re-verified.${CLR_RESET}" >&2
    default_privacy="$(prompt_once default_privacy "local_only")"
    decay_profile="$(prompt_once decay_profile "default")"

    echo >&2
    echo "${CLR_BOLD}Obsidian conventions${CLR_RESET}" >&2
    echo "  ${CLR_DIM}Whether you'll browse the wiki in Obsidian; recorded for future tooling, does not change AGENTS.md.${CLR_RESET}" >&2
    obsidian="$(prompt_once obsidian "y")"

    # Write normalized file.
    {
        printf 'maintainer_name=%s\n' "$maintainer_name"
        printf 'primary_domain=%s\n' "$primary_domain"
        printf 'agent=%s\n' "$agent"
        printf 'default_privacy=%s\n' "$default_privacy"
        printf 'decay_profile=%s\n' "$decay_profile"
        printf 'obsidian=%s\n' "$obsidian"
    } > "$ANSWERS_NORMALIZED"
fi

# ---------------------------------------------------------------------------
# Read normalized answers back into shell variables.
# The normalized file is KEY=VALUE-per-line (possibly with spaces in values),
# so we parse it with `while read` rather than `source` to handle free-form
# maintainer_name correctly.
# ---------------------------------------------------------------------------
maintainer_name=""
primary_domain=""
agent=""
default_privacy=""
decay_profile=""
obsidian=""
while IFS='=' read -r _key _val; do
    case "$_key" in
        maintainer_name)  maintainer_name="$_val" ;;
        primary_domain)   primary_domain="$_val" ;;
        agent)            agent="$_val" ;;
        default_privacy)  default_privacy="$_val" ;;
        decay_profile)    decay_profile="$_val" ;;
        obsidian)         obsidian="$_val" ;;
    esac
done < "$ANSWERS_NORMALIZED"

if [ "$agent" = "claude-code" ]; then
    agent_filename="CLAUDE.md"
else
    agent_filename="AGENTS.md"
fi

# ---------------------------------------------------------------------------
# Template render. Single python3 inline block, args via env vars.
# - RENDER_TO mode: writes <RENDER_TO>/AGENTS.md, returns 0.
# - DRY_RUN mode: emits unified diff to stdout, returns 0.
# - Real-run (no RENDER_TO, no DRY_RUN): exit 2 with not-yet-implemented
#   message (Plan 02 gate, removed in Plan 03).
# ---------------------------------------------------------------------------

# Real-run gate (review concern #6). MUST fire BEFORE any write.
if [ "$DRY_RUN" -eq 0 ] && [ -z "$RENDER_TO" ]; then
    cat >&2 <<'EOF'
bin/init-wizard.sh: not yet implemented — Plan 03 pending.
Use --dry-run to preview the rendered output, or --render-to <dir> for CI testing.
EOF
    exit 2
fi

# Prepare env for python3 render block.
export WZRD_TEMPLATE_PATH="$TEMPLATE_PATH"
export WZRD_AGENT_FILENAME="$agent_filename"
export WZRD_PRIMARY_DOMAIN="$primary_domain"
export WZRD_DEFAULT_PRIVACY="$default_privacy"
export WZRD_DECAY_PROFILE="$decay_profile"
export WZRD_DRY_RUN="$DRY_RUN"
export WZRD_RENDER_TO="$RENDER_TO"
export WZRD_REPO_ROOT="$REPO_ROOT"

# Use a temp file to capture the render for summary (size in bytes, new/modified).
RENDER_TMP="$(mktemp -t wizard-agents-render.XXXXXX)"
# Extend the existing EXIT trap to clean this up as well.
trap 'rm -f "$ANSWERS_NORMALIZED" "$RENDER_TMP"' EXIT INT TERM
export WZRD_RENDER_TMP="$RENDER_TMP"

set +e
python3 - <<'PYEOF'
import os
import re
import sys

TEMPLATE_PATH = os.environ["WZRD_TEMPLATE_PATH"]
AGENT_FILENAME = os.environ["WZRD_AGENT_FILENAME"]
PRIMARY_DOMAIN = os.environ["WZRD_PRIMARY_DOMAIN"]
DEFAULT_PRIVACY = os.environ["WZRD_DEFAULT_PRIVACY"]
DECAY_PROFILE = os.environ["WZRD_DECAY_PROFILE"]
DRY_RUN = os.environ["WZRD_DRY_RUN"] == "1"
RENDER_TO = os.environ["WZRD_RENDER_TO"]
REPO_ROOT = os.environ["WZRD_REPO_ROOT"]
RENDER_TMP = os.environ["WZRD_RENDER_TMP"]

try:
    with open(TEMPLATE_PATH, "r", encoding="utf-8") as f:
        src = f.read()
except OSError as exc:
    print(f"ERROR: failed to read template {TEMPLATE_PATH}: {exc}", file=sys.stderr)
    sys.exit(1)

# Exactly 4 substitutions, in the order listed in <interfaces>.
subs = [
    ("{{AGENT_FILENAME}}", AGENT_FILENAME),
    ("{{PRIMARY_DOMAIN}}", PRIMARY_DOMAIN),
    ("{{DEFAULT_PRIVACY}}", DEFAULT_PRIVACY),
    ("{{DECAY_PROFILE}}", DECAY_PROFILE),
]
for token, value in subs:
    src = src.replace(token, value)

# Post-render leftover assertion.
leftover = re.findall(r"\{\{[A-Z_]+\}\}", src)
if leftover:
    print(f"ERROR: leftover placeholders after render: {leftover}", file=sys.stderr)
    sys.exit(1)

# Always stash the rendered body in RENDER_TMP so the bash caller can compute
# summary metadata (size in bytes).
with open(RENDER_TMP, "w", encoding="utf-8", newline="\n") as f:
    f.write(src)

if DRY_RUN:
    import difflib

    target_path = os.path.join(REPO_ROOT, "AGENTS.md")
    if os.path.exists(target_path):
        with open(target_path, "r", encoding="utf-8") as f:
            a = f.read().splitlines(keepends=False)
    else:
        a = []
    b = src.splitlines(keepends=False)
    diff_iter = difflib.unified_diff(
        a, b,
        fromfile="a/AGENTS.md",
        tofile="b/AGENTS.md",
        lineterm="",
    )
    # Ensure at least the headers are printed even when a == b (difflib emits
    # nothing on equal input). For Plan 02 fresh-init case a = []; b != [], so
    # diff will emit headers.  Guard anyway for safety.
    emitted_any = False
    for line in diff_iter:
        print(line)
        emitted_any = True
    if not emitted_any:
        print("--- a/AGENTS.md")
        print("+++ b/AGENTS.md")
    sys.exit(0)

if RENDER_TO:
    target_dir = RENDER_TO
    os.makedirs(target_dir, exist_ok=True)
    target_path = os.path.join(target_dir, "AGENTS.md")
    # Note: bash caller prints the human-facing `Wrote (...)` summary after
    # this block completes; python emits nothing on success to keep stdout
    # clean for test greps that look only for the `Wrote` line.
    with open(target_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(src)
    sys.exit(0)

# Should be unreachable (real-run gate fires before we get here).
print("ERROR: unreachable render branch", file=sys.stderr)
sys.exit(1)
PYEOF
RC=$?
set -e

if [ "$RC" -ne 0 ]; then
    exit "$RC"
fi

# ---------------------------------------------------------------------------
# Completion summary (D-19). Emitted only in --render-to mode in Plan 02.
# Parses the `__WIZARD_SUMMARY__` marker lines the python block printed.
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ] && [ -n "$RENDER_TO" ]; then
    # The python block already printed __WIZARD_SUMMARY__ <path> <bytes> <status>.
    # Reformat it into the human-facing `Wrote (...):` block.
    #
    # We need to capture stdout from the python block. Since we've already
    # printed it directly (streaming), the marker is in the user's terminal
    # as-is. Rather than rerunning, we print the human summary here from the
    # file on disk.
    rendered_path="$RENDER_TO/AGENTS.md"
    if [ -f "$rendered_path" ]; then
        size_bytes=$(wc -c <"$rendered_path" | tr -d ' ')
        # Determine new vs modified by checking whether the file was present
        # before we wrote. We don't track that reliably here, so default to "new"
        # (the expected state for Plan 02's CI-only --render-to mode).
        status_label="new"
        cat <<EOF
Wrote (render-to mode):
  ${rendered_path}  (${size_bytes} bytes, ${status_label})

Note: --render-to is CI/testing-only. Full wizard output (5 files) lands in Plan 03.
EOF
    fi
fi

exit 0
