---
# dotfiles-xhsm
title: Populate launchd's ssh-agent at login so unattended jobs can sign commits
status: in-progress
type: bug
tags:
    - agent-git-identity
created_at: 2026-08-12T17:39:29Z
updated_at: 2026-08-12T17:39:29Z
---

macOS has two ssh-agents and only one was populated.

- launchd's (/var/run/com.apple.launchd.*/Listeners) goes to every scheduled job and starts empty every login; nothing filled it.
- fish-ssh-agent's (~/.ssh/agent/s.*) reaches interactive shells and is filled by config/fish/conf.d/ssh-keychain.fish.

So commit signing worked in a terminal and failed under launchd. ADR 0031's identity sets gpg.ssh.program=ssh-keygen, and ssh-keygen honours no UseKeychain, so a passphrase-protected key prompts on a tty that isn't there. Cost a full unattended run before failing on 'fatal: failed to write commit object'.

Fix: bin/load-agent-ssh-keys + com.technicalpickles.agent-ssh-keys.plist (RunAtLoad), the missing half of the ssh-keychain.fish pattern.

## Checklist

- [x] bin/load-agent-ssh-keys (idempotent, globs ~/.ssh/agents/*/)
- [x] LaunchAgents/com.technicalpickles.agent-ssh-keys.plist
- [x] Verified end-to-end from a flushed launchd agent: real commit signs G as the agent identity
- [x] Document in LaunchAgents/README.md and bin/CLAUDE.md
- [x] Note in check-agent-ssh-key that its agent check only covers the current shell
