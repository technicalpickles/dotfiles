# 47. default-to-auto-permission-mode

Date: 2026-08-20

## Status

Accepted

## Context

`claude/roles/base.jsonc` pinned `permissions.defaultMode` to `acceptEdits`.
In practice every session got `Shift+Tab`'d straight to auto mode, so the
setting bought nothing but a keystroke.

The obvious fix is to delete the key and inherit the upstream default. That
turns out not to be equivalent. Per [Permission modes][modes], `auto` is the
built-in starting mode as of v2.1.228 (v2.1.233 on native Windows), but *only*
on Pro, Max, and Team plans in a terminal or the VS Code extension. The
built-in default stays `default` (Manual) when:

- the session is `claude -p` or the Agent SDK
- the provider is Amazon Bedrock, Google Cloud's Agent Platform, Microsoft
  Foundry, Claude Platform on AWS, or a signed-in Claude apps gateway session
- the plan is Enterprise, or auth is a Claude Console API key
- feature-flag fetching is off
- it's the first session after an install or an upgrade that adds the default

This repo's roles cover several of those cases (`claude-code-remote`,
`container`, `coi-host`, plus Bedrock-backed work sessions), so dropping the
key would silently leave those in Manual.

## Decision

Set `permissions.defaultMode` to `"auto"` explicitly in
`claude/roles/base.jsonc`. Declare the intent in the source rather than
inheriting a built-in that varies by plan, provider, and version.

Three constraints shaped this:

- **User scope only.** `"auto"` in a project `.claude/settings.json` or
  `.claude/settings.local.json` does not take effect, and worse, its presence
  makes Claude Code fall back to the built-in default instead of honoring the
  `defaultMode` in `~/.claude/settings.json`. `claudeconfig.sh` writes
  user-scope settings, which is the right vehicle. Never set `defaultMode:
  auto` in project settings.
- **Nothing outranks it today.** Managed settings
  (`/Library/Application Support/ClaudeCode/managed-settings.json`) currently
  set neither `permissions.defaultMode` nor `permissions.disableAutoMode`. If
  AIT CPE ever ships `disableAutoMode: "disable"`, sessions start in Manual and
  this setting goes inert, which is the intended precedence.
- **It degrades safely.** When a session selects `auto` but auto mode isn't
  available (org turned it off, or the model doesn't support it), Claude Code
  starts in Manual rather than failing.

### Alternatives Considered

1. **Remove the key entirely**
   - Pros: less config, tracks upstream as the default evolves.
   - Cons: only equals `auto` for Pro/Max/Team terminal sessions; silently
     Manual for `-p`, the SDK, Bedrock, Enterprise/API-key auth, and the first
     run after an upgrade.
   - Rejected: this repo's roles are exactly those cases.

2. **Keep `acceptEdits`**
   - Rejected: it lost to a `Shift+Tab` every single session.

3. **`dontAsk` or `bypassPermissions`**
   - Cons: `dontAsk` runs only pre-approved tools and *denies* protected-path
     writes; `bypassPermissions` drops the classifier entirely.
   - Rejected: `dontAsk` is for locked-down CI, `bypassPermissions` for
     disposable containers. Neither describes a laptop.

## Consequences

### Positive

- Sessions start where they were being driven by hand anyway.
- The `permissions.deny` and `permissions.ask` rules in `base.jsonc` still
  apply: both are evaluated *before* the classifier, and a content-scoped `ask`
  rule always prompts even in auto mode. The safety rails in this repo are
  unaffected.
- One declared value across every role, instead of a built-in that differs per
  plan and provider.

### Negative

- Auto mode routes actions through a classifier call, so a decision costs a
  round trip where an allow-rule hit was instant. `autoMode.classifyAllShell`
  would widen that to every shell command; left off.
- Protected-path writes now go to the classifier instead of prompting.
- `autoMode.environment` is unconfigured, so the classifier trusts only the
  working directory and the current repo's configured remotes. Everything else
  internal (domains, buckets, registries, internal services) reads as external
  until named. That block cannot live in this repo: it is public, and the
  entries are infrastructure names. It belongs in a local-only overlay (the
  `local_keys` list in `claudeconfig.sh`) or in managed settings. Follow-on,
  not resolved here.

## Related

- [ADR 13](0013-claude-code-configuration-management.md) - how these settings
  get generated
- [Permission modes][modes] - the mode table and session-start precedence
- [Configure auto mode](https://code.claude.com/docs/en/auto-mode-config) -
  `autoMode.environment`, the `allow`/`soft_deny`/`hard_deny` lists, and
  `claude auto-mode config` for inspecting the effective rules

[modes]: https://code.claude.com/docs/en/permission-modes
