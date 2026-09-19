---
# dotfiles-40i9
title: Add --transcript-only mode to bin/yt-infographics
status: completed
type: task
priority: normal
created_at: 2026-09-19T15:50:17Z
updated_at: 2026-09-19T15:52:14Z
---

Add a --transcript-only flag that skips video download, keyframe extraction, OCR, and vision entirely -- just fetches captions via yt-dlp, dedupes/chunks the VTT, and writes transcript.md. Manual opt-in flag (not auto-detected talking-head vs infographic classification -- the user already knows which mode they want when picking a video for a capture workflow).

Corresponds to taskwarrior task 629 (UUID 15f5f939-88b5-440a-8647-a243bd5f6d98).

## Checklist
- [x] Add --transcript-only CLI flag with help text
- [x] Skip download_video/keyframes/OCR/triage/dedupe/vision when set
- [x] Guard against combining with --no-transcript (contradictory)
- [x] Write transcript.md only (existing pipeline output for transcript)
- [x] Update module docstring usage examples
- [x] Update bin/CLAUDE.md description of yt-infographics
- [x] Manual smoke test against a real talking-head video (verified early-exit skips video/OCR path against two live videos; verified rolling-caption VTT parse+chunk logic against a synthetic fixture matching YouTube's real auto-caption format)
