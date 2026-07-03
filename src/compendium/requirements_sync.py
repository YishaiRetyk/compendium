# src/compendium/requirements_sync.py — byte-parity port of bin/requirements-sync.sh
# (Phase 25 MIG-05, DEBT-03).
#
# PARITY CONTRACT: the python3 heredoc core is lifted VERBATIM (parsing regexes,
# normalize(), last-write-wins semantics, table/JSON emission). VERIFICATION.md
# discovery stays external: `find -maxdepth 3` + `LC_ALL=C sort` via subprocess
# with identical argv — the goldens were RE-frozen under LC_ALL=C collation
# (uppercase-first), and duplicate-REQ-ID last-write-wins depends on that exact
# file order. The bash mktemp sentinel files were pure bash<->python IPC and are
# internalized (return values) — no observable channel touched them.
import json
import os
import re
import shutil
import subprocess
import sys

USAGE = """Usage: bin/requirements-sync.sh [OPTIONS]

DEBT-03: Compares REQUIREMENTS.md status vs phase VERIFICATION.md truths.
Emits a markdown table (default) or JSON array.

Options:
  --help, -h              Show this help message
  --format <text|json>    Output format (default: text)
  --strict                Exit 2 on any drift row (default: advisory, exit 0)
  --require-complete      Exit 2 when any in-scope REQ-ID has status != Complete
                          in REQUIREMENTS.md. Closure-gate primitive: --strict
                          checks consistency (REQUIREMENTS.md vs VERIFICATION.md);
                          --require-complete checks completion. The two are
                          orthogonal and can be combined. Composes with --phase
                          for phase-scope closure; without --phase the check
                          spans every REQ-ID in REQUIREMENTS.md.
  --phase N               Restrict to REQ-IDs mapped to Phase N in REQUIREMENTS.md
  --root DIR              Override default root (.planning/); REQUIREMENTS.md is
                          read from <root>/REQUIREMENTS.md and VERIFICATION.md
                          files are discovered via find -maxdepth 3.

Exit codes:
  0   Success (advisory mode, or strict with no drift, or require-complete with
      every in-scope REQ-ID Complete)
  1   Script failure (missing files, bad flags, python error)
  2   Strict mode found drift rows, OR require-complete found incomplete rows
      (combined when both flags are passed)

Examples:
  bash bin/requirements-sync.sh
  bash bin/requirements-sync.sh --phase 7 --strict
  bash bin/requirements-sync.sh --format json | jq '.[] | select(.drift)'
  bash bin/requirements-sync.sh --root tests/phase-07/fixtures/requirements-sync
  bash bin/requirements-sync.sh --require-complete           # milestone closure
  bash bin/requirements-sync.sh --phase 12.1 --require-complete  # phase closure
"""

# --- Parse REQUIREMENTS.md traceability table (verbatim from the heredoc) ---
# Rows: | REQ-ID | Phase N | Status |
REQ_ROW_RE = re.compile(
    r'^\|\s*([A-Z]+-\d+)\s*\|\s*Phase\s*([0-9]+(?:\.[0-9]+)?)\s*\|\s*([^|]+?)\s*\|'
)

# --- Parse VERIFICATION.md files (lexicographic order, last-write-wins) ---
# Strip checkbox / emoji / bold prefixes before REQ-ID, then capture status after colon.
LEADING_JUNK = re.compile(
    r'^\s*-\s*(?:\[[ xX]\]\s*)?(?:[^\w\s]+\s*)?(?:\*\*)?'
)
REQ_STATUS = re.compile(
    r'([A-Z]+-\d+)(?:\*\*)?\s*:\s*(.+?)\s*$'
)


def normalize(status):
    s = status.strip().lower()
    if s in ("complete", "done", "pass", "passing"):
        return "Complete"
    if s in ("pending", "todo", "in progress", "blocked"):
        return "Pending"
    return status.strip() or "Unknown"


def parse_requirements(req_file):
    """The heredoc's REQUIREMENTS.md pass: list of (req_id, phase_label, status)."""
    requirements = []
    with open(req_file, encoding="utf-8") as f:
        for line in f:
            m = REQ_ROW_RE.match(line)
            if m:
                requirements.append((m.group(1), m.group(2), m.group(3)))
    return requirements


def parse_verifications(verif_list):
    """The heredoc's VERIFICATION.md pass: (verif_map, warnings) with
    last-write-wins over the given (already LC_ALL=C-sorted) file order."""
    verif_map = {}   # req_id -> (normalized_status, raw_status, file_path)
    warnings = []
    for vf in verif_list:
        try:
            with open(vf, encoding="utf-8") as f:
                content = f.read()
        except OSError:
            continue
        for line in content.splitlines():
            stripped = LEADING_JUNK.sub("", line)
            m = REQ_STATUS.match(stripped)
            if not m:
                continue
            rid = m.group(1)
            raw = m.group(2)
            norm = normalize(raw)
            if rid in verif_map:
                earlier = verif_map[rid][2]
                warnings.append(
                    f"WARN: duplicate REQ-ID {rid} seen in {earlier}; using {vf} per last-write-wins"
                )
            verif_map[rid] = (norm, raw, vf)
    return verif_map, warnings


def build_findings(requirements, verif_map, phase_filter):
    """The heredoc's findings pass. Returns (findings, drift_count)."""
    findings = []
    drift_count = 0
    for rid, phase, req_status in requirements:
        if phase_filter and str(phase) != str(phase_filter):
            continue
        req_norm = normalize(req_status)
        if rid in verif_map:
            v_norm, v_raw, _ = verif_map[rid]
            if v_norm == "Unknown":
                drift = False
                note = f"Unknown status token in VERIFICATION: {v_raw!r}"
            else:
                drift = (req_norm != v_norm)
                note = "DRIFT" if drift else "OK"
            verif_cell = v_norm
        else:
            v_norm = "(not found)"
            drift = False
            note = "OK - Phase not yet run"
            verif_cell = v_norm

        if drift:
            drift_count += 1

        findings.append({
            "req_id": rid,
            "requirements_md": req_norm,
            "verification_md": verif_cell,
            "drift": drift,
            "note": note,
            "phase": phase,
        })
    return findings, drift_count


def _reconfigure_streams():
    for s in (sys.stdout, sys.stderr):
        try:
            s.reconfigure(encoding="utf-8", errors="surrogateescape")
        except Exception:
            pass


def _out(s):
    sys.stdout.write(s)
    sys.stdout.flush()


def _err(s):
    sys.stderr.write(s)
    sys.stderr.flush()


def _rc_of(p):
    return 128 - p.returncode if p.returncode < 0 else p.returncode


def _capture(argv, stdin_bytes=None, stderr=None, env=None):
    sys.stdout.flush()
    sys.stderr.flush()
    p = subprocess.run(argv, input=stdin_bytes, stdout=subprocess.PIPE,
                       stderr=stderr, env=env)
    return p.stdout, _rc_of(p)


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    _reconfigure_streams()

    # -----------------------------------------------------------------------
    # Argument parsing
    # -----------------------------------------------------------------------

    fmt = "text"
    strict = 0
    require_complete = 0
    phase_filter = ""
    root = ".planning"

    while args:
        a = args[0]
        if a in ("--help", "-h"):
            _out(USAGE)
            return 0
        elif a == "--format":
            if len(args) < 2:
                _err("ERROR: --format requires a value\n")
                return 1
            fmt = args[1]
            args = args[2:]
        elif a == "--strict":
            strict = 1
            args = args[1:]
        elif a == "--require-complete":
            require_complete = 1
            args = args[1:]
        elif a == "--phase":
            if len(args) < 2:
                _err("ERROR: --phase requires a value\n")
                return 1
            phase_filter = args[1]
            args = args[2:]
        elif a == "--root":
            if len(args) < 2:
                _err("ERROR: --root requires a value\n")
                return 1
            root = args[1]
            args = args[2:]
        elif a.startswith("-"):
            _err(f"ERROR: Unknown option: {a}\n")
            _err(USAGE)
            return 1
        else:
            _err(f"ERROR: Unexpected positional arg: {a}\n")
            return 1

    if fmt != "text" and fmt != "json":
        _err("ERROR: --format must be 'text' or 'json'\n")
        return 1

    if not shutil.which("python3"):
        _err("ERROR: python3 is required but not found\n")
        return 1

    req_file = f"{root}/REQUIREMENTS.md"
    if not os.path.isfile(req_file):
        _err(f"ERROR: REQUIREMENTS.md not found at {req_file}\n")
        return 1

    # Discover VERIFICATION.md files (maxdepth 3 handles both fixture flat layout
    # and real .planning/phases/XX/XX-VERIFICATION.md layout). find + LC_ALL=C
    # sort stay EXTERNAL — the exact collation order is the last-write-wins seam.
    fo, _frc = _capture(["find", root, "-maxdepth", "3", "-name", "*VERIFICATION.md",
                         "-type", "f"], stderr=subprocess.DEVNULL)
    so, _src = _capture(["sort"], stdin_bytes=fo,
                        env={**os.environ, "LC_ALL": "C"})
    verif_list_str = so.decode("utf-8", "surrogateescape").rstrip("\n")  # $() strip

    # -----------------------------------------------------------------------
    # Core work — verbatim lift of the python3 heredoc
    # -----------------------------------------------------------------------

    verif_list = [p for p in verif_list_str.split("\n") if p.strip()]

    requirements = parse_requirements(req_file)
    verif_map, warnings = parse_verifications(verif_list)

    for w in warnings:
        print(w, file=sys.stderr)
    sys.stderr.flush()

    findings, drift_count = build_findings(requirements, verif_map, phase_filter)

    # --- Completion check (--require-complete) ---
    # A row is "incomplete" iff its REQUIREMENTS.md status is not "Complete".
    incomplete_rows = [row for row in findings if row["requirements_md"] != "Complete"]
    incomplete_count = len(incomplete_rows)

    # --- Emit output ---
    if fmt == "json":
        print(json.dumps(findings, indent=2))
    else:
        print("Advisory mode — active-phase drift expected. Pass --strict at milestone close.")
        print("")
        print("| REQ-ID    | REQUIREMENTS.md | VERIFICATION.md | Drift | Note |")
        print("|-----------|-----------------|-----------------|-------|------|")
        for row in findings:
            drift_cell = "DRIFT" if row["drift"] else "ok"
            print(f"| {row['req_id']:<9} | {row['requirements_md']:<15} | {row['verification_md']:<15} | {drift_cell:<5} | {row['note']} |")
        print("")
        print(f"# {drift_count} drift row(s) of {len(findings)} total.")
        if require_complete:
            scope = f"phase {phase_filter}" if phase_filter else "milestone"
            if incomplete_count == 0:
                print(f"# require-complete ({scope}): all {len(findings)} in-scope REQ-IDs are Complete.")
            else:
                print(f"# require-complete ({scope}): {incomplete_count} of {len(findings)} in-scope REQ-IDs are NOT Complete:")
                for row in incomplete_rows:
                    print(f"#   - {row['req_id']} (Phase {row['phase']}): {row['requirements_md']}")
    sys.stdout.flush()

    print(f"Drift rows: {drift_count} / {len(findings)}", file=sys.stderr)
    if require_complete:
        print(f"Incomplete rows: {incomplete_count} / {len(findings)}", file=sys.stderr)
    sys.stderr.flush()

    # -----------------------------------------------------------------------
    # Exit-code policy (the bash consumed the sentinel counts here)
    # -----------------------------------------------------------------------

    if strict == 1 and drift_count > 0:
        return 2
    if require_complete == 1 and incomplete_count > 0:
        return 2
    return 0


if __name__ == "__main__":          # enables `python3 -m compendium.requirements_sync`
    sys.exit(main(sys.argv[1:]))
