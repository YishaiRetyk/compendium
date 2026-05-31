#!/usr/bin/env bash
# FAITH-02 edge cases (REVIEW MEDIUM): #sec slug/case/space tolerance; no-match
# #sec -> insufficient-locator; malformed locator; unknown source_id; #p range with
# missing upper marker -> lower..EOF; #para over a fenced code block (internal blanks
# do not split); two [prov:] on one line -> two findings.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

write_page "$REPO" "wiki/sources/src-ed.md" <<'EOF'
---
id: src-ed
title: "ED"
type: source
status: active
path: sources/2026/2026-04/ed/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF

write_page "$REPO" "sources/2026/2026-04/ed/source.md" <<'EOF'
## Self-Attention

SELFATT_MARKER content.

FENCE_PARA_START.

```
code line one

code line two
```

<!-- page: 3 -->
PAGE3_MARKER tail content with no upper marker.
EOF

# (a) slug/case/space tolerance: #sec:self-attention matches "## Self-Attention"
write_page "$REPO" "wiki/concepts/a.md" <<'EOF'
---
id: edgea
title: "EdgeA"
type: concept
status: active
privacy: cloud_safe
---
Slug tolerant [prov:src-ed#sec:self-attention|direct|2026-04-15]
EOF

# (b) no matching heading -> insufficient-locator
write_page "$REPO" "wiki/concepts/b.md" <<'EOF'
---
id: edgeb
title: "EdgeB"
type: concept
status: active
privacy: cloud_safe
---
No such section [prov:src-ed#sec:nonexistent|direct|2026-04-15]
EOF

# (c) malformed locator -> insufficient-locator, no crash
write_page "$REPO" "wiki/concepts/c.md" <<'EOF'
---
id: edgec
title: "EdgeC"
type: concept
status: active
privacy: cloud_safe
---
Malformed [prov:src-ed#bogus99|direct|2026-04-15]
EOF

# (d) unknown source_id -> insufficient-locator, no crash
write_page "$REPO" "wiki/concepts/d.md" <<'EOF'
---
id: edged
title: "EdgeD"
type: concept
status: active
privacy: cloud_safe
---
Unknown source [prov:src-nope#sec:self-attention|direct|2026-04-15]
EOF

# (e) #p3- with missing upper marker -> page3..EOF
write_page "$REPO" "wiki/concepts/e.md" <<'EOF'
---
id: edgee
title: "EdgeE"
type: concept
status: active
privacy: cloud_safe
---
Tail page [prov:src-ed#p3|direct|2026-04-15]
EOF

# (f) #para over fenced code block: para indexing treats the fence as ONE paragraph.
# body paragraphs: 1=Self-Attention heading is skipped, p1=SELFATT_MARKER,
# p2=FENCE_PARA_START, p3=the whole code fence, p4=PAGE3_MARKER tail.
write_page "$REPO" "wiki/concepts/f.md" <<'EOF'
---
id: edgef
title: "EdgeF"
type: concept
status: active
privacy: cloud_safe
---
Code para [prov:src-ed#para3|direct|2026-04-15]
EOF

# (g) two [prov:] markers on one claim line -> two findings
write_page "$REPO" "wiki/concepts/g.md" <<'EOF'
---
id: edgeg
title: "EdgeG"
type: concept
status: active
privacy: cloud_safe
---
Two markers [prov:src-ed#sec:self-attention|direct|2026-04-15] and [prov:src-ed#para1|direct|2026-04-15]
EOF

(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --since "$SEED" --sample 50 --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "edges worklist run" || { echo "$out" >&2; exit 1; }

set +e
findings="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --since "$SEED" --sample 50 --format json 2>/dev/null)"
set -e

# (a) slug tolerance resolved
printf '%s' "$out" | grep -q 'SELFATT_MARKER' || { echo "FAIL(a): #sec slug tolerance" >&2; echo "$out" >&2; exit 1; }

# (e) #p3 with no upper marker -> page3..EOF (PAGE3_MARKER present)
printf '%s' "$out" | grep -q 'PAGE3_MARKER' || { echo "FAIL(e): #p3 lower..EOF" >&2; echo "$out" >&2; exit 1; }

# (f) #para3 == the code fence (contains "code line one"/"code line two", internal blank did not split)
printf '%s' "$out" | grep -q 'code line two' || { echo "FAIL(f): fenced code para not one unit" >&2; echo "$out" >&2; exit 1; }

# (b,c,d) at least 3 insufficient-locator findings (nonexistent sec, bogus, unknown source)
ilc="$(printf '%s' "$findings" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f["verdict"]=="insufficient-locator"))')"
if [ "$ilc" -lt 3 ]; then
    echo "FAIL(b/c/d): expected >=3 insufficient-locator findings, got $ilc" >&2
    echo "$findings" >&2; exit 1
fi

# (g) two findings for the edgeg page (one per marker)
gcount="$(printf '%s' "$findings" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f["path"].endswith("g.md")))')"
if [ "$gcount" -lt 2 ]; then
    echo "FAIL(g): two [prov:] on one line did not yield two findings (got $gcount)" >&2
    echo "$findings" >&2; exit 1
fi

echo "PASS: locator edge cases (#sec slug, no-match, malformed, unknown src, #p EOF, fenced #para, multi-prov)"
