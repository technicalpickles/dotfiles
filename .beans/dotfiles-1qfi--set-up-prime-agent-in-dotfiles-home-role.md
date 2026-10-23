---
# dotfiles-1qfi
title: Set up prime-agent in dotfiles (home role)
status: in-progress
type: feature
created_at: 2026-10-23T14:43:57Z
updated_at: 2026-10-23T14:43:57Z
---

Make prime-agent usable under safe on a fresh machine. Findings: ~/.prime/agent doesn't exist and the sandbox can't create it (session lease EPERM); no fnox config on home so OPENROUTER_API_KEY never resolves. Decisions: key via /login inside prime-agent (stored in ~/.prime/agent, accepted gap in ADR 0064), scope = skills + install script + ADR.

## Checklist
- [x] prime.sh: create ~/.prime/agent, link shared skills
- [x] Wire prime.sh into install.sh
- [x] role-home.sb read grant for vault-linked skills (if linked on home)
- [x] Drop/soften fnox default for the key in tools/prime-agent.sh
- [x] ADR
- [ ] Verify end to end with safe prime-agent after merge (/login, one-shot prompt, writing-voice loads)
