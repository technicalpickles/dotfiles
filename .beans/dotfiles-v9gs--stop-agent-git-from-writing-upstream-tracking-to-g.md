---
# dotfiles-v9gs
title: Stop agent git from writing upstream tracking to .git/config
status: completed
type: task
created_at: 2026-10-26T16:00:32Z
updated_at: 2026-10-26T16:00:32Z
---

Agent sessions half-failed on .git/config writes from push -u, bare push under autoSetupRemote, and switch -c x origin/x (206 denials across 143 sessions, 2026-08-06 to 2026-10-26). claude-agent-{home,work} now set branch.autoSetupMerge = false, and push.autoSetupRemote = true moved from common to home/.gitconfig because git ORs that key into a flag, so a later false in the agent config would never undo it (builtin/push.c). claude/rules/worktrees.md tells agents to push without -u, open PRs with gh pr create --head, and pull with an explicit branch.
