---
# dotfiles-ykvm
title: Allow sandbox writes to portool's ledger
status: completed
type: task
priority: normal
created_at: 2026-10-25T21:39:01Z
updated_at: 2026-10-25T21:40:33Z
---

portool's git hooks run `portool sync`, which rewrites ~/.local/state/portool/registry.json. The sandbox denied that, so sync failed silently and brineworks worktrees kept stale .env.portool files without DB_PORT, falling back to main's shared Postgres (taskwarrior fc672ed3).

## Checklist
- [x] Add claude/stacks/portool.jsonc (allowWrite ~/.local/state/portool, Bash(portool:*))
- [x] Regenerate settings with ./claudeconfig.sh
- [x] Verify a sandboxed write to the ledger dir and a sandboxed portool sync succeed
