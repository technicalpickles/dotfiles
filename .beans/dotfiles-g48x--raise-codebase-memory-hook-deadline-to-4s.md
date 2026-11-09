---
# dotfiles-g48x
title: Raise codebase-memory hook deadline to 4s
status: in-progress
type: task
created_at: 2026-11-09T23:23:59Z
updated_at: 2026-11-09T23:23:59Z
---

After the 0.12.1 bump, hook-augment still blew its 2000ms deadline on the first call after idle (measured: two cold calls ~1.7s with empty output, then ~0.17s warm; timeout log kept growing 2424 -> 2433). Set CBM_HOOK_DEADLINE_MS=4000 on every hook-augment command in claude/roles/home.jsonc and work.jsonc so a cold call finishes and injects context. Claude Code's own hook timeout stays 5s.

## Checklist
- [x] Set CBM_HOOK_DEADLINE_MS=4000 in home and work roles
- [x] Run claudeconfig.sh, confirm ~/.claude/settings.json has it
- [ ] Timeout log stops growing over a few sessions
