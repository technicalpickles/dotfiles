# 32. Use fnox for Secrets

Date: 2026-04-24

## Status

Accepted

## Context

Environment variables that hold secrets (API keys, tokens) had been a loose mess. The previous approach lived in `config/fish/conf.d/secrets.fish` and looked like this:

```fish
set -gx OPENAI_API_KEY "op://Personal/OpenAI chatblade/credential"
set -gx WPSCAN_API_TOKEN "op://Personal/Wpscan/Token/Token"
```

The problem: those aren't resolved values, they're literal strings. Only tools that natively understand `op://` syntax (or commands wrapped in `op run`) can do anything useful with them. For everything else, `$OPENAI_API_KEY` was just the text `op://Personal/OpenAI...`.

The obvious fix is to wrap shells in `op run` or have direnv call `op read`, but the 1Password CLI has a lifecycle problem on macOS: every resolution wants Touch ID. That's fine for one-shot CI runs or scripted secret retrieval. It's painful for env vars that get re-read constantly by shell hooks and child processes.

What's needed is something that can fetch a secret once, cache it at the OS level, and hand it to the shell without prompting every time.

## Decision

Adopt [fnox](https://fnox.jdx.dev/) for shell-scoped secrets, with macOS Keychain as the default provider.

Keychain is the right primary because once a secret is stored and the keychain is unlocked (which happens at login), reads are free. No Touch ID, no menu-bar prompts, no lifecycle pain.

fnox also supports 1Password natively, so when a secret legitimately needs to live in 1Password (shared vault, rotation policy, etc.) it can reference `op://` paths through fnox instead of through raw env strings. That's available, just not the default.

### Convention: Unique provider names across nested configs

fnox walks up from the current directory and merges every `fnox.toml` it finds. Inner configs override outer configs at the key level, which means if two `fnox.toml` files both declare `[providers.keychain]`, the inner one wins silently.

This bit us on 2026-04-24. `~/pickleton/fnox.toml` had `[providers.keychain]` with `service = "pickleton"`, and a nested `fnox.toml` declared the same provider name with `service = "dotfiles"`. From inside the nested directory, `RUNLAYER_API_KEY` resolution failed because fnox was now looking it up in the wrong keychain service. Warning logged, env var unset, confusing afternoon.

Rule: name providers by their scope, not their type. `[providers.pickleton]` and `[providers.dotfiles]`, not `[providers.keychain]` in every config.

### Scope

fnox configs currently live per-project (one at `~/pickleton/fnox.toml`). `RUNLAYER_API_KEY` is the first secret managed this way. A global config for truly personal secrets is a reasonable future addition, but hasn't been set up yet.

### Alternatives Considered

1. **`op run --env-file=...`**
   - Pros: Resolves op:// paths at command-launch time
   - Cons: Touch ID per run, doesn't fit the "env var that's always set" shape
   - Rejected: the prompting cadence

2. **direnv + `op read`**
   - Pros: Per-directory env, good ecosystem
   - Cons: Same Touch ID problem, plus direnv reloads are frequent
   - Rejected: same reason

3. **Raw `op://` strings in fish (the old way)**
   - Pros: No moving parts
   - Cons: Nothing actually resolves them; tools see literal strings
   - Rejected: this is what got us here

4. **sops + age for git-committed encrypted secrets**
   - Pros: Version-controlled, reviewable
   - Cons: Wrong shape for personal env vars; designed for team-shared config that lives in repos
   - Rejected: different use case, might still make sense elsewhere

## Consequences

### Positive

- Secrets resolve to real values in shells, no prompting in the hot path
- Keychain unlock state handles auth once per login session
- Provider is swappable; 1Password stays available for secrets that belong there
- Shell integration reacts to `cd`, so per-project secrets come and go with the directory

### Negative

- First-time keychain reads may still prompt once (acceptable)
- Provider-naming collisions are a silent footgun until you know to watch for them
- No global config for personal secrets yet, so anything truly global has to wait or live per-project
- Another tool in the chain; if fnox's shell hook breaks, env vars go with it

### Migration

`config/fish/conf.d/secrets.fish` was removed as part of this decision. It held three `op://` literals (`OPENAI_API_KEY`, `WPSCAN_API_TOKEN`, `NPM_TOKEN`) that weren't actually in use.

## Links

- [fnox docs](https://fnox.jdx.dev/)
- [fnox 1Password provider](https://fnox.jdx.dev/providers/1password)
