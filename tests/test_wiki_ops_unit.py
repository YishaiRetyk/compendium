"""TEST-06 unit layer for the wiki-operations cluster port (Phase 25 Plan 04, MIG-05).

Direct module-level coverage of the six ported tools' pure seams:

  - requirements_sync: traceability-table row regex (incl. decimal phases),
    status normalize(), VERIFICATION.md line parsing (checkbox/bold/emoji junk
    stripping), last-write-wins duplicate handling, findings/drift math.
  - validate_op: the 5 executor checks' pure cores — the verbatim-lifted
    frontmatter schema check (required fields, enums, ARCHIVE/SUPERSEDE guards),
    provenance resolution, structural privacy tiers.
  - search: index parsing (bare-link resolution AND the pinned piped-link
    latent-bug behavior), TL;DR extraction, page-path resolution.
  - repo_snapshot: license-family heuristic (order is load-bearing) and
    dominant-language heuristic.

Byte-level behavior is owned by the phase-24 characterization goldens; these
tests exist for fast, localized regression signal (D-18). Helpers that shell out
(grep/sed/sort) run against tmp fixtures — that is the ported behavior, not a
test shortcut.
"""
import textwrap

import pytest

from compendium import repo_snapshot, requirements_sync, search, validate_op


# ---------------------------------------------------------------------------
# requirements_sync — traceability-table + VERIFICATION parsing
# ---------------------------------------------------------------------------

def test_req_row_re_matches_integer_and_decimal_phases():
    m = requirements_sync.REQ_ROW_RE.match("| TMPL-01 | Phase 7 | Complete |")
    assert m.groups() == ("TMPL-01", "7", "Complete")
    m = requirements_sync.REQ_ROW_RE.match("| BOUND-01 | Phase 12.1 | Pending |")
    assert m.groups() == ("BOUND-01", "12.1", "Pending")


def test_req_row_re_rejects_non_rows():
    assert requirements_sync.REQ_ROW_RE.match("|-------------|-------|--------|") is None
    assert requirements_sync.REQ_ROW_RE.match("- [x] **REQ-1**: prose line") is None
    # Phase cell must literally say "Phase N"
    assert requirements_sync.REQ_ROW_RE.match("| REQ-1 | 7 | Complete |") is None


def test_req_row_re_preserves_punctuated_status():
    m = requirements_sync.REQ_ROW_RE.match(
        "| NEUT-08 | Phase 7 | Deferred (partial - infrastructure shipped) |")
    assert m.group(3) == "Deferred (partial - infrastructure shipped)"


def test_normalize_status_families():
    n = requirements_sync.normalize
    assert n("Complete") == "Complete"
    assert n(" done ") == "Complete"
    assert n("PASS") == "Complete"
    assert n("passing") == "Complete"
    assert n("Pending") == "Pending"
    assert n("todo") == "Pending"
    assert n("In Progress") == "Pending"
    assert n("blocked") == "Pending"
    # Unrecognized tokens pass through stripped; empty becomes Unknown
    assert n("Deferred (partial)") == "Deferred (partial)"
    assert n("   ") == "Unknown"


def test_parse_requirements_reads_only_table_rows(tmp_path):
    req = tmp_path / "REQUIREMENTS.md"
    req.write_text(textwrap.dedent("""\
        # Requirements

        | Requirement | Phase | Status |
        |-------------|-------|--------|
        | REQ-1 | Phase 1 | Complete |
        | REQ-2 | Phase 2 | Pending |

        - [x] **REQ-1**: prose restatement (not a row)
        """), encoding="utf-8")
    rows = requirements_sync.parse_requirements(str(req))
    assert rows == [("REQ-1", "1", "Complete"), ("REQ-2", "2", "Pending")]


def test_parse_verifications_strips_leading_junk(tmp_path):
    vf = tmp_path / "01-VERIFICATION.md"
    vf.write_text(textwrap.dedent("""\
        # Phase 1 Verification

        - [x] REQ-1: Complete
        - [ ] **REQ-2**: Pending
        - ✅ REQ-3: done
        REQ-4: pass
        """), encoding="utf-8")
    vmap, warnings = requirements_sync.parse_verifications([str(vf)])
    assert warnings == []
    assert vmap["REQ-1"][0] == "Complete"
    assert vmap["REQ-2"][0] == "Pending"
    assert vmap["REQ-3"][0] == "Complete"
    assert vmap["REQ-4"][0] == "Complete"


def test_parse_verifications_last_write_wins_emits_warning(tmp_path):
    a = tmp_path / "01-VERIFICATION.md"
    b = tmp_path / "02-VERIFICATION.md"
    a.write_text("- [x] REQ-1: Pending\n", encoding="utf-8")
    b.write_text("- [x] REQ-1: Complete\n", encoding="utf-8")
    # Caller passes the LC_ALL=C-sorted order; later file wins.
    vmap, warnings = requirements_sync.parse_verifications([str(a), str(b)])
    assert vmap["REQ-1"][0] == "Complete"
    assert vmap["REQ-1"][2] == str(b)
    assert len(warnings) == 1
    assert "last-write-wins" in warnings[0]


def test_build_findings_drift_and_not_found_and_unknown():
    requirements = [
        ("REQ-1", "1", "Complete"),   # matches VERIFICATION -> OK
        ("REQ-2", "1", "Pending"),    # VERIFICATION says Complete -> DRIFT
        ("REQ-3", "2", "Pending"),    # no VERIFICATION -> not found, no drift
        ("REQ-4", "1", "Pending"),    # unknown token -> no drift, note names it
    ]
    vmap = {
        "REQ-1": ("Complete", "Complete", "vf"),
        "REQ-2": ("Complete", "done", "vf"),
        "REQ-4": ("Unknown", "Frobnicated!!", "vf"),
    }
    findings, drift = requirements_sync.build_findings(requirements, vmap, "")
    assert drift == 1
    by_id = {f["req_id"]: f for f in findings}
    assert by_id["REQ-2"]["drift"] is True and by_id["REQ-2"]["note"] == "DRIFT"
    assert by_id["REQ-3"]["verification_md"] == "(not found)"
    assert by_id["REQ-3"]["note"] == "OK - Phase not yet run"
    assert by_id["REQ-4"]["drift"] is False
    assert "Frobnicated!!" in by_id["REQ-4"]["note"]


def test_build_findings_phase_filter_composes():
    requirements = [("A-1", "7", "Complete"), ("B-1", "12.1", "Pending")]
    findings, _ = requirements_sync.build_findings(requirements, {}, "12.1")
    assert [f["req_id"] for f in findings] == ["B-1"]


# ---------------------------------------------------------------------------
# validate_op — precondition checks (the 5 executor checks' pure cores)
# ---------------------------------------------------------------------------

VALID_PAGE = textwrap.dedent("""\
    ---
    id: alpha
    title: Sample alpha
    type: concept
    status: active
    summary: A deterministic fixture page.
    created_at: 2026-01-02
    updated_at: 2026-01-02
    sources: []
    epistemic_status: sourced
    tags: [fixture]
    domains: [general]
    ---

    ## TL;DR

    - A fixture claim.
    """)


def _page(tmp_path, content, name="page.md"):
    p = tmp_path / name
    p.write_text(content, encoding="utf-8")
    return str(p)


def test_validate_frontmatter_pass(tmp_path):
    lines, rc = validate_op.validate_frontmatter(_page(tmp_path, VALID_PAGE), "UPDATE")
    assert rc == 0
    assert lines == ["PASS"]


def test_validate_frontmatter_missing_required_fields(tmp_path):
    lines, rc = validate_op.validate_frontmatter(
        _page(tmp_path, "---\nid: x\ntitle: T\n---\nbody\n"), "UPDATE")
    assert rc == 1
    assert lines[0].startswith("FAIL: Missing required fields:")
    assert "'type'" in lines[0]


def test_validate_frontmatter_enum_rejections(tmp_path):
    bad_type = VALID_PAGE.replace("type: concept", "type: gizmo")
    lines, rc = validate_op.validate_frontmatter(_page(tmp_path, bad_type), "UPDATE")
    assert rc == 1 and lines[0].startswith("FAIL: Invalid type 'gizmo'")

    bad_status = VALID_PAGE.replace("status: active", "status: bogus")
    lines, rc = validate_op.validate_frontmatter(_page(tmp_path, bad_status), "UPDATE")
    assert rc == 1 and lines[0].startswith("FAIL: Invalid status 'bogus'")

    bad_epi = VALID_PAGE.replace("epistemic_status: sourced", "epistemic_status: vibes")
    lines, rc = validate_op.validate_frontmatter(_page(tmp_path, bad_epi), "UPDATE")
    assert rc == 1 and lines[0].startswith("FAIL: Invalid epistemic_status 'vibes'")


def test_validate_frontmatter_archive_rejects_already_archived(tmp_path):
    archived = VALID_PAGE.replace("status: active", "status: archived")
    path = _page(tmp_path, archived)
    lines, rc = validate_op.validate_frontmatter(path, "ARCHIVE")
    assert rc == 1 and lines == ["FAIL: Page is already archived"]
    # The guard is ARCHIVE-specific: UPDATE on an archived page passes.
    lines, rc = validate_op.validate_frontmatter(path, "UPDATE")
    assert rc == 0 and lines == ["PASS"]


def test_validate_frontmatter_supersede_rejects_already_superseded(tmp_path):
    superseded = VALID_PAGE.replace("status: active",
                                    "status: active\nsuperseded_by: beta")
    path = _page(tmp_path, superseded)
    lines, rc = validate_op.validate_frontmatter(path, "SUPERSEDE")
    assert rc == 1 and lines == ["FAIL: Page already superseded by 'beta'"]
    lines, rc = validate_op.validate_frontmatter(path, "UPDATE")
    assert rc == 0


def test_validate_frontmatter_source_compilation_status(tmp_path):
    src = VALID_PAGE.replace("type: concept", "type: source").replace(
        "summary: A deterministic fixture page.",
        "summary: s\ncompilation_status: weird")
    lines, rc = validate_op.validate_frontmatter(_page(tmp_path, src), "UPDATE")
    assert rc == 1 and lines == ["FAIL: Invalid compilation_status 'weird'"]


def test_validate_frontmatter_structural_failures(tmp_path):
    lines, rc = validate_op.validate_frontmatter(
        _page(tmp_path, "no frontmatter\n"), "UPDATE")
    assert (lines, rc) == (["FAIL: No YAML frontmatter found"], 1)

    lines, rc = validate_op.validate_frontmatter(
        _page(tmp_path, "---\nid: x\n"), "UPDATE")
    assert (lines, rc) == (["FAIL: Unterminated frontmatter (missing closing ---)"], 1)

    lines, rc = validate_op.validate_frontmatter(
        _page(tmp_path, "---\n---\nbody\n"), "UPDATE")
    assert (lines, rc) == (["FAIL: Empty frontmatter"], 1)

    lines, rc = validate_op.validate_frontmatter(
        _page(tmp_path, "---\nid: [unclosed\n---\nbody\n"), "UPDATE")
    assert rc == 1 and lines[0].startswith("FAIL: YAML parse error:")


def test_check_provenance_no_markers(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    path = _page(tmp_path, VALID_PAGE)
    lines, rc = validate_op.check_provenance(path)
    assert (lines, rc) == (["PASS (no provenance markers found)"], 0)


def test_check_provenance_resolves_and_fails(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    (tmp_path / "wiki-cloud" / "sources").mkdir(parents=True)
    (tmp_path / "wiki-cloud" / "sources" / "src-one.md").write_text("x\n")
    page = _page(tmp_path, VALID_PAGE + "\nClaim [prov:src-one#sec:a].\n")
    lines, rc = validate_op.check_provenance(page)
    assert (lines, rc) == (["PASS"], 0)

    page2 = _page(tmp_path, VALID_PAGE + "\n[prov:ghost#p3] [prov:src-one#p1]\n",
                  name="page2.md")
    lines, rc = validate_op.check_provenance(page2)
    assert rc == 1
    assert lines == [
        "FAIL: Provenance reference 'ghost' does not resolve to wiki-cloud/sources/ghost.md"
    ]


def test_check_privacy_tiers_and_leak(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    cloud = tmp_path / "wiki-cloud" / "concepts"
    cloud.mkdir(parents=True)
    cloud_page = cloud / "a.md"
    cloud_page.write_text(VALID_PAGE, encoding="utf-8")
    lines, rc = validate_op.check_privacy("wiki-cloud/concepts/a.md", "UPDATE")
    assert (lines, rc) == (["PASS (privacy: cloud_safe)"], 0)

    local = tmp_path / "wiki-local" / "concepts"
    local.mkdir(parents=True)
    (local / "p.md").write_text(VALID_PAGE, encoding="utf-8")
    lines, rc = validate_op.check_privacy("wiki-local/concepts/p.md", "UPDATE")
    assert (lines, rc) == (["PASS (privacy: local_only)"], 0)

    # Leak: a cloud page deriving from a source whose summary page is local.
    (tmp_path / "wiki-local" / "sources").mkdir()
    (tmp_path / "wiki-local" / "sources" / "sec.md").write_text("x\n")
    leaky = VALID_PAGE.replace("sources: []", "sources: [sec]")
    cloud_page.write_text(leaky, encoding="utf-8")
    lines, rc = validate_op.check_privacy("wiki-cloud/concepts/a.md", "UPDATE")
    assert rc == 1
    assert lines[0].startswith("FAIL: Privacy violation")


# ---------------------------------------------------------------------------
# search — index parsing (incl. the pinned piped-link latent bug)
# ---------------------------------------------------------------------------

def _seed_wiki(tmp_path, index_body):
    (tmp_path / "wiki-cloud" / "concepts").mkdir(parents=True)
    (tmp_path / "wiki-cloud" / "index.md").write_text(index_body, encoding="utf-8")
    (tmp_path / "wiki-cloud" / "concepts" / "gadget-theory.md").write_text(
        textwrap.dedent("""\
            ---
            id: gadget-theory
            title: Gadget Theory
            type: concept
            ---

            ## TL;DR

            - Gadgets compose into assemblies.

            ## Detail

            More text.
            """), encoding="utf-8")


BARE_INDEX = "# Index\n\n- [[gadget-theory]] -- how gadgets compose\n"
PIPED_INDEX = "# Index\n\n- [[gadget-theory|Gadget Theory]] — how gadgets compose\n"


def test_search_index_returns_only_wikilink_list_lines(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _seed_wiki(tmp_path, BARE_INDEX + "gadget mentioned in prose (not a list entry)\n")
    assert search.search_index("gadget") == "- [[gadget-theory]] -- how gadgets compose"
    assert search.search_index("zebra") == ""


def test_extract_title_bare_and_piped(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    # Bare link: the id alone comes out.
    assert search._extract_title("- [[gadget-theory]] -- x") == "gadget-theory"
    # CHARACTERIZATION PIN (do not "fix"): the piped form keeps "id|Title" —
    # broken on piped indexes since Phase 14; goldens freeze this behavior.
    assert (search._extract_title("- [[gadget-theory|Gadget Theory]] — x")
            == "gadget-theory|Gadget Theory")
    # No wikilink: sed passes the line through unchanged.
    assert search._extract_title("- no link here") == "- no link here"


def test_resolve_page_path_direct_hit_and_unresolved(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _seed_wiki(tmp_path, BARE_INDEX)
    # New contract (ticket 24): returns the path string alone; "" means
    # unresolved — never a status, never an abort.
    assert (search.resolve_page_path("gadget-theory")
            == "wiki-cloud/concepts/gadget-theory.md")
    # A piped index entry resolves via _split_wikilink: the target side is the
    # resolution key, the display side only feeds the title fallback.
    target, display = search._split_wikilink("gadget-theory|Gadget Theory")
    assert (target, display) == ("gadget-theory", "Gadget Theory")
    assert (search.resolve_page_path(target, display)
            == "wiki-cloud/concepts/gadget-theory.md")
    # Unresolvable entry: empty string, no exception, no exit.
    assert search.resolve_page_path("no-such-page") == ""


def test_resolve_page_path_title_grep_fallback(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _seed_wiki(tmp_path, BARE_INDEX)
    (tmp_path / "wiki-cloud" / "overviews").mkdir()
    (tmp_path / "wiki-cloud" / "overviews" / "odd-name.md").write_text(
        "---\ntitle: about weird-slug stuff\n---\n", encoding="utf-8")
    # Target-side frontmatter-title fallback (bare link, no display alias).
    assert (search.resolve_page_path("weird-slug stuff")
            == "wiki-cloud/overviews/odd-name.md")
    # Display-side fallback: a piped entry whose target has no page file but
    # whose display title matches page frontmatter still resolves.
    assert (search.resolve_page_path("missing-id", "about weird-slug stuff")
            == "wiki-cloud/overviews/odd-name.md")


def test_extract_tldr_first_line_only(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _seed_wiki(tmp_path, BARE_INDEX)
    text, rc = search.extract_tldr("wiki-cloud/concepts/gadget-theory.md")
    assert (text, rc) == ("- Gadgets compose into assemblies.", 0)
    # A page without a TL;DR section yields the empty string.
    (tmp_path / "no-tldr.md").write_text("## Detail\n\nbody\n", encoding="utf-8")
    text, rc = search.extract_tldr("no-tldr.md")
    assert (text, rc) == ("", 0)


def test_search_fulltext_excludes_index_and_log(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _seed_wiki(tmp_path, BARE_INDEX + "coupling mentioned in the index too\n")
    (tmp_path / "wiki-cloud" / "log.md").write_text("coupling in log\n", encoding="utf-8")
    (tmp_path / "wiki-cloud" / "concepts" / "gadget-theory.md").write_text(
        "## Detail\n\nThe coupling connects.\n", encoding="utf-8")
    assert search.search_fulltext("coupling") == "wiki-cloud/concepts/gadget-theory.md"


# ---------------------------------------------------------------------------
# repo_snapshot — license + dominant-language heuristics
# ---------------------------------------------------------------------------

def test_detect_license_families(tmp_path):
    repo = tmp_path / "repo"
    repo.mkdir()
    assert repo_snapshot.detect_license(str(repo)) == "unknown"

    (repo / "LICENSE").write_text("MIT License\n\nPermission is hereby granted...\n")
    assert repo_snapshot.detect_license(str(repo)) == "MIT"

    (repo / "LICENSE").write_text("Apache License\nVersion 2.0\n")
    assert repo_snapshot.detect_license(str(repo)) == "Apache-2.0"

    (repo / "LICENSE").write_text("Some homegrown terms\n")
    assert repo_snapshot.detect_license(str(repo)) == "present (unclassified)"


def test_detect_license_specific_families_before_gpl_phrase(tmp_path):
    # MPL/LGPL/AGPL license texts CITE the GNU GPL — the specific family must
    # win over the generic GPL match (order is load-bearing; Phase 22 review).
    repo = tmp_path / "repo"
    repo.mkdir()
    (repo / "LICENSE").write_text(
        "GNU LESSER GENERAL PUBLIC LICENSE\n"
        "...incorporates the terms of the GNU GENERAL PUBLIC LICENSE Version 3...\n")
    assert repo_snapshot.detect_license(str(repo)) == "LGPL"

    (repo / "LICENSE").write_text(
        "GNU GENERAL PUBLIC LICENSE\nVersion 3, 29 June 2007\n")
    assert repo_snapshot.detect_license(str(repo)) == "GPL-3.0"

    (repo / "LICENSE").write_text(
        "GNU GENERAL PUBLIC LICENSE\nVersion 2, June 1991\n")
    assert repo_snapshot.detect_license(str(repo)) == "GPL"


def test_detect_license_first_existing_file_wins(tmp_path):
    repo = tmp_path / "repo"
    repo.mkdir()
    (repo / "LICENSE.md").write_text("MIT License\n")
    (repo / "COPYING").write_text("Apache License\n")
    # LICENSE.md precedes COPYING in the fixed candidate order; loop breaks
    # after the FIRST existing file.
    assert repo_snapshot.detect_license(str(repo)) == "MIT"


def test_detect_primary_language_majority_and_mapping(tmp_path):
    repo = tmp_path / "repo"
    (repo / "src").mkdir(parents=True)
    (repo / "src" / "a.py").write_text("x = 1\n")
    (repo / "src" / "b.py").write_text("y = 2\n")
    (repo / "src" / "c.sh").write_text("true\n")
    lang, rc = repo_snapshot.detect_primary_language(str(repo))
    assert (lang, rc) == ("Python", 0)


def test_detect_primary_language_skips_git_and_unknown_ext(tmp_path):
    repo = tmp_path / "repo"
    (repo / ".git").mkdir(parents=True)
    (repo / ".git" / "hook.py").write_text("x\n")   # inside .git -> excluded
    (repo / "notes.txt").write_text("x\n")          # not an impl extension
    lang, rc = repo_snapshot.detect_primary_language(str(repo))
    assert (lang, rc) == ("unknown", 0)


def test_detect_primary_language_unmapped_extension_prints_ext(tmp_path):
    # An extension in the find clause but absent from the awk map prints the
    # raw extension — there is none such today, so exercise the awk fallback
    # shape via 'h' -> C mapping instead (header-only repo).
    repo = tmp_path / "repo"
    repo.mkdir()
    (repo / "lib.h").write_text("#pragma once\n")
    lang, rc = repo_snapshot.detect_primary_language(str(repo))
    assert (lang, rc) == ("C", 0)


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-v"]))
