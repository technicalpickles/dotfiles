---
# dotfiles-wfq3
title: Add gpg.ssh.allowedSignersFile for local commit verification
status: completed
type: feature
priority: normal
created_at: 2026-06-12T23:16:08Z
updated_at: 2026-06-12T23:19:44Z
---

Added local SSH allowed-signers trust file so git can verify SSH-signed commits locally.

## Checklist

- [x] Create home/.gitconfig.d/allowed_signers with human + personal-agent identities
- [x] Add allowedSignersFile to home/.gitconfig.d/signing
- [x] Verify git log --show-signature reports Good signature (HEAD 7e45125 = G)
- [x] Write ADR 0034

Result: personal-agent + personal-human commits verify as G. Work-agent commits show U (No principal matched) until work identity is appended. GitHub PR-merge commits show E (GPG/RSA, not SSH). All expected.
