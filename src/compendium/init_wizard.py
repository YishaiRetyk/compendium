# src/compendium/init_wizard.py -- Template personalization wizard.
# Byte-parity port of bin/init-wizard.sh (Phase 25 Plan 05, MIG-04).
#
# PORT BOUNDARY (LOCKED -- docs/reference/python-shim-contract.md §4):
#   The bash preflight() (bin/init-wizard.sh:146-169, exit 3 on missing
#   bash>=4 / git / python3) is NOT ported. It stays in the bin/init-wizard.sh
#   shim because a Python port cannot detect "python3 missing" from inside
#   python3. This module begins where the bash body continues AFTER
#   `preflight` -- everything else (arg parsing, color detection, the exit-4
#   already-initialized guard, the 6-prompt interactive flow, --answers-file
#   validation, the 4-token render, --dry-run diffs, --render-to, staging-dir
#   real-run promote, sync-claude re-assert, completion summary) is replicated
#   byte-for-byte against the frozen bash implementation.
#
# Modes / exit codes / environment: see USAGE below (identical to the bash
# script's usage() heredoc).
#
# The bash script's 9 python3 heredocs are lifted verbatim as functions
# (_answers_file_pyblock, _validate_one_pyblock, _render_pyblock); their
# env-var handoffs (WZRD_*) are preserved as os.environ assignments so the
# lifted bodies read the same channel the heredocs did.

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

# ---------------------------------------------------------------------------
# usage() heredoc (bin/init-wizard.sh:69-100) -- verbatim.
# ---------------------------------------------------------------------------
USAGE = """\
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
"""

# ---------------------------------------------------------------------------
# Idempotency-guard refusal message (bin/init-wizard.sh:204-220) -- verbatim
# unquoted heredoc; only ${SETUP_DATE} is substituted.
# ---------------------------------------------------------------------------
ALREADY_INITIALIZED_MSG = """\
ERROR: This repo is already initialized.
       Found .wizard-answers.yaml (setup date: {setup_date}).

       The wizard does not re-render on an initialized repo. v1.1 does not
       include a --force or --upgrade flag.

       To re-run from scratch:
         rm .wizard-answers.yaml AGENTS.md
         bash bin/init-wizard.sh
         (or delete .wizard-answers.yaml and AGENTS.md manually)

       To preview what would be written (no mutation):
         bash bin/init-wizard.sh --dry-run

       Upgrade flow is planned for v1.2 (copier-style 3-way merge).
"""

# ---------------------------------------------------------------------------
# Shared validator contract (D-14 / D-17). The bash script embeds this RULES
# table verbatim in BOTH python3 heredocs (answers-file validation and
# per-prompt validate_one); lifted once here -- the text is identical.
# ---------------------------------------------------------------------------
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


def _run_pyblock(fn):
    """Run a lifted python3-heredoc body; map its sys.exit() to the exit code
    the heredoc's python3 process would have returned to bash."""
    try:
        fn()
    except SystemExit as exc:
        code = exc.code
        if code is None:
            return 0
        if isinstance(code, int):
            return code
        print(code, file=sys.stderr)   # sys.exit("msg") semantics (unused by the blocks)
        return 1
    return 0


# ---------------------------------------------------------------------------
# python3 heredoc 1 (bin/init-wizard.sh:243-379): --answers-file load +
# validate + normalized key=value handoff. Body verbatim; reads WZRD_* env.
# ---------------------------------------------------------------------------
def _answers_file_pyblock():
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


# ---------------------------------------------------------------------------
# python3 heredoc 2 (bin/init-wizard.sh:399-446): validate_one() body.
# Verbatim; reads WZRD_VFIELD / WZRD_VVALUE env.
# ---------------------------------------------------------------------------
def _validate_one_pyblock():
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


def validate_one(field, value):
    """bash validate_one() (bin/init-wizard.sh:395-447): env handoff + heredoc."""
    os.environ["WZRD_VFIELD"] = field
    os.environ["WZRD_VVALUE"] = value
    return _run_pyblock(_validate_one_pyblock) == 0


# ---------------------------------------------------------------------------
# Interactive-path text helpers (bash edge-behavior twins).
# ---------------------------------------------------------------------------
def _sed_trim_whitespace(text):
    """`printf '%s' "$RAW" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'` wrapped
    in command substitution (bin/init-wizard.sh:388): per-LINE strip of
    leading/trailing POSIX [[:space:]], then $() strips trailing newlines.
    Empty input produces empty output."""
    trimmed = "\n".join(
        re.sub(r"^[ \t\v\f\r]+|[ \t\v\f\r]+$", "", line)
        for line in text.split("\n")
    )
    return trimmed.rstrip("\n")


def _bash_read_line(stream):
    """`read -r value` twin (bin/init-wizard.sh:454-456) returning the value
    the bash prompt loop ends up with BEFORE the empty->default fallback:
      - a newline-terminated line: newline delimiter dropped, then default-IFS
        word-splitting trims leading/trailing spaces+tabs (single target var;
        internal whitespace preserved, \\r et al. kept);
      - EOF (even with a partial unterminated line): the script's
        `if ! read -r value; then value=""` branch discards it -> ""."""
    line = stream.readline()
    if line.endswith("\n"):
        return line[:-1].strip(" \t")
    return ""


def prompt_once(field, default):
    """bash prompt_once() (bin/init-wizard.sh:449-465). Prompt on stderr
    (no newline), read one line from stdin, empty -> default, re-prompt until
    validate_one passes."""
    while True:
        sys.stderr.write(f"  {field} [Default: {default}]: ")
        sys.stderr.flush()
        value = _bash_read_line(sys.stdin)
        if value == "":
            value = default
        if validate_one(field, value):
            return value


# ---------------------------------------------------------------------------
# python3 heredoc 3 (bin/init-wizard.sh:558-1070): render + side-effects.
# Body verbatim; reads WZRD_* env. sys.exit codes surface via _run_pyblock.
# ---------------------------------------------------------------------------
def _render_pyblock():
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

    # -----------------------------------------------------------------------
    # Determinism env vars: WIZARD_GENERATED_AT, WIZARD_TEMPLATE_SHA.
    # TODAY = date portion of WIZARD_GENERATED_AT (if set) OR today's UTC date.
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # atomic_write: tempfile + os.replace pattern (RESEARCH.md Example 1).
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # render_agents_md: the 4-token template render. Same logic as Plan 02.
    # -----------------------------------------------------------------------
    def render_agents_md():
        try:
            with open(TEMPLATE_PATH, "r", encoding="utf-8") as f:
                src = f.read()
        except OSError as exc:
            raise RuntimeError(f"failed to read template {TEMPLATE_PATH}: {exc}")

        # Phase 16 (reference extraction): the {{DEFAULT_PRIVACY}} and {{DECAY_PROFILE}}
        # carrier lines were removed from schema/AGENTS.template.md when §5/§6 were
        # extracted to leaf files. Privacy is now structural (Phase 15, §13) so there is
        # no privacy_default line to render, and the decay profile is recorded only in
        # .wizard-answers.yaml + the decision record (below) — not substituted into the
        # spec. DEFAULT_PRIVACY / DECAY_PROFILE remain live answers used for those outputs.
        subs = [
            ("{{AGENT_FILENAME}}", AGENT_FILENAME),
            ("{{PRIMARY_DOMAIN}}", PRIMARY_DOMAIN),
        ]
        for token, value in subs:
            src = src.replace(token, value)

        leftover = re.findall(r"\{\{[A-Z_]+\}\}", src)
        if leftover:
            raise RuntimeError(f"leftover placeholders after AGENTS.md render: {leftover}")
        return src

    # -----------------------------------------------------------------------
    # render_answers_yaml: .wizard-answers.yaml (RESEARCH.md Example 2 shape).
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # render_decision_record: deterministic substitution into RESEARCH.md Example 5
    # skeleton. All 11 placeholders substituted; 7 sections present; post-render
    # no {{...}} leftovers.
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # update_index_md: narrow helper that edits wiki-cloud/index.md.
    #
    # Guardrails:
    #   1. Idempotency: skip if the exact wikilink entry already present.
    #   2. Duplicate-header guard: refuse if `## Decisions` appears > 1 times.
    #   3. Malformed recovery: clear error if file missing/unreadable.
    #
    # Returns new content as string.
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # _render_all_five: render all artifacts into the provided stage dir.
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # _validate_staging: assert all 5 files exist, no leftover placeholders,
    # re-run update_index_md's duplicate-header guard on the staged index.
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # _promote_staging_to_repo_root: atomic mv of each artifact from stage to
    # repo root. Relies on same-filesystem rename (atomic) when stage lives under
    # repo root.
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # DRY-RUN mode: emit unified diffs for all 5 files to stdout.
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # RENDER-TO mode: write all 5 artifacts into <RENDER_TO>/ (no staging).
    # -----------------------------------------------------------------------
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

    # -----------------------------------------------------------------------
    # REAL-RUN mode: staging-dir render + atomic promote (review concern #8).
    # -----------------------------------------------------------------------
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


# ---------------------------------------------------------------------------
# Already-initialized detection (bin/init-wizard.sh:195-222).
# ---------------------------------------------------------------------------
def _already_initialized_setup_date(answers_yaml_path):
    """SETUP_DATE resolution (bin/init-wizard.sh:196-203).

    bash: `stat -c '%y' FILE 2>/dev/null | cut -d' ' -f1 || ... || echo "<unknown>"`
    The pipeline's exit status is cut's (0 even when stat fails), so the BSD-stat
    and echo fallbacks are unreachable; the observable chain is: no `stat` in
    PATH -> "<unknown>"; otherwise field 1 of stat's output (empty -> "<unknown>").
    """
    setup_date = "<unknown>"
    if shutil.which("stat"):
        try:
            r = subprocess.run(
                ["stat", "-c", "%y", answers_yaml_path],
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                text=True, check=False,
            )
            out = r.stdout
        except Exception:
            out = ""
        # `| cut -d' ' -f1` (first space-delimited field, per line), then
        # command substitution strips trailing newlines.
        setup_date = "\n".join(
            line.split(" ", 1)[0] for line in out.split("\n")
        ).rstrip("\n")
        if setup_date == "":
            setup_date = "<unknown>"
    return setup_date


# ---------------------------------------------------------------------------
# main -- the bash flow from AFTER `preflight` (line 169) to `exit 0` (1144).
# ---------------------------------------------------------------------------
def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]

    # REPO_ROOT/TEMPLATE_PATH (bin/init-wizard.sh:48-56): the bash script
    # anchors on $0 (bin/ -> repo root); the module anchors on its own file
    # (src/compendium/ -> repo root). Same observable behavior for any cwd.
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    template_path = repo_root + "/schema/AGENTS.template.md"

    # -----------------------------------------------------------------------
    # Flags (defaults) + parse loop (bin/init-wizard.sh:61-141).
    # -----------------------------------------------------------------------
    dry_run = 0
    answers_file = ""
    render_to = ""

    args = list(argv)
    while len(args) > 0:
        arg = args[0]
        if arg in ("--help", "-h"):
            sys.stdout.write(USAGE)
            return 0
        elif arg == "--dry-run":
            dry_run = 1
            args = args[1:]
        elif arg == "--answers-file":
            if len(args) < 2 or args[1] == "":
                sys.stderr.write("ERROR: --answers-file requires a path argument\n")
                sys.stderr.write(USAGE)
                return 1
            answers_file = args[1]
            args = args[2:]
        elif arg == "--render-to":
            if len(args) < 2 or args[1] == "":
                sys.stderr.write("ERROR: --render-to requires a directory argument\n")
                sys.stderr.write(USAGE)
                return 1
            render_to = args[1]
            args = args[2:]
        else:
            sys.stderr.write(f"ERROR: unknown argument: {arg}\n")
            sys.stderr.write(USAGE)
            return 1

    # (Pre-flight (D-15) runs here in bash -- NOT ported; owned by the shim.)

    # -----------------------------------------------------------------------
    # Color / NO_COLOR detection (D-20; bin/init-wizard.sh:175-187).
    # -----------------------------------------------------------------------
    if sys.stdout.isatty() and not os.environ.get("NO_COLOR"):
        clr_dim = "\033[2m"
        clr_bold = "\033[1m"
        clr_reset = "\033[0m"
    else:
        clr_dim = ""
        clr_bold = ""
        clr_reset = ""

    # -----------------------------------------------------------------------
    # Idempotency guard (D-03, D-04). --dry-run always allowed (D-06).
    # -----------------------------------------------------------------------
    wizard_answers_path = repo_root + "/.wizard-answers.yaml"
    if dry_run == 0 and os.path.isfile(wizard_answers_path):
        setup_date = _already_initialized_setup_date(wizard_answers_path)
        sys.stderr.write(ALREADY_INITIALIZED_MSG.format(setup_date=setup_date))
        return 4

    # -----------------------------------------------------------------------
    # Validator + answers collection (bin/init-wizard.sh:229-531), then the
    # render heredoc + post-write steps. Temp files mirror the bash mktemp +
    # trap-EXIT cleanup.
    # -----------------------------------------------------------------------
    fd, answers_normalized = tempfile.mkstemp(prefix="wizard-answers-normalized.")
    os.close(fd)
    render_tmp = None
    try:
        if answers_file:
            # ----- Path A: --answers-file -----
            if not os.path.isfile(answers_file):
                sys.stderr.write(f"ERROR: --answers-file not found: {answers_file}\n")
                return 1

            os.environ["WZRD_ANSWERS_FILE"] = answers_file
            os.environ["WZRD_NORMALIZED"] = answers_normalized

            py_rc = _run_pyblock(_answers_file_pyblock)
            if py_rc != 0:
                return py_rc
        else:
            # ----- Path B: Interactive -----
            try:
                r = subprocess.run(
                    ["git", "config", "user.name"],
                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                    text=True, check=False,
                )
                raw_uname = r.stdout
            except Exception:
                raw_uname = ""      # `|| true`
            raw_uname = raw_uname.rstrip("\n")   # $() strips trailing newlines
            trimmed_uname = _sed_trim_whitespace(raw_uname)
            if trimmed_uname == "":
                maintainer_default = "unknown"
            else:
                maintainer_default = trimmed_uname

            def echo_err(s=""):
                sys.stderr.write(s + "\n")
                sys.stderr.flush()

            echo_err()
            echo_err(f"{clr_bold}Wiki Compiler Template Setup{clr_reset}")
            echo_err(f"{clr_dim}6 questions. Press Enter to accept defaults.{clr_reset}")
            echo_err()

            echo_err(f"{clr_bold}Maintainer{clr_reset}")
            echo_err(f"  {clr_dim}Recorded in the initial decision record for attribution.{clr_reset}")
            maintainer_name = prompt_once("maintainer_name", maintainer_default)

            echo_err()
            echo_err(f"{clr_bold}Domain{clr_reset}")
            echo_err(f"  {clr_dim}Your primary knowledge domain seeds the staleness decay rate and AGENTS.md frontmatter examples.{clr_reset}")
            primary_domain = prompt_once("primary_domain", "personal-knowledge")

            echo_err()
            echo_err(f"{clr_bold}LLM agent{clr_reset}")
            echo_err(f"  {clr_dim}Determines which file the canonical-spec self-reference points at; both AGENTS.md and CLAUDE.md are always written byte-identical.{clr_reset}")
            agent = prompt_once("agent", "claude-code")

            echo_err()
            echo_err(f"{clr_bold}Privacy defaults{clr_reset}")
            echo_err(f"  {clr_dim}Default privacy tier applied to new pages, and how fast claims decay if their source is not re-verified.{clr_reset}")
            default_privacy = prompt_once("default_privacy", "local_only")
            decay_profile = prompt_once("decay_profile", "default")

            echo_err()
            echo_err(f"{clr_bold}Obsidian conventions{clr_reset}")
            echo_err(f"  {clr_dim}Whether you'll browse the wiki in Obsidian; recorded for future tooling, does not change AGENTS.md.{clr_reset}")
            obsidian = prompt_once("obsidian", "y")

            with open(answers_normalized, "w", encoding="utf-8") as f:
                f.write(f"maintainer_name={maintainer_name}\n")
                f.write(f"primary_domain={primary_domain}\n")
                f.write(f"agent={agent}\n")
                f.write(f"default_privacy={default_privacy}\n")
                f.write(f"decay_profile={decay_profile}\n")
                f.write(f"obsidian={obsidian}\n")

        # -------------------------------------------------------------------
        # Read normalized answers back (bin/init-wizard.sh:510-525):
        # `while IFS='=' read -r _key _val` -- split on the FIRST '=' only,
        # rest of the line verbatim; an unterminated final line is dropped.
        # -------------------------------------------------------------------
        maintainer_name = ""
        primary_domain = ""
        agent = ""
        default_privacy = ""
        decay_profile = ""
        obsidian = ""
        with open(answers_normalized, "r", encoding="utf-8") as f:
            content = f.read()
        for line in content.split("\n")[:-1]:
            _key, _sep, _val = line.partition("=")
            if _key == "maintainer_name":
                maintainer_name = _val
            elif _key == "primary_domain":
                primary_domain = _val
            elif _key == "agent":
                agent = _val
            elif _key == "default_privacy":
                default_privacy = _val
            elif _key == "decay_profile":
                decay_profile = _val
            elif _key == "obsidian":
                obsidian = _val

        if agent == "claude-code":
            agent_filename = "CLAUDE.md"
        else:
            agent_filename = "AGENTS.md"

        # -------------------------------------------------------------------
        # Render + side-effects (bin/init-wizard.sh:541-1076): env handoff to
        # the lifted heredoc body.
        # -------------------------------------------------------------------
        os.environ["WZRD_TEMPLATE_PATH"] = template_path
        os.environ["WZRD_AGENT_FILENAME"] = agent_filename
        os.environ["WZRD_PRIMARY_DOMAIN"] = primary_domain
        os.environ["WZRD_DEFAULT_PRIVACY"] = default_privacy
        os.environ["WZRD_DECAY_PROFILE"] = decay_profile
        os.environ["WZRD_AGENT"] = agent
        os.environ["WZRD_MAINTAINER_NAME"] = maintainer_name
        os.environ["WZRD_OBSIDIAN"] = obsidian
        os.environ["WZRD_DRY_RUN"] = str(dry_run)
        os.environ["WZRD_RENDER_TO"] = render_to
        os.environ["WZRD_REPO_ROOT"] = repo_root

        fd, render_tmp = tempfile.mkstemp(prefix="wizard-agents-render.")
        os.close(fd)
        os.environ["WZRD_RENDER_TMP"] = render_tmp

        rc = _run_pyblock(_render_pyblock)
        if rc != 0:
            return rc

        # -------------------------------------------------------------------
        # Post-write: re-assert AGENTS.md == CLAUDE.md via bin/sync-claude.sh
        # in real-run mode (bin/init-wizard.sh:1085-1092).
        # -------------------------------------------------------------------
        if dry_run == 0 and render_to == "":
            sync_ok = False
            try:
                r = subprocess.run(
                    ["bash", repo_root + "/bin/sync-claude.sh"],
                    cwd=repo_root, stdout=subprocess.DEVNULL, check=False,
                )
                sync_ok = r.returncode == 0
            except Exception:
                sync_ok = False
            if not sync_ok:
                sys.stderr.write(
                    "ERROR: bin/sync-claude.sh failed post-write; AGENTS.md and CLAUDE.md may be out of sync\n"
                )
                return 1

        # -------------------------------------------------------------------
        # Completion summary (D-19; bin/init-wizard.sh:1098-1142). Emitted in
        # both --render-to and real-run modes; skipped for --dry-run.
        # -------------------------------------------------------------------
        if dry_run == 0:
            if render_to != "":
                target_root = render_to
                mode_label = "render-to mode"
            else:
                target_root = repo_root
                mode_label = "real-run mode"

            # Determine TODAY for decision-record path (match python logic).
            # NOTE: bash tests -n on the RAW env var and slices its first 10
            # chars (no strip) -- the render heredoc strips; keep both as-is.
            if os.environ.get("WIZARD_GENERATED_AT", "") != "":
                today_for_summary = os.environ["WIZARD_GENERATED_AT"][:10]
            else:
                today_for_summary = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")

            def _size(p):
                # `wc -c <file | tr -d ' '` if the file exists, else "?"
                if os.path.isfile(p):
                    return str(os.path.getsize(p))
                return "?"

            agents_path = target_root + "/AGENTS.md"
            claude_path = target_root + "/CLAUDE.md"
            answers_path = target_root + "/.wizard-answers.yaml"
            decision_path = target_root + f"/wiki-cloud/decisions/dr-{today_for_summary}-initial-setup.md"
            index_path = target_root + "/wiki-cloud/index.md"

            sys.stdout.write(
                f"Wrote ({mode_label}):\n"
                f"  {agents_path}  ({_size(agents_path)} bytes, new)\n"
                f"  {claude_path}  ({_size(claude_path)} bytes, byte-identical to AGENTS.md)\n"
                f"  {answers_path}  ({_size(answers_path)} bytes, new)\n"
                f"  {decision_path}  ({_size(decision_path)} bytes, new)\n"
                f"  {index_path}  ({_size(index_path)} bytes, updated)\n"
            )
            if render_to != "":
                sys.stdout.write(
                    "\nNote: --render-to is CI/testing-only. For real-run, omit --render-to.\n"
                )
            sys.stdout.flush()

        return 0
    finally:
        # trap 'rm -f "$ANSWERS_NORMALIZED" "$RENDER_TMP"' EXIT INT TERM
        for _p in (answers_normalized, render_tmp):
            if _p:
                try:
                    os.unlink(_p)
                except OSError:
                    pass


if __name__ == "__main__":          # enables `python3 -m compendium.init_wizard`
    sys.exit(main(sys.argv[1:]))
