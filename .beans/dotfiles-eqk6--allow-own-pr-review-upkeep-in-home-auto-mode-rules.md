---
# dotfiles-eqk6
title: Allow own-PR review upkeep in home auto mode rules
status: in-progress
type: task
created_at: 2026-11-09T19:16:08Z
updated_at: 2026-11-09T19:16:08Z
---

Add two prose allow rules to claude/roles/home.jsonc: reply to and resolve review threads on a PR the user authored, and gh pr ready and gh pr edit --add-label on a PR the agent opened or was told to work on. Both gated on the user asking in this session.

## Checklist
- [x] Rules written in home.jsonc
- [x] prettier check and JSONC parse
- [x] Rule diff against the live config: 2 allow added, 0 soft_deny or hard_deny removed
- [ ] claudeconfig.sh run after merge
