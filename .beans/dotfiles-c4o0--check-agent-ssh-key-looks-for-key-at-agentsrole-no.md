---
# dotfiles-c4o0
title: check-agent-ssh-key looks for key at agents/<role> not the real identity
status: completed
type: bug
priority: high
created_at: 2026-06-27T01:57:54Z
updated_at: 2026-06-27T03:03:18Z
---

claudeconfig.sh's SSH validation failed for the home role: check-agent-ssh-key derived the key path from the role (~/.ssh/agents/home) instead of the actual identity (~/.ssh/agents/personal). Email already had a --email override read from the gitconfig include; the key path did not, so it told the user to run 'setup-agent-ssh-key home' (creating a wrong, non-enrolled identity).

Fix: add --key override to check-agent-ssh-key (accepts private or .pub path, strips .pub), derive identity name for setup hints from the key dir. claudeconfig.sh reads user.signingkey from the role's gitconfig include and passes --key, keeping the include the single source of truth. Works for both roles (work identity lives in agents/work, home in agents/personal).

Also surfaced: the personal key files had swapped perms (private 644, public 600). Fixed to 600/644. Likely a one-off from a vault restore, not a setup-agent-ssh-key bug (that script chmods correctly).

## Checklist

- [x] Add --key flag to check-agent-ssh-key, derive KEY_PATH/KEY_DIR/IDENTITY
- [x] setup hint uses identity name, not role
- [x] claudeconfig.sh reads signingkey + passes --key
- [x] Update usage text + bin/CLAUDE.md
- [x] Fix swapped key perms on ~/.ssh/agents/personal
- [x] Verify validator finds personal key + perms check passes
- [ ] User re-runs ./claudeconfig.sh end-to-end (network/gh checks)
