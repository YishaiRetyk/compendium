"""TEST-06 unit layer for the brownfield port (Phase 25 Plan 01, MIG-01).

Direct module-level coverage through the public main() dispatch — the heredoc-lifted
subcommand bodies are deliberately closures (verbatim extraction), so the unit seams
are the dispatch contract plus real bootstrap/scan runs on tmp fixtures. Byte-level
behavior parity is owned by the phase-10/11 suites + the WIKI_IMPL oracle; these
tests exist for fast, localized regression signal (D-18).
"""
import os

import pytest

from compendium import brownfield


def run_main(argv, capsys):
    """Call main(); normalize SystemExit vs return-code into (code, out, err)."""
    try:
        code = brownfield.main(argv)
    except SystemExit as e:
        code = e.code if e.code is not None else 0
    out, err = capsys.readouterr().out, ""
    # capsys.readouterr() returns both; re-split properly:
    return code, out, err


def run_main2(argv, capsys):
    try:
        code = brownfield.main(argv)
    except SystemExit as e:
        code = e.code if e.code is not None else 0
    captured = capsys.readouterr()
    return code, captured.out, captured.err


def test_no_args_usage_to_stderr_exit_1(capsys):
    code, out, err = run_main2([], capsys)
    assert code == 1
    assert out == ""
    assert err.startswith("Usage: bin/brownfield.sh")


def test_help_usage_to_stdout_exit_0(capsys):
    code, out, err = run_main2(["--help"], capsys)
    assert code == 0
    assert err == ""
    assert out.startswith("Usage: bin/brownfield.sh")


def test_unknown_subcommand_exit_1(capsys):
    code, out, err = run_main2(["frobnicate"], capsys)
    assert code == 1
    assert "ERROR: unknown subcommand: frobnicate" in err


def test_bootstrap_unknown_option_exit_1(capsys):
    code, out, err = run_main2(["bootstrap", "--bogus"], capsys)
    assert code == 1
    assert "ERROR: unknown bootstrap option: --bogus" in err


def test_bootstrap_root_missing_exit_1(tmp_path, capsys):
    missing = str(tmp_path / "nope")
    code, out, err = run_main2(["bootstrap", "--root", missing], capsys)
    assert code == 1
    assert "does not exist or is not a directory" in err


@pytest.fixture
def mini_vault(tmp_path, monkeypatch):
    monkeypatch.setenv("BROWNFIELD_FIXTURE_TODAY", "2026-01-15")
    page = tmp_path / "note.md"
    page.write_text(
        "---\ntitle: A Note\n---\n\n# A Note\n\nBody text.\n", encoding="utf-8"
    )
    return tmp_path


def test_bootstrap_dry_run_writes_report_only(mini_vault, capsys):
    code, out, err = run_main2(["bootstrap", "--root", str(mini_vault)], capsys)
    assert code == 0
    report = mini_vault / ".brownfield" / "REPORT.md"
    assert report.is_file()
    # dry-run must not mutate the page
    assert "bootstrap_stage" not in (mini_vault / "note.md").read_text(encoding="utf-8")


def test_bootstrap_apply_sets_sentinel_and_is_idempotent(mini_vault, capsys):
    code, _, _ = run_main2(["bootstrap", "--root", str(mini_vault), "--apply"], capsys)
    assert code == 0
    text = (mini_vault / "note.md").read_text(encoding="utf-8")
    assert "bootstrap_stage: bootstrapped" in text
    # Second apply: D-10 sentinel skip leaves the file byte-identical.
    code2, _, _ = run_main2(["bootstrap", "--root", str(mini_vault), "--apply"], capsys)
    assert code2 == 0
    assert (mini_vault / "note.md").read_text(encoding="utf-8") == text


def test_scan_writes_report_no_mutation(mini_vault, capsys):
    before = (mini_vault / "note.md").read_text(encoding="utf-8")
    code, _, _ = run_main2(["scan", "--root", str(mini_vault)], capsys)
    assert code == 0
    assert (mini_vault / ".brownfield" / "REPORT.md").is_file()
    assert (mini_vault / "note.md").read_text(encoding="utf-8") == before
