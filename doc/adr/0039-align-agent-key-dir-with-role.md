# 39. Align the agent SSH key directory with the role name

Date: 2026-06-26

## Status

Accepted

Amends [ADR 0035](0035-canonical-dotpickles-role-names.md) (the "Role name vs
agent identity name" section).

## Context

[ADR 0031](0031-role-scoped-agent-git-identity.md) put the home role's agent SSH
key at `~/.ssh/agents/personal/`, and [ADR 0035](0035-canonical-dotpickles-role-names.md)
decided to keep that `personal` name (key dir _and_ email) even after the role
itself was renamed `personal` -> `home`, to preserve the GitHub Verified-badge
enrollment tied to `joshua.nichols+personal-agent@gmail.com`.

In practice the split name was a recurring source of confusion. `check-agent-ssh-key`
derived the key path from the role (`~/.ssh/agents/$ROLE`), so on the home role it
looked for `~/.ssh/agents/home` and failed, then told the user to run
`setup-agent-ssh-key home` -- which would mint a _new_ `home` identity rather than
point at the existing key. The role-vs-identity gap had to be papered over with a
`--key` override threaded from the gitconfig include.

The Verified-badge enrollment is tied to the **email address and the key**, not to
the on-disk directory name. Moving the key directory does not touch enrollment.

## Decision

The agent key directory tracks the **role**: the home role's key lives at
`~/.ssh/agents/home/`.

The agent **email stays `joshua.nichols+personal-agent@gmail.com`** for now. It is
the GitHub-enrolled, Verified address; re-enrolling under a `home`-named address is
a separate, optional step deferred until there's a reason to do it. So today the
home identity is: key dir `home`, email `personal-agent`.

The role's gitconfig include (`home/.gitconfig.d/claude-agent-home`) remains the
single source of truth for both the email and the key path. `claudeconfig.sh` reads
`user.signingkey` from it and passes `--key` to `check-agent-ssh-key`, so the
validator never guesses the key location even though the email still differs from
the role-derived default.

This amends ADR 0035's "Role name vs agent identity name" section: the key dir is no
longer kept as `personal`. Only the email is.

## Consequences

### Positive

- The key dir matches the role, so the obvious mental model (`agents/<role>`) is
  correct again, and `setup-agent-ssh-key home` would recreate the right directory.
- One fewer place where `personal` lingers; the remaining `personal` is isolated to
  the email, with a documented reason.

### Negative

- The email still doesn't match the role, so `setup-agent-ssh-key home` defaults to
  the wrong address and must be run with
  `--email joshua.nichols+personal-agent@gmail.com`. The include keeps the live
  config correct regardless; this only bites a from-scratch re-setup.
- A future email re-enrollment (to `+home-agent`) is still outstanding if full
  alignment is ever wanted.
