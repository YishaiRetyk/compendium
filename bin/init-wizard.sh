#!/usr/bin/env bash
# bin/init-wizard.sh -- Template personalization wizard (Phase 08 Plan 03 full).
#
# Lands the full real-run side-effects path on top of Plan 02's deterministic
# core: pre-flight (D-15), 6-prompt flow (D-11), D-13 semantic-group
# explainers, shared validator contract (D-14 / D-17), 4-token template render
# against schema/AGENTS.template.md, --dry-run unified diff (D-18),
# --render-to <dir> (CI/testing-only) mode, idempotency guard (D-03 / D-04),
# plus: staging-dir render + atomic promote, .wizard-answers.yaml, initial
# decision record, AGENTS.md->CLAUDE.md sync, wiki-cloud/index.md Decisions
# Note: wiki-local/ is created lazily (D-06); interactive privacy-tier prompt deferred to Phase D (WIZ).
# subsection edit (3 guardrails: idempotency, duplicate-header, malformed),
# and template_sha resolution chain (env > git-lookup > <unresolved>).
#
# Modes:
#   (default)               Interactive. Prompts for 6 answers; writes 5
#                           artifacts (AGENTS.md, CLAUDE.md, .wizard-answers.yaml,
#                           wiki-cloud/decisions/dr-<TODAY>-initial-setup.md, wiki-cloud/index.md)
#                           to repo root via staging-dir + atomic promote.
#   --answers-file <path>   Non-interactive YAML answers; fails with summary on
#                           validation errors.
#   --dry-run               Preview unified diffs to stdout for all 5 files;
#                           mutates nothing. Always allowed regardless of init
#                           state (D-06).
#   --render-to <dir>       (internal -- CI/testing only) Write rendered files
#                           to <dir> rather than repo root. Used by tests/CI.
#
# Exit codes:
#   0  success
#   1  generic failure (bad arg, write error, guardrail failure)
#   3  pre-flight failure (missing bash >= 4 / git / python3)
#   4  refused (already initialized)
#   5  validation failure (invalid input or --answers-file errors)
#
# Environment:
#   WIZARD_GENERATED_AT   ISO 8601 override for tests (date portion used for TODAY)
#   WIZARD_TEMPLATE_SHA   Template SHA override for tests (authoritative when set)
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
                          .wizard-answers.yaml, an initial decision record, and updates
                          wiki-cloud/index.md at repo root (5 artifacts, atomic promote).
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
  1  generic failure (bad arg, write error, guardrail failure)
  3  pre-flight failure (missing bash >= 4 / git / python3)
  4  refused (repo already initialized; .wizard-answers.yaml present and not --dry-run)
  5  validation failure (invalid input or --answers-file errors)

Environment variables (CI/testing — internal):
  WIZARD_GENERATED_AT   ISO 8601 timestamp; overrides datetime.utcnow() for reproducible tests
                        (date portion drives the TODAY substitution in the decision record)
  WIZARD_TEMPLATE_SHA   Overrides `git log -1 schema/AGENTS.template.md` SHA lookup
                        (authoritative when set; git-history fallback is best-effort)
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
# The guard triggers whenever .wizard-answers.yaml is already present at the
# resolved REPO_ROOT and we would otherwise proceed to a write (either
# real-run OR --render-to). --dry-run (D-06) always bypasses.
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ] && [ -f "$REPO_ROOT/.wizard-answers.yaml" ]; then
    SETUP_DATE="<unknown>"
    if command -v stat >/dev/null 2>&1; then
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
# Implemented in a single python3 block so the contract lives in one place.
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
    RAW_UNAME="$(git config user.name 2>/dev/null || true)"
    TRIMMED_UNAME="$(printf '%s' "$RAW_UNAME" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
    if [ -z "$TRIMMED_UNAME" ]; then
        MAINTAINER_DEFAULT="unknown"
    else
        MAINTAINER_DEFAULT="$TRIMMED_UNAME"
    fi

    validate_one() {
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
        local field="$1" default="$2"
        local value
        while true; do
            printf '  %s [Default: %s]: ' "$field" "$default" >&2
            if ! read -r value; then
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

    echo >&2
    echo "${CLR_BOLD}Wiki Compiler Template Setup${CLR_RESET}" >&2
    echo "${CLR_DIM}6 questions. Press Enter to accept defaults.${CLR_RESET}" >&2
    echo >&2

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
# Render + side-effects. Single python3 inline block.
# - RENDER_TO mode: writes 5 artifacts directly to <RENDER_TO>/
# - DRY_RUN mode: emits unified diffs for all 5 files to stdout
# - Real-run (no RENDER_TO, no DRY_RUN): staging-dir render + atomic promote
#   to repo root + bash bin/sync-claude.sh
# ---------------------------------------------------------------------------

export WZRD_TEMPLATE_PATH="$TEMPLATE_PATH"
export WZRD_AGENT_FILENAME="$agent_filename"
export WZRD_PRIMARY_DOMAIN="$primary_domain"
export WZRD_DEFAULT_PRIVACY="$default_privacy"
export WZRD_DECAY_PROFILE="$decay_profile"
export WZRD_AGENT="$agent"
export WZRD_MAINTAINER_NAME="$maintainer_name"
export WZRD_OBSIDIAN="$obsidian"
export WZRD_DRY_RUN="$DRY_RUN"
export WZRD_RENDER_TO="$RENDER_TO"
export WZRD_REPO_ROOT="$REPO_ROOT"

RENDER_TMP="$(mktemp -t wizard-agents-render.XXXXXX)"
trap 'rm -f "$ANSWERS_NORMALIZED" "$RENDER_TMP"' EXIT INT TERM
export WZRD_RENDER_TMP="$RENDER_TMP"

set +e
python3 - <<'PYEOF'
import datetime
import difflib
import filecmp
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

TEMPLATE_PATH = os.environ["WZRD_TEMPLATE_PATH"]
AGENT_FILENAME = os.environ["WZRD_AGENT_FILENAME"]
PRIMARY_DOMAIN = os.environ["WZRD_PRIMARY_DOMAIN"]
DEFAULT_PRIVACY = os.environ["WZRD_DEFAULT_PRIVACY"]
DECAY_PROFILE = os.environ["WZRD_DECAY_PROFILE"]
AGENT = os.environ["WZRD_AGENT"]
MAINTAINER_NAME = os.environ["WZRD_MAINTAINER_NAME"]
OBSIDIAN_STR = os.environ["WZRD_OBSIDIAN"]
DRY_RUN = os.environ["WZRD_DRY_RUN"] == "1"
RENDER_TO = os.environ["WZRD_RENDER_TO"]
REPO_ROOT = os.environ["WZRD_REPO_ROOT"]
RENDER_TMP = os.environ["WZRD_RENDER_TMP"]

WIZARD_VERSION = "1.1.0"
OBSIDIAN_BOOL = OBSIDIAN_STR.strip().lower() in {"true", "y", "yes", "1"}
OBSIDIAN_YN = "yes" if OBSIDIAN_BOOL else "no"

# ---------------------------------------------------------------------------
# Determinism env vars: WIZARD_GENERATED_AT, WIZARD_TEMPLATE_SHA.
# TODAY = date portion of WIZARD_GENERATED_AT (if set) OR today's UTC date.
# ---------------------------------------------------------------------------
env_generated_at = os.environ.get("WIZARD_GENERATED_AT", "").strip()
if env_generated_at:
    GENERATED_AT = env_generated_at
    # Date portion is first 10 chars (YYYY-MM-DD) when in ISO-8601 form.
    TODAY = env_generated_at[:10]
else:
    # Use timezone-aware UTC (datetime.utcnow() is deprecated as of 3.12).
    try:
        now = datetime.datetime.now(datetime.timezone.utc)
    except Exception:
        now = datetime.datetime.utcnow()
    GENERATED_AT = now.strftime("%Y-%m-%dT%H:%M:%SZ")
    TODAY = now.strftime("%Y-%m-%d")

# template_sha resolution chain (review concern #9):
# 1. WIZARD_TEMPLATE_SHA env var (authoritative when set)
# 2. git log -1 --format=%H schema/AGENTS.template.md (best-effort)
# 3. literal "<unresolved>" (final fallback)
TEMPLATE_SHA = os.environ.get("WIZARD_TEMPLATE_SHA", "").strip()
if not TEMPLATE_SHA:
    try:
        r = subprocess.run(
            ["git", "log", "-1", "--format=%H", "schema/AGENTS.template.md"],
            capture_output=True, text=True, check=False,
            cwd=REPO_ROOT,
        )
        TEMPLATE_SHA = r.stdout.strip() or "<unresolved>"
    except Exception:
        TEMPLATE_SHA = "<unresolved>"


# ---------------------------------------------------------------------------
# atomic_write: tempfile + os.replace pattern (RESEARCH.md Example 1).
# ---------------------------------------------------------------------------
def atomic_write(path, content):
    path = pathlib.Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(
        dir=str(path.parent),
        prefix="." + path.name + ".",
        suffix=".tmp",
    )
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as f:
            f.write(content)
        os.replace(tmp, str(path))
    except Exception:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


# ---------------------------------------------------------------------------
# render_agents_md: the 4-token template render. Same logic as Plan 02.
# ---------------------------------------------------------------------------
def render_agents_md():
    try:
        with open(TEMPLATE_PATH, "r", encoding="utf-8") as f:
            src = f.read()
    except OSError as exc:
        raise RuntimeError(f"failed to read template {TEMPLATE_PATH}: {exc}")

    subs = [
        ("{{AGENT_FILENAME}}", AGENT_FILENAME),
        ("{{PRIMARY_DOMAIN}}", PRIMARY_DOMAIN),
        ("{{DEFAULT_PRIVACY}}", DEFAULT_PRIVACY),
        ("{{DECAY_PROFILE}}", DECAY_PROFILE),
    ]
    for token, value in subs:
        src = src.replace(token, value)

    leftover = re.findall(r"\{\{[A-Z_]+\}\}", src)
    if leftover:
        raise RuntimeError(f"leftover placeholders after AGENTS.md render: {leftover}")
    return src


# ---------------------------------------------------------------------------
# render_answers_yaml: .wizard-answers.yaml (RESEARCH.md Example 2 shape).
# ---------------------------------------------------------------------------
def render_answers_yaml():
    obsidian_lit = "true" if OBSIDIAN_BOOL else "false"
    return (
        f"# Generated by bin/init-wizard.sh v{WIZARD_VERSION} on {GENERATED_AT}\n"
        f"# Source of truth for the wizard answer set; powers v1.2 `--upgrade`.\n"
        f'wizard_version: "{WIZARD_VERSION}"\n'
        f'generated_at: "{GENERATED_AT}"\n'
        f'template_sha: "{TEMPLATE_SHA}"\n'
        f"answers:\n"
        f"  maintainer_name: {json.dumps(MAINTAINER_NAME)}\n"
        f"  primary_domain: {json.dumps(PRIMARY_DOMAIN)}\n"
        f"  agent: {json.dumps(AGENT)}\n"
        f"  default_privacy: {json.dumps(DEFAULT_PRIVACY)}\n"
        f"  decay_profile: {json.dumps(DECAY_PROFILE)}\n"
        f"  obsidian: {obsidian_lit}\n"
    )


# ---------------------------------------------------------------------------
# render_decision_record: deterministic substitution into RESEARCH.md Example 5
# skeleton. All 11 placeholders substituted; 7 sections present; post-render
# no {{...}} leftovers.
# ---------------------------------------------------------------------------
def render_decision_record():
    # Alternatives: for each prompt 2-5, enumerate the OTHER allowed values.
    other_domains = "e.g. `software`, `research-notes`, `journalism` — user-selected from free-form input"
    other_agents = ", ".join(sorted({"claude-code", "codex", "other"} - {AGENT})) or "(none)"
    other_privacies = ", ".join(sorted({"local_only", "cloud_safe"} - {DEFAULT_PRIVACY})) or "(none)"
    other_decays = ", ".join(sorted({"software", "science", "biography", "personal-goals", "default"} - {DECAY_PROFILE})) or "(none)"

    body = f"""---
id: dr-{TODAY}-initial-setup
title: "Initial Wizard Setup -- {PRIMARY_DOMAIN}"
type: decision
status: active
summary: "Wizard-driven personalization of the template with {PRIMARY_DOMAIN} domain, {AGENT} agent, {DEFAULT_PRIVACY} privacy tier, {DECAY_PROFILE} decay profile, Obsidian browsing {OBSIDIAN_YN}."
created_at: {TODAY}
updated_at: {TODAY}
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

Adopted domain `{PRIMARY_DOMAIN}`, LLM agent `{AGENT}` (AGENT_FILENAME = `{AGENT_FILENAME}`), default privacy tier `{DEFAULT_PRIVACY}`, decay profile `{DECAY_PROFILE}`, Obsidian browsing `{OBSIDIAN_YN}`. Maintainer: `{MAINTAINER_NAME}`.

## Why

The framing adopted is "one canonical personalized AGENTS.md driven by a machine-authoritative answer set (.wizard-answers.yaml)." The framing it replaces is "ad-hoc hand-edits with no reproducible upgrade path." This record + `.wizard-answers.yaml` enable v1.2's `--upgrade` flow (3-way merge on schema version bumps).

## Alternatives Considered

- **Primary domain alternatives rejected:** {other_domains}. Selected `{PRIMARY_DOMAIN}`.
- **Agent alternatives rejected:** {other_agents}. Selected `{AGENT}`.
- **Privacy tier alternatives rejected:** {other_privacies}. Selected `{DEFAULT_PRIVACY}`.
- **Decay profile alternatives rejected:** {other_decays}. Selected `{DECAY_PROFILE}`.
- **Hand-editing template:** Rejected in favor of wizard reproducibility + `.wizard-answers.yaml` provenance.

## Consequences

- `AGENTS.md` personalized at template SHA `{TEMPLATE_SHA}`.
- `CLAUDE.md` kept byte-identical via `bin/sync-claude.sh`.
- `.wizard-answers.yaml` committed as the machine-authoritative source.
- Upgrade path in v1.2 will use `.wizard-answers.yaml` + template SHA for 3-way merge.

## Affected Pages

None. This is an inaugural infrastructure record.

## Sources

- `.wizard-answers.yaml` -- machine-authoritative answer set (see file at repo root for the full YAML).
- `schema/AGENTS.template.md` at git SHA `{TEMPLATE_SHA}` -- the template rendered.
- `AGENTS.md §4.6` -- schema this record conforms to.
- Wizard: `bin/init-wizard.sh` v`{WIZARD_VERSION}`, invoked `{GENERATED_AT}`.
"""
    leftover = re.findall(r"\{\{[A-Z_]+\}\}", body)
    if leftover:
        raise RuntimeError(f"leftover placeholders after decision record render: {leftover}")
    return body


# ---------------------------------------------------------------------------
# update_index_md: narrow helper that edits wiki-cloud/index.md.
#
# Guardrails:
#   1. Idempotency: skip if the exact wikilink entry already present.
#   2. Duplicate-header guard: refuse if `## Decisions` appears > 1 times.
#   3. Malformed recovery: clear error if file missing/unreadable.
#
# Returns new content as string.
# ---------------------------------------------------------------------------
def update_index_md(index_path, today, primary_domain):
    p = pathlib.Path(index_path)
    if not p.exists():
        raise RuntimeError(
            f"wiki-cloud/index.md missing/malformed at {index_path} -- copy from template or run "
            "`bin/init-wizard.sh --dry-run` to inspect"
        )
    try:
        content = p.read_text(encoding="utf-8")
    except OSError as exc:
        raise RuntimeError(
            f"wiki-cloud/index.md missing/malformed at {index_path}: {exc} -- copy from template or run "
            "`bin/init-wizard.sh --dry-run` to inspect"
        )

    entry_line = (
        f"- [[dr-{today}-initial-setup|Initial Wizard Setup -- {primary_domain}]] "
        f"-- Wizard-driven template personalization (wiki-infrastructure, {today})"
    )

    # Guardrail 1: idempotency.
    if entry_line in content:
        return content  # no-op

    # Guardrail 2: duplicate-header guard.
    decisions_headers = re.findall(r"(?m)^## Decisions\s*$", content)
    if len(decisions_headers) > 1:
        raise RuntimeError(
            f"wiki-cloud/index.md has {len(decisions_headers)} `## Decisions` headings -- "
            "please resolve manually (expected 0 or 1)."
        )

    if len(decisions_headers) == 0:
        # Create the section.
        new_content = content.rstrip("\n") + f"\n\n## Decisions\n\n{entry_line}\n"
    else:
        # Insert at end of existing Decisions section. "End" = just before the
        # next `## ` heading, or EOF.
        lines = content.split("\n")
        header_idx = None
        for i, line in enumerate(lines):
            if re.match(r"^## Decisions\s*$", line):
                header_idx = i
                break
        assert header_idx is not None

        # Find the end of the section: next `## ` line or end of file.
        end_idx = len(lines)
        for j in range(header_idx + 1, len(lines)):
            if re.match(r"^## ", lines[j]):
                end_idx = j
                break

        # Section content is lines[header_idx+1 : end_idx]. Trim trailing blanks
        # then append entry.
        section_body = lines[header_idx + 1:end_idx]
        # Strip trailing empty lines from section body.
        while section_body and section_body[-1].strip() == "":
            section_body.pop()
        new_lines = (
            lines[:header_idx + 1]
            + [""]
            + section_body
            + [entry_line, ""]
            + lines[end_idx:]
        )
        new_content = "\n".join(new_lines)
        if not new_content.endswith("\n"):
            new_content += "\n"
    return new_content


# ---------------------------------------------------------------------------
# _render_all_five: render all artifacts into the provided stage dir.
# ---------------------------------------------------------------------------
def _render_all_five(stage, source_index_path):
    """Render all 5 artifacts into stage/.

    Args:
        stage: pathlib.Path to the staging directory.
        source_index_path: pathlib.Path to the wiki-cloud/index.md to read-and-update.
    """
    agents = render_agents_md()
    atomic_write(stage / "AGENTS.md", agents)

    # CLAUDE.md is a byte-identical copy of AGENTS.md.
    shutil.copyfile(stage / "AGENTS.md", stage / "CLAUDE.md")
    if not filecmp.cmp(stage / "AGENTS.md", stage / "CLAUDE.md", shallow=False):
        raise RuntimeError("post-copy byte-mismatch AGENTS.md vs CLAUDE.md (should be impossible)")

    atomic_write(stage / ".wizard-answers.yaml", render_answers_yaml())

    decision_rel = pathlib.Path("wiki-cloud") / "decisions" / f"dr-{TODAY}-initial-setup.md"
    atomic_write(stage / decision_rel, render_decision_record())

    # wiki-cloud/index.md: read source, call helper, write result.
    updated_index = update_index_md(source_index_path, TODAY, PRIMARY_DOMAIN)
    atomic_write(stage / "wiki-cloud" / "index.md", updated_index)


# ---------------------------------------------------------------------------
# _validate_staging: assert all 5 files exist, no leftover placeholders,
# re-run update_index_md's duplicate-header guard on the staged index.
# ---------------------------------------------------------------------------
def _validate_staging(stage):
    required = [
        stage / "AGENTS.md",
        stage / "CLAUDE.md",
        stage / ".wizard-answers.yaml",
        stage / "wiki-cloud" / "decisions" / f"dr-{TODAY}-initial-setup.md",
        stage / "wiki-cloud" / "index.md",
    ]
    for p in required:
        if not p.exists():
            raise RuntimeError(f"staging missing required artifact: {p}")

    for p in required:
        content = p.read_text(encoding="utf-8")
        leftover = re.findall(r"\{\{[A-Z_]+\}\}", content)
        if leftover:
            raise RuntimeError(f"leftover placeholders in staged {p}: {leftover}")

    staged_index = (stage / "wiki-cloud" / "index.md").read_text(encoding="utf-8")
    decisions_headers = re.findall(r"(?m)^## Decisions\s*$", staged_index)
    if len(decisions_headers) > 1:
        raise RuntimeError(
            f"staged wiki-cloud/index.md has {len(decisions_headers)} `## Decisions` headings -- "
            "please resolve manually (expected exactly 1)."
        )


# ---------------------------------------------------------------------------
# _promote_staging_to_repo_root: atomic mv of each artifact from stage to
# repo root. Relies on same-filesystem rename (atomic) when stage lives under
# repo root.
# ---------------------------------------------------------------------------
def _promote_staging_to_repo_root(stage):
    relpaths = [
        pathlib.Path("AGENTS.md"),
        pathlib.Path("CLAUDE.md"),
        pathlib.Path(".wizard-answers.yaml"),
        pathlib.Path("wiki-cloud") / "decisions" / f"dr-{TODAY}-initial-setup.md",
        pathlib.Path("wiki-cloud") / "index.md",
    ]
    repo = pathlib.Path(REPO_ROOT)
    for rel in relpaths:
        src = stage / rel
        dst = repo / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))


# ---------------------------------------------------------------------------
# DRY-RUN mode: emit unified diffs for all 5 files to stdout.
# ---------------------------------------------------------------------------
if DRY_RUN:
    repo = pathlib.Path(REPO_ROOT)

    def _diff(label, old_content, new_content):
        a = old_content.splitlines() if old_content else []
        b = new_content.splitlines() if new_content else []
        diff_iter = difflib.unified_diff(
            a, b,
            fromfile=f"a/{label}",
            tofile=f"b/{label}",
            lineterm="",
        )
        emitted_any = False
        for line in diff_iter:
            print(line)
            emitted_any = True
        if not emitted_any:
            print(f"--- a/{label}")
            print(f"+++ b/{label}")

    # 1. AGENTS.md
    agents = render_agents_md()
    target = repo / "AGENTS.md"
    old = target.read_text(encoding="utf-8") if target.exists() else ""
    _diff("AGENTS.md", old, agents)

    # 2. CLAUDE.md (byte-identical to AGENTS.md)
    target = repo / "CLAUDE.md"
    old = target.read_text(encoding="utf-8") if target.exists() else ""
    _diff("CLAUDE.md", old, agents)

    # 3. .wizard-answers.yaml
    answers_yaml = render_answers_yaml()
    target = repo / ".wizard-answers.yaml"
    old = target.read_text(encoding="utf-8") if target.exists() else ""
    _diff(".wizard-answers.yaml", old, answers_yaml)

    # 4. wiki-cloud/decisions/dr-<TODAY>-initial-setup.md
    decision_rel = f"wiki-cloud/decisions/dr-{TODAY}-initial-setup.md"
    decision = render_decision_record()
    target = repo / decision_rel
    old = target.read_text(encoding="utf-8") if target.exists() else ""
    _diff(decision_rel, old, decision)

    # 5. wiki-cloud/index.md (diff against existing)
    index_path = repo / "wiki-cloud" / "index.md"
    if index_path.exists():
        try:
            new_index = update_index_md(str(index_path), TODAY, PRIMARY_DOMAIN)
            old = index_path.read_text(encoding="utf-8")
            _diff("wiki-cloud/index.md", old, new_index)
        except RuntimeError as exc:
            print(f"WARN: wiki-cloud/index.md preview skipped: {exc}", file=sys.stderr)
    else:
        print(f"WARN: wiki-cloud/index.md not found at {index_path}; skipping diff preview.", file=sys.stderr)

    # Stash AGENTS.md for any downstream summary consumer (back-compat).
    with open(RENDER_TMP, "w", encoding="utf-8", newline="\n") as f:
        f.write(agents)
    sys.exit(0)


# ---------------------------------------------------------------------------
# RENDER-TO mode: write all 5 artifacts into <RENDER_TO>/ (no staging).
# ---------------------------------------------------------------------------
if RENDER_TO:
    target_root = pathlib.Path(RENDER_TO)
    target_root.mkdir(parents=True, exist_ok=True)

    # source index: if target_root/wiki-cloud/index.md exists, use it; else fall back
    # to repo's existing wiki-cloud/index.md.
    target_index = target_root / "wiki-cloud" / "index.md"
    repo_index = pathlib.Path(REPO_ROOT) / "wiki-cloud" / "index.md"
    if target_index.exists():
        source_index_path = str(target_index)
    elif repo_index.exists():
        source_index_path = str(repo_index)
    else:
        print(
            f"ERROR: wiki-cloud/index.md not found in either --render-to target ({target_index}) "
            f"or repo root ({repo_index})",
            file=sys.stderr,
        )
        sys.exit(1)

    try:
        _render_all_five(target_root, source_index_path)
        _validate_staging(target_root)
    except RuntimeError as exc:
        print(f"ERROR: wizard write failed: {exc}", file=sys.stderr)
        sys.exit(1)

    # Stash AGENTS.md for summary.
    shutil.copyfile(target_root / "AGENTS.md", RENDER_TMP)
    sys.exit(0)


# ---------------------------------------------------------------------------
# REAL-RUN mode: staging-dir render + atomic promote (review concern #8).
# ---------------------------------------------------------------------------
repo = pathlib.Path(REPO_ROOT)
stage = pathlib.Path(tempfile.mkdtemp(dir=str(repo), prefix=".wizard-stage-"))
rc = 0
try:
    repo_index = repo / "wiki-cloud" / "index.md"
    if not repo_index.exists():
        raise RuntimeError(
            f"wiki-cloud/index.md missing at {repo_index} -- copy from template or run "
            "`bin/init-wizard.sh --dry-run` to inspect"
        )
    _render_all_five(stage, str(repo_index))
    _validate_staging(stage)
    _promote_staging_to_repo_root(stage)
except RuntimeError as exc:
    print(f"ERROR: wizard write failed: {exc}", file=sys.stderr)
    print("Repo root untouched. See `--dry-run` to preview.", file=sys.stderr)
    rc = 1
except Exception as exc:
    print(f"ERROR: wizard write failed (unexpected): {exc}", file=sys.stderr)
    print("Repo root untouched. See `--dry-run` to preview.", file=sys.stderr)
    rc = 1
finally:
    if stage.exists():
        shutil.rmtree(str(stage), ignore_errors=True)

# Stash AGENTS.md for summary.
final_agents = repo / "AGENTS.md"
if rc == 0 and final_agents.exists():
    shutil.copyfile(str(final_agents), RENDER_TMP)

sys.exit(rc)
PYEOF
RC=$?
set -e

if [ "$RC" -ne 0 ]; then
    exit "$RC"
fi

# ---------------------------------------------------------------------------
# Post-write: invoke bin/sync-claude.sh in real-run mode to re-assert the
# AGENTS.md == CLAUDE.md byte-equal invariant from the repo-root location.
# In --render-to mode, CLAUDE.md was already written to the target dir via
# shutil.copyfile inside the python block (same byte content), so no
# sync-claude invocation is needed (the script assumes repo-root paths).
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ] && [ -z "$RENDER_TO" ]; then
    # cd to REPO_ROOT so sync-claude.sh resolves AGENTS.md / CLAUDE.md
    # relative to the repo regardless of caller's cwd.
    (cd "$REPO_ROOT" && bash "$SCRIPT_DIR/sync-claude.sh" >/dev/null) || {
        echo "ERROR: bin/sync-claude.sh failed post-write; AGENTS.md and CLAUDE.md may be out of sync" >&2
        exit 1
    }
fi

# ---------------------------------------------------------------------------
# Completion summary (D-19). Emitted in both --render-to and real-run modes;
# skipped for --dry-run (diff output is the summary).
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" -eq 0 ]; then
    if [ -n "$RENDER_TO" ]; then
        target_root="$RENDER_TO"
        mode_label="render-to mode"
    else
        target_root="$REPO_ROOT"
        mode_label="real-run mode"
    fi

    # Determine TODAY for decision-record path (match python logic).
    if [ -n "${WIZARD_GENERATED_AT:-}" ]; then
        TODAY_FOR_SUMMARY="${WIZARD_GENERATED_AT:0:10}"
    else
        TODAY_FOR_SUMMARY="$(date -u +%Y-%m-%d)"
    fi

    _size() {
        if [ -f "$1" ]; then
            wc -c <"$1" | tr -d ' '
        else
            echo "?"
        fi
    }

    agents_path="$target_root/AGENTS.md"
    claude_path="$target_root/CLAUDE.md"
    answers_path="$target_root/.wizard-answers.yaml"
    decision_path="$target_root/wiki-cloud/decisions/dr-${TODAY_FOR_SUMMARY}-initial-setup.md"
    index_path="$target_root/wiki-cloud/index.md"

    cat <<EOF
Wrote (${mode_label}):
  ${agents_path}  ($(_size "$agents_path") bytes, new)
  ${claude_path}  ($(_size "$claude_path") bytes, byte-identical to AGENTS.md)
  ${answers_path}  ($(_size "$answers_path") bytes, new)
  ${decision_path}  ($(_size "$decision_path") bytes, new)
  ${index_path}  ($(_size "$index_path") bytes, updated)
EOF
    if [ -n "$RENDER_TO" ]; then
        cat <<EOF

Note: --render-to is CI/testing-only. For real-run, omit --render-to.
EOF
    fi
fi

exit 0
