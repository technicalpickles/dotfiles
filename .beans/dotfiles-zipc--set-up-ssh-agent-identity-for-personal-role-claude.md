---
# dotfiles-zipc
title: Set up SSH agent identity for personal role Claude sessions
status: completed
type: feature
priority: normal
created_at: 2026-04-18T15:50:47Z
updated_at: 2026-04-18T16:16:03Z
---

Add a separate SSH key + email identity for Claude Code sessions running under the personal role, so autonomous agents can push and sign commits without needing interactive 1Password GPG approval.

## Design (decided 2026-04-18)

- Key: ~/.ssh/agents/personal/id_ed25519, passphrase in macOS Keychain, auto-loaded by existing config/fish/conf.d/ssh-keychain.fish (ADR 0030)
- Email: joshua.nichols+personal-agent@gmail.com (verified on GitHub)
- Public key registered on GitHub as both auth key and signing key
- Per-role env vars in claude/roles/personal.jsonc set GIT_SSH_COMMAND, committer/author email, and user.signingkey via GIT_CONFIG_COUNT/KEY/VALUE trio
- GIT_SSH_COMMAND uses -o IdentityAgent=SSH_AUTH_SOCK to bypass the 1Password IdentityAgent configured for Host \*
- Work role identity deferred until work context needs it

## Checklist

- [x] Write bin/setup-agent-ssh-key script (idempotent, prints checklist of manual GitHub steps)
- [x] Add env block to claude/roles/personal.jsonc
- [x] Write ADR 0031 documenting the role-scoped agent identity pattern
- [x] Update doc/adr/README.md
- [x] Write bin/check-agent-ssh-key validator (local files, Keychain, GitHub registration, settings.json, ssh auth)
- [x] Update bin/CLAUDE.md with both scripts
- [x] gh auth refresh for user:email,read:public_key,read:ssh_signing_key
- [x] Upload pub key to GitHub as auth key and signing key
- [x] Verify joshua.nichols+personal-agent@gmail.com on GitHub
- [x] DOTPICKLES_ROLE=personal ./claudeconfig.sh (from non-sandboxed shell)
- [x] bin/check-agent-ssh-key personal passes all 8 checks
