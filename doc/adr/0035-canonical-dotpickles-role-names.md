# 35. Canonical DOTPICKLES_ROLE names

Date: 2026-06-12

## Status

Accepted

## Context

Role-based adaptation is the central architectural pattern of this repo (see
[architecture.md](../architecture.md)): a single `DOTPICKLES_ROLE` value selects
git identity, Brewfile additions, shell behavior, Claude settings, and SSH agent
allowlists. Despite being load-bearing for nearly every subsystem, the role
_system_ was only ever described in passing inside other ADRs ([0013](0013-claude-code-configuration-management.md),
[0031](0031-role-scoped-agent-git-identity.md), [0033](0033-1password-ssh-agent-allowlist.md)).
The set of valid role names was never written down anywhere authoritative.

That gap caused a real, long-lived failure. An early non-work role named
`personal` was later renamed to `home` in some places (`config/fish/config.fish`,
the SSH agent allowlist) but not others (`install.sh`, `home/.zshenv`,
`claudeconfig.sh`, `claude/roles/personal.jsonc`, the agent gitconfig). Because
nothing declared the canonical name, each consumer drifted independently. The
live machines emitted `home` while `claude/roles/` only had `personal.jsonc`, so
the Claude agent git identity silently never loaded and every agent commit fell
back to the interactive 1Password signing prompt. It went unnoticed for roughly
two months.

Role detection is also necessarily duplicated: `install.sh` (bash),
`config/fish/config.fish` (fish), and `home/.zshenv` (zsh) each re-implement the
same hostname check because the three shells can't share one snippet. Three
copies of a literal role string is exactly where drift creeps in.

## Decision

The canonical `DOTPICKLES_ROLE` values are:

- **`home`** -- personal machines (the default for any non-work, non-container host)
- **`work`** -- hostnames matching `josh-nichols-*`
- **`container`** -- detected at runtime inside containers (Docker/lxc)

`personal` is **retired**; it was the former name for `home`. No new code should
emit or branch on it.

Every role-keyed consumer must use exactly these names. Known consumers:

- `Brewfile.<role>`
- `claude/roles/<role>.jsonc`
- `config/1password/agent.toml.<role>` ([ADR 0033](0033-1password-ssh-agent-allowlist.md))
- the role default / branch in `claudeconfig.sh`, `sshconfig.sh`, `install.sh`, `gitconfig.sh`
- the starship prompt context fallback in `config/fish/conf.d/starship-init.fish`

`gitconfig.sh` (a `case "$DOTPICKLES_ROLE"` branch) and the starship prompt
fallback were both missed by the original rename and only caught later:
`gitconfig.sh` would hit its `*)` "Unexpected role" exit on a `home` machine, and
the prompt showed a stale `personal` because its fallback string was never updated.

### Fish: set the role in conf.d, not config.fish

Fish sources `conf.d/*.fish` before `config.fish`. The starship prompt
(`conf.d/starship-init.fish`) reads `DOTPICKLES_ROLE` at init time, so the role
must be set by an earlier-sorting conf.d file. It lives in
`conf.d/dotpickles-role.fish` (sorts before `starship-init`). Setting it in
`config.fish` is too late: the prompt builds with the role unset and falls back to
its default, silently showing the wrong role.

### Role name vs agent identity name

> **Amended by [ADR 0039](0039-align-agent-key-dir-with-role.md):** the key
> directory was later moved to `~/.ssh/agents/home/` to match the role. Only the
> _email_ stays `personal-agent` now. The rest of this section stands.

The dotfiles _role_ is distinct from the git _identity_ a role uses. The `home`
role signs as the GitHub-enrolled `personal-agent` identity (email
`joshua.nichols+personal-agent@gmail.com`, key under `~/.ssh/agents/personal/`,
see [ADR 0031](0031-role-scoped-agent-git-identity.md)). Those keep the
`personal` name to preserve the Verified-badge enrollment. Renaming the role to
`home` does **not** rename the identity. The agent gitconfig fragment is
`claude-agent-home` (named for the role), but its contents point at the
`personal`-named identity on purpose.

## Consequences

### Positive

- One authoritative list to check a new role-keyed file against.
- The role-vs-identity distinction is recorded, so "why does `home` use a
  `personal` key" has a documented answer instead of looking like a bug.

### Negative

- Detection stays duplicated across three shells; this ADR documents the
  canonical names but does not (cannot easily) DRY the detection itself. The
  mitigation is the fail-loud guard in [ADR 0036](0036-fail-loud-role-resolution.md),
  which makes a drifted/typo'd role visible instead of silent.
- Renaming a role in future touches every consumer above at once; there is no
  single rename point.
