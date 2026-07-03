"""PKG-01 install/import smoke test (Phase 24 Plan 01).

Bootstraps an isolated venv (the system python3 environment must not be
assumed to have a usable pip for editable installs) and proves:
  1. `pip install -e .` succeeds against pyproject.toml.
  2. `import compendium` + representative tool modules resolve.
  3. `python -m compendium.lint` exhibits the documented STUB contract:
     exit 70 (NOT_IMPLEMENTED sentinel) + a "not yet implemented" stderr line
     (REVIEWS MEDIUM: a stub that exits 0 could mask a missed Phase-25 port).
"""

import pathlib
import subprocess
import sys

from conftest import requires_network

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent


@requires_network  # pip must resolve the pinned deps unless a warm cache exists
def test_editable_install_and_imports(tmp_path):
    venv_dir = tmp_path / ".venv"
    proc = subprocess.run(
        [sys.executable, "-m", "venv", str(venv_dir)],
        capture_output=True, text=True, check=False,
    )
    assert proc.returncode == 0, f"venv bootstrap failed: {proc.stderr}"

    pip = venv_dir / "bin" / "pip"
    py = venv_dir / "bin" / "python"

    proc = subprocess.run(
        [str(pip), "install", "-e", "."],
        cwd=REPO_ROOT, capture_output=True, text=True, check=False,
    )
    assert proc.returncode == 0, f"pip install -e . failed: {proc.stderr}"

    proc = subprocess.run(
        [str(py), "-c",
         "import compendium, compendium.lint, compendium.validate_op, "
         "compendium.repo_snapshot"],
        capture_output=True, text=True, check=False,
    )
    assert proc.returncode == 0, f"package import failed: {proc.stderr}"

    # D-04 module-invocation form works. Pre-MIG-02 this asserted the stub
    # sentinel (exit 70 + "not yet implemented"); compendium.lint is now the
    # PORTED tool, so a bare run would lint the caller's cwd (and write the
    # report/log side effects) -- probe the read-only --version contract
    # instead: exit 0 + the LINT_VERSION semver on stdout.
    proc = subprocess.run(
        [str(py), "-m", "compendium.lint", "--version"],
        capture_output=True, text=True, check=False,
    )
    assert proc.returncode == 0, (
        f"module invocation: expected exit 0, got {proc.returncode}; "
        f"stderr: {proc.stderr}"
    )
    import re
    assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", proc.stdout.strip()), (
        f"--version stdout not a semver: {proc.stdout!r}"
    )
