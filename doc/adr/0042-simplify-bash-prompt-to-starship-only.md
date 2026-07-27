# 42. Simplify bash prompt to starship only

Date: 2026-07-11

## Status

Accepted

## Context

Bash carried two competing prompt implementations left over from before
[ADR 0007](0007-switch-to-starship.md) switched fish and zsh to starship:

- The `starship` plugin in oh-my-bash's `plugins=()` array (`home/.bashrc`),
  which correctly runs `eval "$(starship init bash)"` and unsets `OSH_THEME`.
- `home/.bash_profile.d/prompt.sh`, an ezprompt.net-generated custom `PS1` that
  shells out to `git status` on every prompt render to compute dirty-state
  flags. `home/.bash_profile` sourced this file _after_ `.bashrc` loaded the
  starship plugin, so it silently clobbered the `PS1` starship had just set.

There was also a vendored `vendor/sbp` git submodule (`brujoand/sbp`, a
themeable bash prompt framework) with a fallback sourcing block in
`.bash_profile`, already commented out and unused.

Net effect: bash never actually used starship for its prompt, despite the
plugin being enabled, and carried a slow git-parsing prompt plus a dead
submodule.

## Decision

Remove both legacy prompt paths and let the already-configured oh-my-bash
`starship` plugin be the only thing that sets `PS1` in bash, matching how fish
and zsh already work.

- Deleted `home/.bash_profile.d/prompt.sh`.
- Removed the block in `home/.bash_profile` that sourced it (and the
  commented-out `vendor/sbp` fallback).
- Removed the `vendor/sbp` git submodule (`git submodule deinit` + `git rm`,
  which also dropped its `.gitmodules` entry).

### Alternatives Considered

1. **Reorder sourcing so starship's `PS1` wins**
   - Rejected: would keep two prompt implementations around for no benefit;
     starship already fully replaces both.
2. **Migrate to `vendor/sbp` as the bash prompt framework**
   - Rejected: reintroduces a bash-only prompt framework/dependency when
     starship already gives a consistent prompt across fish, zsh, and bash.

## Consequences

### Positive

- Bash prompt now matches fish/zsh: one prompt engine, one config
  (`config/starship.toml`), no drift.
- No more `git status` shellout on every bash prompt render.
- One fewer vendored git submodule to keep updated.

### Negative

- Bash doesn't yet set `DOTPICKLES_ROLE`/`STARSHIP_CTX` for interactive
  shells the way fish's `config/fish/conf.d/starship-init.fish` does, so the
  starship context segment won't show role/devcontainer context in bash. Left
  out of scope for this change; can be added later if wanted.
