# 33. 1Password SSH Agent Allowlist

Date: 2026-05-04

## Status

Accepted

## Context

`ssh/config.d/auth` (see [ADR 26](0026-versioned-ssh-config-with-config-d.md))
points `Host *`'s `IdentityAgent` at the 1Password agent socket. Every ssh
connection that doesn't have a more specific `IdentityAgent` lands there, and
1Password offers up keys from the unlocked vault.

By default, 1Password's agent offers _every_ SSH key item in every vault the
account can see. On a single-purpose machine that's fine. On a machine with
both work and personal contexts, it's noisy and occasionally wrong:

- Servers that allow multiple keys for a user may auth with whichever one
  shows up first, even if it isn't the "right" one
- 1Password prompts for biometric/system approval per key offer, and offering
  irrelevant keys means more prompts to dismiss
- The personal-agent key from [ADR 31](0031-role-scoped-agent-git-identity.md)
  lives on disk + macOS Keychain by design, but is also stored in 1Password
  vault as a backup. That entry should never be _offered_ by the 1Password
  agent (the on-disk + Keychain path is what claude-agent uses), even though
  it's fine for it to live in the vault for reference.

On the work laptop specifically, `ssh-add -l` against the 1Password socket
listed seven keys, including the personal-agent key. That's the immediate
trigger.

## Decision

Manage `~/.config/1Password/ssh/agent.toml` as a role-aware symlink into the
dotfiles repo. The file in the repo is an allowlist of 1Password items by
title, scoped per-role.

### Implementation

**`config/1password/agent.toml.<role>`** holds the allowlist for that role.
On the work laptop, only Gusto-related items are listed:

```toml
[[ssh-keys]]
item = "Gusto Laptop id_ed25519"

[[ssh-keys]]
item = "Gusto Signing Key"

[[ssh-keys]]
item = "homebrew-gusto_deploy_key"
```

Listed `[[ssh-keys]]` entries are an allowlist: 1Password offers only those
items, regardless of what else lives in the vault. `item` matches the
1Password item title (not the SSH key comment).

**`sshconfig.sh`** appends a section that resolves
`config/1password/agent.toml.$DOTPICKLES_ROLE` and symlinks it to
`~/.config/1Password/ssh/agent.toml` if the source file exists and the
1Password app dir is present. The role-aware path means a new machine joining
under a different role doesn't accidentally inherit another machine's
allowlist; it just skips the link until the role's file exists.

**`functions.sh`'s `link_directory_contents`** skip list adds
`config/1password`. Without that, the auto-linker would try to symlink the
directory itself to `~/.config/1password` (lowercase), which 1Password
ignores -- it reads the capital-P path. Listing it as a skip alongside
`config/fish` matches the existing pattern for "directory managed by its own
installer."

### Why per-role rather than per-host

1Password's `agent.toml` does support `host = "..."` filters per key, which
would let one file describe behavior for both work and personal hosts. But
the dotfiles role system already cleanly partitions "this is a work laptop"
from "this is a personal laptop," and the simplest mental model is "the
allowlist is whatever the role file says." A future iteration could add
host-scoping inside a role file (e.g. work laptop allows the Gusto signing
key for github.com only) without changing the role-based selection.

### Alternatives Considered

1. **Single allowlist with `host =` filters covering both machines**

   - Pros: one file describes everything
   - Cons: every machine's vault still has to share the same item titles;
     a vault rename on one machine breaks behavior on the other; harder to
     reason about
   - Rejected: role-based selection is a cleaner cut

2. **Delete the personal-agent key from the 1Password vault**

   - Pros: no allowlist needed; problem disappears
   - Cons: loses the "key is backed up in 1Password" property, which is the
     reason it was added in the first place
   - Rejected: the user wants the key in the vault for reference

3. **Stop using the 1Password agent altogether on the work laptop**

   - Pros: removes a class of identity-leak issues
   - Cons: defeats 1Password as the auth UX for the entire flow, including
     non-agent uses; significantly larger change for one annoyance
   - Rejected: too broad

## Consequences

### Positive

- 1Password offers only the keys relevant to the active role, cutting the
  work laptop from 7 offered keys to 3
- The personal-agent key stays in 1Password vault for backup but is not
  offered by the 1Password agent on any machine, preserving ADR 31's
  "agent key auth path is on-disk + Keychain only" property
- A new role file (`agent.toml.<role>`) is a one-file change to add another
  machine type
- Existing `link` helper handles the symlink lifecycle (creation, rewriting,
  conflict prompts) without bespoke shell

### Negative

- One more file to keep in sync per role. When a new key is added to the
  vault for that role, it has to be added to the allowlist or it won't be
  offered. Failure mode is "key isn't found," which is loud rather than
  silent
- 1Password item _titles_ are the matching key. Renaming an item in
  1Password silently breaks the allowlist until the file is updated
- The capital-P quirk (`~/.config/1Password/` vs the rest of `~/.config/`'s
  lowercase convention) means the skip list and the explicit symlink in
  sshconfig.sh are necessary; a reader who doesn't know the quirk might
  wonder why config/1password isn't auto-linked like everything else under
  config/
