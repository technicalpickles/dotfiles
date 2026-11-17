---
# dotfiles-mejv
title: Renovate's re2 native module isn't built under mise
status: draft
type: task
created_at: 2026-11-17T13:09:26Z
updated_at: 2026-11-17T13:09:26Z
---

Local renovate runs log 'Cannot find module ./build/Release/re2.node' (re2@1.27.0 inside the mise npm-renovate install) and fall back to JS regex. Exit code is 0, so it's benign, but it's noise on every run and slower regex. Probably the mise npm backend skips install scripts. Seen 2026-11-17 on renovate 44.184.1, node 24.22.2.
