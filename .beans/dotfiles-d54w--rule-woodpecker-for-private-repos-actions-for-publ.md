---
# dotfiles-d54w
title: 'Rule: Woodpecker for private repos, Actions for public'
status: completed
type: task
created_at: 2026-11-16T02:18:50Z
updated_at: 2026-11-16T02:18:50Z
---

Global rule (claude/rules/ci.md) so sessions in any private repo default to Woodpecker instead of offering GitHub Actions. Evidence: public repos with CI all use Actions; the private repo with real CI runs only Woodpecker (image publish 37 s, 2026-11-15); 'we use woodpecker for CI' (2026-09-09) was only saved as one project's memory. Two private repos deviate (one Actions only, one both). ## Checklist - [x] write the rule - [x] run ./claudeconfig.sh after merge so the symlink exists - [x] decide whether the two deviating private repos should move (2026-11-16: pirpg already on Woodpecker, ghost theme stays on Actions)
