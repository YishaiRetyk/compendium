"""tests/test_blackbox_suites.py — the CUT-02 pytest bridge (D-26-01).

Bridges the frozen black-box bash suites onto pytest. It discovers every
``tests/phase-<suite>/test_*.sh`` in the enumerated suite set, emits ONE pytest
case per file (id = ``phase-<suite>/<testname>``), and runs each against the REAL
Python ``bin/`` — the seam (``tests/lib/invoke_tool.sh``) runs each tool's
``bin/<tool>.sh`` shim, which execs ``python3 -m compendium.<tool>``. (Post-26-02
there is one implementation; the frozen-bash parity oracle is retired.)

The pinned baseline in ``tests/SUITE_MANIFEST.txt`` is the contract: a manifest
``FAIL`` row is ``xfail(strict=True)`` (a stale prior-phase test that must keep
failing — if it starts passing, strict-xfail turns the XPASS into a failure so the
manifest is re-pinned deliberately); every other file must exit 0.

Bridge, NOT rewrite (D-26-01): the bash files ARE the behavioral spec. This
collector replaced the retired bash *runner*; the bash test *files* stay as the
spec, now driven in parallel by pytest-xdist (``-n auto``).

Faithfulness note: ``PDF_EXTRACT_SKIP_LIVE=1`` mirrors the retired runner's default
(no live PDF/OCR). The seam pins ``LC_ALL=C``/``TZ=UTC``/``PYTHONPATH`` per tool-call
internally, so the reproduced pass/FAIL baseline is byte-for-byte SUITE_MANIFEST.txt.
"""

import os
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
MANIFEST = REPO_ROOT / "tests" / "SUITE_MANIFEST.txt"

# The enumerated suite set (inherited from the retired run-all-suites.sh) — an explicit
# list, never a glob: a phase dir with test_*.sh but absent here is intentionally out of
# the black-box net (e.g. phase-07/08's setup suites, run by their own CI job).
SUITES = ["09", "09.1", "10", "11", "12.1", "12.2", "13",
          "15", "18", "20", "22", "23", "24"]

# Suites whose tests touch SHARED live state and therefore cannot run concurrently
# with each other under pytest-xdist (the bash runner was strictly serial, so these
# races never existed before the bridge). They are pinned to ONE worker via a shared
# `xdist_group` under `--dist loadgroup`; every other suite parallelizes freely.
#   18   — mutates the LIVE .claude/skills/ tree (gen-skills injects/restores drift;
#          two of its tests racing was the concrete flake this guards against).
#   24   — characterization tests read the LIVE .claude/skills via `gen-skills --check`
#          (root-anchored, ignores cwd), so they race suite 18's drift injection.
#   12.2 — clones the live repo and runs the live pre-commit hook (contends on .git).
SERIAL_SUITES = {"12.2", "18", "24"}
_LIVE_GROUP = pytest.mark.xdist_group("live_repo")


def _load_manifest():
    """Return {'phase-<NN>/<testname>': 'PASS'|'FAIL'} from SUITE_MANIFEST.txt."""
    baseline = {}
    for raw in MANIFEST.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        name, status = line.split()
        baseline[name] = status
    return baseline


_BASELINE = _load_manifest()


def _discover():
    """One pytest.param per enumerated-suite test_*.sh; pinned FAILs → xfail-strict."""
    params = []
    for suite in SUITES:
        suite_dir = REPO_ROOT / "tests" / f"phase-{suite}"
        if not suite_dir.is_dir():
            # LOUD failure, never a silent glob skip (mirrors run-all's FATAL guard).
            raise RuntimeError(f"enumerated suite missing: {suite_dir}")
        for test in sorted(suite_dir.glob("test_*.sh")):
            name = f"phase-{suite}/{test.stem}"
            marks = []
            if suite in SERIAL_SUITES:
                marks.append(_LIVE_GROUP)
            if _BASELINE.get(name) == "FAIL":
                marks.append(pytest.mark.xfail(
                    strict=True,
                    reason=f"pinned FAIL in SUITE_MANIFEST.txt ({name}) — stale prior-phase test",
                ))
            params.append(pytest.param(str(test), name, id=name, marks=marks))
    return params


@pytest.mark.parametrize("test_path,name", _discover())
def test_blackbox_suite(test_path, name, tmp_path):
    """Run one frozen bash suite file against the real Python bin/.

    cwd is a fresh per-test tmp dir, NOT the repo root: a handful of suites write
    relative scratch files (`2>stderr.txt`) into cwd, which under one shared
    repo-root cwd would collide across xdist workers. Tests locate the repo through
    absolute $REPO_ROOT/$SCRIPT_DIR (from BASH_SOURCE, cwd-independent) or self-`cd`,
    so an isolated cwd is transparent to them while making relative writes race-free.
    """
    env = dict(os.environ)
    env.setdefault("PDF_EXTRACT_SKIP_LIVE", "1")  # retired runner's default: no live PDF/OCR
    result = subprocess.run(
        ["bash", test_path],
        cwd=str(tmp_path),
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    if result.returncode != 0:
        tail = result.stdout[-4000:] if result.stdout else "(no output)"
        pytest.fail(f"{name} exited {result.returncode}\n--- last output ---\n{tail}")


def test_manifest_matches_suite_files():
    """The manifest and the on-disk enumerated-suite files must be in bijection.

    Carries forward the retired runner's "MANIFEST ROW WITHOUT A TEST FILE" guard (a
    deleted regression-carrying test must not silently shrink the net) AND the
    symmetric direction (a new unpinned test file must be pinned deliberately,
    not left to pass silently). Currently 205 rows ↔ 205 files.
    """
    on_disk = {
        f"phase-{suite}/{p.stem}"
        for suite in SUITES
        for p in (REPO_ROOT / "tests" / f"phase-{suite}").glob("test_*.sh")
    }
    pinned = set(_BASELINE)
    missing_files = sorted(pinned - on_disk)
    unpinned_files = sorted(on_disk - pinned)
    assert not missing_files, f"manifest rows with no test file (deleted test?): {missing_files}"
    assert not unpinned_files, f"test files absent from SUITE_MANIFEST.txt (pin them): {unpinned_files}"
