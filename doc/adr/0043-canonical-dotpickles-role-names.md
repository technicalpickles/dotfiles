# 43. Canonical DOTPICKLES_ROLE names

Date: 2026-07-15

## Status

Accepted

Supersedes [ADR-0035](0035-canonical-dotpickles-role-names.md).

## Context

[ADR 0035](0035-canonical-dotpickles-role-names.md) was written specifically to
stop role-name drift: it existed because an earlier rename (`personal` -> `home`)
had landed in some consumers but not others, and nothing authoritative said what
the valid names even were.

Two things have happened since that make 0035 itself the next instance of the
problem it was written to prevent.

**First, 0035's own list had already drifted by the time it was accepted.** It
names `home`, `work`, and `container`. It omits `claude-code-remote`, even
though that role predates 0035 by two weeks: `functions.sh` has emitted
`claude-code-remote` from `dotpickles_detect_role` since
[ADR 0040](0040-claude-code-remote-role.md) (2026-06-28), `gitconfig.sh` branches
on it, and `claude/roles/claude-code-remote.jsonc` exists on disk. 0035 (dated
2026-06-12) predates 0040, so the omission wasn't a mistake at the time it was
written. It just never got updated when 0040 landed three weeks later. That's
the exact failure mode 0035 exists to catch: a canonical list is only
authoritative for as long as someone remembers to touch it every time a role is
added. Worth saying plainly, because it's the strongest argument for why this
list needs restating rather than just extending: the fix for role drift is
itself subject to role drift.

**Second, adding `coi-host`** (an OrbStack VM running incus as a
[Code on Incus](https://github.com/technicalpickles/pickled-coi) host)
**introduces a mode 0035 didn't contemplate: explicit-only roles.** Every role
in 0035's list is auto-detected in `dotpickles_detect_role`
(`functions.sh:188`) from something observable at runtime: a hostname pattern,
a container marker file, an environment variable set by the cloud runner.
`coi-host` has no such signal. An OrbStack Ubuntu VM looks like any other Linux
box from inside; nothing distinguishes "this is a COI host" from "this is some
other VM someone happened to create." So `coi-host` is never detected. It's set
by the caller, specifically pickled-coi's `vm/setup.sh`, which runs
`DOTPICKLES_ROLE=coi-host ./install.sh --yes`. This already works today without
any change to detection: `dotpickles_detect_role` returns immediately if
`DOTPICKLES_ROLE` is already set in the environment (`functions.sh:189`). 0035
never says this mode exists; it reads as if every role is discovered, never
asserted. Both are now first-class.

## Decision

The canonical `DOTPICKLES_ROLE` values are:

- **`home`** -- personal machines (the default for any non-work, non-container,
  non-remote host)
- **`work`** -- hostnames matching `josh-nichols-*`
- **`container`** -- detected at runtime inside containers (Docker/lxc)
- **`claude-code-remote`** -- Claude Code's cloud runner, detected via
  `CLAUDE_CODE_REMOTE=true`
- **`coi-host`** -- an OrbStack VM running incus as a COI host. Set explicitly
  by pickled-coi's `vm/setup.sh`; never auto-detected, because nothing at
  runtime distinguishes such a VM from any other Linux box.

`personal` stays retired, per 0035. No new code should emit or branch on it.

### Detection is not the only path

Most roles above are auto-detected by `dotpickles_detect_role`
(`functions.sh:188`), which runs at `functions.sh` source time so the role is
guaranteed set for every consumer. But detection only fires when
`DOTPICKLES_ROLE` is unset:

```sh
dotpickles_detect_role() {
  if [ -n "${DOTPICKLES_ROLE:-}" ]; then
    return
  fi
  ...
```

`coi-host` relies on exactly that early return. This is a supported mode, not a
workaround: a caller that already knows its own role (because it's the thing
that created the VM in the first place) can set `DOTPICKLES_ROLE` directly and
every downstream consumer treats it the same as an auto-detected value. The
role system was implicitly built to support this from the start; 0035 just
never said so.

Every role-keyed consumer must use exactly the canonical names above. Known
consumers, verified against the current code (not carried forward
unverified from 0035):

| Consumer                                                                                 | coi-host impact                                                                                                                                              |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `gitconfig.sh` `case "$DOTPICKLES_ROLE"`                                                 | Must list the role, or it hits the `*)` branch and hard-exits with "Unexpected role"                                                                         |
| `claude/roles/<role>.jsonc`                                                              | Must exist, or `claudeconfig.sh` fires its ADR 0031 fail-loud missing-role warning                                                                           |
| `Brewfile.<role>`                                                                        | None needed for coi-host; this mechanism is macOS-only                                                                                                       |
| `config/1password/agent.toml.<role>` ([ADR 0033](0033-1password-ssh-agent-allowlist.md)) | None needed; only `.home` and `.work` exist, and `sshconfig.sh` gates on the macOS 1Password app directory, so it's skipped on Linux the same as `container` |
| `config/fish/conf.d/starship-init.fish`                                                  | None needed; it uses the role as a display string with a `home` fallback, and `coi-host` just displays as-is                                                 |
| `install.sh`                                                                             | None needed; it only echoes the role                                                                                                                         |
| `sshconfig.sh`                                                                           | None needed; macOS-gated                                                                                                                                     |

## Consequences

### Positive

- One authoritative list again, this time including the role that was missing
  from the list meant to prevent exactly that.
- Explicit-only roles (roles set by a caller instead of detected) are now a
  documented, supported category instead of an implicit side effect of
  `dotpickles_detect_role`'s early return.
- `coi-host` gets a role file and a `gitconfig.sh` branch up front, so it
  doesn't repeat the pattern where a role ships before its consumers catch up.

### Negative

- This ADR can drift the same way 0035 did if a future role addition doesn't
  also update this list. The fail-loud guard ([ADR 0036](0036-fail-loud-role-resolution.md))
  still catches missing role files; nothing catches a canonical-list omission
  except someone noticing, same as before.
- Explicit-only roles have no runtime check that the caller got the role name
  right. A typo in `vm/setup.sh` (`coi_host` instead of `coi-host`) produces an
  "Unexpected role" hard exit from `gitconfig.sh`, which is at least loud, but
  there's no earlier validation.
