"""TEST-06 unit coverage for compendium.init_wizard (Phase 25 Plan 05, MIG-04).

Covers the three TEST-06 areas for the init-wizard port:
  1. placeholder substitution -- the 4-token template render (2 live tokens after
     Phase 16), including the wizard<->manual setup-parity fixture byte-equality;
  2. answer validation + trimming -- the D-14/D-17 shared validator contract and
     the bash `read -r` / sed-trim twins;
  3. already-initialized detection -- the exit-4 guard (byte-compared against the
     frozen Phase-24 golden) and the D-06 --dry-run bypass.

Module-behavior tests run the module in a throwaway scaffold (the module anchors
REPO_ROOT on its own file, so the scaffold gets its own src/compendium copy --
mirroring tests/phase-24/test_shim_preflight_exit3.sh's scaffold pattern).
The bash preflight (exit 3) is intentionally NOT covered here: it stays in the
bin/init-wizard.sh shim (docs/reference/python-shim-contract.md §4).
"""

import datetime
import io
import os
import pathlib
import shutil
import subprocess
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "src"))

import compendium.init_wizard as iw  # noqa: E402

GOLDEN_EXIT4_STDERR = (
    REPO_ROOT / "tests" / "goldens" / "init-wizard" / "already-initialized" / "stderr"
)
CANONICAL_ANSWERS = REPO_ROOT / "schema" / "fixtures" / "canonical-answers.yaml"
CANONICAL_AGENTS = REPO_ROOT / "schema" / "fixtures" / "canonical-AGENTS.md"
TEMPLATE = REPO_ROOT / "schema" / "AGENTS.template.md"


# ---------------------------------------------------------------------------
# Scaffold + runner helpers.
# ---------------------------------------------------------------------------
def make_scaffold(tmp_path):
    """Throwaway fixture repo with its own module copy (REPO_ROOT anchor)."""
    fix = tmp_path / "fix"
    (fix / "bin").mkdir(parents=True)
    (fix / "schema").mkdir()
    (fix / "src" / "compendium").mkdir(parents=True)
    (fix / "wiki-cloud").mkdir()
    shutil.copy2(REPO_ROOT / "bin" / "sync-claude.sh", fix / "bin" / "sync-claude.sh")
    shutil.copy2(TEMPLATE, fix / "schema" / "AGENTS.template.md")
    for name in ("__init__.py", "init_wizard.py"):
        shutil.copy2(REPO_ROOT / "src" / "compendium" / name,
                     fix / "src" / "compendium" / name)
    (fix / "wiki-cloud" / "index.md").write_text(
        "# Index\n\n## Decisions\n\n- seed entry\n", encoding="utf-8"
    )
    return fix


def run_wizard(fix, *args, stdin="", env_extra=None):
    """Run `python3 -m compendium.init_wizard` anchored at the scaffold."""
    env = dict(
        os.environ,
        PYTHONPATH=str(fix / "src"),
        PYTHONDONTWRITEBYTECODE="1",
        LC_ALL="C",
        TZ="UTC",
        WIZARD_GENERATED_AT="2026-04-16T00:00:00Z",
        WIZARD_TEMPLATE_SHA="test-sha",
    )
    if env_extra:
        env.update(env_extra)
    return subprocess.run(
        [sys.executable, "-m", "compendium.init_wizard", *args],
        cwd=fix, input=stdin, text=True, capture_output=True, env=env,
    )


def write_answers(path, **overrides):
    answers = {
        "maintainer_name": '"Template Maintainer"',
        "primary_domain": '"personal-knowledge"',
        "agent": '"claude-code"',
        "default_privacy": '"cloud_safe"',
        "decay_profile": '"default"',
        "obsidian": "true",
    }
    answers.update(overrides)
    body = "answers:\n" + "".join(f"  {k}: {v}\n" for k, v in answers.items())
    path.write_text(body, encoding="utf-8")


# ===========================================================================
# 1. Placeholder substitution (TEST-06 area 1)
# ===========================================================================
def test_render_substitutes_both_live_tokens_claude_code(tmp_path):
    """agent=claude-code -> {{AGENT_FILENAME}}=CLAUDE.md, {{PRIMARY_DOMAIN}} verbatim;
    rendered AGENTS.md is byte-exactly template.replace(...)."""
    fix = make_scaffold(tmp_path)
    af = tmp_path / "answers.yaml"
    write_answers(af, primary_domain='"research-notes"')
    r = run_wizard(fix, "--answers-file", str(af), "--render-to", "out")
    assert r.returncode == 0, r.stderr

    rendered = (fix / "out" / "AGENTS.md").read_bytes()
    expected = (
        TEMPLATE.read_text(encoding="utf-8")
        .replace("{{AGENT_FILENAME}}", "CLAUDE.md")
        .replace("{{PRIMARY_DOMAIN}}", "research-notes")
    ).encode("utf-8")
    assert rendered == expected
    assert b"{{" not in rendered  # no leftover placeholders (guardrail honored)
    # CLAUDE.md byte-identical (sync-claude invariant, render-to path)
    assert (fix / "out" / "CLAUDE.md").read_bytes() == rendered


def test_render_agent_filename_is_agents_md_for_non_claude_agents(tmp_path):
    """agent=codex -> the canonical-spec self-reference token renders AGENTS.md."""
    fix = make_scaffold(tmp_path)
    af = tmp_path / "answers.yaml"
    write_answers(af, agent='"codex"', primary_domain='"software-notes"')
    r = run_wizard(fix, "--answers-file", str(af), "--render-to", "out")
    assert r.returncode == 0, r.stderr

    rendered = (fix / "out" / "AGENTS.md").read_text(encoding="utf-8")
    expected = (
        TEMPLATE.read_text(encoding="utf-8")
        .replace("{{AGENT_FILENAME}}", "AGENTS.md")
        .replace("{{PRIMARY_DOMAIN}}", "software-notes")
    )
    assert rendered == expected


def test_setup_parity_canonical_fixture_byte_equality(tmp_path):
    """The setup-parity gate property: canonical answers + frozen env render
    byte-equal to schema/fixtures/canonical-AGENTS.md (wizard<->manual track)."""
    fix = make_scaffold(tmp_path)
    r = run_wizard(
        fix, "--answers-file", str(CANONICAL_ANSWERS), "--render-to", "out",
        env_extra={"WIZARD_GENERATED_AT": "2026-04-16T00:00:00Z",
                   "WIZARD_TEMPLATE_SHA": "<frozen-fixture>"},
    )
    assert r.returncode == 0, r.stderr
    assert (fix / "out" / "AGENTS.md").read_bytes() == CANONICAL_AGENTS.read_bytes()
    # answers yaml records the frozen metadata verbatim
    answers_yaml = (fix / "out" / ".wizard-answers.yaml").read_text(encoding="utf-8")
    assert 'generated_at: "2026-04-16T00:00:00Z"' in answers_yaml
    assert 'template_sha: "<frozen-fixture>"' in answers_yaml


# ===========================================================================
# 2. Answer validation + trimming (TEST-06 area 2)
# ===========================================================================
def test_rules_validator_contract():
    """D-14 shared validator: the 6 fields' accept/reject sets."""
    accept = {
        "maintainer_name": ["Alex Doe", " padded ok "],
        "primary_domain": ["personal-knowledge", "a", "0-9-z"],
        "agent": ["claude-code", "codex", "other"],
        "default_privacy": ["local_only", "cloud_safe"],
        "decay_profile": ["software", "science", "biography", "personal-goals", "default"],
        "obsidian": [True, False],
    }
    reject = {
        "maintainer_name": ["", "   ", 42],
        "primary_domain": ["Bad Domain!", "UPPER", "", "a_b", None],
        "agent": ["vim", "", "Claude-Code"],
        "default_privacy": ["secret", "", "LOCAL_ONLY"],
        "decay_profile": ["weird", ""],
        "obsidian": ["true", "yes", 1, None],  # rule requires a real bool
    }
    for field, values in accept.items():
        _, _, check = iw.RULES[field]
        for v in values:
            assert check(v), f"{field} should accept {v!r}"
    for field, values in reject.items():
        _, _, check = iw.RULES[field]
        for v in values:
            assert not check(v), f"{field} should reject {v!r}"


def test_validate_one_error_shape(capsys):
    """D-17 error shape: `Invalid <field> "<value>". Must match <rule>. Try: <example>.`"""
    assert iw.validate_one("primary_domain", "Bad Domain!") is False
    assert capsys.readouterr().err == (
        'Invalid primary_domain "Bad Domain!". '
        "Must match ^[a-z0-9-]+$. Try: personal-knowledge.\n"
    )
    assert iw.validate_one("obsidian", "maybe") is False
    assert capsys.readouterr().err == (
        'Invalid obsidian "maybe". Must match true or false. Try: true.\n'
    )
    assert iw.validate_one("agent", "claude-code") is True
    assert capsys.readouterr().err == ""


def test_validate_one_obsidian_synonym_coercion(capsys):
    for raw in ("y", "Y", "yes", "TRUE", "1", " y ", "n", "NO", "false", "0"):
        assert iw.validate_one("obsidian", raw) is True, raw
    for raw in ("maybe", "", "2", "yep"):
        assert iw.validate_one("obsidian", raw) is False, raw
    capsys.readouterr()  # drain


def test_bash_read_line_trimming_semantics():
    """`read -r value` twin: newline delimiter dropped; leading/trailing
    spaces+tabs trimmed (default IFS, single var); internal whitespace and \\r
    preserved; EOF (even mid-line) yields '' (the `if ! read -r` branch)."""
    cases = [
        ("  Alice Smith  \n", "Alice Smith"),
        ("\tTabbed\t\n", "Tabbed"),
        ("a   b  c \n", "a   b  c"),        # internal runs preserved
        (" \r x \r \n", "\r x \r"),          # \r is not IFS whitespace
        ("\n", ""),
        ("   \n", ""),
        ("", ""),                             # pure EOF
        ("partial", ""),                      # EOF with unterminated line -> discarded
    ]
    for raw, expected in cases:
        assert iw._bash_read_line(io.StringIO(raw)) == expected, repr(raw)


def test_sed_trim_whitespace_twin():
    """sed -E 's/^[[:space:]]+|[[:space:]]+$//g' per line, $()-stripped."""
    assert iw._sed_trim_whitespace("  Alex Doe  ") == "Alex Doe"
    assert iw._sed_trim_whitespace("\t\v x \f\r") == "x"
    assert iw._sed_trim_whitespace("") == ""
    assert iw._sed_trim_whitespace("   \t ") == ""
    assert iw._sed_trim_whitespace(" a \n  b ") == "a\nb"  # per-line trim


def test_answers_file_validation_fails_closed_exit5(tmp_path):
    """Bad --answers-file values -> exit 5 + summary; nothing rendered."""
    fix = make_scaffold(tmp_path)
    af = tmp_path / "bad.yaml"
    write_answers(af, primary_domain='"Bad Domain!"', agent='"vim"')
    r = run_wizard(fix, "--answers-file", str(af), "--render-to", "out")
    assert r.returncode == 5
    assert "Found 2 validation error(s):" in r.stderr
    assert ('  - Invalid primary_domain "Bad Domain!". '
            "Must match ^[a-z0-9-]+$. Try: personal-knowledge.") in r.stderr
    assert ('  - Invalid agent "vim". '
            "Must match one of {claude-code, codex, other}. Try: claude-code.") in r.stderr
    assert not (fix / "out").exists()


def test_interactive_trims_and_reprompts_until_valid(tmp_path):
    """Prompt loop: blank -> default; invalid -> D-17 error + re-prompt;
    padded input trimmed like bash `read -r`."""
    fix = make_scaffold(tmp_path)
    stdin = (
        "  Padded Name  \n"   # maintainer_name (trimmed)
        "Bad Domain!\n"       # primary_domain invalid -> re-prompt
        "good-domain\n"       # primary_domain valid
        "\n"                  # agent -> default claude-code
        "\n"                  # default_privacy -> default local_only
        "\n"                  # decay_profile -> default
        "\n"                  # obsidian -> default y
    )
    # Neutralize git config so the maintainer default is deterministic ("unknown").
    r = run_wizard(
        fix, "--render-to", "out", stdin=stdin,
        env_extra={"GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_SYSTEM": "/dev/null"},
    )
    assert r.returncode == 0, r.stderr
    assert r.stderr.count("  primary_domain [Default: personal-knowledge]: ") == 2
    assert ('Invalid primary_domain "Bad Domain!". '
            "Must match ^[a-z0-9-]+$. Try: personal-knowledge.") in r.stderr
    assert "  maintainer_name [Default: unknown]: " in r.stderr
    answers_yaml = (fix / "out" / ".wizard-answers.yaml").read_text(encoding="utf-8")
    assert '  maintainer_name: "Padded Name"' in answers_yaml
    assert '  primary_domain: "good-domain"' in answers_yaml
    assert "  obsidian: true" in answers_yaml


# ===========================================================================
# 3. Already-initialized detection (TEST-06 area 3)
# ===========================================================================
def _seed_initialized(fix):
    sentinel = fix / ".wizard-answers.yaml"
    sentinel.write_text("x\n", encoding="utf-8")
    t = datetime.datetime(2026, 1, 2, tzinfo=datetime.timezone.utc).timestamp()
    os.utime(sentinel, (t, t))
    return sentinel


def test_already_initialized_refuses_exit4_golden_stderr(tmp_path):
    """.wizard-answers.yaml present + non-dry-run -> exit 4; stderr byte-equal
    to the frozen Phase-24 golden (setup date = sentinel mtime); no writes."""
    fix = make_scaffold(tmp_path)
    _seed_initialized(fix)
    before = sorted(p.relative_to(fix) for p in fix.rglob("*"))
    r = run_wizard(fix)  # interactive mode, stdin empty -> guard fires first
    assert r.returncode == 4
    assert r.stdout == ""
    assert r.stderr == GOLDEN_EXIT4_STDERR.read_text(encoding="utf-8")
    after = sorted(p.relative_to(fix) for p in fix.rglob("*"))
    assert before == after  # guard mutates nothing


def test_already_initialized_guard_covers_render_to(tmp_path):
    """The guard fires for --render-to writes too (not only real-run)."""
    fix = make_scaffold(tmp_path)
    _seed_initialized(fix)
    af = tmp_path / "answers.yaml"
    write_answers(af)
    r = run_wizard(fix, "--answers-file", str(af), "--render-to", "out")
    assert r.returncode == 4
    assert "ERROR: This repo is already initialized." in r.stderr
    assert not (fix / "out").exists()


def test_already_initialized_dry_run_bypass(tmp_path):
    """D-06: --dry-run is always allowed on an initialized repo (exit 0, diffs
    on stdout, still no mutation)."""
    fix = make_scaffold(tmp_path)
    sentinel = _seed_initialized(fix)
    sentinel_bytes = sentinel.read_bytes()
    r = run_wizard(fix, "--answers-file", str(CANONICAL_ANSWERS), "--dry-run")
    assert r.returncode == 0, r.stderr
    assert "--- a/AGENTS.md" in r.stdout
    assert "+++ b/AGENTS.md" in r.stdout
    assert not (fix / "AGENTS.md").exists()
    assert sentinel.read_bytes() == sentinel_bytes


def test_not_initialized_render_to_writes_and_summarizes(tmp_path):
    """No sentinel -> render-to run succeeds and prints the D-19 summary."""
    fix = make_scaffold(tmp_path)
    r = run_wizard(fix, "--answers-file", str(CANONICAL_ANSWERS), "--render-to", "out")
    assert r.returncode == 0, r.stderr
    assert r.stdout.startswith("Wrote (render-to mode):\n")
    assert "Note: --render-to is CI/testing-only." in r.stdout
    for rel in ("AGENTS.md", "CLAUDE.md", ".wizard-answers.yaml",
                "wiki-cloud/decisions/dr-2026-04-16-initial-setup.md",
                "wiki-cloud/index.md"):
        assert (fix / "out" / rel).is_file(), rel
