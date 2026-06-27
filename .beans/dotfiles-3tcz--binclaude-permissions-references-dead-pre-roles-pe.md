---
# dotfiles-3tcz
title: bin/claude-permissions references dead pre-roles permission files + stale path
status: completed
type: bug
priority: low
created_at: 2026-06-23T19:03:41Z
updated_at: 2026-06-27T15:38:07Z
---

bin/claude-permissions is actively used (permissions-manager skill, claude/stacks/shell.jsonc allowlist, README), so it was fixed, not retired.

Root problems: it enumerated dead pre-roles files (claude/permissions.{,personal.,work.}json) under a stale ~/workspace/dotfiles path, and the project-local scan also assumed ~/workspace (which does not exist; projects live under ~/github.com/<org>/<repo>).

## Done

- [x] Dotfiles-template sources now glob claude/roles/*.jsonc + claude/stacks/*.jsonc, located relative to the script (__file__) so it resolves wherever the repo is cloned
- [x] Added string-aware JSONC comment stripper so the .jsonc role/stack files parse (loader only handled trailing commas before; // comments would break json.loads)
- [x] Project-local scan now globs ~/github.com/*/*/.claude/settings.local.json (ghq layout), listing only repos that actually have a local file
- [x] Verified: 27 sources found, 453 unique allows parsed, clean stderr, py_compile OK, summary/locations/aggregate all work
