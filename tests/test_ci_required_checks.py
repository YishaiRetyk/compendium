"""PKG-04/CUT-02 CI introspection.

Parses the workflow YAMLs and enforces:
  1. The 6 required job names exist as EXACT keys (branch-protection contract).
  2. None of the 6 required jobs carries a strategy.matrix (a matrix renames the check).
  3. All 6 required jobs install the package (`pip install -e .`) + setup-python.
  4. The pytest regression net (tests.yml) installs dev deps and invokes pytest — it
     replaced the retired parity matrix (26-02: one impl, nothing to diff).
  5. The retired parity/oracle machinery stays gone (resurrection guard).
"""

import pathlib

import yaml

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
WF = REPO_ROOT / ".github" / "workflows"

REQUIRED = {
    "lint.yml": ["lint", "privacy-leak", "strict", "skills-check"],
    "neutrality.yml": ["neutrality"],
    "setup-parity.yml": ["setup-parity"],
}


def _load(name):
    return yaml.safe_load((WF / name).read_text(encoding="utf-8"))


def test_required_job_names_exact():
    for wf_name, jobs in REQUIRED.items():
        d = _load(wf_name)
        for job in jobs:
            assert job in d["jobs"], (
                f"{wf_name}: required check '{job}' missing/renamed — "
                f"branch protection breaks (PKG-04)"
            )


def test_no_matrix_on_required_jobs():
    for wf_name, jobs in REQUIRED.items():
        d = _load(wf_name)
        for job in jobs:
            strategy = d["jobs"][job].get("strategy", {}) or {}
            assert "matrix" not in strategy, (
                f"{wf_name}:{job}: a matrix changes the required-check name "
                f"(Pitfall 4 — PKG-04)"
            )


def test_all_required_jobs_install_package():
    for wf_name, jobs in REQUIRED.items():
        d = _load(wf_name)
        for job in jobs:
            steps = d["jobs"][job]["steps"]
            assert any("pip install -e ." in str(s.get("run", "")) for s in steps), (
                f"{wf_name}:{job}: does not install the package — a ported "
                f"python shim fails here (PKG-04; skills-check = REVIEWS HIGH#10)"
            )
            assert any("setup-python" in str(s.get("uses", "")) for s in steps), (
                f"{wf_name}:{job}: missing setup-python"
            )


def test_tests_workflow_runs_pytest():
    """tests.yml (the pytest regression net that replaced parity.yml) must install the
    dev extras (pytest + pytest-xdist) and invoke pytest — the single parallel entrypoint."""
    d = _load("tests.yml")
    assert "tests" in d["jobs"], "tests.yml: 'tests' job missing"
    steps = d["jobs"]["tests"]["steps"]
    runs = " ".join(str(s.get("run", "")) for s in steps)
    assert "pip install -e .[dev]" in runs, "tests.yml: does not install dev extras (pytest-xdist)"
    assert "pytest" in runs, "tests.yml: does not invoke pytest"
    assert any("setup-python" in str(s.get("uses", "")) for s in steps), (
        "tests.yml: missing setup-python"
    )


def test_retired_parity_machinery_is_gone():
    """26-02 retired the frozen-bash parity oracle. Guard against accidental resurrection:
    the migration-only apparatus (parity workflow, bash runner, staged/common-freeze gates,
    ported manifest, freeze baseline) must stay deleted — pytest is the whole net now."""
    assert not (WF / "parity.yml").exists(), "parity.yml should be deleted (26-02)"
    for gone in (
        "tests/run-all-suites.sh",
        "bin/check-staged-parity.sh",
        "bin/check-common-freeze.sh",
        "tests/ported.manifest",
        "tests/freeze-baseline.sha",
        "tests/lib/oracle-worktree.sh",
    ):
        assert not (REPO_ROOT / gone).exists(), f"{gone} should be deleted (26-02)"
