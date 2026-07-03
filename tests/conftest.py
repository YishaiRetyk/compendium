"""Pytest harness (Phase 24 Plan 03, TEST-05) — FROZEN shared surface (D-08).

Behaviorally mirrors the bash fixture helpers (D-13: the bash helpers stay untouched):
  git_repo     <-> make_bare_repo   (tests/phase-13/lib.sh)
  fixture_repo <-> make_fixture_repo (tests/phase-10/lib.sh; excludes per-fixture README.md)
Both fixtures use ONE SEED_MSG (REVIEWS MEDIUM: the bash helpers diverge on
"seed" vs "fixture seed"; the pytest layer unifies on make_bare_repo's exact
message). Ready to host net-new TEST-06 unit coverage from Phase 25.
"""

import os
import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
FIXTURES = REPO_ROOT / "tests"
SEED_MSG = "seed"   # ONE source of truth — make_bare_repo's exact message (REVIEWS MEDIUM)


def _git(cwd, *args):
    subprocess.run(["git", *args], cwd=cwd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def _seed(repo: Path):
    _git(repo, "init", "-q", "-b", "main")
    _git(repo, "config", "user.email", "fixture@example.com")
    _git(repo, "config", "user.name", "Fixture")


@pytest.fixture
def git_repo(tmp_path):
    """Fresh seeded git repo (mirrors make_bare_repo)."""
    _seed(tmp_path)
    _git(tmp_path, "-c", "commit.gpgsign=false", "commit", "-q",
         "--allow-empty", "-m", SEED_MSG)
    return tmp_path


@pytest.fixture
def fixture_repo(tmp_path_factory):
    """Copy tests/phase-NN/fixtures/<name>/ into a FRESH seeded repo per call
    (mirrors make_fixture_repo; excludes per-fixture README.md). REVIEWS MEDIUM:
    a fresh tmp dir PER call — no state accumulation across factory invocations."""
    def _make(phase, name):
        repo = tmp_path_factory.mktemp(f"fixture-{phase}-{name}")
        src = FIXTURES / f"phase-{phase}" / "fixtures" / name
        for f in src.rglob("*"):
            if f.is_file() and f.name != "README.md":
                dst = repo / f.relative_to(src)
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f, dst)
        _seed(repo)
        _git(repo, "add", "-A")
        _git(repo, "-c", "commit.gpgsign=false", "commit", "-q",
             "--allow-empty", "-m", SEED_MSG)
        return repo
    return _make


def assert_golden_tree(actual_dir: Path, golden_dir: Path):
    """Byte-exact directory comparison helper (TEST-05)."""
    a = {p.relative_to(actual_dir): p for p in actual_dir.rglob("*") if p.is_file()}
    g = {p.relative_to(golden_dir): p for p in golden_dir.rglob("*") if p.is_file()}
    assert set(a) == set(g), f"tree mismatch: {set(a) ^ set(g)}"
    for rel in g:
        assert a[rel].read_bytes() == g[rel].read_bytes(), f"byte diff: {rel}"


def _ollama_up():
    import urllib.request
    try:
        urllib.request.urlopen("http://localhost:11434/api/tags", timeout=2)
        return True
    except Exception:
        return False


requires_ollama = pytest.mark.skipif(not _ollama_up(), reason="Ollama unreachable")
requires_network = pytest.mark.skipif(os.environ.get("NO_NETWORK") == "1",
                                      reason="network disabled")
