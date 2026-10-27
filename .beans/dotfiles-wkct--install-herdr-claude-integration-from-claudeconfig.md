---
# dotfiles-wkct
title: Install herdr Claude integration from claudeconfig.sh
status: completed
type: task
created_at: 2026-10-26T21:31:49Z
updated_at: 2026-10-27T13:50:00Z
---

herdr resumes Claude panes after a server restart (e.g. Coder workspace shutdown) only when its Claude integration hook reports session IDs. `herdr integration install claude` writes ~/.claude/hooks/herdr-agent-state.sh and adds a SessionStart entry to ~/.claude/settings.json, which claudeconfig.sh regenerates, so a manual install gets wiped on the next run.

Fix: claudeconfig.sh runs `herdr integration install claude` after generate_settings when herdr is on PATH, for every role. The hook no-ops outside herdr (HERDR_ENV check).

## Checklist
- [x] claudeconfig.sh runs the install after generate_settings
- [x] Document in claude/README.md
- [x] npm run lint
- [x] Verified after a Coder workspace restart (2026-10-27): herdr restored the layout, Claude panes resumed from their session refs, and the SessionStart hook survived
