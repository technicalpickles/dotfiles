---
# dotfiles-npey
title: Make the private-repo comment exception a home-scoped rule
status: in-progress
type: task
created_at: 2026-11-17T13:26:26Z
updated_at: 2026-11-17T15:00:00Z
---

The private-repo comment exception lived in a memory scoped to the `~/github.com` project, so sessions in other projects still showed a draft before commenting on the user's own private repos. Make it a rule in `claude/rules/`, scoped to home and coi-host, since on work roles private repos belong to the employer and have an audience.

This started as a broader move of pickle-mode's general principles into always-loaded rules. Probes on 2026-11-17 showed trunk already behaved right on nine of ten scenarios, and an audit found several moved rules wrong on work roles or in pstack's stack runs, so the scope shrank to this one rule. Plan and evidence: ~/.claude/orchestrate/pickle-mode-split/docs/plan.md.

## Checklist
- [x] Add claude/rules/private-repo-comments.md with `dotpickles_role: home,coi-host`
- [x] Append "Stop and raise it instead." to "Understand before executing" in claude/CLAUDE.md
- [x] Probe: own private repo posts without a draft; org-owned private repo keeps the confirm step
- [ ] After merge, run ./claudeconfig.sh to link the new rule file
- [ ] Delete the comment-on-private-repo-prs memory once the rule is linked
