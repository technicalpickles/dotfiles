---
# dotfiles-wswz
title: 1Password SSH agent allowlist not installed (agent key being offered)
status: completed
type: bug
priority: normal
created_at: 2026-06-22T02:35:41Z
updated_at: 2026-06-22T02:36:03Z
---

1Password's SSH agent is offering all vault keys, including ~/.ssh/agents/personal/id_ed25519 (the claude-agent key from ADR 0031) and 'brineworks-agent - iPhone SSH key', neither of which are in the home allowlist. Root cause: ~/.config/1Password/ssh/agent.toml symlink was never created (dir doesn't exist), so the ADR 0033 allowlist isn't in effect. sshconfig.sh hasn't been run since ADR 0033 landed. Fix: run sshconfig.sh to install the role-scoped allowlist symlink, then verify ssh-add -l against the 1Password socket only shows the 3 allowlisted home keys.
