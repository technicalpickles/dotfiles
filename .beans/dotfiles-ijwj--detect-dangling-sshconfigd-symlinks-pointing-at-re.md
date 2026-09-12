---
# dotfiles-ijwj
title: Detect dangling ~/.ssh/config.d symlinks pointing at removed worktrees
status: todo
type: task
created_at: 2026-09-12T12:54:48Z
updated_at: 2026-09-12T12:54:48Z
---

Discovered while fixing dotfiles-pscz: ~/.ssh/config.d/agent-relay silently
pointed at a removed worktree (.claude/worktrees/github-ssh-relay) because
sshconfig.sh was last run from inside that worktree (its link() function
uses the script's own $DIR as the symlink source). This broke agent SSH
routing through the relay for ALL hosts, and the failure mode ("Operation
not permitted" connecting on port 22) looks identical to a sandbox/allowlist
problem, not a broken symlink -- it took a while to trace.

sshconfig.sh's existing re-point prompt (link() in functions.sh) requires
interactive confirm and defaults to skip non-interactively, so a dangling
symlink like this can persist silently across sessions.

Add a check (to claudeconfig.sh, sshconfig.sh, or a doctor-style script) that
verifies ~/.ssh/config.d/* (and similar generated symlinks) resolve into the
main dotfiles checkout, not a worktree path, and either fixes it
automatically or fails loudly.
