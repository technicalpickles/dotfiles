---
# dotfiles-cwre
title: Claude Code cloud setup - claude-code-remote role + per-project plugin bootstrap
status: completed
type: feature
priority: normal
created_at: 2026-06-28T17:54:20Z
updated_at: 2026-06-28T18:20:00Z
---

Make personal GitHub repos behave well in Claude Code on the web (cloud), where
the repo is cloned fresh into an ephemeral container with no global `~/.claude`.

Two complementary pieces, unified by a single shared manifest so the
marketplace/plugin list lives in exactly one place:

1. **Per-repo plugins/marketplaces.** Cloud only reads a repo's *committed*
   `.claude/settings.json`. A new `claude-project-setup.sh` stamps a recommended
   set (`extraKnownMarketplaces` + `enabledPlugins`) onto any repo, merging
   without clobbering existing keys.
2. **A `claude-code-remote` role.** Detected via `CLAUDE_CODE_REMOTE=true`. Cloud
   is already sandboxed (`IS_SANDBOX=yes`) and git auth goes through the GitHub
   integration, so the role disables the dotfiles sandbox, skips the agent SSH
   identity, and strips macOS-only bits.

While touching the role plumbing, do the full pre-existing cleanup: claudeconfig
default `personal` -> `home`, rename `personal.jsonc` -> `home.jsonc`, add
`container.jsonc`, fix `gitconfig.sh` cases, unify detection across the three
shells.

Full plan: see the approved plan file.

## Checklist
- [x] Part A: add `claude/marketplaces.jsonc` shared manifest (verified real
      plugin@marketplace names: superpowers family lives in the umbrella
      obra/superpowers-marketplace; the git plugin is `git` not `git-workflows`)
- [x] Part B: move `read_json()` from claudeconfig.sh into functions.sh
- [x] Part C1: new role file `claude/roles/claude-code-remote.jsonc` (sandbox off)
- [x] Part C2: unify detection (claude-code-remote -> container -> work -> home)
      in install.sh, config/fish/conf.d/dotpickles-role.fish, home/.zshenv
- [x] Part C3: claudeconfig default -> home; rename personal.jsonc -> home.jsonc;
      add container.jsonc; fix gitconfig.sh case statement
- [x] Part D: new `claude-project-setup.sh` (merge-not-clobber committed settings)
- [x] Part E: refactor configure_marketplaces() to read the manifest
- [x] Part F: document cloud bootstrap (claudeconfig.sh standalone) + install.sh audit
- [x] ADR 0039 (project plugin bootstrap) + ADR 0040 (claude-code-remote role) +
      doc/adr/README.md entries + doc/architecture.md role section
- [x] Verify: format:check passes for all touched/new files (typecheck fails on a
      pre-existing tsconfig deprecation, unrelated); claude-project-setup.sh
      end-to-end (dry-run + real merge preserving permissions); claude-code-remote
      sandbox override confirmed (base true -> merged false)

## Note: prettier normalized two stale files

`claudeconfig.sh` and `gitconfig.sh` were the only 2 of 42 committed `.sh` files
that failed the repo's prettier (stale 2-space `case` indentation). Formatting them
to conform reindents their `case` blocks (~54 lines of whitespace beyond the
logical edits), matching the other 40 files and what lefthook would produce.
