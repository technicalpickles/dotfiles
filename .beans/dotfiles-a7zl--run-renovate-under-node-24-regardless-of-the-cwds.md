---
# dotfiles-a7zl
title: Run renovate under node 24 regardless of the cwd's node pin
status: completed
type: task
priority: normal
created_at: 2026-11-17T13:07:44Z
updated_at: 2026-11-17T13:09:49Z
---

Renovate 44 needs node ^24.11. mise resolves node from the cwd's config, so in any repo pinning an older node (dotfiles pins 22.23.4) `renovate` and `renovate-config-validator` crash with 'RegExp.escape is not a function'. Wrap both in bin/ via mise exec, like bin/qmd.

## Checklist

- [x] bin/renovate wrapper, bin/renovate-config-validator symlink
- [x] Verified under a node 22 pin and in another repo
- [x] bin/CLAUDE.md index entry
