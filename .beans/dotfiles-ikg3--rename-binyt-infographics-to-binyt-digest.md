---
# dotfiles-ikg3
title: Rename bin/yt-infographics to bin/yt-digest
status: completed
type: task
created_at: 2026-09-19T17:11:49Z
updated_at: 2026-09-19T17:11:49Z
---

Renamed since the script pulls both spoken transcript and infographic text, not infographics alone -- yt-digest better reflects 'everything worth summarizing out of a video' (per its own docstring). git mv + updated internal usage examples, default --out-dir name, and bin/CLAUDE.md entry. Follow-up to dotfiles-40i9 (--transcript-only flag).
