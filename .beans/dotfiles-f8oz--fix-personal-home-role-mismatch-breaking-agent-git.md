---
# dotfiles-f8oz
title: Fix personal->home role mismatch breaking agent git identity
status: completed
type: bug
priority: high
created_at: 2026-06-12T01:53:13Z
updated_at: 2026-06-12T01:57:50Z
---

DOTPICKLES_ROLE=home had no matching claude/roles/home.jsonc (only personal.jsonc). claudeconfig.sh silently skipped the role merge, so ~/.claude/settings.json got no env block, GIT_CONFIG_GLOBAL was never set, and Claude git commits fell through to op-ssh-sign -> 1Password prompt every commit. Fixed by completing the personal->home role rename and adding a loud-fail guard.

## Checklist

- [x] git mv claude/roles/personal.jsonc -> home.jsonc
- [x] git mv home/.gitconfig.d/claude-agent-personal -> claude-agent-home
- [x] Update GIT_CONFIG_GLOBAL ref + comments in home.jsonc
- [x] Update comment in claude-agent-home (kept personal-agent identity)
- [x] Fix stale personal default in home/.zshenv
- [x] Fix stale DOTPICKLES_ROLE:personal in fish_variables (gitignored, local only)
- [x] claudeconfig.sh: default ROLE home + loud-fail guard for missing role file
- [x] Regenerate ~/.claude/settings.json (env.GIT_CONFIG_GLOBAL now present)
- [x] Relink not needed (~/.gitconfig.d is a symlinked dir)
- [x] Verified: ssh-keygen signs non-interactively, commit authored as personal-agent, no 1Password prompt

Note: local git log --show-signature shows No signature because gpg.ssh.allowedSignersFile is unset; GitHub still shows Verified via enrolled key. Optional follow-up if local verification matters.
