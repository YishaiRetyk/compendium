#!/usr/bin/env python3
# .github/scripts/json-to-annotations.py
# CI-05: convert bin/lint.sh --format json output to GitHub Actions workflow commands.
#
# Severity -> command:
#   error    -> ::error
#   warning  -> ::warning
#   info     -> ::notice      (GitHub uses 'notice' as the lowest tier, NOT 'info')
#
# Annotation cap (GitHub Docs 2026):
#   10 error + 10 warning + 50 total per job. Findings beyond the cap are
#   silently dropped from the PR UI. We sort errors first and emit a trailing
#   ::notice "N more findings -- see lint.json in workflow logs" when capped.
#
# Usage: python3 .github/scripts/json-to-annotations.py <json-file>
import json
import sys

SEVERITY_CMD = {'error': 'error', 'warning': 'warning', 'info': 'notice'}
CAP_ERROR = 10
CAP_WARNING = 10
CAP_TOTAL = 50


def escape(s):
    """Per GitHub Actions: %0D for CR, %0A for LF, %25 for %."""
    return str(s).replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')


def main():
    if len(sys.argv) != 2:
        print("Usage: json-to-annotations.py <json-file>", file=sys.stderr)
        sys.exit(1)
    path = sys.argv[1]
    try:
        data = json.load(open(path))
    except FileNotFoundError:
        print(f"ERROR: findings file not found: {path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"ERROR: findings file is not valid JSON: {e}", file=sys.stderr)
        sys.exit(1)
    if not isinstance(data, list):
        print(f"ERROR: findings file must be a JSON array, got {type(data).__name__}", file=sys.stderr)
        sys.exit(1)

    # Sort: errors first, then warnings, then info -- preserves most-important
    # findings when annotations are capped.
    severity_order = {'error': 0, 'warning': 1, 'info': 2}
    data.sort(key=lambda i: severity_order.get(i.get('severity', 'info'), 3))

    emitted_error = 0
    emitted_warning = 0
    emitted_total = 0
    dropped = 0
    for item in data:
        sev = item.get('severity', 'info')
        cmd = SEVERITY_CMD.get(sev, 'notice')
        # Per-severity caps
        if sev == 'error' and emitted_error >= CAP_ERROR:
            dropped += 1
            continue
        if sev == 'warning' and emitted_warning >= CAP_WARNING:
            dropped += 1
            continue
        if emitted_total >= CAP_TOTAL:
            dropped += 1
            continue
        parts = []
        if item.get('path'):
            parts.append(f"file={escape(item['path'])}")
        if item.get('line'):
            parts.append(f"line={escape(item['line'])}")
        attrs = ','.join(parts)
        msg = escape(item.get('message', ''))
        # Include category in message for reviewer context
        cat = item.get('category', '')
        if cat:
            msg = f"[{cat}] {msg}"
        print(f"::{cmd} {attrs}::{msg}")
        if sev == 'error':
            emitted_error += 1
        elif sev == 'warning':
            emitted_warning += 1
        emitted_total += 1
    if dropped > 0:
        print(
            f"::notice::{dropped} more findings dropped from PR annotations (GitHub cap: "
            f"{CAP_ERROR} error + {CAP_WARNING} warning + {CAP_TOTAL} total per job). "
            f"See full lint output in workflow logs."
        )


if __name__ == '__main__':
    main()
