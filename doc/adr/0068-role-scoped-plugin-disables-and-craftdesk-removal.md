# 68. Role-scoped plugin disables and craftdesk removal

Date: 2026-10-28

## Status

Accepted

## Context

A `/skill-doctor` pass flagged plugins that hadn't been used recently. Acting on it surfaced two gaps in how dotfiles manages Claude Code plugins:

- **Removing a plugin had no source of truth.** `enabledPlugins` is local-only state: `claudeconfig.sh` preserves it across regenerations instead of writing it ([ADR 13](0013-claude-code-configuration-management.md)). So "disable `github-actions` on work machines" had nowhere to live. The only declared plugin lists are the `core` and `dev` profiles in `claude/marketplaces.jsonc`, which feed `cloud-project-setup.sh` and say nothing about roles.
- **Dead config was still around.** `claude/profiles/*.json` were templates for `craftdesk-setup`, added 2026-01-08. Craftdesk is no longer used, and `marketplaces.jsonc` profiles took over the job of naming plugin bundles ([ADR 41](0041-project-level-claude-plugin-bootstrap.md)). `bin/analyze-claude-sessions` existed only to prioritize the craftdesk migration.

## Decision

- **`marketplaces.jsonc` gets a top-level `disabledPlugins` map**, `"<plugin>@<marketplace>": [roles]`. It mirrors `excludeRoles` on marketplaces: the manifest names roles, the script filters on `$DOTPICKLES_ROLE`. It starts with `github-actions@pickled-claude-plugins` for `work` and `work-coder`.
- **`claude/configure-marketplaces.sh` applies it** with `claude plugin disable <id> --scope user`. It already runs from `claudeconfig.sh` and standalone (Coder's `coder-setup.sh`), so both paths get it. The CLI call is idempotent in effect: "already disabled" counts as success, and a plugin that isn't installed is skipped with a note.
- **Disable only, no declarative uninstall.** Uninstalling stays a manual `claude plugin uninstall`, because the manifest has no notion of "should be installed". Dropping a plugin from the `core` and `dev` profiles (`elements-of-style` here) covers the cloud-project case.
- **Craftdesk is removed**: `claude/profiles/`, `bin/craftdesk-setup`, `bin/craftdesk-setup-test` and `bin/analyze-claude-sessions`. The craftdesk plans under `doc/plans/` stay as history.
- **Sandbox and docs follow the plugin removals.** `~/.plannotator` leaves the `allowWrite` list in `claude/stacks/claude.jsonc` and `claude/README.md`, since plannotator is uninstalled.

### Alternatives Considered

1. **Role files write `enabledPlugins`**
   - Pros: no CLI call, one generated `settings.json`.
   - Cons: `enabledPlugins` is deliberately preserved from the existing file so `/plugin` toggles survive. Writing it from roles would either clobber those or need a merge rule that decides who wins per key.
2. **A `plugins` section in each role file**
   - Pros: sits next to the other per-role settings.
   - Cons: the role files are merged into `settings.json`, so an unknown key would leak into it unless filtered out. It also splits plugin config across two places while marketplaces and pins already live in `marketplaces.jsonc`.
3. **Leave the disable as local state**
   - Pros: nothing to build.
   - Cons: a fresh work machine or Coder workspace re-enables the plugin, and nothing records why it was off.

## Consequences

- A new work machine, or a Coder workspace, gets `github-actions` disabled without anyone remembering to do it.
- The script re-disables the plugin on each run, so enabling it by hand on a work role doesn't survive the next `claudeconfig.sh`. Remove the entry from `disabledPlugins` to keep it on.
- Disables apply at user scope only. Project or local-scope enablement is untouched.
- Local-scope plugin records pointing at deleted worktrees can't be uninstalled through the CLI. They stay in `installed_plugins.json` until someone cleans that file by hand.
