# 41. Project-level Claude plugin bootstrap

Date: 2026-06-28

## Status

Accepted

## Context

Claude Code on the web (cloud) clones a repo fresh into an ephemeral container
with no global `~/.claude`. Plugins and marketplaces only load there if they are
declared in the repo's **committed** `.claude/settings.json` (via
`extraKnownMarketplaces` + `enabledPlugins`). Until now the only example of that
was this repo's own hand-written `.claude/settings.json`; there was no repeatable
way to apply a recommended set to other personal repos.

Separately, the marketplace list was hardcoded in two places that could drift: the
`marketplaces=(...)` array in `claudeconfig.sh::configure_marketplaces()` (global
clones) and any per-repo settings written by hand.

## Decision

Add a single shared manifest, `claude/marketplaces.jsonc`, as the source of truth
for marketplaces (alias -> GitHub repo) and named plugin profiles (`core`, `dev`;
default `dev`). Two consumers read it:

- `claudeconfig.sh::configure_marketplaces()` builds its clone list from the
  manifest instead of a hardcoded array.
- A new `claude-project-setup.sh [TARGET_DIR] [--profile NAME] [--dry-run]`
  resolves a profile to `extraKnownMarketplaces` + `enabledPlugins` and **merges**
  them into the target repo's committed `.claude/settings.json`, touching only
  those two keys (permissions/hooks/env survive; our entries win on collision so
  re-runs refresh). Atomic write + `jq empty` validation + one-time `.backup`,
  mirroring `claudeconfig.sh`.

The shared `read_json()` JSONC parser moved from `claudeconfig.sh` into
`functions.sh` so both scripts use it.

Marketplace keys in the manifest are local aliases; `enabledPlugins` references
them as `<plugin>@<alias>`. The plugin and marketplace names were verified against
each upstream repo's `.claude-plugin/marketplace.json`. Notably, the superpowers
family (superpowers, elements-of-style, ...) lives in the umbrella
`obra/superpowers-marketplace`, not bare `obra/superpowers`, and the git plugin in
`pickled-claude-plugins` is named `git` (not `git-workflows`).

### Alternatives Considered

1. **Hardcode the list in each script**
   - Rejected: that is the drift this ADR removes.
2. **Reuse `claude/profiles/*.json`**
   - Cons: those are git+branch+path dependency lists (a different model); path
     deps don't map to a `plugin@marketplace` key.
   - Rejected: wrong shape for `enabledPlugins`.
3. **Write `.claude/settings.local.json`**
   - Rejected: it is gitignored, so cloud (which only reads committed files) can't
     see it.

## Consequences

### Positive

- One command sets any repo up for a good cloud experience; one manifest to edit.
- `configure_marketplaces()` and per-repo settings can't drift.
- Fixed a latent bug: `superpowers-marketplace` now points at the umbrella repo.

### Negative

- The manifest's plugin/marketplace strings must stay in sync with upstream
  marketplace.json `name` fields; a rename upstream silently breaks a profile
  until the manifest is updated.
- `claude-project-setup.sh` writes a committed file; the user must still commit it.
