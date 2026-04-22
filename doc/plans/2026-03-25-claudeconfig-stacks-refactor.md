# Claudeconfig Stacks Refactor

**Date:** 2026-03-25
**Status:** Implemented
**Scope:** `claude/` directory structure + `claudeconfig.sh` merge logic

## Problem

The Claude Code configuration system in dotfiles uses flat `permissions.*.json` files that only support permission rules (`allow`/`ask`/`deny`). With the introduction of sandbox configuration (network allowed hosts, filesystem write paths), there's no place to co-locate sandbox config with the permissions for the same tool/ecosystem. The sandbox config currently lives only in `~/.claude/settings.json` and gets wiped when `claudeconfig.sh` regenerates.

Additionally, several settings accumulated during agent-safehouse work need to be captured in version-controlled source files.

## Goals

1. Co-locate permissions and sandbox config per topic ("stack")
2. Capture all sandbox config from the live settings.json into source files
3. Clean separation between roles (base/personal/work) and stacks (tool ecosystems)
4. Updated merge logic in `claudeconfig.sh` that handles the new schema
5. Updated documentation

## Non-Goals

- Changing how `enabledPlugins` is managed (tracked separately)
- Changing the role system (personal/work) itself
- Adding new permissions not already in the live settings (exception: `Read(~/.claude/plugins/cache/**)` added to reduce per-skill permission prompts)

## File Structure

### Before

```
claude/
  settings.base.json
  settings.personal.json
  settings.work.json
  permissions.json            # base safety rules
  permissions.personal.json
  permissions.work.json
  permissions.beans.json
  permissions.colima.json
  permissions.docker.json
  permissions.git.jsonc
  permissions.github.json
  permissions.go.json
  permissions.mcp.json
  permissions.mise.json
  permissions.node.json
  permissions.python.json
  permissions.ruby.json
  permissions.rust.json
  permissions.shell.json
  permissions.skills.json
  permissions.web.json
```

### After

```
claude/
  roles/
    base.jsonc         # settings.base.json + permissions.json merged
    personal.jsonc     # settings.personal.json + permissions.personal.json merged
    work.jsonc         # settings.work.json + permissions.work.json merged
  stacks/
    beans.jsonc
    buildkite.jsonc    # NEW
    colima.jsonc
    docker.jsonc
    docs.jsonc         # NEW (misc reference documentation sites)
    git.jsonc
    github.jsonc
    go.jsonc
    mcp.jsonc
    mise.jsonc
    node.jsonc
    python.jsonc
    ruby.jsonc
    rust.jsonc
    shell.jsonc
    skills.jsonc
  CLAUDE.md
  README.md            # updated
```

`permissions.web.json` is eliminated. Its domains distribute to topic stacks and `stacks/docs.jsonc`.

Unchanged directories (not part of this refactor): `claude/profiles/`, `claude/skills/`, `claude/CLAUDE.md`.

## Schema

### Stack Files

All files use JSONC (`.jsonc`), allowing `//` and `/* */` comments. Use comments to document where config came from (e.g. `// source: agent-safehouse`) or why a rule exists. Each stack file supports three optional top-level keys.

```json
{
  "permissions": {
    "allow": [],
    "ask": [],
    "deny": []
  },
  "sandbox": {
    "network": {
      "allowedHosts": []
    },
    "filesystem": {
      "allowWrite": []
    }
  }
}
```

All keys are optional. A stack can have only `permissions`, only `sandbox`, or both.

### Role Files

Role files keep their existing settings keys and add the same `permissions` and `sandbox` keys:

```json
{
  "statusLine": { "..." },
  "includeCoAuthoredBy": true,
  "permissions": {
    "allow": [],
    "ask": [],
    "deny": []
  },
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "enableWeakerNetworkIsolation": true,
    "network": {
      "allowedHosts": []
    }
  }
}
```

Sandbox scalar settings (`enabled`, `autoAllowBashIfSandboxed`, `enableWeakerNetworkIsolation`) live in roles only. Stacks only contribute to arrays.

## Sandbox Config Distribution

All config below was captured from the live `~/.claude/settings.json` (source: agent-safehouse session 2026-03-25).

### roles/base.jsonc

Settings:
- `statusLine`, `includeCoAuthoredBy`

Sandbox scalars:
- `enabled: true`
- `autoAllowBashIfSandboxed: true`
- `enableWeakerNetworkIsolation: true`

Sandbox network:
- `api.anthropic.com` (claude infrastructure)
- `code.claude.com` (claude docs)

Permissions (from current `permissions.json`):
- All base safety `allow`/`ask`/`deny` rules
- NEW: `Read(~/.claude/plugins/cache/**)`
- From old `web.json`: `WebFetch(domain:code.claude.com)`

### roles/work.jsonc

Settings:
- `awsAuthRefresh`, `env` (AWS/Bedrock config)

Permissions (from current `permissions.work.json`):
- `Bash(npx bktide:*)`, `Bash(bundle install)`, etc.

Sandbox network:
- `portal.sso.us-west-2.amazonaws.com` (AWS SSO)

### stacks/mise.jsonc

Sandbox network: `mise.jdx.dev`, `mise-versions.jdx.dev`

Sandbox filesystem: `~/.local/share/mise`, `~/.config/mise`, `~/.local/state/mise`, `~/.cache/mise`, `~/Library/Caches/mise`

WebFetch permission (from old `web.json`): `WebFetch(domain:mise.jdx.dev)`

### stacks/github.jsonc

Sandbox network: `api.github.com`, `github.com`, `docs.github.com`, `raw.githubusercontent.com`

Sandbox filesystem: `~/.config/gh`, `~/.cache/gh`, `~/.local/share/gh`, `~/.local/state/gh`

WebFetch permissions (from old `web.json`): `WebFetch(domain:docs.github.com)`, `WebFetch(domain:github.com)`, `WebFetch(domain:raw.githubusercontent.com)`

### stacks/node.jsonc

Sandbox network: `registry.npmjs.org`

Sandbox filesystem:
- npm: `~/.npm`, `~/.config/npm`, `~/.cache/npm`, `~/.cache/node`, `~/.node-gyp`, `~/.cache/node-gyp`, `~/.config/configstore`, `~/Library/Caches/npm`
- pnpm: `~/.config/pnpm`, `~/.pnpm-state`, `~/.pnpm-store`, `~/.local/share/pnpm`, `~/.local/state/pnpm`, `~/Library/pnpm`, `~/Library/Caches/pnpm`, `~/Library/Preferences/pnpm`
- yarn: `~/.yarn`, `~/.yarnrc`, `~/.yarnrc.yml`, `~/.config/yarn`, `~/.cache/yarn`, `~/Library/Caches/Yarn`
- corepack: `~/.cache/node/corepack`, `~/Library/Caches/node/corepack`
- test browsers: `~/Library/Caches/ms-playwright`, `~/Library/Caches/Cypress`, `~/.cache/puppeteer`

### stacks/ruby.jsonc

Sandbox filesystem: `~/.bundle`, `~/.gem`, `~/.cache/bundler`, `~/.cache/rubygems`, `~/Library/Caches/bundle`, `~/.rbenv`

### stacks/go.jsonc

Sandbox filesystem: `~/go`, `~/.cache/go-build`, `~/Library/Caches/go-build`, `~/.config/go`, `~/.cache/golangci-lint`, `~/Library/Caches/golangci-lint`, `~/.local/share/go`

### stacks/rust.jsonc

Sandbox filesystem: `~/.cargo`, `~/.rustup`, `~/.cache/cargo`, `~/Library/Caches/cargo`

### stacks/python.jsonc

Sandbox filesystem: `~/.cache/uv`, `~/.cache/pip`, `~/.config/uv`, `~/.local/share/uv`, `~/.local/state/uv`, `~/Library/Caches/uv`, `~/Library/Caches/pip`, `~/.cache/pre-commit`

### stacks/docker.jsonc

Sandbox filesystem: `~/.docker`

### stacks/colima.jsonc

Sandbox filesystem: `~/.colima`

### stacks/buildkite.jsonc (NEW)

Sandbox network: `buildkite.com`

Sandbox filesystem: `~/.local/state/bktide`

### stacks/git.jsonc (already JSONC)

Sandbox network: `hk.jdx.dev` (hk git hooks tool)

WebFetch permission: `WebFetch(domain:hk.jdx.dev)` (moves from old web.json)

### stacks/shell.jsonc

Sandbox network: `formulae.brew.sh` (Homebrew)

### stacks/skills.jsonc

Permissions only (no sandbox config). Carries forward all `Skill(...)` allow rules from current `permissions.skills.json` unchanged.

### stacks/mcp.jsonc

Permissions only (no sandbox config). Carries forward MCP `allow`/`ask` rules from current `permissions.mcp.json` unchanged.

### stacks/beans.jsonc

Permissions only (no sandbox config). Carries forward `beans` allow/ask rules from current `permissions.beans.json` unchanged.

### stacks/docs.jsonc (NEW)

Sandbox network: `karafka.io`, `lima-vm.io`

WebFetch permissions: `WebFetch(domain:karafka.io)`, `WebFetch(domain:lima-vm.io)`

## Merge Logic

### Order

**Important:** Permissions and sandbox arrays are extracted separately from each role file and concatenated, not deep-merged. jq's `*` operator replaces arrays rather than concatenating them, so a naive deep merge of role files would lose base permissions when the specific role also has permissions.

1. Load `roles/base.jsonc`: extract settings keys (everything except `permissions` and `sandbox`), permissions arrays, and sandbox config (scalars + arrays)
2. Load `roles/<role>.jsonc`: deep merge settings keys on top of base. Extract permissions arrays and sandbox arrays separately.
3. Concat base + role permissions arrays and sandbox arrays (base first, then role)
4. For each `stacks/*.jsonc` (sorted alphabetically for determinism):
   - Concat `permissions.allow`, `.ask`, `.deny`
   - Concat `sandbox.network.allowedHosts`
   - Concat `sandbox.filesystem.allowWrite`
5. Dedup and sort all arrays
6. Assemble final JSON: merged settings + permissions + sandbox
7. Merge in `local_keys` from existing `~/.claude/settings.json`
8. Validate and write

### Empty Role Files

`roles/personal.jsonc` is effectively empty (empty permission arrays, no settings overrides). It should still exist as `{}` for consistency and as a place to add personal-specific config later. The merge logic handles missing keys gracefully.

### Local Keys

Preserved from the existing `~/.claude/settings.json` across regenerations:

- `model` (machine-specific model preference)
- `enabledPlugins` (tracked separately)
- `extraKnownMarketplaces` (managed by `configure_marketplaces()` in claudeconfig.sh)

These are NOT in any source file. They survive because `claudeconfig.sh` reads them from the existing output before overwriting.

### Key Changes from Current Logic

- `read_json` (JSONC parser) reused as-is
- Glob pattern changes from `permissions.*.json` / `permissions.*.jsonc` to `stacks/*.jsonc` and `roles/*.jsonc`
- Permission extraction changes from top-level `allow`/`ask`/`deny` to nested `permissions.allow` etc.
- New sandbox array merging (same concat + dedup + sort pattern as permissions)
- Sandbox scalars (`enabled`, `autoAllowBashIfSandboxed`, `enableWeakerNetworkIsolation`) come from roles only
- `local_keys` changes from `("awsAuthRefresh" "env" "model" "sandbox")` to `("model" "enabledPlugins" "extraKnownMarketplaces")` since `awsAuthRefresh`, `env`, and `sandbox` are now managed in role/stack source files

## Documentation

`claude/README.md` gets rewritten to cover:

- Architecture: `roles/` + `stacks/` layout with tree diagram
- Schema: the `permissions` + `sandbox` shape
- Merge order and precedence
- How to add a new stack
- How to add a network host or filesystem write path
- Local keys: what they are, why they exist
- Existing useful sections preserved: permission syntax, promotion workflow, debugging (updated for new paths)

## Verification

1. Before running refactored `claudeconfig.sh`, review live `~/.claude/settings.json` for any drift since the spec was written. Account for new permissions, hosts, or settings.
2. Run refactored `claudeconfig.sh`
3. Diff output `~/.claude/settings.json` against saved pre-refactor snapshot
4. The diff should show only: the new `Read` permission, network hosts (new in output), and ordering changes. No permissions lost.
5. Start a new Claude Code session, verify sandbox config is active in the Bash tool description

## Migration Steps

Big-bang approach (single PR):

1. Create `claude/roles/` and `claude/stacks/` directories
2. Move and restructure role files (base, personal, work)
3. Move and restructure stack files (rename + add sandbox config)
4. Create new stacks: `buildkite.jsonc`, `docs.jsonc`
5. Eliminate `permissions.web.json` (distribute domains to stacks)
6. Rewrite `claudeconfig.sh` merge logic
7. Update `claude/README.md`
8. Run and verify output matches current live settings
9. Delete old `permissions.*.json`, `permissions.*.jsonc`, and `settings.*.json` files
