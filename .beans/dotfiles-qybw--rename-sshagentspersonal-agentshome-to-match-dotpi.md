---
# dotfiles-qybw
title: Rename ~/.ssh/agents/personal -> agents/home to match dotpickles role
status: completed
type: task
priority: normal
created_at: 2026-06-27T02:12:00Z
updated_at: 2026-06-27T02:15:26Z
---

Aligned the agent SSH key directory with the role name (home), reversing part of ADR 0035 (which kept it under agents/personal). Email stays joshua.nichols+personal-agent@gmail.com (GitHub-enrolled). Key has no passphrase and is loaded by fingerprint, so the move did not disrupt the live agent.

## Checklist

- [x] mv ~/.ssh/agents/personal -> ~/.ssh/agents/home
- [x] Re-add new path to ssh-agent/keychain (ssh-add --apple-use-keychain)
- [x] claude-agent-home: signingkey, sshCommand, comment -> agents/home
- [x] allowed_signers comment -> agents/home
- [x] agent.toml.home: backup comment + stale "personal role" header -> home
- [x] home.jsonc comment -> agents/home, recreate cmd uses --email
- [x] check-agent-ssh-key: usage + internal comment reworded (dir tracks role, email still differs)
- [x] setup/check help example role: personal -> home
- [x] ADR 0039 + README link + amend note on ADR 0035
- [x] Verify check-agent-ssh-key passes against agents/home (perms/agent/GitHub email OK)
- [x] npm run lint

Live already (gitconfig include is symlinked); no re-run required. Email re-enrollment to +home-agent deferred (noted in ADR 0039 negatives).
