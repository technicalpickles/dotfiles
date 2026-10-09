---
# dotfiles-gp5r
title: Install lefthook hooks in the dotfiles clone
status: todo
type: task
created_at: 2026-10-04T18:35:18Z
updated_at: 2026-10-04T18:35:18Z
---

lefthook isn't installed in this clone: .git/hooks only has samples and core.hooksPath is unset. So the pre-commit prettier/typecheck hooks in lefthook.yml never run (found during the hardened-brew branch, where a commit with syntax prettier's sh parser rejects went through). Run `lefthook install` in the main checkout and check it applies to worktrees too. Consider adding it to install.sh or dotfiles-doctor.
