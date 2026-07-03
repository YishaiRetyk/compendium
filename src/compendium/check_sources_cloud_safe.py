# src/compendium/check_sources_cloud_safe.py -- FAIL-CLOSED raw-source cloud-safe guard
# (PRIV-03, cycle-2 HIGH).
# Phase 25 MIG-03 byte-parity port of bin/check-sources-cloud-safe.sh: main() replicates
# the bash arg loop exactly (same error strings/streams/exit codes, usage text verbatim),
# exports the same CSG_ROOT env key, then run() executes the bash python3-heredoc body
# verbatim. Do NOT "improve" observable behavior -- the parity oracle diffs
# stdout/stderr/exit against the frozen bash implementation.
#
# PURPOSE: Asserts that EVERY raw source under sources/ is cloud-safe:
#   (i)  No raw source carries the local_only privacy marker in frontmatter.
#   (ii) No sources/local-only/ directory exists.
#
# FAIL-CLOSED: exits NON-zero if either assertion is violated. A future adopter
# who adds a sensitive raw source triggers CI failure and is forced onto the
# deferred sources-local/ structural tier (documented in docs/reference/privacy-model.md).
#
# STRUCTURAL RULE (Phase 15 §13): raw sources/ is cloud-safe-only. A source that
# must be local lives as its SOURCE-SUMMARY page under wiki-local/sources/. The
# FAITH-04 resolver keys off the summary page tier, never the raw sources/ path.
# This guard proves the "raw sources/ cloud-safe-only" invariant is structurally
# maintained.
#
# PARSING: Uses read_fm_body() (NOT grep) to parse frontmatter, avoiding
# false-positives from prose 'privacy:' lines in source bodies. The bash heredoc
# imported it from bin/lib/brownfield_yaml.py via a CSG_LIB_DIR fallback chain;
# the port imports the frozen byte-identical lift compendium.common.yaml_rt.
#
# Exit codes:
#   0  clean -- all raw sources are cloud-safe
#   1  script failure OR violation found
import os
import pathlib
import sys

try:
    from compendium.common.yaml_rt import read_fm_body
except ImportError:
    # Unreachable in practice (yaml_rt ships in the same package); kept for
    # fidelity with the bash heredoc's import-failure branch.
    print("ERROR: bin/lib/brownfield_yaml.py not found. Ensure LIB_DIR is set or run from repo root.", file=sys.stderr)
    sys.exit(1)

# Usage text extracted VERBATIM from the bin/check-sources-cloud-safe.sh usage() heredoc.
USAGE = """Usage: bin/check-sources-cloud-safe.sh [OPTIONS]

FAIL-CLOSED raw-source cloud-safe guard (PRIV-03).
Asserts every raw source under sources/ is cloud-safe:
  (i) No raw source carries 'privacy: local_only' frontmatter
  (ii) No sources/local-only/ directory exists

This is a structural invariant guard wired into CI (privacy-leak job).

Options:
  --root DIR    Repository root (default: PWD)
  --help, -h    Show this help

Exit codes:
  0  all raw sources cloud-safe
  1  violation found OR script failure
"""


def run():
    """Execute the heredoc body (ported verbatim from the bash python3 heredoc).

    sys.exit(N) propagates out of main() naturally -- this matches the bash
    `set +e` / `PYRC=$?` / `exit $PYRC` re-raise of the heredoc's exit code.
    """
    ROOT = os.path.abspath(os.environ['CSG_ROOT'])

    sources_dir = pathlib.Path(ROOT) / 'sources'
    if not sources_dir.is_dir():
        # No sources/ directory -> trivially satisfied (clean vault)
        print("OK: no sources/ directory; raw-source cloud-safe invariant vacuously holds")
        sys.exit(0)

    violations = []

    # (i) Check for sources/local-only/ directory
    local_only_dir = sources_dir / 'local-only'
    if local_only_dir.is_dir():
        violations.append(
            f"FAIL: sources/local-only/ directory exists -- raw sources must be cloud-safe-only. "
            f"Move local raw sources to wiki-local/sources/ as source-summary pages "
            f"(see docs/reference/privacy-model.md for the sources-local/ forward reference)."
        )

    # (ii) Check each raw source for 'privacy: local_only' frontmatter
    for md_path in sorted(sources_dir.rglob('*.md')):
        try:
            fm, body, raw = read_fm_body(str(md_path))
        except Exception as e:
            # Parse error -- log as warning but don't fail (the file may be malformed)
            print(f"WARN: could not parse frontmatter in {md_path.relative_to(ROOT)}: {e}", file=sys.stderr)
            continue
        if fm is None:
            continue
        priv = fm.get('privacy')
        if priv == 'local_only':
            rel = md_path.relative_to(ROOT)
            violations.append(
                f"FAIL: {rel}: raw source carries 'privacy: local_only' frontmatter. "
                f"Raw sources/ must be cloud-safe-only. "
                f"Move to wiki-local/sources/ as a source-summary page "
                f"(see docs/reference/privacy-model.md)."
            )

    if violations:
        for v in violations:
            print(v, file=sys.stderr)
        print(
            f"\nFAIL-CLOSED: {len(violations)} raw-source cloud-safe violation(s) found. "
            f"Fix by removing 'privacy: local_only' frontmatter from raw sources/ "
            f"and using wiki-local/sources/ for local source-summary pages instead.",
            file=sys.stderr
        )
        sys.exit(1)

    print(f"OK: all raw sources under sources/ are cloud-safe ({sum(1 for _ in sources_dir.rglob('*.md'))} files checked)")
    sys.exit(0)


def main(argv=None):
    # Replicates the bin/check-sources-cloud-safe.sh bash arg loop EXACTLY (same
    # error strings to the same streams, same exit codes).
    if argv is None:
        argv = sys.argv[1:]
    args = list(argv)

    root = os.getcwd()

    i = 0
    while i < len(args):
        a = args[i]
        if a in ("--help", "-h"):
            sys.stdout.write(USAGE)
            return 0
        elif a == "--root":
            if len(args) - i < 2:
                print("ERROR: --root requires a value", file=sys.stderr)
                return 1
            root = args[i + 1]
            i += 2
        elif a.startswith("-"):
            print(f"ERROR: unknown option: {a}", file=sys.stderr)
            sys.stderr.write(USAGE)
            return 1
        else:
            print(f"ERROR: unexpected argument: {a}", file=sys.stderr)
            return 1

    os.environ["CSG_ROOT"] = root

    run()
    return 0


if __name__ == "__main__":          # enables `python3 -m compendium.check_sources_cloud_safe`
    sys.exit(main(sys.argv[1:]))
