"""Phase 25 Plan 03 (TEST-06, MIG-04 partial) — setup/release trio unit layer.

Net-new pytest coverage for the three Python ports:
  compendium.sync_claude  — drift detection, copy round-trip, exit-code contract
                            (0 ok / 1 error / 2 drift; DRIFT text is golden-locked)
  compendium.gen_skills   — skills rendering determinism (body_for == committed
                            SKILL.md bytes), template thinness, --check contract
                            (0 ok / 1 drift; root-anchored, read-only here)
  compendium.release      — allowlist/denylist plan output (golden-locked order),
                            arg-parse contract, y/N gate, staged pre-flight failure

CLI-level tests run the modules via `python -m` subprocesses (the shipped
invocation form) so return-code/stream behavior is exercised end-to-end.
Pure-logic tests import the modules directly. Nothing here mutates the live
repo: gen-skills tests are --check/read-only; release staging tests run in
tmp fixtures with TMPDIR pointed inside tmp_path.
"""

import os
import pathlib
import subprocess
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "src"
sys.path.insert(0, str(SRC_DIR))  # allow running without `pip install -e .`

from compendium import gen_skills, release, sync_claude  # noqa: E402

GOLD = REPO_ROOT / "tests" / "goldens"
OPS = ("ingest", "query", "lint", "reflect")


def _run(module, args, cwd, stdin=None, env_extra=None):
    """Invoke `python -m compendium.<module>` the way the shim will."""
    env = dict(os.environ)
    env["PYTHONPATH"] = str(SRC_DIR) + os.pathsep + env.get("PYTHONPATH", "")
    if env_extra:
        env.update(env_extra)
    return subprocess.run(
        [sys.executable, "-m", f"compendium.{module}", *args],
        cwd=cwd, env=env, input=stdin,
        capture_output=True, text=True, check=False,
    )


# ---------------------------------------------------------------- sync-claude

def _seed_agents(d, agents="agents body\n", claude=None):
    (d / "AGENTS.md").write_text(agents)
    if claude is not None:
        (d / "CLAUDE.md").write_text(claude)


def test_sync_claude_help(tmp_path):
    p = _run("sync_claude", ["--help"], tmp_path)
    assert p.returncode == 0
    assert p.stdout == "Usage: bin/sync-claude.sh [--check]\n"  # keeps the .sh name


def test_sync_claude_src_missing(tmp_path):
    p = _run("sync_claude", [], tmp_path)
    assert p.returncode == 1
    assert p.stderr == "ERROR: AGENTS.md missing\n"


def test_sync_claude_unknown_arg(tmp_path):
    _seed_agents(tmp_path)
    p = _run("sync_claude", ["--frobnicate"], tmp_path)
    assert p.returncode == 1
    assert p.stderr == "ERROR: unknown arg: --frobnicate\n"


def test_sync_claude_check_dst_missing(tmp_path):
    _seed_agents(tmp_path)
    p = _run("sync_claude", ["--check"], tmp_path)
    assert p.returncode == 2
    assert p.stderr == "DRIFT: CLAUDE.md missing\n"


def test_sync_claude_check_drift_matches_golden(tmp_path):
    _seed_agents(tmp_path, claude="stale claude body\n")
    p = _run("sync_claude", ["--check"], tmp_path)
    assert p.returncode == 2
    assert p.stdout == ""
    golden = (GOLD / "sync-claude" / "check-drift" / "stderr").read_text()
    assert p.stderr == golden  # byte-for-byte the frozen bash diagnostic


def test_sync_claude_check_clean(tmp_path):
    _seed_agents(tmp_path, claude="agents body\n")
    p = _run("sync_claude", ["--check"], tmp_path)
    assert p.returncode == 0
    assert p.stdout == "OK: AGENTS.md == CLAUDE.md\n"


def test_sync_claude_copy_roundtrip(tmp_path):
    _seed_agents(tmp_path, claude="stale claude body\n")
    p = _run("sync_claude", [], tmp_path)
    assert p.returncode == 0
    assert p.stdout == "Synced AGENTS.md -> CLAUDE.md\n"
    assert (tmp_path / "CLAUDE.md").read_bytes() == (tmp_path / "AGENTS.md").read_bytes()
    # idempotent: an immediate --check is clean
    assert _run("sync_claude", ["--check"], tmp_path).returncode == 0


# ------------------------------------------------------------------ gen-skills

def test_body_for_deterministic():
    for op in OPS:
        assert gen_skills.body_for(op) == gen_skills.body_for(op)


def test_body_for_matches_committed_skills():
    """Rendering determinism against the repo: the derived copies ARE the template."""
    for op in OPS:
        committed = (REPO_ROOT / ".claude" / "skills" / op / "SKILL.md").read_bytes()
        assert gen_skills.body_for(op).encode() == committed, f"drift: {op}"


def test_body_shape_stays_thin():
    for op in OPS:
        body = gen_skills.body_for(op)
        lines = body.split("\n")
        assert lines[0] == "---" and lines[3] == "---"
        assert lines[1] == f"name: {op}"
        assert lines[2] == f"description: {gen_skills.DESC[op]}"
        assert body.endswith("verbatim.\n")
        # D-07 thinness: exactly 2 post-frontmatter lines (max 3)
        assert gen_skills._awk_body_line_count(body.encode()) == 2


def test_descriptions_stay_yaml_safe_and_impersonal():
    """The structural assertions' invariants hold for the shipped descriptions."""
    import re
    for op, desc in gen_skills.DESC.items():
        assert desc.strip(), f"{op}: empty description"
        assert not re.search(r": | #", desc), f"{op}: breaks unquoted YAML"
        assert not re.search(
            r"\b(I|we|We|I'll|We'll|I've|We've|I'm|we're|We're)\b", desc
        ), f"{op}: first-person pronoun"


def test_awk_body_line_count_edges():
    count = gen_skills._awk_body_line_count
    assert count(b"---\na: b\n---\n\nbody\n") == 2
    assert count(b"---\na: b\n---\nno trailing newline") == 1
    assert count(b"---\na: b\n---\n") == 0
    # a LATER ----prefixed line still counts as a body line (awk parity)
    assert count(b"---\na: b\n---\nbody\n---\nmore\n") == 3
    assert count(b"no frontmatter at all\n") == 0


def test_gen_skills_help_and_unknown_arg(tmp_path):
    p = _run("gen_skills", ["--help"], tmp_path)
    assert p.returncode == 0
    assert p.stdout.startswith("Usage: bin/gen-skills.sh [--check]\n")
    p = _run("gen_skills", ["--frobnicate"], tmp_path)
    assert p.returncode == 1
    assert p.stderr == "ERROR: unknown arg: --frobnicate\n"


def test_gen_skills_check_clean_from_foreign_cwd(tmp_path):
    """Root-anchored: --check run from an unrelated cwd still checks the repo."""
    p = _run("gen_skills", ["--check"], tmp_path)
    assert p.returncode == 0
    golden = (GOLD / "gen-skills" / "check-in-sync" / "stdout").read_text()
    assert p.stdout == golden
    assert p.stderr == ""


# --------------------------------------------------------------------- release

def test_release_allowlist_verbatim():
    """Golden-locked arrays (24-REVIEW deferred): do NOT extend with src/ or
    pyproject.toml in this plan — the INCLUDES/EXCLUDES echo lines are frozen."""
    assert release.ALLOWLIST == (
        "README.md", "LICENSE", "PRIVACY.md", "AGENTS.md", "CLAUDE.md",
        ".gitignore", ".gitattributes", ".obsidianignore",
        ".neutrality-denylist.txt", "bin", "schema", "docs", ".claude/skills",
        "wiki-cloud/index.md", "wiki-cloud/log.md", "wiki-cloud/decisions",
        "examples/kahneman", ".github", ".githooks",
        "tests/phase-07", "tests/phase-18",
    )
    assert release.DENYLIST_PATHS == (
        ".planning", ".brownfield", ".git", ".obsidian/workspace",
        ".obsidian/cache", "wiki-cloud/entities", "wiki-cloud/concepts",
        "wiki-cloud/comparisons", "wiki-cloud/overviews", "wiki-cloud/sources",
        "wiki-cloud/maintenance",
    )


def test_release_noargs_matches_golden(tmp_path):
    p = _run("release", [], tmp_path)
    assert p.returncode == 1
    assert p.stdout == ""
    golden = (GOLD / "release" / "usage-noargs" / "stderr").read_text()
    assert p.stderr == golden


def test_release_dry_run_plan_matches_golden(tmp_path):
    p = _run("release", ["--remote", "file:///nonexistent-remote.git", "--dry-run"],
             tmp_path)
    assert p.returncode == 0
    golden = (GOLD / "release" / "dry-run-plan" / "stdout").read_text()
    assert p.stdout == golden
    assert p.stderr == ""


def test_release_plan_lists_allowlist_in_order(tmp_path):
    p = _run("release", ["--remote", "r", "--tag", "v9.9"], tmp_path)
    assert p.returncode == 0
    lines = p.stdout.splitlines()
    includes = [l[len("  INCLUDES: "):] for l in lines if l.startswith("  INCLUDES: ")]
    excludes = [l[len("  EXCLUDES: "):] for l in lines if l.startswith("  EXCLUDES: ")]
    assert includes == list(release.ALLOWLIST)
    assert excludes == list(release.DENYLIST_PATHS)
    assert lines[1] == "Tag: v9.9"
    assert lines[-1] == "(dry-run) Pass --apply to execute."


def test_release_unknown_arg(tmp_path):
    p = _run("release", ["--frobnicate"], tmp_path)
    assert p.returncode == 1
    assert p.stderr.startswith("ERROR: unknown argument: --frobnicate\n")
    assert "Usage: bin/release.sh" in p.stderr


def test_release_remote_as_last_arg_dies_silently(tmp_path):
    """bash `shift 2` past end under set -e: exit 1, no output (quirk preserved)."""
    p = _run("release", ["--remote"], tmp_path)
    assert p.returncode == 1
    assert p.stdout == "" and p.stderr == ""


def test_release_apply_abort_on_n(tmp_path):
    p = _run("release", ["--remote", "r", "--apply"], tmp_path, stdin="n\n")
    assert p.returncode == 0
    assert p.stdout.endswith("Aborted.\n")


def test_release_apply_eof_exits_1(tmp_path):
    """Closed stdin: bash read fails under set -e — exit 1 after the plan block."""
    p = _run("release", ["--remote", "r", "--apply"], tmp_path, stdin="")
    assert p.returncode == 1
    assert p.stdout.endswith("EXCLUDES: wiki-cloud/maintenance\n\n")  # nothing after plan
    assert "Aborted." not in p.stdout


def test_release_apply_accepts_yes_variants(tmp_path):
    """y/Y/yes/YES (whitespace-stripped) proceed; the empty fixture then fails
    the staged pre-flight (no .neutrality-denylist.txt) with exit 2 — and the
    staging dir is trap-cleaned."""
    tmpdir = tmp_path / "tmpdir"
    tmpdir.mkdir()
    for answer in ("y\n", "Y\n", "yes\n", "YES\n", "  y  \n"):
        p = _run("release", ["--remote", "r", "--apply"], tmp_path,
                 stdin=answer, env_extra={"TMPDIR": str(tmpdir)})
        assert p.returncode == 2, f"answer {answer!r}"
        assert "ERROR: .neutrality-denylist.txt missing in staged dir" in p.stderr
        assert list(tmpdir.iterdir()) == [], "staging dir leaked"


def test_release_email_env_override(tmp_path):
    p = _run("release", ["--remote", "r"], tmp_path,
             env_extra={"RELEASE_EMAIL": "custom@example.test"})
    assert "Release commit email: custom@example.test\n" in p.stdout
    # bash ${RELEASE_EMAIL:-default}: empty string also falls back to default
    p = _run("release", ["--remote", "r"], tmp_path,
             env_extra={"RELEASE_EMAIL": ""})
    assert "Release commit email: release@example.invalid\n" in p.stdout
