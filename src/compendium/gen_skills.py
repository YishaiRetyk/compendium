# src/compendium/gen_skills.py -- Phase 18 / SKILL-01+SKILL-02: deterministic skill
# generator + --check drift gate. Byte-parity port of bin/gen-skills.sh (Phase 25
# MIG-04, plan 25-03).
#
# Artifact SOT: this module (body template + per-op description data, D-01/D-02).
# Behavioral SOT: schema/workflows/{op}.md (each SKILL.md body points there).
# DO NOT hand-edit .claude/skills/{op}/SKILL.md files -- they are derived copies.
#   Hand-edits are caught by --check and rejected.
#
# D-01: all inputs inline in this file (description strings + body template).
# D-02: fixed op quartet (ingest query lint reflect); adding/removing ops = code edit.
# D-05: exit 0=OK, 1=drift. Note: sync-claude exits 2 on drift; gen-skills
#   uses exit 1 per SPEC requirement 2. Behavior is otherwise identical.
# D-06: --check performs BOTH regenerate-diff AND independent structural assertions.
# D-07: structural assertions are NOT redundant with the regenerate-diff check.
#   A fattened template still passes diff (committed == fattened-template); the
#   independent assertions (<=3 body lines, dir-purity, no first-person pronoun, no
#   disable-model-invocation:true) are the real guard that the template stays thin.
#   Never remove these assertions as "redundant with diff".
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

OPS = ("ingest", "query", "lint", "reflect")

# what+when, not how (REVIEWS.md MEDIUM: keep descriptions to what/when; do not
# encode the classify-extract-merge-lint pipeline -- that is behavior owned by the
# workflow file, and putting it in always-loaded L1 metadata duplicates behavior).
# "lint" avoids the word "audit" (REVIEWS.md MEDIUM: Audit is a DISTINCT workflow
# in this project -- bin/audit-claims.sh / schema/workflows/audit.md -- so naming
# it here would mislead model invocation toward the wrong operation).
DESC = {
    "ingest": "Processes a new source document into wiki pages. Invoke when asked"
              " to ingest, add, or process a new source into the wiki.",
    "query": "Answers a question using the wiki and compiles any novel synthesis"
             " back into wiki pages. Invoke when asked to look up, explain, or"
             " synthesize wiki content.",
    "lint": "Detects and reports wiki quality issues including orphan pages, stale"
            " claims, broken provenance markers, and missing cross-references."
            " Invoke when asked to lint or health-check the wiki.",
    "reflect": "Performs structural reasoning over wiki history and authors"
               " decision records for significant schema or organizational changes."
               " Invoke when asked to reflect, review, or record a decision.",
}


def _out(msg):
    sys.stdout.write(msg + "\n")
    sys.stdout.flush()


def _err(msg):
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()


def body_for(op):
    return (
        "---\n"
        "name: " + op + "\n"
        "description: " + DESC[op] + "\n"
        "---\n"
        "\n"
        "You have been invoked to " + op + ". Read `schema/workflows/" + op
        + ".md` and follow it verbatim.\n"
    )


def _usage():
    _out("Usage: bin/gen-skills.sh [--check]")
    _out("")
    _out("Without --check: write all four SKILL.md files (idempotent).")
    _out("With    --check: regenerate to temp dir, diff vs committed, run structural")
    _out("                 assertions, exit 0=OK / 1=drift.")


def _awk_body_line_count(content):
    """Replicate: awk '/^---/{n++; if(n==2){found=1; next}} found{print}' | wc -l
    (lines after the SECOND ----prefixed line; a later --- line still prints)."""
    lines = content.split(b"\n")
    if lines and lines[-1] == b"":
        lines.pop()  # a trailing newline yields no extra awk record
    n = 0
    found = False
    count = 0
    for ln in lines:
        if ln.startswith(b"---"):
            n += 1
            if n == 2:
                found = True
                continue
        if found:
            count += 1
    return count


def _check(tmpdir):
    drift = 0

    # Step 1: regenerate-diff (D-06 first gate)
    for op in OPS:
        body = body_for(op).encode()
        with open(os.path.join(tmpdir, op + "-SKILL.md"), "wb") as f:
            f.write(body)
        committed = ".claude/skills/" + op + "/SKILL.md"
        if not os.path.isfile(committed):
            _err("DRIFT: " + committed + " missing")
            drift = 1
            continue
        with open(committed, "rb") as f:
            if f.read() != body:
                _err("DRIFT: " + committed + " differs from template."
                     " Run: bash bin/gen-skills.sh && git add .claude/skills/")
                drift = 1

    # Step 2: independent structural assertions (D-06/D-07)
    # These are NOT redundant with the regenerate-diff above. A fattened template
    # (with procedural content in the body) still passes diff (committed == fattened-
    # template). The assertions below are the real guard that the TEMPLATE itself
    # stays thin. Never remove these as "redundant with diff" (D-07).
    for op in OPS:
        d = ".claude/skills/" + op
        skill = d + "/SKILL.md"
        if not os.path.isfile(skill):
            continue  # already reported as missing above
        with open(skill, "rb") as f:
            content = f.read()

        # Assert body <=3 lines (post-frontmatter lines only -- excludes the --- delimiters)
        body_lines = _awk_body_line_count(content)
        if body_lines > 3:
            _err("ASSERT FAIL: " + skill + " body has " + str(body_lines)
                 + " lines (max 3)")
            drift = 1

        # Assert the pointer target exists (REVIEWS.md MEDIUM: --check never verified that
        # schema/workflows/{op}.md exists -- a dead pointer would pass diff + line-count).
        if not os.path.isfile("schema/workflows/" + op + ".md"):
            _err("ASSERT FAIL: pointer target schema/workflows/" + op
                 + ".md does not exist (dead " + skill + " pointer)")
            drift = 1

        # Assert the directory contains ONLY SKILL.md (SPEC: each skill dir contains only
        # SKILL.md). Reject ANY top-level entry that is not SKILL.md -- a non-md file,
        # or a stray file the pre-commit hook might auto-stage, must also fail the gate.
        # L2 loads ALL top-level files in a skill dir, so any stray file inflates context.
        extra = len([e for e in os.listdir(d) if e != "SKILL.md"])
        if extra > 0:
            _err("ASSERT FAIL: " + d + " contains " + str(extra)
                 + " entr(y/ies) other than SKILL.md (dir-purity)")
            drift = 1

        # Assert no first-person pronoun in description line (grep -E \b word
        # boundaries; case-sensitive on the explicit token list).
        file_lines = content.split(b"\n")
        if file_lines and file_lines[-1] == b"":
            file_lines.pop()
        desc_val = b"\n".join(
            ln for ln in file_lines if ln.startswith(b"description:"))
        if re.search(rb"\b(I|we|We|I'll|We'll|I've|We've|I'm|we're|We're)\b",
                     desc_val):
            _err("ASSERT FAIL: " + skill
                 + " description contains first-person pronoun")
            drift = 1

        # Assert the description is a YAML-safe non-empty unquoted scalar. The value
        # after `description: ` must be non-empty and must not contain a colon-space
        # (`: `) or a ` #` that an unquoted YAML scalar would mis-parse.
        desc_payload = b"\n".join(
            ln[len(b"description: "):] if ln.startswith(b"description: ") else ln
            for ln in desc_val.split(b"\n"))
        if desc_payload.replace(b" ", b"") == b"":
            _err("ASSERT FAIL: " + skill + " description is empty")
            drift = 1
        elif re.search(rb": | #", desc_payload):
            _err("ASSERT FAIL: " + skill + " description has ': ' or ' #' --"
                 " breaks unquoted YAML; rephrase or quote in get_desc()")
            drift = 1

        # Assert disable-model-invocation:true is NOT present (model invocation is allowed, D-05)
        if re.search(rb"disable-model-invocation: *true", content):
            _err("ASSERT FAIL: " + skill + " has disable-model-invocation:true"
                 " (model invocation is allowed)")
            drift = 1

    if drift == 0:
        _out("OK: .claude/skills/ matches template + all structural assertions pass")
        return 0
    return 1


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)

    # Anchor every relative path to the repo root, not the caller's cwd (REVIEW WR-01).
    # All paths below (.claude/skills/{op}, schema/workflows/{op}.md) are repo-relative;
    # the module lives at src/compendium/gen_skills.py, so the repo root is three
    # parents up. Fail loudly if the resolved root does not look like the repo
    # (a workflow file the generator depends on).
    repo_root = Path(__file__).resolve().parent.parent.parent
    # REVIEW FIX (finding D2, 2026-07-03): restore the caller's cwd on exit. bash `cd` died
    # with the process; this in-process os.chdir would otherwise leave a pytest interpreter
    # (which imports and drives main()) rebased onto the live repo, so later cwd-relative
    # tools scan/mutate the real repo instead of a fixture. Statement order below is byte-
    # unchanged (--help/guard still run post-chdir exactly as the bash body did).
    _prev_cwd = os.getcwd()
    os.chdir(repo_root)
    try:
        if not os.path.isfile("schema/workflows/ingest.md"):
            _err("ERROR: cannot resolve repo root from " + str(repo_root)
                 + " (schema/workflows/ingest.md missing)")
            return 1

        check_only = False
        for a in args:
            if a in ("--help", "-h"):
                _usage()
                return 0
            if a == "--check":
                check_only = True
            else:
                _err("ERROR: unknown arg: " + a)
                return 1

        if check_only:
            tmpdir = tempfile.mkdtemp()
            try:
                return _check(tmpdir)
            finally:
                shutil.rmtree(tmpdir, ignore_errors=True)

        # Generate mode: write all four SKILL.md files (idempotent -- re-run overwrites identically)
        for op in OPS:
            d = ".claude/skills/" + op
            os.makedirs(d, exist_ok=True)
            with open(d + "/SKILL.md", "wb") as f:
                f.write(body_for(op).encode())
            _out("Generated " + d + "/SKILL.md")
        _out("Done. Run 'git add .claude/skills/' to stage.")
        return 0
    finally:
        try:
            os.chdir(_prev_cwd)
        except OSError:
            pass


if __name__ == "__main__":          # enables `python3 -m compendium.gen_skills`
    sys.exit(main(sys.argv[1:]))
