---
# dotfiles-pscz
title: Fix dangling ~/.ssh/config.d/agent-relay symlink and add gist.github.com to relay allowlist
status: completed
type: bug
created_at: 2026-09-12T12:54:37Z
updated_at: 2026-09-12T12:54:37Z
---

While extending the agent-ssh-relay allowlist to cover gist.github.com (previously
gist fell back to HTTPS via gh's credential helper since it wasn't allowlisted),
discovered ~/.ssh/config.d/agent-relay was a dangling symlink pointing at a
worktree (.claude/worktrees/github-ssh-relay) that had already been removed
after merge. This meant the ProxyCommand routing agent SSH through the
gost relay (ADR 0055) was silently inactive for ALL hosts, including
github.com -- direct `ssh -T git@github.com` from an agent session was
failing with "Operation not permitted" (raw port 22, sandbox-blocked),
not just gist.

Root cause: sshconfig.sh's `link()` uses $DIR (script location) as the
symlink source; it was last run from inside that worktree, so the symlink
pointed there instead of the main checkout. Re-running sshconfig.sh only
offers an interactive re-point confirmation (defaults to skip
non-interactively), so this could persist indefinitely without an explicit
check.

## Checklist
- [x] Added gist.github.com:22 to config/gost/agent-ssh-relay.yml
- [x] Removed now-unneeded HTTPS credential-helper fallback for gist.github.com in home/.gitconfig.d/claude-agent-home
- [x] Reloaded the agent-ssh-relay LaunchAgent (launchctl kickstart)
- [x] Fixed the dangling ~/.ssh/config.d/agent-relay symlink to point at the main checkout
- [x] Added gist.github.com known_hosts entries (same host keys as github.com)
- [x] Verified live SSH auth to both github.com and gist.github.com through the relay from an agent session
- [x] Updated stale comments in home/.gitconfig.d/claude-agent-home and home/.gitconfig.d/common referencing the now-removed interactive HTTPS rewrite (separate related change earlier this session)

## Follow-up worth considering
Nothing currently detects a wrong/dangling ~/.ssh/config.d symlink automatically --
it silently degrades to "sandbox blocks port 22" errors that look like a
completely different problem. Worth a taskwarrior task to add a doctor-style
check (e.g. to a `wt doctor`-alike or claudeconfig.sh) that verifies
~/.ssh/config.d/* symlinks resolve into the main dotfiles checkout, not a worktree.
