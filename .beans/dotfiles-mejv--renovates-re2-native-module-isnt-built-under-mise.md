---
# dotfiles-mejv
title: Renovate's re2 native module isn't built under mise
status: completed
type: task
priority: normal
created_at: 2026-11-17T13:09:26Z
updated_at: 2026-11-17T13:13:46Z
---

Local renovate runs log 'Cannot find module ./build/Release/re2.node' (re2@1.27.0 inside the mise npm-renovate install) and fall back to JS regex. Exit code is 0, so it's benign, but it's noise on every run and slower regex. Probably the mise npm backend skips install scripts. Seen 2026-11-17 on renovate 44.184.1, node 24.22.2.

## Resolution

mise skips dependency install scripts by default. `allow_builds = ["re2"]` on the `npm:renovate` entry lets re2 fetch its prebuilt `re2.node`. Verified 2026-11-17: after a forced reinstall, `bin/renovate --platform=local --dry-run=lookup` exits 0 with no re2 lines.
