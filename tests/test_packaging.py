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

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent


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

    # D-04 module-invocation form works AND the stub fails loudly (exit 70).
    proc = subprocess.run(
        [str(py), "-m", "compendium.lint"],
        capture_output=True, text=True, check=False,
    )
    assert proc.returncode == 70, (
        f"stub sentinel: expected exit 70, got {proc.returncode}; "
        f"stderr: {proc.stderr}"
    )
    assert "not yet implemented" in proc.stderr, f"stub stderr: {proc.stderr}"
