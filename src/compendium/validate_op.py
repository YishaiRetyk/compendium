# src/compendium/validate_op.py — byte-parity port of bin/validate-op.sh (Phase 25 MIG-05).
#
# PARITY CONTRACT: the two inline `python3 -c` blocks (frontmatter schema check,
# structural privacy check) are lifted VERBATIM as internal functions — the bash
# captured their merged stdout+stderr ($(... 2>&1)), so the lifts return an
# ordered line list + exit status instead of printing. External commands the bash
# shells out to (grep -oP / sed / sort -u in check_provenance, realpath in the
# MERGE-distinct check) stay external via subprocess with identical argv.
# Diagnostics are a user-facing contract (.claude/settings.local.json hook).
import os
import re
import subprocess
import sys

USAGE = """Usage: bin/validate-op.sh <OPERATION> <target-path> [second-path]

Validates a structured wiki operation before it is applied.

Operations:
  UPDATE    <path>          Validate updating an existing page
  MERGE     <path-a> <path-b>  Validate merging two pages
  SUPERSEDE <path>          Validate superseding a page
  ARCHIVE   <path>          Validate archiving a page

Checks performed (5 mechanical checks per AGENTS.md section 9):
  [1/5] Target page(s) exist
  [2/5] YAML frontmatter parses and satisfies schema (enum values, required fields)
  [3/5] Provenance references resolve to known source IDs in wiki-cloud/sources/
  [4/5] Privacy flags respected (inheritance: strictest source tier wins)
  [5/5] MERGE-specific: both pages exist and are distinct

Per-operation rules:
  - ARCHIVE rejects already-archived pages
  - SUPERSEDE rejects already-superseded pages

Exit codes:
  0  All checks PASS
  1  One or more checks FAIL, or usage error

Options:
  --help, -h    Show this help message
"""


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


def _capture(argv, stdin_bytes=None, stderr=None):
    sys.stdout.flush()
    sys.stderr.flush()
    p = subprocess.run(argv, input=stdin_bytes, stdout=subprocess.PIPE, stderr=stderr)
    return p.stdout, _rc_of(p)


def _cs(out_bytes):
    return out_bytes.decode("utf-8", "surrogateescape").rstrip("\n")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def validate_frontmatter(file, op):
    """Verbatim lift of the bash validate_frontmatter python3 -c block.
    Returns (ordered output lines, exit status) — the bash captured 2>&1."""
    import yaml
    out = []
    try:
        content = open(file).read()

        if not content.startswith('---'):
            out.append('FAIL: No YAML frontmatter found')
            return out, 1

        try:
            end = content.index('---', 3)
            fm = yaml.safe_load(content[3:end])
            if fm is None:
                out.append('FAIL: Empty frontmatter')
                return out, 1

            # Check required base fields (always required)
            required = ['id', 'title', 'type', 'status', 'summary', 'created_at', 'updated_at',
                        'sources', 'epistemic_status', 'tags', 'domains']
            missing = [f for f in required if f not in fm]
            if missing:
                out.append(f'FAIL: Missing required fields: {missing}')
                return out, 1

            # Validate enum values
            valid_types = {'entity', 'concept', 'source', 'comparison', 'overview', 'decision'}
            if fm['type'] not in valid_types:
                out.append(f"FAIL: Invalid type '{fm['type']}', must be one of: {sorted(valid_types)}")
                return out, 1

            valid_status = {'active', 'stale', 'superseded', 'archived'}
            if fm['status'] not in valid_status:
                out.append(f"FAIL: Invalid status '{fm['status']}', must be one of: {sorted(valid_status)}")
                return out, 1

            valid_epistemic = {'sourced', 'mixed', 'tentative', 'stale'}
            if fm['epistemic_status'] not in valid_epistemic:
                out.append(f"FAIL: Invalid epistemic_status '{fm['epistemic_status']}', must be one of: {sorted(valid_epistemic)}")
                return out, 1

            # Privacy is structural (Phase 15): determined by directory tier
            # (wiki-cloud/ vs wiki-local/), not a frontmatter field. No enum check here.

            # Per-operation checks
            if op == 'ARCHIVE' and fm['status'] == 'archived':
                out.append('FAIL: Page is already archived')
                return out, 1

            if op == 'SUPERSEDE' and fm.get('superseded_by'):
                out.append(f"FAIL: Page already superseded by '{fm['superseded_by']}'")
                return out, 1

            # Source-type specific: check compilation fields if present
            if fm['type'] == 'source':
                comp_status = fm.get('compilation_status')
                if comp_status and comp_status not in ('pending', 'partial', 'compiled', 'stale'):
                    out.append(f"FAIL: Invalid compilation_status '{comp_status}'")
                    return out, 1

            out.append('PASS')
            return out, 0

        except yaml.YAMLError as e:
            out.append(f'FAIL: YAML parse error: {e}')
            return out, 1
        except ValueError:
            out.append('FAIL: Unterminated frontmatter (missing closing ---)')
            return out, 1
    except Exception:
        # The bash python3 -c would die with a traceback (captured 2>&1); no
        # traceback line matches the caller's `grep -i "^FAIL"` filter, so only
        # the FAIL verdict is observable. Keep the text for the merged capture.
        import traceback
        out.extend(traceback.format_exc().rstrip("\n").split("\n"))
        return out, 1


def check_provenance(file):
    """Port of check_provenance — grep/sed/sort stay external (identical argv).
    Returns (ordered merged output lines, status)."""
    out = []
    o1, _r1 = _capture(["grep", "-oP", r"\[prov:([^#\]]+)#", file],
                       stderr=subprocess.DEVNULL)
    o2, _r2 = _capture(["sed", r"s/\[prov://;s/#$//"], stdin_bytes=o1)
    o3, _r3 = _capture(["sort", "-u"], stdin_bytes=o2)
    src_ids = _cs(o3)  # $(...) || true
    if not src_ids:
        out.append("PASS (no provenance markers found)")
        return out, 0
    failed = 0
    for src_id in src_ids.split("\n"):
        if not os.path.isfile(f"wiki-cloud/sources/{src_id}.md"):
            out.append(f"FAIL: Provenance reference '{src_id}' does not resolve to wiki-cloud/sources/{src_id}.md")
            failed = 1
    if failed == 0:
        out.append("PASS")
    return out, failed


def check_privacy(file, op):
    """Verbatim lift of the bash check_privacy python3 -c block.
    Returns (ordered output lines, exit status) — the bash captured 2>&1."""
    import yaml
    out = []
    try:
        # Phase 15 structural privacy: a page's tier is its directory, not a frontmatter
        # field. A page under wiki-local/ is local_only; under wiki-cloud/ is cloud_safe.
        def is_local(p):
            p = (p or '').lstrip('/')
            return p == 'wiki-local' or p.startswith('wiki-local/') or '/wiki-local/' in ('/' + p)

        page_local = is_local(file)

        # Parse sources for the structural inheritance check (frontmatter is optional here
        # for the privacy decision -- the tier comes from the path, not the field).
        sources = []
        content = open(file).read()
        if content.startswith('---'):
            try:
                end = content.index('---', 3)
                fm = yaml.safe_load(content[3:end]) or {}
                sources = fm.get('sources', []) or []
            except (ValueError, yaml.YAMLError):
                pass  # frontmatter issues are Check 4's concern, not this check's

        # A contributing source is local iff its SUMMARY page lives under wiki-local/sources/.
        local_sources = [s for s in sources if os.path.exists(f'wiki-local/sources/{s}.md')]
        if local_sources and not page_local:
            out.append(f"FAIL: Privacy violation -- page is under wiki-cloud/ (cloud_safe) but source(s) {local_sources} live under wiki-local/. The page must live under wiki-local/ per the asymmetric two-dir model.")
            return out, 1

        tier = 'local_only' if page_local else 'cloud_safe'
        out.append(f'PASS (privacy: {tier})')
        return out, 0
    except Exception:
        import traceback
        out.extend(traceback.format_exc().rstrip("\n").split("\n"))
        return out, 1


def _physical_lines(entries):
    """Entries may embed newlines (e.g. multi-line PyYAML errors); the bash greps
    operate on PHYSICAL lines of the captured $(... 2>&1) text."""
    return "\n".join(entries).split("\n")


def _grep_q(lines, prefix):
    """echo "$x" | grep -q "^PREFIX" (case-sensitive)."""
    return any(l.startswith(prefix) for l in _physical_lines(lines))


def _grep_contains(lines, needle):
    """echo "$x" | grep -q "needle" (substring, any line)."""
    return any(needle in l for l in _physical_lines(lines))


def _emit_fail_lines(lines):
    """echo "$x" | grep -i "^FAIL" >&2 || true"""
    pat = re.compile(r'^fail', re.IGNORECASE)
    for l in _physical_lines(lines):
        if pat.match(l):
            _err(l + "\n")


def print_check(num, label, result):
    _out("  [%s/5] %-25s %s\n" % (num, label, result))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    _reconfigure_streams()

    if len(args) == 0:
        _out(USAGE)
        return 1

    if args[0] in ("--help", "-h"):
        _out(USAGE)
        return 0

    op = args[0]
    rest = args[1:]

    # Validate operation type
    if op not in ("UPDATE", "MERGE", "SUPERSEDE", "ARCHIVE"):
        _err(f"ERROR: Invalid operation type: '{op}'\n")
        _err("Must be one of: UPDATE, MERGE, SUPERSEDE, ARCHIVE\n")
        return 1

    # Validate argument count
    path_a = path_b = target = None
    if op == "MERGE":
        if len(rest) < 2:
            _err("ERROR: MERGE requires two target paths\n")
            _err("Usage: bin/validate-op.sh MERGE <path-a> <path-b>\n")
            return 1
        path_a = rest[0]
        path_b = rest[1]
    else:
        if len(rest) < 1:
            _err(f"ERROR: {op} requires a target path\n")
            _err(f"Usage: bin/validate-op.sh {op} <target-path>\n")
            return 1
        target = rest[0]

    # -----------------------------------------------------------------------
    # Run 5 mechanical checks
    # -----------------------------------------------------------------------

    failed = 0

    if op == "MERGE":
        _out(f"=== Validating {op} on {path_a} + {path_b} ===\n")
    else:
        _out(f"=== Validating {op} on {target} ===\n")
    _out("\n")

    # --- Check 1: Target page(s) exist ---
    if op == "MERGE":
        if not os.path.isfile(path_a):
            print_check(1, "Target exists", "FAIL")
            _err(f"  FAIL: Target page does not exist: {path_a}\n")
            failed = 1
        elif not os.path.isfile(path_b):
            print_check(1, "Target exists", "FAIL")
            _err(f"  FAIL: Target page does not exist: {path_b}\n")
            failed = 1
        else:
            print_check(1, "Target exists", "PASS")
    else:
        if os.path.isfile(target):
            print_check(1, "Target exists", "PASS")
        else:
            print_check(1, "Target exists", "FAIL")
            _err(f"  FAIL: Target page does not exist: {target}\n")
            failed = 1

    # --- Check 2: Frontmatter valid (YAML parse + schema) ---
    if failed == 0:
        if op == "MERGE":
            fm_a, _ = validate_frontmatter(path_a, op)
            fm_b, _ = validate_frontmatter(path_b, op)
            if _grep_q(fm_a, "PASS") and _grep_q(fm_b, "PASS"):
                print_check(2, "Frontmatter valid", "PASS")
            else:
                print_check(2, "Frontmatter valid", "FAIL")
                _emit_fail_lines(fm_a)
                _emit_fail_lines(fm_b)
                failed = 1
        else:
            fm_result, _ = validate_frontmatter(target, op)
            if _grep_q(fm_result, "PASS"):
                print_check(2, "Frontmatter valid", "PASS")
            else:
                print_check(2, "Frontmatter valid", "FAIL")
                _emit_fail_lines(fm_result)
                failed = 1
    else:
        print_check(2, "Frontmatter valid", "SKIP (target missing)")

    # --- Check 3: Provenance resolves ---
    if failed == 0:
        if op == "MERGE":
            prov_a, _ = check_provenance(path_a)
            prov_b, _ = check_provenance(path_b)
            if _grep_q(prov_a, "PASS") and _grep_q(prov_b, "PASS"):
                print_check(3, "Provenance resolves", "PASS")
            else:
                print_check(3, "Provenance resolves", "FAIL")
                _emit_fail_lines(prov_a)
                _emit_fail_lines(prov_b)
                failed = 1
        else:
            prov_result, _ = check_provenance(target)
            if _grep_q(prov_result, "PASS"):
                print_check(3, "Provenance resolves", "\n".join(prov_result))
            else:
                print_check(3, "Provenance resolves", "FAIL")
                _emit_fail_lines(prov_result)
                failed = 1
    else:
        print_check(3, "Provenance resolves", "SKIP (prior check failed)")

    # --- Check 4: Privacy respected ---
    if failed == 0:
        if op == "MERGE":
            priv_a, _ = check_privacy(path_a, op)
            priv_b, _ = check_privacy(path_b, op)
            if _grep_q(priv_a, "PASS") and _grep_q(priv_b, "PASS"):
                # For MERGE, warn if either page is local_only
                if _grep_contains(priv_a, "local_only") or _grep_contains(priv_b, "local_only"):
                    print_check(4, "Privacy respected", "PASS (WARN: MERGE includes local_only page -- merged result MUST be local_only)")
                else:
                    print_check(4, "Privacy respected", "PASS")
            else:
                print_check(4, "Privacy respected", "FAIL")
                _emit_fail_lines(priv_a)
                _emit_fail_lines(priv_b)
                failed = 1
        else:
            priv_result, _ = check_privacy(target, op)
            if _grep_q(priv_result, "PASS"):
                print_check(4, "Privacy respected", "\n".join(priv_result))
            else:
                print_check(4, "Privacy respected", "FAIL")
                _emit_fail_lines(priv_result)
                failed = 1
    else:
        print_check(4, "Privacy respected", "SKIP (prior check failed)")

    # --- Check 5: MERGE distinct pages ---
    if op == "MERGE":
        if failed == 0:
            ro, rrc = _capture(["realpath", path_a], stderr=subprocess.DEVNULL)
            real_a = _cs(ro) if rrc == 0 else path_a
            ro, rrc = _capture(["realpath", path_b], stderr=subprocess.DEVNULL)
            real_b = _cs(ro) if rrc == 0 else path_b
            if real_a == real_b:
                print_check(5, "MERGE distinct pages", "FAIL")
                _err("  FAIL: MERGE requires two distinct pages, got the same page twice\n")
                failed = 1
            else:
                print_check(5, "MERGE distinct pages", "PASS")
        else:
            print_check(5, "MERGE distinct pages", "SKIP (prior check failed)")
    else:
        print_check(5, "MERGE distinct pages", "SKIP (not MERGE)")

    # -----------------------------------------------------------------------
    # Summary
    # -----------------------------------------------------------------------

    _out("\n")
    if failed == 0:
        _out("=== RESULT: PASS ===\n")
        return 0
    else:
        _out("=== RESULT: FAIL ===\n")
        return 1


if __name__ == "__main__":          # enables `python3 -m compendium.validate_op`
    sys.exit(main(sys.argv[1:]))
