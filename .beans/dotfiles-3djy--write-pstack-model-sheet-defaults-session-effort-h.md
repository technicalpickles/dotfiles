---
# dotfiles-3djy
title: 'Write pstack model sheet: defaults, session effort, hook off'
status: in-progress
type: task
created_at: 2026-11-15T22:09:45Z
updated_at: 2026-11-15T22:09:45Z
---

Add claude/pstack-models.md (default effort session, session hook off, no role lines so pstack defaults hold), link it to ~/.claude/pstack-models.md in claudeconfig.sh, and load it with an @ include in claude/CLAUDE.md. pickle-mode now routes, so pstack's own SessionStart hook is off.

## Checklist
- [x] Write the sheet
- [x] Link it and include it
- [ ] Run ./claudeconfig.sh after merge
- [ ] After ~2 weeks, compare fix-forward rounds per PR by code-delegate model; flip feature/refactoring to opus if sonnet needs more rounds
