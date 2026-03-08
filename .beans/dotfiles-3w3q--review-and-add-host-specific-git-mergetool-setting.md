---
# dotfiles-3w3q
title: Review and add host-specific git mergetool settings in .gitconfig.d
status: todo
type: task
created_at: 2026-03-08T19:45:55Z
updated_at: 2026-03-08T19:45:55Z
---

During a git pull conflict resolution session, we identified that mergetool configuration (especially with absolute paths like VS Code Insiders) should be host-specific rather than shared in the main .gitconfig.

## Context

The shared home/.gitconfig currently has:

- [merge] conflictstyle = merge

But mergetool definitions with hardcoded paths (e.g. VS Code Insiders) should live in host-specific config files. The pattern for this is .gitconfig.d/ with includeIf directives.

## Plan

- Review the current .gitconfig.d/ directory structure
- Decide on naming convention for host-specific files
- Add mergetool definitions (e.g. mergetool 'code' with VS Code Insiders path)
- Consider whether 'tool = code' should also be host-specific or stay shared

## Checklist

- [ ] Audit current .gitconfig.d/ contents and any existing includeIf patterns
- [ ] Decide naming convention for host-specific gitconfig files
- [ ] Add host-specific mergetool definition for VS Code Insiders
- [ ] Wire up the include in home/.gitconfig
