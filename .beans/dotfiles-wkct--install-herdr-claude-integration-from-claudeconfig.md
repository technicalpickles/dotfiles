---
# dotfiles-wkct
title: Install herdr Claude integration from claudeconfig.sh
status: in-progress
type: task
created_at: 2026-10-26T21:31:49Z
updated_at: 2026-10-26T21:31:49Z
---

herdr resumes Claude panes after a server restart (e.g. Coder workspace shutdown) only when its Claude integration hook reports session IDs. `herdr integration install claude` writes ~/.claude/hooks/herdr-agent-state.sh and adds a SessionStart entry to ~/.claude/settings.json, which claudeconfig.sh regenerates, so a manual install gets wiped on the next run.

Fix: claudeconfig.sh runs `herdr integration install claude` after generate_settings when herdr is on PATH, for every role. The hook no-ops outside herdr (HERDR_ENV check).

## Checklist
- [x] claudeconfig.sh runs the install after generate_settings
- [x] Document in claude/README.md
- [x] npm run lint
