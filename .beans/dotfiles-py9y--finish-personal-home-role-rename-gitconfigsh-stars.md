---
# dotfiles-py9y
title: Finish personal->home role rename (gitconfig.sh + starship prompt)
status: completed
type: bug
priority: normal
created_at: 2026-06-22T02:19:07Z
updated_at: 2026-06-22T02:22:17Z
---

Commit e3e5027 renamed DOTPICKLES_ROLE personal->home but missed two files. Both fixed, plus docs captured.

## Checklist
- [x] gitconfig.sh: rename `personal)` case to `home)` (keep personal-identity include path)
- [x] Fix fish role detection so DOTPICKLES_ROLE is set before starship-init reads it (extracted to conf.d/dotpickles-role.fish, removed from config.fish, fixed starship fallback personal->home)
- [x] Verify gitconfig.sh runs and prompt reflects real role (bash -n + fish simulation: ctx=home)
- [x] Docs: architecture.md (fish path + conf.d ordering note), config/fish/CLAUDE.md (Load Order Gotcha section), ADR 0035 (added gitconfig.sh + starship fallback to consumers, conf.d placement note)
