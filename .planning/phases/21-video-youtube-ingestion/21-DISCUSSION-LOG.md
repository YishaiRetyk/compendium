# Phase 21: Video/YouTube Ingestion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 21-Video/YouTube Ingestion
**Areas discussed:** Transcript marker format + glue depth, What gets committed (asset handling), STT epistemic tier + verification, Validation video criteria

---

## Transcript marker format + glue depth

### Speaker label / timestamp line grammar
| Option | Description | Selected |
|--------|-------------|----------|
| `[H:MM:SS] SPEAKER: text` | Timestamp first; backward-compatible with the existing `TS_RE` audit resolver and the existing transcript source | ✓ |
| Speaker turn blocks | Speaker heading per turn, bare timestamped lines inside; needs audit-resolver tweak | |
| You decide | Claude picks | |

**User's choice:** `[H:MM:SS] SPEAKER: text`
**Notes:** Zero-change compatibility with `bin/audit-claims.sh` was the deciding factor — `#t` locators resolve against this grammar today.

### Speaker-label policy
| Option | Description | Selected |
|--------|-------------|----------|
| Human-named at ingest | Map SPEAKER_NN → real names before commit | |
| Keep SPEAKER_NN as-is | Commit raw diarization labels | |
| Labels only when multi-speaker | Single-speaker omits labels (existing pattern); multi-speaker keeps raw labels, renaming optional | ✓ |

**User's choice:** Labels only when multi-speaker
**Notes:** Matches the existing single-speaker exemplar which has no labels at all.

### Glue depth
| Option | Description | Selected |
|--------|-------------|----------|
| No new script | `schema/` documents generic contract; `stt` invocation in `.planning/` notes | ✓ |
| `bin/video-extract.sh` w/ pluggable cmd | Thin script taking URL + STT_CMD, normalizes output | |
| Decide after seeing stt output | Defer to researcher/planner | |

**User's choice:** No new script
**Notes:** `stt` already does URL→transcript end-to-end; a wrapper would wrap one command. Diverges from Phase 20 (which shipped `bin/pdf-extract.sh`) because `stt` is a personal tool that can't be named in template-public `bin/`.

### Timestamp density
| Option | Description | Selected |
|--------|-------------|----------|
| Per-segment, as STT emits | One `[H:MM:SS]` line per ~2-5s segment; like the existing transcript | ✓ |
| Clustered paragraphs | Merge into utterance clusters; needs a merge step | |
| You decide | Claude picks | |

**User's choice:** Per-segment, as STT emits
**Notes:** Finest `#t` anchor precision + zero post-processing.

---

## What gets committed (asset handling)

### Committed artifact set
| Option | Description | Selected |
|--------|-------------|----------|
| Transcript only, single file | One `.md`: frontmatter + `[H:MM:SS]` lines; the transcript IS the record | ✓ |
| Bundle + machine metadata | Bundle dir with source.md + yt-dlp `.info.json` | |
| Bundle + metadata + thumbnail | As above plus thumbnail image | |

**User's choice:** Transcript only, single file
**Notes:** No co-located assets exist for a video, so no bundle dir; matches the existing de-facto source.

### Extraction fields + enforcement
| Option | Description | Selected |
|--------|-------------|----------|
| Yes, convention-only | Record extraction_tool/model/date; no lint (can't mechanically detect STT vs official captions) | ✓ |
| Yes, lint-enforced via url field | Require fields when url is a video host; wrong for official-caption videos | |
| Skip extraction fields for video | Keep only VID-02's five fields | |

**User's choice:** Yes, convention-only
**Notes:** No mechanical signal distinguishes STT from official captions, so a lint rule would guess.

### Link-rot stance (VID-03 wording)
| Option | Description | Selected |
|--------|-------------|----------|
| Transcript IS the archive | Committed transcript + metadata is durable; url is a courtesy pointer; no machinery | ✓ |
| + optional archive_url field | Same + optional Wayback snapshot field | |
| + rot annotation convention | Same + a way to mark a source rotted | |

**User's choice:** Transcript IS the archive
**Notes:** Cleanest reading of VID-03's "no drift machinery"; `#t` resolves against the committed transcript, not the live video.

### Video description / show-notes
| Option | Description | Selected |
|--------|-------------|----------|
| Case-by-case at ingest | Optional `## Description` when it carries substance; skip promo | ✓ |
| Always include | Description always committed verbatim | |
| Never include | Transcript only, strictly | |

**User's choice:** Case-by-case at ingest

---

## STT epistemic tier + verification

### Epistemic policy
| Option | Description | Selected |
|--------|-------------|----------|
| Sourced + hedging mandate + degraded escape | Clean → sourced + mandated claim-level hedging on failure surface; degraded audio → tentative + spot-verify N=3 | ✓ |
| Tiered, PDF-symmetric only | Clean → sourced, degraded → tentative + spot-verify; no claim-level mandate | |
| Sourced + claim-level hedging only | Page stays sourced + hedging mandate; no page-tier flip | |

**User's choice:** Sourced + hedging mandate + degraded escape
**Notes:** Formalizes the claim-level hedging the existing two transcripts already do, while keeping a PDF-symmetric escape for genuinely bad audio.

### Spot-verification target
| Option | Description | Selected |
|--------|-------------|----------|
| Against the live video at its `#t` timestamp | Re-watch N=3 sampled segments on YouTube; rotted-source fallback = stay tentative | ✓ |
| Re-run STT and diff | Re-transcribe and compare runs; misses systematic mis-hears | |
| You decide | Claude picks | |

**User's choice:** Against the live video at its `#t` timestamp
**Notes:** Honest about the transcript-only / no-local-asset reality (D-05).

---

## Validation video criteria

### Validation video profile
| Option | Description | Selected |
|--------|-------------|----------|
| Short multi-speaker, ~5-20 min | 2+ speaker, clean, cloud-safe; exercises the new SPEAKER labeling path + diarization | ✓ |
| Short single-speaker, ~5-20 min | Talking-head; simplest but leaves multi-speaker path unexercised | |
| You decide | Claude picks | |

**User's choice:** Short multi-speaker, ~5-20 min
**Notes:** Multi-speaker exercises the one piece of new convention surface (speaker labels) with zero existing coverage.

### Transcription host
| Option | Description | Selected |
|--------|-------------|----------|
| On the GPU box, copy transcript back | Run stt on the remote box (Phase 20 pattern) | |
| Wherever stt is installed at execution | Defer host to executor | |
| You decide | Claude picks | |

**User's choice:** On this machine (the workstation)
**Notes:** Override of the recommended remote-box option. Verified: `stt` is installed locally (`~/.local/bin/stt`, uv-managed `~/transcript`) with a local RTX 5070 Ti — no SSH tunnel needed, unlike Phase 20. `yt-dlp`/`faster-whisper` not global but `stt` runs in its own uv venv (expected).

---

## Claude's Discretion

- Exact convention-doc structure/wording and filename (new `schema/reference/*.md` vs. extension of existing transcript doc).
- Frontmatter field spelling for the five VID-02 fields and whether they're added to `frontmatter.md`.
- `N`-segment selection method for degraded-audio spot-verification.
- Hour-digit timestamp normalization (`0:04:56` vs `00:04:56`) per the audit `TS_RE` tolerance.
- Whether the schema edits warrant a `reflect`-tier decision record.

## Deferred Ideas

None — discussion stayed within phase scope. Declined-but-recorded alternatives (for traceability): `.info.json`/thumbnail bundle; `archive_url`/`url_dead:` rot fields; lint-enforced extraction fields. A future phase may revisit if link-rot becomes a felt problem.
