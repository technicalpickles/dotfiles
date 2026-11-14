# 67. Pin global mise tools and leave runtimes to projects

Date: 2026-10-27

## Status

Accepted

## Context

[ADR 6](0006-switch-to-mise.md) moved tool management to mise. The global config lives in `config/mise/conf.d/dotfiles.toml` (tracked) and `config/mise/config.toml` (gitignored, per machine, created by `miseconfig.sh`). Four things had piled up:

- Entries set to `"latest"` can't be bumped by Renovate (there is no version to compare), and two machines could install different builds.
- Renovate's default mise file patterns match `mise.toml` and `.config/mise/`, not `config/mise/`, so the tracked config wasn't being scanned at all.
- Language runtimes (`go`, `python`, `rust`, `ruby`, `node`) sat in the global config as fallbacks, while the projects that need them mostly carry their own `mise.toml` (`cenv`, `schemaflow`, `gdev-wish`). Of the Go repos under `repos/`, only `beads` had none, and its `go.mod` wants a newer Go than the global one.
- mise can read `go.mod` as a version source (`idiomatic_version_file_enable_tools`), but it is deprecating that: the `go` directive is only a minimum, and support is removed in mise 2026.11.0. A `toolchain` line, `.go-version` or `mise.toml` still work.

## Decision

- **Global tools are pinned to exact versions.** `fnox`, `pitchfork`, `starship` and `uv` moved from `latest` to the installed versions. Anything that should stay manual says so in a comment next to the pin (`codebase-memory-mcp`, `ccstatusline`).
- **Renovate tracks `config/mise/`.** `renovate.json` sets the mise manager's `managerFilePatterns` to the `config/mise/` files and strips the `v` prefix from github tags (mise drops it, Renovate writes the raw tag back). Minor and patch bumps land in one grouped "mise tools" PR and automerge once CI passes. Majors open their own PR. The two deliberate pins above are excluded from grouping and automerge.
- **Runtimes belong to projects.** A project carries a `mise.toml` for its own `go`, `python` and `rust`. The global config doesn't need to supply them.
- **A clone with no upstream mise config gets an untracked `mise.local.toml`.** It holds the version `go.mod` or CI expects. `mise.local.toml` and `.mise.local.toml` are ignored in the global gitignore (`home/.gitignore`), so they can't be committed into someone else's repo.
- **`go.mod` is not a version source.** The idiomatic-file setting stays at `node` and `python`.

### Alternatives Considered

1. **`mise.lock`**
   - Pros: records checksums and download URLs for the `github:` tools, and makes `latest` entries concrete so Renovate can bump them.
   - Cons: `fnox` and `pitchfork` failed to lock for `linux-x64` (no `packslip.sigstore.json` on their releases). The hosted Renovate may not be able to refresh a lockfile. Where it would live with a split global config is untested.
   - Deferred: revisit after the grouped mise PRs have run for a while.
2. **Read `go.mod` through `idiomatic_version_file_enable_tools`**
   - Pros: no per-clone file for Go projects.
   - Cons: the `go` directive is only a minimum version, and mise removes support in 2026.11.0.
   - Rejected.

## Consequences

### Positive

- Renovate opens a weekly PR for global tool bumps instead of versions drifting silently.
- Two machines install the same build of a pinned tool.
- A project's mise config states the runtime it needs, so the global config doesn't mask a missing one.
- Local override files can't be committed into someone else's repo.

### Negative

- Pinned tools need a bump PR merged now and then, which `latest` didn't. That is the point, but it's still work.
- `"latest"` entries left in the gitignored `config.toml` (`cenv`, `go`) stay invisible to Renovate.
- A fresh clone of a project with no mise config needs its `mise.local.toml` created by hand.
- Global `node` has to stay: the `npm:` tools (`ccstatusline`, `markdownlint-cli2`) install without node, but their bin shims run whatever `node` is first on `PATH`.

## Links

- [Renovate config](https://github.com/technicalpickles/dotfiles/pull/97), [automerge](https://github.com/technicalpickles/dotfiles/pull/99), [mise tools](https://github.com/technicalpickles/dotfiles/pull/100), [pin latest tools](https://github.com/technicalpickles/dotfiles/pull/102), [global ignore for `mise.local.toml`](https://github.com/technicalpickles/dotfiles/pull/105)
- [Renovate mise manager](https://docs.renovatebot.com/modules/manager/mise/)
- [mise lockfile](https://mise.jdx.dev/dev-tools/mise-lock.html)
