# src/compendium/sync_claude.py -- TMPL-10, D-03: AGENTS.md -> CLAUDE.md byte copy.
# Byte-parity port of bin/sync-claude.sh (Phase 25 MIG-04, plan 25-03).
# Idempotent. Zero deps. Usage text keeps the bin/sync-claude.sh name --
# the shim IS the stable interface.
import os
import shutil
import sys

SRC = "AGENTS.md"
DST = "CLAUDE.md"


def _out(msg):
    sys.stdout.write(msg + "\n")
    sys.stdout.flush()


def _err(msg):
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()


def _read_bytes(path):
    with open(path, "rb") as f:
        return f.read()


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    check_only = False

    for a in args:
        if a in ("--help", "-h"):
            _out("Usage: bin/sync-claude.sh [--check]")
            return 0
        if a == "--check":
            check_only = True
        else:
            _err("ERROR: unknown arg: " + a)
            return 1

    if not os.path.isfile(SRC):
        _err("ERROR: " + SRC + " missing")
        return 1

    if check_only:
        if not os.path.isfile(DST):
            _err("DRIFT: " + DST + " missing")
            return 2
        try:
            same = _read_bytes(SRC) == _read_bytes(DST)
        except OSError:
            same = False  # cmp trouble (unreadable operand) reads as drift, like `! cmp -s`
        if not same:
            _err("DRIFT: " + DST + " differs from " + SRC
                 + ". Run: bash bin/sync-claude.sh && git add " + DST)
            return 2
        _out("OK: " + SRC + " == " + DST)
        return 0

    # cp semantics: copy INTO an existing directory target; new files take the
    # source's mode bits masked by umask; existing targets keep their own mode.
    if os.path.isdir(DST):
        shutil.copyfile(SRC, os.path.join(DST, os.path.basename(SRC)))
    else:
        dst_existed = os.path.exists(DST)
        shutil.copyfile(SRC, DST)
        if not dst_existed:
            um = os.umask(0)
            os.umask(um)
            os.chmod(DST, os.stat(SRC).st_mode & 0o777 & ~um)

    try:
        same = os.path.isfile(DST) and _read_bytes(SRC) == _read_bytes(DST)
    except OSError:
        same = False
    if not same:
        _err("ERROR: post-copy byte-mismatch (should be impossible)")
        return 1
    _out("Synced " + SRC + " -> " + DST)
    return 0


if __name__ == "__main__":          # enables `python3 -m compendium.sync_claude`
    sys.exit(main(sys.argv[1:]))
