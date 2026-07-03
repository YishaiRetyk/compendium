"""MIG-03 checker unit layer (Phase 25, TEST-06).

Direct module-level pytest coverage of the three privacy/neutrality checkers
ported in MIG-03 (src/compendium/check_neutrality.py, check_privacy.py,
check_sources_cloud_safe.py). The byte-parity oracle covers the CLI surface;
this file covers the ported helpers' semantics directly:

  - check_neutrality.tokenize(): stopword filtering, length floor, hyphenated
    slugs preserved as single tokens, lowercase-normalized sorted-dedup output.
  - check_privacy.path_contains_wiki_local(): PATH-COMPONENT semantics (a
    'wiki-local-ish' substring must NOT trip the guard).
  - check_neutrality.load_denylist(): comment/blank filtering + lowercasing.
  - check_neutrality.has_neutrality_exempt(): frontmatter-only detection.
  - check_sources_cloud_safe.run(): local_only frontmatter detection against a
    tmp_path fixture (FAIL-CLOSED exit 1) plus the clean/vacuous exit-0 paths.
"""

import pytest

from compendium import check_neutrality, check_privacy, check_sources_cloud_safe


# ---------------------------------------------------------------------------
# check_neutrality.tokenize()
# ---------------------------------------------------------------------------

def test_tokenize_filters_stopwords():
    # 'the', 'and', 'decision', 'wiki' are embedded stopwords; 'quixotic' is not.
    assert check_neutrality.tokenize("the quixotic decision and wiki") == ["quixotic"]


def test_tokenize_length_floor():
    # TOKEN_RE requires [A-Za-z][A-Za-z0-9-]{2,} -> 1- and 2-char words never tokenize.
    assert check_neutrality.tokenize("ab xy zq abc") == ["abc"]


def test_tokenize_preserves_hyphenated_slugs():
    # A hyphenated slug stays ONE token -- even when its components ('personal',
    # 'decision', 'journal') are individually stopwords, the slug survives.
    assert check_neutrality.tokenize("personal-decision-journal") == [
        "personal-decision-journal"
    ]


def test_tokenize_lowercases_dedups_and_sorts():
    assert check_neutrality.tokenize("Zebra QUIXOTIC zebra") == ["quixotic", "zebra"]


# ---------------------------------------------------------------------------
# check_privacy.path_contains_wiki_local()
# ---------------------------------------------------------------------------

def test_path_contains_wiki_local_component_positive():
    assert check_privacy.path_contains_wiki_local("docs/wiki-local/page.md") is True
    assert check_privacy.path_contains_wiki_local("examples/deep/wiki-local/sub/x.md") is True
    # Windows-style separators are normalized before the component split.
    assert check_privacy.path_contains_wiki_local("docs\\wiki-local\\page.md") is True


def test_path_contains_wiki_local_noncomponent_negative():
    # 'wiki-local-ish' substrings are NOT path components -- must not trip.
    assert check_privacy.path_contains_wiki_local("docs/wiki-localish/page.md") is False
    assert check_privacy.path_contains_wiki_local("docs/my-wiki-local-notes.md") is False
    assert check_privacy.path_contains_wiki_local("docs/awiki-local/page.md") is False


# ---------------------------------------------------------------------------
# check_neutrality.load_denylist()
# ---------------------------------------------------------------------------

def test_load_denylist_filters_comments_and_blanks(tmp_path):
    deny = tmp_path / ".neutrality-denylist.txt"
    deny.write_text(
        "# a comment\n"
        "\n"
        "TermOne\n"
        "   \n"
        "# another comment\n"
        "  multi word term  \n",
        encoding="utf-8",
    )
    assert check_neutrality.load_denylist(str(deny)) == ["termone", "multi word term"]


def test_load_denylist_missing_file_returns_none(tmp_path):
    assert check_neutrality.load_denylist(str(tmp_path / "absent.txt")) is None


# ---------------------------------------------------------------------------
# check_neutrality.has_neutrality_exempt()
# ---------------------------------------------------------------------------

def test_has_neutrality_exempt_detects_frontmatter_flag():
    assert check_neutrality.has_neutrality_exempt(
        "---\nid: x\nneutrality_exempt: true\n---\n\nBody.\n"
    ) is True
    # Case-insensitive match (re.I).
    assert check_neutrality.has_neutrality_exempt(
        "---\nneutrality_exempt: True\n---\n\nBody.\n"
    ) is True


def test_has_neutrality_exempt_negatives():
    # No frontmatter block at all.
    assert check_neutrality.has_neutrality_exempt("plain body\n") is False
    # Frontmatter without the flag.
    assert check_neutrality.has_neutrality_exempt("---\nid: x\n---\n\nBody.\n") is False
    # Flag mentioned in the BODY only (after the closing ---) does not count.
    assert check_neutrality.has_neutrality_exempt(
        "---\nid: x\n---\n\nneutrality_exempt: true\n"
    ) is False


# ---------------------------------------------------------------------------
# check_sources_cloud_safe.run() -- local_only detection on a tmp_path fixture
# ---------------------------------------------------------------------------

def _write_source(root, rel, text):
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8")
    return p


def test_sources_cloud_safe_flags_local_only(tmp_path, monkeypatch, capsys):
    _write_source(
        tmp_path, "sources/2026/2026-01/2026-01-02-secret.md",
        "---\nid: src-2026-01-02-secret\nprivacy: local_only\n---\n\nBody.\n",
    )
    _write_source(
        tmp_path, "sources/2026/2026-01/2026-01-03-open.md",
        "---\nid: src-2026-01-03-open\n---\n\nBody.\n",
    )
    monkeypatch.setenv("CSG_ROOT", str(tmp_path))
    with pytest.raises(SystemExit) as exc:
        check_sources_cloud_safe.run()
    assert exc.value.code == 1  # FAIL-CLOSED contract: exit 1 (NOT 2) on violation
    err = capsys.readouterr().err
    assert "sources/2026/2026-01/2026-01-02-secret.md" in err
    assert "'privacy: local_only' frontmatter" in err
    assert "FAIL-CLOSED: 1 raw-source cloud-safe violation(s) found" in err


def test_sources_cloud_safe_clean_exits_zero(tmp_path, monkeypatch, capsys):
    _write_source(
        tmp_path, "sources/2026/2026-01/2026-01-03-open.md",
        "---\nid: src-2026-01-03-open\n---\n\nBody.\n",
    )
    monkeypatch.setenv("CSG_ROOT", str(tmp_path))
    with pytest.raises(SystemExit) as exc:
        check_sources_cloud_safe.run()
    assert exc.value.code == 0
    out = capsys.readouterr().out
    assert "OK: all raw sources under sources/ are cloud-safe (1 files checked)" in out


def test_sources_cloud_safe_vacuous_without_sources_dir(tmp_path, monkeypatch, capsys):
    monkeypatch.setenv("CSG_ROOT", str(tmp_path))
    with pytest.raises(SystemExit) as exc:
        check_sources_cloud_safe.run()
    assert exc.value.code == 0
    out = capsys.readouterr().out
    assert "vacuously holds" in out
