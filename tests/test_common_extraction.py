"""PKG-02 extraction tests (Phase 24 Plan 02) — the TEST-06 seed.

Covers:
  Test 0  PRECONDITION: audit-claims.sh's inline primitives are byte-identical to
          lint.sh's (modulo the known "(COPIED from lint.sh)" docstring) BEFORE the
          single frozen copy is trusted — a pre-existing divergence must fail loudly.
  Test 1  make_yaml() factory settings (typ='rt', preserve_quotes, block style,
          None->null representer).
  Test 2  make_yaml round-trip over a committed fixture is BYTE-IDENTICAL to the
          committed expected output (the canonicalization chokepoint is preserved).
  Test 3  privacy resolver: _is_local case-fold/normalization + callables.
  Test 4  the 5 lifted common/ modules are byte-identical to their bin/lib sources.
  Tests 5-7  page.py behaviors: parse_frontmatter 3-tuple contract,
          parse_frontmatter_str, regex matches.
  Test 8  page.py's regex/function source text is byte-identical to the
          authoritative copy in bin/lint.sh.
"""

import pathlib
import re

import pytest

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
LINT_SH = (REPO_ROOT / "bin" / "lint.sh").read_text(encoding="utf-8")
AUDIT_SH = (REPO_ROOT / "bin" / "audit-claims.sh").read_text(encoding="utf-8")
PAGE_PY = (REPO_ROOT / "src" / "compendium" / "common" / "page.py").read_text(encoding="utf-8")

LIFT_MAP = {
    "privacy_resolve.py": "privacy.py",
    "brownfield_yaml.py": "yaml_rt.py",
    "brownfield_walk.py": "walk.py",
    "brownfield_classify.py": "classify.py",
    "brownfield_provenance.py": "provenance.py",
}


def _extract_block(text, start_pattern, end_pattern):
    """Return the source text from the line matching start_pattern up to (not
    including) the line matching end_pattern. Fails loudly if either anchor is
    missing or ambiguous."""
    start_matches = [m for m in re.finditer(start_pattern, text, re.MULTILINE)]
    assert len(start_matches) == 1, (
        f"anchor {start_pattern!r}: expected exactly 1 match, got {len(start_matches)}"
    )
    start = start_matches[0].start()
    end_match = re.search(end_pattern, text[start:], re.MULTILINE)
    assert end_match, f"end anchor {end_pattern!r} not found after {start_pattern!r}"
    return text[start:start + end_match.start()]


def _shared_symbols(text):
    """Extract the 4 precondition symbols' source text from a script."""
    return {
        "PROV_RE": _extract_block(text, r"^PROV_RE = re\.compile\(", r"^\)$\n"),
        "EPISTEMIC_INLINE_RE": _extract_block(
            text, r"^EPISTEMIC_INLINE_RE = re\.compile\(.*$", r"$"
        ),
        "WIKILINK_RE": _extract_block(text, r"^WIKILINK_RE = re\.compile\(.*$", r"$"),
        "parse_frontmatter": _extract_block(
            text, r"^def parse_frontmatter\(filepath\):", r"^\S"
        ),
    }


def test_0_precondition_audit_claims_matches_lint():
    """REVIEWS LOW/MEDIUM: prove the audit-claims copy == lint copy BEFORE unifying.

    The only permitted difference is the audit-claims '(COPIED from lint.sh)'
    docstring suffix. Any other divergence means a pre-existing split-brain that
    must NOT be silently unified into the frozen surface.
    """
    lint_syms = _shared_symbols(LINT_SH)
    audit_syms = _shared_symbols(AUDIT_SH)
    for name in lint_syms:
        audit_text = audit_syms[name].replace(" (COPIED from lint.sh)", "")
        # Trailing whitespace/newline runs at block edges are not semantic.
        assert audit_text.rstrip() == lint_syms[name].rstrip(), (
            f"PRECONDITION FAILED: {name} diverges between bin/lint.sh and "
            f"bin/audit-claims.sh — do NOT extract; resolve the split-brain first.\n"
            f"lint:\n{lint_syms[name]}\naudit:\n{audit_syms[name]}"
        )


def test_1_make_yaml_settings():
    from compendium.common.yaml_rt import make_yaml
    y = make_yaml()
    assert y.preserve_quotes is True
    assert y.default_flow_style is False
    # None -> null representer registered (dump a None and check the token).
    from ruamel.yaml.compat import StringIO
    buf = StringIO()
    y.dump({"k": None}, buf)
    assert "k: null" in buf.getvalue()


def test_2_make_yaml_roundtrip_byte_exact():
    from compendium.common.yaml_rt import make_yaml, split_frontmatter
    from ruamel.yaml.compat import StringIO
    fixture_in = REPO_ROOT / "tests" / "fixtures" / "common" / "frontmatter_in.md"
    fixture_out = REPO_ROOT / "tests" / "fixtures" / "common" / "frontmatter_out.yaml"
    fm_text, _body = split_frontmatter(fixture_in.read_text(encoding="utf-8"))
    assert fm_text is not None
    y = make_yaml()
    data = y.load(fm_text)
    buf = StringIO()
    y.dump(data, buf)
    assert buf.getvalue().encode() == fixture_out.read_bytes(), (
        "make_yaml canonicalization drifted from the committed fixture"
    )


def test_3_privacy_resolver_behavior():
    from compendium.common.privacy import (
        _is_local, resolve_source_privacy, resolve_effective_claim_privacy,
    )
    assert _is_local("wiki-local/x.md") is True
    assert _is_local("./wiki-local/x.md") is True
    assert _is_local("WIKI-LOCAL/x.md") is True  # WR-02 case-fold
    assert _is_local("wiki-cloud/x.md") is False
    assert callable(resolve_source_privacy)
    assert callable(resolve_effective_claim_privacy)


def test_4_verbatim_lift_byte_identity():
    for src_name, dst_name in LIFT_MAP.items():
        src = (REPO_ROOT / "bin" / "lib" / src_name).read_bytes()
        dst = (REPO_ROOT / "src" / "compendium" / "common" / dst_name).read_bytes()
        assert src == dst, f"{dst_name} is not a byte-identical lift of {src_name}"


def test_5_parse_frontmatter_contract(tmp_path):
    from compendium.common.page import parse_frontmatter
    good = tmp_path / "good.md"
    good.write_text("---\nid: x\n---\nbody\n", encoding="utf-8")
    fm, body, err = parse_frontmatter(str(good))
    assert fm == {"id": "x"} and body == "\nbody\n" and err is None

    unterminated = tmp_path / "unterminated.md"
    unterminated.write_text("---\nid: x\nbody\n", encoding="utf-8")
    fm, body, err = parse_frontmatter(str(unterminated))
    assert fm is None and err == "Unterminated frontmatter (missing closing ---)"

    plain = tmp_path / "plain.md"
    plain.write_text("no frontmatter here\n", encoding="utf-8")
    fm, body, err = parse_frontmatter(str(plain))
    assert fm is None and body == "no frontmatter here\n" and err is None


def test_6_parse_frontmatter_str_contract():
    from compendium.common.page import parse_frontmatter_str
    fm, body, err = parse_frontmatter_str("---\nid: x\n---\nbody\n")
    assert fm == {"id": "x"} and err is None
    fm, body, err = parse_frontmatter_str("plain text")
    assert fm is None and body == "plain text" and err is None
    # non-dict frontmatter collapses to None (audit-claims variant behavior)
    fm, body, err = parse_frontmatter_str("---\n- just\n- a list\n---\nbody\n")
    assert fm is None and err is None


def test_7_regexes_match():
    from compendium.common.page import (
        PROV_RE, EPISTEMIC_INLINE_RE, WIKILINK_RE, PIPED_LINK_RE, BARE_LINK_RE,
    )
    m = PROV_RE.search("claim [prov:src-2026-01-02-x#sec:intro]")
    assert m and m.group(1) == "src-2026-01-02-x" and m.group(2) == "sec:intro"
    for val in ("sourced", "mixed", "inferred", "tentative", "stale"):
        assert EPISTEMIC_INLINE_RE.search(f"x [epistemic:: {val}]"), val
    assert WIKILINK_RE.search("[[some-id|Some Title]]")
    assert PIPED_LINK_RE.search("[[some-id|Some Title]]")
    assert BARE_LINK_RE.search("[[bare-target]]")


def test_8_page_py_source_identity_with_lint():
    """page.py's primitives are character-identical to the authoritative lint.sh copy."""
    anchors = [
        (r"^WIKILINK_RE = re\.compile\(.*$", r"$"),
        (r"^PIPED_LINK_RE = re\.compile\(.*$", r"$"),
        (r"^BARE_LINK_RE  = re\.compile\(.*$", r"$"),
        (r"^PROV_RE = re\.compile\(", r"^\)$\n"),
        (r"^EPISTEMIC_INLINE_RE = re\.compile\(.*$", r"$"),
        (r"^_FENCE_OPEN_RE = re\.compile\(.*$", r"$"),
        (r"^_HTMLCOM_RE = re\.compile\(.*$", r"$"),
        (r"^_INLINE_RE  = re\.compile\(.*$", r"$"),
        (r"^_FM_RE      = re\.compile\(.*$", r"$"),
        (r"^def _mask_fences\(text\):", r"^\S"),
        (r"^def mask_markdown\(text\):", r"^\S"),
        (r"^def parse_frontmatter\(filepath\):", r"^\S"),
        (r"^EXCLUDE_FILES = .*$", r"$"),
        (r"^EXCLUDE_DIRS = .*$", r"$"),
    ]
    for start, end in anchors:
        lint_block = _extract_block(LINT_SH, start, end)
        page_block = _extract_block(PAGE_PY, start, end)
        assert page_block.rstrip() == lint_block.rstrip(), (
            f"page.py drifted from lint.sh for anchor {start!r}"
        )
