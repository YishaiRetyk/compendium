"""PKG-04/TEST-01/TEST-02 CI introspection (Phase 24 Plan 05).

Parses the workflow YAMLs and enforces:
  1. The 6 required job names exist as EXACT keys (branch-protection contract).
  2. None of the 6 required jobs carries a strategy.matrix.
  3. parity.yml has the WIKI_IMPL matrix job + the parity-equivalence job.
  4. All 6 required jobs install the package (`pip install -e .`).
  5. The enumerated suite list in tests/run-all-suites.sh includes 22, 23 AND 24
     (REVIEWS HIGH#5 + RB-5), parity.yml invokes the runner, and the runner
     carries the IT_CAPTURE_DIR-fed --require-parity channel comparison
     (REVIEWS HIGH#4 / cycle-3 finding #2 / TEST-01).
"""

import pathlib
import re

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


def test_parity_matrix_and_equivalence_jobs():
    d = _load("parity.yml")
    impls = d["jobs"]["parity-suites"]["strategy"]["matrix"]["impl"]
    assert "bash" in impls and "py" in impls, f"WIKI_IMPL matrix incomplete: {impls}"
    assert "parity-equivalence" in d["jobs"], (
        f"parity-equivalence job missing (REVIEWS HIGH#4): {list(d['jobs'])}"
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


def test_suites_enumerated_and_channel_comparison_present():
    runner = (REPO_ROOT / "tests" / "run-all-suites.sh").read_text(encoding="utf-8")
    m = re.search(r"^SUITES=\(([^)]*)\)", runner, re.MULTILINE)
    assert m, "run-all-suites.sh: enumerated SUITES=() list missing (must not be a glob)"
    suites = m.group(1).split()
    for required_suite in ("09", "10", "13", "15", "20", "22", "23", "24"):
        assert required_suite in suites, (
            f"run-all-suites.sh: suite {required_suite} missing from the enumerated "
            f"list {suites} (REVIEWS HIGH#5 / RB-5 — 22/23 are the real desktop "
            f"suites, 24 is the goldens suite)"
        )
    assert "IT_CAPTURE_DIR" in runner and "require-parity" in runner, (
        "run-all-suites.sh: IT_CAPTURE_DIR channel capture / --require-parity missing "
        "(REVIEWS HIGH#4 / cycle-3 finding #2 / TEST-01)"
    )
    assert re.search(r"\bcmp\b|\bdiff\b", runner), (
        "run-all-suites.sh: no byte-comparison (cmp/diff) in the parity path"
    )
    parity = (WF / "parity.yml").read_text(encoding="utf-8")
    assert "run-all-suites.sh" in parity, "parity.yml does not invoke the runner"
    assert "no-direct-bin-calls.sh" in parity, "parity.yml missing the routing gate"
