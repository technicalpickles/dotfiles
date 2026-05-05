---
# dotfiles-h7kh
title: Consolidate DOTPICKLES_ROLE detection into single source of truth
status: in-progress
type: feature
priority: normal
created_at: 2026-04-26T19:08:53Z
updated_at: 2026-04-26T19:10:48Z
---

Five role-detection sites disagree (install.sh, config.fish, home/.zshenv, claudeconfig.sh, fish_variables) across three vocabularies (personal/work, home/work, personal/work/container). Consolidate to a canonical bash script bin/dotpickles-role with override file.

Plan: doc/plans/2026-04-26-consolidate-role-detection.md
Related: dotfiles-w9y9 (the home/personal naming clash that surfaced this)

## Checklist

- [ ] dotpickles-role-script: write bin/dotpickles-role + test/dotpickles-role.sh
- [ ] gitignore-override: add .dotpickles-role to .gitignore
- [ ] install-sh-uses-script: replace inline detection in install.sh
- [ ] fish-uses-script: config.fish calls script + evicts universal var
- [ ] rename-home-to-personal: update conf.d/git-duet.fish + conf.d/rustup.fish
- [ ] zshenv-uses-script: home/.zshenv calls script
- [ ] claudeconfig-warn-on-missing: claudeconfig.sh uses script + warns when role file missing
- [ ] docs-and-adr: update doc/architecture.md + write ADR 0021
- [ ] close-w9y9-and-h7kh: mark related beans complete
- [ ] final-verify: cross-shell consistency check + npm run lint
