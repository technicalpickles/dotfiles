---
# dotfiles-se8i
title: Investigate git:commit skill's use of -t vs -F for commit messages
status: todo
type: task
created_at: 2026-08-27T23:36:37Z
updated_at: 2026-08-27T23:36:37Z
---

The git:commit skill (pickled-claude-plugins, git/3.2.0/skills/commit/SKILL.md) instructs agents to run 'git commit -t scratch/path-to-message.txt' to commit from a saved message file. That failed today: '-t' sets a commit *template* and expects an interactive editor session to edit/confirm it -- there's no editor in a non-interactive agent shell, so it aborted with 'Aborting commit; you did not edit the message.' Had to fall back to 'git commit -F scratch/path-to-message.txt', which reads the file directly as the final message with no edit step.

Investigate whether the skill should just say -F instead of -t, or whether -t is intentional for some other (interactive) use case the skill author had in mind. If it's a plain bug, fix it upstream in the pickled-claude-plugins git plugin (dotfiles doesn't own that repo, so this may mean filing/fixing it there, not here).
