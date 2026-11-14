---
# dotfiles-9tdl
title: Document .git/config sandbox friction and EnterWorktree papercuts in worktrees rule
status: completed
type: task
created_at: 2026-10-26T10:39:44Z
updated_at: 2026-10-26T10:39:44Z
---

Added two bullets to claude/rules/worktrees.md: (1) branch-config writes (branch -m, set-upstream, push -u, branch deletes) hit the sandbox because a worktree's branch config lives in the main repo's .git/config, seen in ~20 sessions across 12 projects; (2) EnterWorktree papercuts: worktree-<name> branch naming invites the rename, isolation guard refuses compound Bash, fresh baseRef drops local-only commits. Evidence from cq over session transcripts. Open question not addressed here: sandbox-level fix for .git/config (see taskwarrior 76a81a62-d294-4ec4-a373-cb278ee1804d).
