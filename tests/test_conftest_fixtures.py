"""Self-tests for the pytest harness fixtures (Phase 24 Plan 03, TEST-05)."""

import re
import subprocess
import sys
from pathlib import Path

import pytest

TESTS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(TESTS_DIR))
from conftest import SEED_MSG, assert_golden_tree  # noqa: E402


def _git_out(cwd, *args):
    return subprocess.run(["git", *args], cwd=cwd, check=True,
                          capture_output=True, text=True).stdout.strip()


def test_git_repo_is_seeded(git_repo):
    assert (git_repo / ".git").is_dir()
    assert _git_out(git_repo, "branch", "--show-current") == "main"
    log = _git_out(git_repo, "log", "--oneline")
    assert len(log.splitlines()) == 1
    assert SEED_MSG in log


def test_git_identity(git_repo):
    assert _git_out(git_repo, "config", "user.email") == "fixture@example.com"
    assert _git_out(git_repo, "config", "user.name") == "Fixture"


def test_seed_msg_matches_make_bare_repo():
    """REVIEWS MEDIUM: the unification is enforced against the bash source, not assumed."""
    lib = (TESTS_DIR / "phase-13" / "lib.sh").read_text(encoding="utf-8")
    m = re.search(r'--allow-empty -m "([^"]+)"', lib)
    assert m, "make_bare_repo seed commit not found in tests/phase-13/lib.sh"
    assert SEED_MSG == m.group(1)


def test_assert_golden_tree_roundtrip(tmp_path):
    a = tmp_path / "a"
    b = tmp_path / "b"
    for d in (a, b):
        (d / "sub").mkdir(parents=True)
        (d / "sub" / "f.md").write_text("same content\n", encoding="utf-8")
        (d / "top.md").write_text("top\n", encoding="utf-8")
    assert_golden_tree(a, b)  # identical -> passes
    (b / "top.md").write_text("top!\n", encoding="utf-8")
    with pytest.raises(AssertionError):
        assert_golden_tree(a, b)


def test_fixture_repo_fresh_per_call(fixture_repo, tmp_path):
    """REVIEWS MEDIUM: fresh dir per factory call + README exclusion, using a
    self-contained source tree (no dependence on a specific phase fixture)."""
    src = tmp_path / "phase-xx" / "fixtures" / "tiny"
    src.mkdir(parents=True)
    (src / "README.md").write_text("fixture docs — excluded\n", encoding="utf-8")
    (src / "page.md").write_text("real content\n", encoding="utf-8")

    import conftest
    orig = conftest.FIXTURES
    conftest.FIXTURES = tmp_path
    try:
        r1 = fixture_repo("xx", "tiny")
        r2 = fixture_repo("xx", "tiny")
    finally:
        conftest.FIXTURES = orig

    for r in (r1, r2):
        assert not (r / "README.md").exists(), "per-fixture README.md must be excluded"
        assert (r / "page.md").read_text(encoding="utf-8") == "real content\n"
        assert SEED_MSG in _git_out(r, "log", "--oneline")
    assert r1 != r2, "factory calls must land in DISTINCT directories (no shared state)"
