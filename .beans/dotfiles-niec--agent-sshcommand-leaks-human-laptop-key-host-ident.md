---
# dotfiles-niec
title: Agent sshCommand leaks human laptop key (Host * IdentityFile)
status: completed
type: bug
priority: high
created_at: 2026-06-13T14:30:50Z
updated_at: 2026-06-13T14:30:50Z
---

## Symptom

Claude agent git operations under DOTPICKLES_ROLE=work/home can authenticate to GitHub with the *human* laptop key (~/.ssh/id_ed25519, josh.nichols@gusto.com) instead of the dedicated agent key, or hard-fail headless. Observed in pickletown session 3a4fb651 (2026-06-12):

    sign_and_send_pubkey: signing failed for ED25519 "Gusto Laptop id_ed25519" from agent: communication with agent failed

In that same session, commit 668a7956 was authored+signed as josh.nichols+agent@gusto.com, proving GIT_CONFIG_GLOBAL/user.email/signingkey WERE active. Only the SSH *transport* picked the wrong key.

## Root cause

core.sshCommand in claude-agent-{work,home}:

    ssh -i ~/.ssh/agents/<role>/id_ed25519 -o IdentitiesOnly=yes -o IdentityAgent=SSH_AUTH_SOCK

IdentityAgent=SSH_AUTH_SOCK correctly overrides the 1Password Host * agent (command-line wins). BUT IdentityFile is *additive*, not first-wins: ~/.ssh/config 'Host *' adds 'IdentityFile ~/.ssh/id_ed25519' (laptop key), and IdentitiesOnly=yes keeps it as a candidate. So ssh has two eligible identities. When the session's SSH_AUTH_SOCK points at an agent that can't sign the laptop key (1Password headless, or stale/dead socket), the laptop-key attempt tanks the whole op. Even when healthy, ssh can offer the laptop key and auth as the human, silently defeating the agent identity.

## Fix

Add -F /dev/null to the agent sshCommand so ssh ignores ~/.ssh/config entirely (no Host * IdentityFile leak, no 1Password Host * IdentityAgent). IdentityAgent=SSH_AUTH_SOCK still resolves (env var, not config). Verified safe: no github.com-specific Host block in ~/.ssh/config.d/ that this would drop; known_hosts is unaffected by -F.

## Also

allowed_signers was missing the work-agent identity (josh.nichols+agent@gusto.com + work-agent pubkey), so +agent commits verify as U (untrusted) locally. The file says to append work-role identities; do it.

## Checklist
- [x] Add -F /dev/null to claude-agent-work sshCommand
- [x] Add -F /dev/null to claude-agent-home sshCommand
- [x] Append work-agent identity to allowed_signers
- [x] Update ADR 0031 subtlety note (IdentityAgent rationale shifts with -F /dev/null)
- [x] Verify a real git fetch uses the work key (ssh -v)

## Verification (2026-06-13)

`ssh -vT git@github.com` via the new sshCommand offers ONLY the work key
(`SHA256:mwyw…`) and authenticates; the old command offered the laptop key
(`SHA256:bo+X…`) first and authed as the human. `git verify-commit 668a7956`
now reports "Good git signature for josh.nichols+agent@gusto.com" (was `U`).
