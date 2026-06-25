---
# dotfiles-3tcz
title: bin/claude-permissions references dead pre-roles permission files + stale path
status: todo
type: bug
priority: low
created_at: 2026-06-23T19:03:41Z
updated_at: 2026-06-23T19:03:41Z
---

bin/claude-permissions (lines ~95-110) enumerates dotfiles templates claude/permissions.json, permissions.personal.json, permissions.work.json -- none exist since the move to claude/roles/*.jsonc. It also looks under ~/workspace/dotfiles, but this repo lives at ~/github.com/technicalpickles/dotfiles. The .exists() guards keep it from erroring, so it silently reports nothing instead of the real role files. Update it to read claude/roles/*.jsonc at the correct dotfiles path, or retire the script if unused.
