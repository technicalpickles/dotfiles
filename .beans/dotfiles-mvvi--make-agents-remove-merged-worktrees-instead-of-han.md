---
# dotfiles-mvvi
title: Make agents remove merged worktrees instead of handing it back
status: completed
type: task
priority: normal
created_at: 2026-11-17T12:32:59Z
updated_at: 2026-11-17T12:45:31Z
---

claude/rules/worktrees.md loaded ~500 words into every session, but only ~12% of sessions (218 of 1739 since 2026-10-17) ran wt. Its cleanup line ('remove it yourself or leave it if the user is still working there') also let agents hand wt remove back to Josh. Moved the wt mechanics and a remove-after-merge rule into the git:git-worktrees skill plus a gh pr merge PostToolUse hook in pickled-claude-plugins (git 3.6.0). This rule keeps the preference, a pointer to the skill, and the two push bullets that apply to every agent branch.
