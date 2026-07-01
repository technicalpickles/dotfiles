---
# dotfiles-5886
title: Fix stale references in CLAUDE.md files
status: completed
type: task
priority: normal
created_at: 2026-07-01T14:40:01Z
updated_at: 2026-07-01T14:40:15Z
---

Audit found 3 accuracy bugs across CLAUDE.md files:
- Root CLAUDE.md: subsystem link points to claude/CLAUDE.md (personal instructions) instead of claude/README.md (settings/permissions docs)
- config/fish/CLAUDE.md: references non-existent atuin.fish; mise listed under conf.d but inits in config.fish
- bin/CLAUDE.md: missing several Claude utilities (claude-status-line, claude-permissions, claude-with, analyze-claude-sessions)
