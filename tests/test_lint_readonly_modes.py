"""26-03: lint's non-interactive VALIDATION modes (--staged, --ci) must be READ-ONLY.

The pre-commit hook runs `lint --strict --staged`; before 26-03 that mutated the wiki on
every commit — it rewrote wiki-cloud/maintenance/lint-report.md and appended a
`## [date] lint | wiki-cloud health check` entry to wiki-cloud/log.md (25-REVIEW F15 / the
2026-07-03-hook-lint-clobbers-wiki-report todo). A read-only validation run must not write.

These tests pin BOTH directions: --staged and --ci leave both files byte-unchanged, while
a plain interactive `lint` still writes them (the maintenance write path stays alive).
"""

import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
LINT = REPO_ROOT / "bin" / "lint.sh"

VALID_PAGE = """\
---
id: alpha
title: "Alpha"
type: concept
status: active
summary: "A fixture concept."
created_at: 2026-01-02
updated_at: 2026-01-02
sources: [src-x]
epistemic_status: sourced
tags: [fixture]
domains: [general]
supersedes:
superseded_by:
aliases: []
has_contradictions: false
knowledge_domain: software
neutrality_exempt: false
---

## TL;DR

- A fixture claim. [prov:src-x#p1]

## Sources

- src-x
"""

LOG_SEED = "# Activity Log\n\n## [2026-01-01] seed\n\nseeded.\n"
REPORT_SEED = "# stale lint report (must be overwritten only by a plain maintenance run)\n"


def _make_wiki(root: Path):
    (root / "wiki-cloud" / "concepts").mkdir(parents=True)
    (root / "wiki-cloud" / "maintenance").mkdir(parents=True)
    (root / "wiki-cloud" / "concepts" / "alpha.md").write_text(VALID_PAGE, encoding="utf-8")
    (root / "wiki-cloud" / "log.md").write_text(LOG_SEED, encoding="utf-8")
    (root / "wiki-cloud" / "maintenance" / "lint-report.md").write_text(REPORT_SEED, encoding="utf-8")


def _run(root, *args):
    return subprocess.run(
        ["bash", str(LINT), *args],
        cwd=str(root),
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def test_plain_lint_writes_report_and_log(tmp_path):
    """The interactive maintenance path stays alive: a plain `lint` rewrites the report
    and appends a log entry (guards against a fix that makes ALL modes read-only)."""
    _make_wiki(tmp_path)
    log = tmp_path / "wiki-cloud" / "log.md"
    report = tmp_path / "wiki-cloud" / "maintenance" / "lint-report.md"
    before_log, before_report = log.read_bytes(), report.read_bytes()
    _run(tmp_path, "wiki-cloud/")
    assert report.read_bytes() != before_report, "plain lint must (re)write lint-report.md"
    assert log.read_bytes() != before_log, "plain lint must append a log entry to log.md"


@pytest.mark.parametrize(
    "mode",
    [
        pytest.param(["--ci", "wiki-cloud/"], id="ci"),
        pytest.param(["--strict", "--staged", "--category", "provenance"], id="staged"),
    ],
)
def test_validation_modes_are_readonly(tmp_path, mode):
    """--staged (the pre-commit gate) and --ci must NOT mutate the wiki — this is the
    clobber fix. Both files must be byte-identical before and after the run."""
    _make_wiki(tmp_path)
    # --staged discovers changes from the git index, so the wiki must be a staged git repo.
    subprocess.run(["git", "init", "-q", "-b", "main"], cwd=tmp_path, check=True)
    subprocess.run(["git", "add", "-A"], cwd=tmp_path, check=True)
    log = tmp_path / "wiki-cloud" / "log.md"
    report = tmp_path / "wiki-cloud" / "maintenance" / "lint-report.md"
    before_log, before_report = log.read_bytes(), report.read_bytes()
    _run(tmp_path, *mode)
    assert log.read_bytes() == before_log, f"{mode}: log.md must be byte-unchanged (read-only validation)"
    assert report.read_bytes() == before_report, f"{mode}: lint-report.md must be byte-unchanged (read-only validation)"
