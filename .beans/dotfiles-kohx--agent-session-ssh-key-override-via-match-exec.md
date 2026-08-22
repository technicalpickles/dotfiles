---
# dotfiles-kohx
title: Agent-session SSH key override via Match exec
status: completed
type: task
created_at: 2026-08-22T20:44:45Z
updated_at: 2026-08-22T20:44:45Z
---

Plain \`ssh <host>\` from a Claude Code session was hitting 1Password's TouchID-gated IdentityAgent, same class of problem ADR 0031 solved for git-over-SSH but not for direct ssh. Fixed by adding \`Match exec\` blocks to ssh/config.d/auth, keyed on \$CLAUDECODE + \$DOTPICKLES_ROLE, that redirect to the Keychain-loaded per-role agent key over fish-ssh-agent -- no TouchID, works for any host once the key is authorized there, no per-host config needed. Verified end-to-end against picklelab after adding the agent key's public half to its authorized_keys.

## Checklist
- [x] Add Match exec blocks to ssh/config.d/auth
- [x] Document mechanism in ssh/CLAUDE.md
- [x] Verify with \`ssh -G\` (with/without \$CLAUDECODE) and a live \`ssh picklelab\`
- [x] Write ADR 0048 recording the decision and alternatives considered
- [x] Commit changes
