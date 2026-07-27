---
# dotfiles-h7kh
title: Consolidate DOTPICKLES_ROLE detection into single source of truth
status: in-progress
type: feature
priority: normal
created_at: 2026-04-26T19:08:53Z
updated_at: 2026-06-27T01:52:27Z
---

Five role-detection sites disagree (install.sh, config.fish, home/.zshenv, claudeconfig.sh, fish_variables) across three vocabularies. Consolidate to a canonical source with override file.

Plan: doc/plans/2026-04-26-consolidate-role-detection.md
Related: dotfiles-w9y9 (naming clash), dotfiles-y9zc (rename re-apply)

UPDATE 2026-06-26: the BASH setup scripts (install.sh, gitconfig.sh, claudeconfig.sh, sshconfig.sh) are now consolidated via dotpickles_detect_role() in functions.sh, which they all source. That fixed the standalone-run failure. Remaining h7kh scope: the cross-shell bin/dotpickles-role exec d by fish + zsh so all three shells share ONE detector (functions.sh covers bash only; fish/zsh still have their own copies, which ADR 0035 notes is hard to avoid).

## Checklist

- [ ] dotpickles-role-script: write bin/dotpickles-role + test/dotpickles-role.sh
- [ ] gitignore-override: add .dotpickles-role to .gitignore
- [x] install-sh-uses-script: install.sh detection consolidated (via functions.sh)
- [ ] fish-uses-script: config.fish calls script + evicts universal var
- [ ] zshenv-uses-script: home/.zshenv calls script
- [x] claudeconfig-uses-shared: sources functions.sh detector; warns when role file missing
- [ ] docs-and-adr: update doc/architecture.md + write ADR
- [ ] close-w9y9-and-h7kh: mark related beans complete
- [ ] final-verify: cross-shell consistency check + npm run lint
