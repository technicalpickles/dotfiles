---
# dotfiles-ijwj
title: Detect dangling ~/.ssh/config.d symlinks pointing at removed worktrees
status: scrapped
type: task
priority: normal
created_at: 2026-09-12T12:54:48Z
updated_at: 2026-09-12T13:01:00Z
---

Duplicate of dotfiles-51b3 (created 2026-09-08 after the same class of bug hit the LaunchAgent plist and gost YAML symlinks during the PR #34 merge). Today's occurrence (~/.ssh/config.d/agent-relay via sshconfig.sh) is now folded into 51b3's body/checklist as the second confirmed instance, with the scope broadened to cover functions.sh's link() generically, not just symlinks.sh's LaunchAgent-specific logic. See dotfiles-51b3.
