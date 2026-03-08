---
# dotfiles-3w3q
title: Review and add host-specific git mergetool settings in .gitconfig.d
status: completed
type: task
priority: normal
created_at: 2026-03-08T19:45:55Z
updated_at: 2026-03-08T20:29:58Z
---

During a git pull conflict resolution session, we identified that mergetool configuration (especially with absolute paths like VS Code Insiders) should be host-specific rather than shared in the main .gitconfig.

## Resolution

Decided to remove VS Code mergetool support entirely since VS Code is not currently in use. Git does not have a built-in env var equivalent to \$EDITOR for merge tools, so config-based approaches are the only option.

## Checklist

- [x] Audit current .gitconfig.d/ contents and any existing includeIf patterns
- [x] Decide naming convention for host-specific gitconfig files
- [x] Remove vscode and vscode-macos from .gitconfig.d/
- [x] Remove [mergetool "code"] block from home/.gitconfig
- [x] Remove vscode detection block from gitconfig.sh
- [x] Remove vscode-macos include from .gitconfig.local
