# src/compendium/pdf_extract.py — byte-parity port of bin/pdf-extract.sh (Phase 25 MIG-05).
#
# PARITY CONTRACT: ALL external commands stay external with identical argv —
# pdftoppm/pdfinfo (poppler), jq, base64, curl, awk. The Phase-20 live test
# drives the tool through its OLLAMA_URL/PDF_EXTRACT_MODEL env knobs against a
# local HTTP stub; keeping curl (not urllib) preserves both the observable
# request behavior and any PATH interception. Preflight fail-loud messages are
# verbatim. Bash `set -euo pipefail` abort points replicated — including the
# silent exit-2 when the per-page PNG glob matches nothing (ls fails inside a
# $() assignment with stderr devnulled).
import glob
import os
import subprocess
import sys

EXTRACT_VERSION = "0.1.0"


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


def _run(argv, stdin_bytes=None, stdout=None, stderr=None):
    sys.stdout.flush()
    sys.stderr.flush()
    p = subprocess.run(argv, input=stdin_bytes, stdout=stdout, stderr=stderr)
    return _rc_of(p)


def _capture(argv, stdin_bytes=None, stderr=None):
    sys.stdout.flush()
    sys.stderr.flush()
    p = subprocess.run(argv, input=stdin_bytes, stdout=subprocess.PIPE, stderr=stderr)
    return p.stdout, _rc_of(p)


def _cs(out_bytes):
    return out_bytes.decode("utf-8", "surrogateescape").rstrip("\n")


def _b(s):
    return s.encode("utf-8", "surrogateescape")


def _which(cmd):
    import shutil
    return shutil.which(cmd)


class _State:
    """Mutable defaults — usage() interpolates the CURRENT values (the bash
    heredoc is unquoted, so ${DPI} etc. expand at call time)."""

    def __init__(self):
        self.model = os.environ.get("PDF_EXTRACT_MODEL", "richardyoung/olmocr2:7b-q8")
        self.dpi = os.environ.get("PDF_EXTRACT_DPI", "150")
        self.ollama_url = os.environ.get("OLLAMA_URL", "http://localhost:11434")
        self.prompt = os.environ.get(
            "PDF_EXTRACT_PROMPT",
            "Extract all text from this document page as Markdown, preserving structure.")
        self.page_timeout = os.environ.get("PDF_EXTRACT_TIMEOUT", "300")
        self.ollama_options_json = os.environ.get("OLLAMA_OPTIONS_JSON", "")


def usage(st):
    return f"""Usage: pdf-extract.sh [--dpi N] [--model TAG] [--out FILE] <input.pdf>

PDF->Markdown acquisition glue: renders each page to PNG (pdftoppm), OCRs it via
a local Ollama VLM, and assembles one <!-- page: N --> marker per 1-based page so
the output is ready for standard ingest.

Arguments:
  <input.pdf>        Path to the input PDF (positional, required).

Options:
  --dpi N            Render resolution (default: {st.dpi}).
  --model TAG        Ollama model tag (default: {st.model}).
  --out FILE         Output Markdown path (default: <input>.md).
  --help, -h         Show this help.

Requires: poppler (pdftoppm, pdfinfo), a reachable Ollama server, jq, base64, curl.

Env overrides:
  PDF_EXTRACT_MODEL          Model tag (same as --model).
  PDF_EXTRACT_DPI            Render DPI (same as --dpi).
  PDF_EXTRACT_PROMPT         OCR prompt sent with each page image.
  PDF_EXTRACT_TIMEOUT        Per-page curl timeout in SECONDS (default {st.page_timeout}).
                             NOTE: the FIRST page's call includes the model
                             cold-load (a ~9.5 GB model), so on a slow or
                             memory-pressured host page 1 may need a higher value.
                             A page-1 "timed out" error usually means raise this
                             override, not a hang.
  OLLAMA_URL                 Ollama server base URL (default {st.ollama_url}).
  OLLAMA_OPTIONS_JSON        Optional JSON model-options blob (e.g. '{{"num_ctx":8192}}').

Output contract: one <!-- page: N --> marker per page, on its own line, where N
is the 1-based page number that begins below the marker.
"""


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    _reconfigure_streams()

    st = _State()
    out_path = ""
    pdf = ""

    # --- Arg parse (while/case, mirrors bin/ingest.sh) -------------------------
    while args:
        a = args[0]
        if a in ("--help", "-h"):
            _out(usage(st))
            return 0
        elif a == "--dpi":
            if len(args) < 2:
                _err("ERROR: --dpi requires a value\n")
                return 1
            st.dpi = args[1]
            args = args[2:]
        elif a == "--model":
            if len(args) < 2:
                _err("ERROR: --model requires a value\n")
                return 1
            st.model = args[1]
            args = args[2:]
        elif a == "--out":
            if len(args) < 2:
                _err("ERROR: --out requires a value\n")
                return 1
            out_path = args[1]
            args = args[2:]
        elif a == "--":
            args = args[1:]
            if args and not pdf:
                pdf = args[0]
                args = args[1:]
        elif a.startswith("-"):
            _err(f"ERROR: Unknown option: {a}\n")
            _err(usage(st))
            return 1
        else:
            if not pdf:
                pdf = a
            else:
                _err(f"ERROR: Unexpected positional argument: {a}\n")
                _err(usage(st))
                return 1
            args = args[1:]

    if not pdf:
        _err("ERROR: no input PDF given\n")
        _err(usage(st))
        return 1

    # --- Preflight checks (fail loud) ------------------------------------------
    for cmd in ("pdftoppm", "pdfinfo", "jq", "base64", "curl"):
        if not _which(cmd):
            _err(f"ERROR: required command not found: {cmd}\n")
            return 1

    if not os.path.isfile(pdf):
        _err(f"ERROR: input PDF not found: {pdf}\n")
        return 1

    # Validate the optional options blob before touching the model.
    if st.ollama_options_json:
        rc = _run(["jq", "-e", "."], stdin_bytes=_b(st.ollama_options_json) + b"\n",
                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if rc != 0:
            _err(f"ERROR: OLLAMA_OPTIONS_JSON is not valid JSON: {st.ollama_options_json}\n")
            return 1

    # Server reachable?
    rc = _run(["curl", "-sf", f"{st.ollama_url}/api/tags"],
              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if rc != 0:
        _err(f"ERROR: Ollama server not reachable at {st.ollama_url}\n")
        return 1

    # Model actually pulled? (A reachable server with a missing model otherwise
    # yields null text on every page.)
    tags_out, crc = _capture(["curl", "-sf", f"{st.ollama_url}/api/tags"])
    jrc = _run(["jq", "-e", "--arg", "m", st.model,
                '.models[] | select(.name == $m)'],
               stdin_bytes=tags_out, stdout=subprocess.DEVNULL)
    if crc != 0 or jrc != 0:
        _err(f"ERROR: model {st.model} not found on Ollama server (ollama pull {st.model})\n")
        return 1

    # --- Default OUT ------------------------------------------------------------
    if not out_path:
        # ${PDF%.pdf}.md
        out_path = (pdf[:-4] if pdf.endswith(".pdf") else pdf) + ".md"

    # --- Page count ---------------------------------------------------------------
    po, prc = _capture(["pdfinfo", pdf])
    ao, arc = _capture(["awk", "/^Pages:/{print $2}"], stdin_bytes=po)
    pipeline_rc = arc if arc != 0 else prc
    if pipeline_rc != 0:
        sys.exit(pipeline_rc)  # set -e on the $() assignment
    pages_str = _cs(ao)
    import re
    if not (re.fullmatch(r"[0-9]+", pages_str) and int(pages_str) > 0):
        _err(f"ERROR: could not determine page count for {pdf}\n")
        return 1
    pages = int(pages_str)

    to, trc = _capture(["mktemp", "-d"])
    if trc != 0:
        sys.exit(trc)
    tmp = _cs(to)

    try:
        # Write to a temp output first; move into place only on success so a partial/
        # aborted run never leaves a structurally-valid-looking $OUT behind.
        out_tmp = f"{tmp}/out.md"
        open(out_tmp, "wb").close()  # : > "$OUT_TMP"

        # Count markers the script itself emits (WR-04).
        emitted = 0

        for n in range(1, pages + 1):
            rc = _run(["pdftoppm", "-png", "-r", st.dpi, "-f", str(n), "-l", str(n),
                       pdf, f"{tmp}/page-{n}"], stdout=subprocess.DEVNULL)
            if rc != 0:
                sys.exit(rc)

            # Select EXACTLY one render, failing loud on zero or multiple matches.
            pngs = sorted(glob.glob(f"{tmp}/page-{n}-*.png"))
            if len(pngs) == 0:
                # bash: the unmatched glob reaches `ls` literally; ls exits 2 with
                # stderr devnulled, and the $() assignment aborts under set -e
                # BEFORE the friendly count error can print.
                sys.exit(2)
            png_count = len(pngs)
            if png_count != 1:
                _err(f"ERROR: expected exactly 1 rendered PNG for page {n}, found {png_count}\n")
                sys.exit(1)
            png = pngs[0]

            # Encode to a FILE, never a shell-var-into-argv (128 KB argv limit).
            with open(f"{tmp}/page.b64", "wb") as b64f:
                sys.stdout.flush()
                sys.stderr.flush()
                p = subprocess.run(["base64", "-w0", png], stdout=b64f)
            if _rc_of(p) != 0:
                sys.exit(_rc_of(p))

            # Build the request JSON to a file via --rawfile (file-based I/O end to end).
            if st.ollama_options_json:
                jq_argv = ["jq", "-n", "--arg", "m", st.model, "--arg", "p", st.prompt,
                           "--rawfile", "img", f"{tmp}/page.b64",
                           "--argjson", "opts", st.ollama_options_json,
                           '{model:$m, prompt:$p, images:[$img], stream:false} + {options:$opts}']
            else:
                jq_argv = ["jq", "-n", "--arg", "m", st.model, "--arg", "p", st.prompt,
                           "--rawfile", "img", f"{tmp}/page.b64",
                           '{model:$m, prompt:$p, images:[$img], stream:false}']
            with open(f"{tmp}/req.json", "wb") as reqf:
                sys.stdout.flush()
                sys.stderr.flush()
                p = subprocess.run(jq_argv, stdout=reqf)
            if _rc_of(p) != 0:
                sys.exit(_rc_of(p))

            # Capture the FULL response and check it before extracting text. NEVER pipe
            # straight to jq -r '.response' — a failed call yields the literal string
            # "null" under a valid marker, the worst failure mode for a provenance system.
            resp, rc = _capture(["curl", "-fsS", "--max-time", st.page_timeout,
                                 f"{st.ollama_url}/api/generate", "-d", f"@{tmp}/req.json"])
            if rc != 0:
                _err(f"ERROR: Ollama call failed (or timed out after {st.page_timeout}s) on page {n}\n")
                sys.exit(1)
            resp_line = resp.decode("utf-8", "surrogateescape").rstrip("\n")  # RESP=$(...)
            has_err_rc = _run(["jq", "-e", 'has("error")'],
                              stdin_bytes=_b(resp_line) + b"\n",
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if has_err_rc == 0:
                eo, _ = _capture(["jq", "-r", ".error"], stdin_bytes=_b(resp_line) + b"\n")
                _err(f"ERROR: Ollama error on page {n}: {_cs(eo)}\n")
                sys.exit(1)
            null_rc = _run(["jq", "-e", ".response != null"],
                           stdin_bytes=_b(resp_line) + b"\n",
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if null_rc != 0:
                _err(f"ERROR: null response on page {n}\n")
                sys.exit(1)
            to_, trc_ = _capture(["jq", "-r", ".response"], stdin_bytes=_b(resp_line) + b"\n")
            if trc_ != 0:
                sys.exit(trc_)
            text = _cs(to_)  # TEXT=$(...) strips trailing newlines

            # ALWAYS emit the marker even if TEXT is an empty string (a genuinely blank
            # page is legitimate; keeps #p slices aligned). Only null/error responses abort.
            with open(out_tmp, "ab") as of:
                of.write(_b(f"<!-- page: {n} -->\n{text}\n\n"))
            emitted += 1

            rc = _run(["rm", "-f", png, f"{tmp}/page.b64", f"{tmp}/req.json"])
            if rc != 0:
                sys.exit(rc)

        # Sanity-check the count of markers the script emitted against the page count.
        if emitted != pages:
            _err(f"ERROR: emitted marker count ({emitted}) != page count ({pages})\n")
            sys.exit(1)

        rc = _run(["mv", out_tmp, out_path])
        if rc != 0:
            sys.exit(rc)
        _err(f"pdf-extract: wrote {out_path} ({pages} pages)\n")
        return 0
    finally:
        # trap 'rm -rf "$TMP"' EXIT
        subprocess.run(["rm", "-rf", tmp])


if __name__ == "__main__":          # enables `python3 -m compendium.pdf_extract`
    sys.exit(main(sys.argv[1:]))
