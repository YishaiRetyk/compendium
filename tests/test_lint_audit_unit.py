"""MIG-02 lint/audit unit layer (Phase 25, TEST-06).

Direct pytest coverage for the long-pole cluster port (src/compendium/lint.py,
src/compendium/audit_claims.py) on top of the frozen compendium.common.page.
The byte-parity oracle covers the CLI surface; this file covers the ported
semantics directly:

  - common.page.mask_markdown edge cases (the WR-02/WR-03 fence rules both
    tools depend on) -- exercised via common.page, the single canonical copy.
  - provenance resolution: PROV_RE group shapes, broken-ref detection,
    fence-masked markers never flagged.
  - decay/staleness math: DECAY_RATES x EPISTEMIC_MODIFIERS boundary, the
    checked_at -> ingested_at -> updated_at fallback chain, --fix insertion.
  - orphan detection: id-only resolution (aliases never save a page),
    fence-masked links never count, index.md counts as an inbound linker.
  - audit locator resolution: every #-locator family incl. the Phase-22
    fence-boundary rules for #sec/#ref/#path/#commit.
  - the verifier security contract: payload on STDIN ONLY, shell=False
    (shell metacharacters in the command must never reach a shell).
"""

import json
import textwrap
from datetime import date, timedelta

from compendium import audit_claims, lint
from compendium.common.page import PROV_RE, mask_markdown


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def write(path, *parts):
    """Write dedent-ed parts. Each part is dedented SEPARATELY so an indented
    triple-quoted body keeps its fences/headings at column 0 even when
    concatenated after column-0 frontmatter."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(textwrap.dedent(p) for p in parts), encoding="utf-8")


def page_fm(pid, ptype="concept", extra=""):
    fm = textwrap.dedent(f"""\
        ---
        id: {pid}
        title: "Title {pid}"
        type: {ptype}
        status: active
        summary: "Fixture {pid}."
        created_at: 2026-01-02
        updated_at: 2026-01-02
        sources: []
        epistemic_status: sourced
        tags: [alpha]
        domains: [dom-one]
        supersedes:
        superseded_by:
        aliases: []
        has_contradictions: false
        knowledge_domain: software
        """)
    if extra:
        # extra is dedented SEPARATELY (an interpolated multi-line block would
        # defeat the template's own dedent by owning column 0).
        fm += textwrap.dedent(extra).rstrip("\n") + "\n"
    return fm + "---\n"


def run_lint(tmp_path, monkeypatch, capsys, *args):
    """Run lint.main() with cwd=tmp_path; return (rc, findings-from-json-stdout)."""
    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("WIKI_ROOT", raising=False)
    monkeypatch.delenv("LINT_REPO_ROOT", raising=False)
    rc = lint.main(list(args))
    out = capsys.readouterr().out
    findings = json.loads(out) if out.strip().startswith("[") else None
    return rc, findings


# ---------------------------------------------------------------------------
# mask_markdown edges (via common.page -- the one canonical copy)
# ---------------------------------------------------------------------------

def test_mask_markdown_is_length_preserving():
    text = "---\nid: x\n---\n\nbody `code` text\n```\nfenced\n```\ntail <!-- c -->\n"
    masked = mask_markdown(text)
    assert len(masked) == len(text)
    assert masked.count("\n") == text.count("\n")


def test_mask_markdown_blanks_frontmatter_fences_comments_inline():
    text = "---\nid: x\n---\nkeep [[a|A]] `gone` <!-- gone --> end\n```\n[[fenced|F]]\n```\n"
    masked = mask_markdown(text)
    assert "id: x" not in masked
    assert "[[a|A]]" in masked
    assert "gone" not in masked
    assert "[[fenced|F]]" not in masked


def test_mask_fences_info_string_closer_does_not_close():
    # WR-03: a would-be closer carrying an info string does NOT close the block.
    text = "```python\ncode\n```python\nstill fenced\n```\nafter\n"
    masked = mask_markdown(text)
    assert "still fenced" not in masked
    assert "after" in masked


def test_mask_fences_unclosed_extends_to_eof():
    # WR-02: an unclosed fence masks everything to end-of-file.
    text = "before\n```\nnever closed\ntail\n"
    masked = mask_markdown(text)
    assert "before" in masked
    assert "never closed" not in masked
    assert "tail" not in masked


def test_mask_fences_closer_must_match_char_and_length():
    # Shorter run / other char never closes; a longer same-char run does.
    text = "~~~~\nfenced\n~~~\n```\nstill\n~~~~~\nout\n"
    masked = mask_markdown(text)
    assert "fenced" not in masked
    assert "still" not in masked
    assert "out" in masked


def test_mask_fences_column_zero_anchoring():
    # An indented run is NOT an opener (deliberate column-0 anchoring).
    text = "  ```\nnot fenced\n"
    masked = mask_markdown(text)
    assert "not fenced" in masked


def test_mask_markdown_preserves_offsets():
    text = "`x`  [[target|Display]]\n"
    masked = mask_markdown(text)
    assert masked.index("[[target|Display]]") == text.index("[[target|Display]]")


# ---------------------------------------------------------------------------
# provenance resolution
# ---------------------------------------------------------------------------

def test_prov_re_group_shapes():
    m = PROV_RE.search("claim [prov:src-a#sec:intro|direct|2026-01-02]")
    assert m.groups() == ("src-a", "sec:intro", "direct", "2026-01-02")
    m = PROV_RE.search("claim [prov:src-a#p8]")
    assert m.groups() == ("src-a", "p8", None, None)
    # table-cell \|...\| escapes inject a trailing backslash into groups 2/3
    m = PROV_RE.search(r"| [prov:src-a#sec:intro\|direct\|2026-01-02] |")
    assert m.group(2).endswith("\\")


def test_prov_re_multiple_markers_per_line():
    line = "a [prov:s1#p1|direct] b [prov:s2#p2|inferred] c"
    got = [(m.group(1), m.group(3)) for m in PROV_RE.finditer(line)]
    assert got == [("s1", "direct"), ("s2", "inferred")]


def test_lint_flags_broken_prov_ref_but_not_fenced_examples(tmp_path, monkeypatch, capsys):
    write(tmp_path / "wiki-cloud/concepts/c.md", page_fm("c"), """
        Real broken ref [prov:src-ghost#p1|direct].

        ```
        Documentation example [prov:src-doc-only#p1|direct] stays unflagged.
        ```
        """)
    rc, findings = run_lint(tmp_path, monkeypatch, capsys,
                            "--category", "provenance", "--dry-run", "--format", "json")
    assert rc == 0
    msgs = [f["message"] for f in findings if f["category"] == "provenance"]
    assert any("src-ghost" in m for m in msgs)
    assert not any("src-doc-only" in m for m in msgs)


def test_lint_epistemic_laundering_on_research_report(tmp_path, monkeypatch, capsys):
    write(tmp_path / "sources/2026/2026-01/r.md", "# Raw\n")
    write(tmp_path / "wiki-cloud/sources/src-rep.md",
          page_fm("src-rep", "source", extra=textwrap.dedent("""\
              path: sources/2026/2026-01/r.md
              content_hash: "sha256:x"
              ingested_at: 2026-01-02
              source_type: research-report
              compilation_status: compiled""")) + "\nBody.\n")
    write(tmp_path / "wiki-cloud/concepts/c.md", page_fm("c"), """
        Laundered [prov:src-rep#r1|direct].
        Clean [prov:src-rep#r2|derived].
        """)
    rc, findings = run_lint(tmp_path, monkeypatch, capsys,
                            "--category", "provenance", "--dry-run", "--format", "json")
    launder = [f for f in findings if "Epistemic laundering" in f["message"]]
    assert len(launder) == 1
    assert "support_type=direct" in launder[0]["message"]


# ---------------------------------------------------------------------------
# decay / staleness math
# ---------------------------------------------------------------------------

def test_decay_tables_match_spec():
    assert lint.DECAY_RATES["software"] == timedelta(days=180)
    assert lint.DECAY_RATES["technology"] == timedelta(days=180)
    assert lint.DECAY_RATES["science"] == timedelta(days=730)
    assert lint.DECAY_RATES["biography"] == timedelta(days=1825)
    assert lint.DECAY_RATES["personal-goals"] == timedelta(days=90)
    assert lint.DEFAULT_DECAY == timedelta(days=365)
    assert lint.EPISTEMIC_MODIFIERS == {
        "tentative": 0.5, "inferred": 0.75, "sourced": 1.0, "mixed": 0.85}


def _stale_vault(tmp_path, checked_at, epistemic=""):
    write(tmp_path / "sources/2026/2026-01/r.md", "# Raw\n")
    write(tmp_path / "wiki-cloud/sources/src-a.md",
          page_fm("src-a", "source", extra=textwrap.dedent("""\
              path: sources/2026/2026-01/r.md
              content_hash: "sha256:x"
              ingested_at: 2026-01-02
              source_type: paper
              compilation_status: compiled""")) + "\nBody.\n")
    write(tmp_path / "wiki-cloud/concepts/c.md", page_fm("c") + f"""
        Claim [prov:src-a#p1|direct|{checked_at}]{epistemic} here.
        """)


def test_stale_boundary_age_equal_threshold_is_fresh(tmp_path, monkeypatch, capsys):
    # software domain (180d) with tentative modifier (0.5) -> 90d effective.
    # age == effective decay is NOT stale (strict > comparison).
    checked = date.today() - timedelta(days=90)
    _stale_vault(tmp_path, checked.isoformat(), " [epistemic:: tentative]")
    rc, findings = run_lint(tmp_path, monkeypatch, capsys,
                            "--category", "stale", "--dry-run", "--format", "json")
    assert [f for f in findings if f["category"] == "stale"] == []


def test_stale_boundary_one_day_past_flags(tmp_path, monkeypatch, capsys):
    checked = date.today() - timedelta(days=91)
    _stale_vault(tmp_path, checked.isoformat(), " [epistemic:: tentative]")
    rc, findings = run_lint(tmp_path, monkeypatch, capsys,
                            "--category", "stale", "--dry-run", "--format", "json")
    stale = [f for f in findings if f["category"] == "stale"]
    assert len(stale) == 1
    assert "exceeds 90d decay for domain software" in stale[0]["message"]


def test_stale_fallback_chain_uses_ingested_at(tmp_path, monkeypatch, capsys):
    # No checked_at on the marker: source ingested_at (ancient) drives the age.
    write(tmp_path / "sources/2026/2026-01/r.md", "# Raw\n")
    write(tmp_path / "wiki-cloud/sources/src-a.md",
          page_fm("src-a", "source", extra=textwrap.dedent("""\
              path: sources/2026/2026-01/r.md
              content_hash: "sha256:x"
              ingested_at: 2020-01-02
              source_type: paper
              compilation_status: compiled""")) + "\nBody.\n")
    write(tmp_path / "wiki-cloud/concepts/c.md", page_fm("c"), """
        Claim [prov:src-a#p1] no dates on the marker.
        """)
    rc, findings = run_lint(tmp_path, monkeypatch, capsys,
                            "--category", "stale", "--dry-run", "--format", "json")
    assert any(f["category"] == "stale" and "2020-01-02" in f["message"] for f in findings)


def test_stale_fallback_chain_uses_page_updated_at(tmp_path, monkeypatch, capsys):
    # Unknown source id -> falls through to the page's updated_at (2026-01-02
    # in page_fm; too fresh only if within decay -- use an old page).
    old = (date.today() - timedelta(days=400)).isoformat()
    write(tmp_path / "wiki-cloud/concepts/c.md",
          page_fm("c").replace("updated_at: 2026-01-02", f"updated_at: {old}"), """
        Claim [prov:src-unknown#p1] here.
        """)
    rc, findings = run_lint(tmp_path, monkeypatch, capsys,
                            "--category", "stale", "--dry-run", "--format", "json")
    assert any(f["category"] == "stale" and old in f["message"] for f in findings)


def test_stale_fix_inserts_marker_after_last_prov(tmp_path, monkeypatch, capsys):
    checked = (date.today() - timedelta(days=400)).isoformat()
    _stale_vault(tmp_path, checked)
    rc, findings = run_lint(tmp_path, monkeypatch, capsys, "--category", "stale",
                            "--fix", "--format", "json")
    fixed = (tmp_path / "wiki-cloud/concepts/c.md").read_text(encoding="utf-8")
    assert f"[prov:src-a#p1|direct|{checked}] [epistemic:: stale] here." in fixed
    assert any(f["category"] == "autofix" for f in findings)


def test_stale_fix_replaces_existing_epistemic_marker(tmp_path, monkeypatch, capsys):
    checked = (date.today() - timedelta(days=400)).isoformat()
    _stale_vault(tmp_path, checked, " [epistemic:: sourced]")
    run_lint(tmp_path, monkeypatch, capsys, "--category", "stale", "--fix", "--format", "json")
    fixed = (tmp_path / "wiki-cloud/concepts/c.md").read_text(encoding="utf-8")
    assert "[epistemic:: stale]" in fixed
    assert "[epistemic:: sourced]" not in fixed


# ---------------------------------------------------------------------------
# orphan detection
# ---------------------------------------------------------------------------

def _orphan_vault(tmp_path):
    write(tmp_path / "wiki-cloud/index.md", "# Index\n\n- [[indexed|Title indexed]]\n")
    write(tmp_path / "wiki-cloud/concepts/indexed.md", page_fm("indexed"), """
        Links [[linked|Title linked]].

        ```
        [[fence-only|Fenced]] link must not count.
        ```
        Alias link [[Nickname]] must not count either.
        """)
    write(tmp_path / "wiki-cloud/concepts/linked.md", page_fm("linked") + "\nBody.\n")
    write(tmp_path / "wiki-cloud/concepts/fence-only.md", page_fm("fence-only") + "\nBody.\n")
    write(tmp_path / "wiki-cloud/concepts/aliased.md",
          page_fm("aliased").replace("aliases: []", 'aliases: ["Nickname"]') + "\nBody.\n")


def test_orphan_detection_id_only_resolution(tmp_path, monkeypatch, capsys):
    _orphan_vault(tmp_path)
    rc, findings = run_lint(tmp_path, monkeypatch, capsys,
                            "--category", "orphan", "--dry-run", "--format", "json")
    orphans = {f["path"] for f in findings if f["category"] == "orphan"}
    # indexed: saved by index.md; linked: saved by piped body link.
    assert "wiki-cloud/concepts/indexed.md" not in orphans
    assert "wiki-cloud/concepts/linked.md" not in orphans
    # fence-only: its only inbound link sits in a code fence -> orphan.
    assert "wiki-cloud/concepts/fence-only.md" in orphans
    # aliased: an [[Alias]] link never saves a page (id-only resolution).
    assert "wiki-cloud/concepts/aliased.md" in orphans


def test_orphan_self_link_does_not_count(tmp_path, monkeypatch, capsys):
    write(tmp_path / "wiki-cloud/concepts/selfy.md", page_fm("selfy"), """
        Self link [[selfy|Title selfy]] only.
        """)
    rc, findings = run_lint(tmp_path, monkeypatch, capsys,
                            "--category", "orphan", "--dry-run", "--format", "json")
    assert any(f["path"] == "wiki-cloud/concepts/selfy.md" for f in findings)


# ---------------------------------------------------------------------------
# audit locator resolution (incl. fence boundaries)
# ---------------------------------------------------------------------------

SEC_DOC = textwrap.dedent("""\
    # Top

    ## Introduction

    Intro body.

    ```md
    ## Quoted Heading

    fenced text
    ```

    ## Deep Dive Analysis Section

    Deep body.

    ### Sub Point

    Sub body.

    ## Next

    Next body.
    """)


def test_resolve_sec_exact_and_slice_end():
    got = audit_claims._resolve_sec(SEC_DOC, "introduction")
    assert got.startswith("## Introduction")
    assert "Intro body." in got
    # quoted fenced heading is INSIDE the slice (does not terminate it)
    assert "## Quoted Heading" in got
    assert "Deep body." not in got


def test_resolve_sec_fenced_heading_never_matches():
    assert audit_claims._resolve_sec(SEC_DOC, "quoted-heading") is None


def test_resolve_sec_token_subsequence_fallback():
    got = audit_claims._resolve_sec(SEC_DOC, "deep-dive")
    assert got.startswith("## Deep Dive Analysis Section")
    # slice runs to the next same-or-higher level heading (## Next), so the
    # deeper ### Sub Point stays inside.
    assert "### Sub Point" in got
    assert "Next body." not in got


def test_resolve_sec_missing():
    assert audit_claims._resolve_sec(SEC_DOC, "absent-heading") is None


def test_resolve_para_skips_headings_and_counts_fence_as_one():
    doc = "---\nid: raw\n---\n\n## H\n\nPara one.\n\n```\nfence line\n\nstill fence\n```\n\nPara three.\n"
    assert audit_claims._resolve_para(doc, 1) == "Para one."
    assert audit_claims._resolve_para(doc, 2).startswith("```")
    assert audit_claims._resolve_para(doc, 3) == "Para three."
    assert audit_claims._resolve_para(doc, 4) is None
    assert audit_claims._resolve_para(doc, 0) is None


def test_resolve_t_timestamp_window():
    doc = "[00:10] early\n[00:45] mid\nplain line\n[01:30] late\n"
    got = audit_claims._resolve_t(doc, "00:40", "01:00")
    assert got == "[00:45] mid"
    assert audit_claims._resolve_t("no timestamps here\n", "00:00", "01:00") is None


def test_resolve_page_markers():
    doc = "head\n<!-- page: 8 -->\neight\n<!-- page: 9 -->\nnine\n"
    got = audit_claims._resolve_page(doc, 8, 8)
    assert "eight" in got and "nine" not in got
    # missing upper marker -> EOF
    got = audit_claims._resolve_page(doc, 9, 12)
    assert "nine" in got
    # missing lower marker or no markers at all -> None (never the whole doc)
    assert audit_claims._resolve_page(doc, 3, 4) is None
    assert audit_claims._resolve_page("no markers\n", 1, 1) is None


REF_DOC = textwrap.dedent("""\
    # Report

    ```md
    ## References

    - quoted bullet inside fence
    ```

    ## References

    - First entry
      wrapped continuation
    - Second entry

    ## After
    """)


def test_resolve_ref_fence_aware_and_wrapped_bullets():
    # the fenced '## References' must not anchor; bullets join continuations
    assert audit_claims._resolve_ref(REF_DOC, 1) == "First entry wrapped continuation"
    assert audit_claims._resolve_ref(REF_DOC, 2) == "Second entry"
    assert audit_claims._resolve_ref(REF_DOC, 3) is None
    assert audit_claims._resolve_ref("no bib here\n", 1) is None


PATH_DOC = textwrap.dedent("""\
    # Snapshot

    ## Snapshot Metadata

    - Commit: 0123456789abcdef0123456789abcdef01234567

    ## Excerpts

    ### src/app.py:L10-L40

    ```python
    def main():
        pass
    ### quoted/entry.py:L1-L2
    ## quoted heading
    ```

    ### README.md

    ```md
    body
    ```

    ### src/app.py:L99

    ```python
    x = 1
    ```
    """)


def test_resolve_path_range_containment():
    got = audit_claims._resolve_path(PATH_DOC, "src/app.py:L12-L20")
    assert got.startswith("### src/app.py:L10-L40")
    # fenced quoted markdown stays inside the entry slice
    assert "### quoted/entry.py:L1-L2" in got
    assert "README.md" not in got
    # uncontained / inverted ranges never resolve
    assert audit_claims._resolve_path(PATH_DOC, "src/app.py:L50-L60") is None
    assert audit_claims._resolve_path(PATH_DOC, "src/app.py:L20-L12") is None


def test_resolve_path_whole_file_and_single_line():
    # whole-file entry matches PATH-ONLY requests, never range requests
    assert audit_claims._resolve_path(PATH_DOC, "README.md").startswith("### README.md")
    assert audit_claims._resolve_path(PATH_DOC, "README.md:L1-L2") is None
    # a single-line entry ':L<n>' is valid heading grammar
    assert audit_claims._resolve_path(PATH_DOC, "src/app.py:L99").startswith("### src/app.py:L99")
    # fenced quoted entries never register
    assert audit_claims._resolve_path(PATH_DOC, "quoted/entry.py:L1-L2") is None


def test_resolve_path_last_nonfenced_excerpts_wins():
    doc = "## Excerpts\n\n### old/file.md\n\nx\n\n## Excerpts\n\n### new/file.md\n\ny\n"
    assert audit_claims._resolve_path(doc, "old/file.md") is None
    assert audit_claims._resolve_path(doc, "new/file.md") is not None


def test_resolve_commit_prefix_match_only_snapshot_commit():
    got = audit_claims._resolve_commit(PATH_DOC, "0123456789ab")
    assert got.startswith("## Snapshot Metadata")
    # full 40-hex works; a non-matching sha or a <7-hex prefix never resolves
    assert audit_claims._resolve_commit(PATH_DOC, "0123456789abcdef0123456789abcdef01234567")
    assert audit_claims._resolve_commit(PATH_DOC, "ffffffffffff") is None
    assert audit_claims._resolve_commit(PATH_DOC, "01234") is None
    assert audit_claims._resolve_commit("no metadata\n", "0123456789ab") is None


def test_resolve_locator_dispatch():
    assert audit_claims.resolve_locator(SEC_DOC, "#img2") == (None, "skipped-nontext")
    # '#'-less form normalizes; table-cell backslash residue is stripped
    assert audit_claims.resolve_locator(SEC_DOC, "sec:introduction\\")[0].startswith("## Introduction")
    # #path: dispatches before #p (shared prefix)
    assert audit_claims.resolve_locator(PATH_DOC, "#path:README.md")[0] is not None
    # unknown / malformed locators -> (None, None)
    assert audit_claims.resolve_locator(SEC_DOC, "#zzz9") == (None, None)
    assert audit_claims.resolve_locator(SEC_DOC, "#paraX") == (None, None)
    assert audit_claims.resolve_locator(SEC_DOC, "#pX-Y") == (None, None)


def test_fence_mask_lines_flags_and_boundaries():
    text = "a\n```python\ncode\n```python\nstill\n```\nb\n~~~\nunclosed\n"
    lines, fenced = audit_claims._fence_mask_lines(text)
    assert lines == text.splitlines()
    # info-string "closer" does not close (WR-03); real closer line is fenced
    assert fenced == [False, True, True, True, True, True, False, True, True]


# ---------------------------------------------------------------------------
# verifier security contract (STDIN-only payload, shell=False)
# ---------------------------------------------------------------------------

def _recording_stub(tmp_path):
    stub = tmp_path / "stub-verifier.sh"
    stub.write_text(
        "#!/usr/bin/env bash\n"
        'printf \'%s\\n\' "$*" > argv.log\n'
        "cat > stdin.log\n"
        "printf '{\"verdict\":\"supports\",\"rationale\":\"ok\"}\\n'\n",
        encoding="utf-8")
    stub.chmod(0o755)
    return stub


def test_verifier_payload_is_stdin_only(tmp_path):
    _recording_stub(tmp_path)
    verdict, rationale = audit_claims.run_verifier(
        "./stub-verifier.sh --tag t1", "the claim text", "the passage text",
        "direct", str(tmp_path))
    assert (verdict, rationale) == ("supports", "ok")
    argv = (tmp_path / "argv.log").read_text(encoding="utf-8")
    stdin = json.loads((tmp_path / "stdin.log").read_text(encoding="utf-8"))
    # argv sees ONLY the command's own args -- never claim/passage text
    assert "--tag t1" in argv
    assert "claim text" not in argv and "passage text" not in argv
    # stdin carries the full payload
    assert stdin == {"claim": "the claim text", "passage": "the passage text",
                     "support_type": "direct"}


def test_verifier_shell_metacharacters_never_reach_a_shell(tmp_path):
    # shell=False + shlex.split: '; touch pwned' must NOT execute.
    verdict, rationale = audit_claims.run_verifier(
        "./no-such-verifier.sh; touch pwned", "c", "p", "direct", str(tmp_path))
    assert verdict == "insufficient"
    assert rationale.startswith("verifier could not be invoked:")
    assert not (tmp_path / "pwned").exists()


def test_verifier_source_pins_shell_false_and_stdin_input():
    import inspect
    src = inspect.getsource(audit_claims.run_verifier)
    assert "shell=False" in src
    assert "input=payload" in src


def test_verifier_defensive_parsing(tmp_path):
    garbage = tmp_path / "garbage.sh"
    garbage.write_text("#!/usr/bin/env bash\ncat >/dev/null\necho not-json\n", encoding="utf-8")
    garbage.chmod(0o755)
    assert audit_claims.run_verifier("./garbage.sh", "c", "p", "d", str(tmp_path)) == \
        ("insufficient", "verifier returned unparseable output")

    oob = tmp_path / "oob.sh"
    oob.write_text('#!/usr/bin/env bash\ncat >/dev/null\necho \'{"verdict":"nope"}\'\n',
                   encoding="utf-8")
    oob.chmod(0o755)
    verdict, rationale = audit_claims.run_verifier("./oob.sh", "c", "p", "d", str(tmp_path))
    assert verdict == "insufficient"
    assert rationale == "verifier returned out-of-enum verdict: 'nope'"


def test_severity_for_maps_contradicts_to_warning_only():
    assert audit_claims.severity_for("contradicts") == "warning"
    for v in ("supports", "weak", "insufficient", "insufficient-locator",
              "skipped-privacy", "skipped-nontext"):
        assert audit_claims.severity_for(v) == "info"
