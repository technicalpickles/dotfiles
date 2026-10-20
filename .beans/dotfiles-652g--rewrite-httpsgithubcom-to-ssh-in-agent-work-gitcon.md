---
# dotfiles-652g
title: Rewrite https://github.com to SSH in agent work gitconfig
status: in-progress
type: bug
created_at: 2026-10-20T17:31:44Z
updated_at: 2026-10-20T17:31:44Z
---

Agent sessions fetching tracked repos with https:// remotes fell through to the system osxkeychain helper and prompted for a keychain password. 8a0831a removed the old HTTPS rewrite and gh helper when work moved to the relay but nothing covered existing https remotes. Adds url insteadOf https://github.com/ -> git@github.com: to claude-agent-work and fixes the stale CLAUDE.md work-role note.
