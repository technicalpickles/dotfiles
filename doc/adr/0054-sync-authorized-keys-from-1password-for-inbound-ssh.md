# 54. Sync authorized_keys from 1Password for inbound SSH

Date: 2026-09-05

## Status

Accepted

## Context

The motivating goal: SSH into the home-role laptop from other devices over
Tailscale, without wiring up Tailscale's own SSH server. That means macOS's
Remote Login plus a populated `~/.ssh/authorized_keys` on the laptop.

Left as a manually-managed file, `authorized_keys` doesn't reproduce. If this
laptop gets wiped and reprovisioned, or another home-role machine is set up
later, there's nothing in the repo recording which personal identities should
be trusted to log in -- it has to be reconstructed from memory, one pubkey at
a time, copied out of 1Password by hand.

[ADR 0033](0033-1password-ssh-agent-allowlist.md) already solved the mirror
image of this problem: which 1Password SSH items get _offered_ when this
machine connects _out_, tracked declaratively in
`config/1password/agent.toml.<role>` and applied by `sshconfig.sh`. The same
shape of problem -- "which identities does this machine trust" -- applies to
inbound connections too.

## Decision

Add `config/ssh/authorized_keys.home` -- a list of 1Password item titles
(vault `Personal`) -- and have `sshconfig.sh` fetch each one's public key and
sync it into `~/.ssh/authorized_keys` on every run, scoped to the `home` role
only.

This is a separate list from `config/1password/agent.toml.home`, not a reuse
of it, even though the two currently overlap. Outbound and inbound trust are
genuinely different sets: a key worth _offering_ when this machine initiates
a connection (e.g. a router's key, so it never should) isn't automatically
one that should be _trusted_ to connect in, and vice versa. Keeping them
separate means each file states its own, single question and one doesn't
silently expand the other later.

Turning on Remote Login itself is left as a manual step. It's a real macOS
security setting, and this repo's automation doesn't flip those -- only
detects and warns (a non-sudo `/dev/tcp` probe on port 22) so the person
setting up a machine still consciously opts in via System Settings.

## Consequences

### Positive

- Re-provisioning a home-role machine (or wiping/replacing this one) restores
  inbound SSH trust with `./sshconfig.sh`, not by memory.
- Adding or revoking a personal identity for inbound access is a one-line
  edit to `config/ssh/authorized_keys.home`, mirroring the existing
  `agent.toml.<role>` workflow.
- The sync is idempotent and safe to run repeatedly (matches existing
  `sshconfig.sh` conventions).

### Negative

- Two parallel 1Password-backed lists (`agent.toml.home` and
  `authorized_keys.home`) to keep in sync by hand when a key is genuinely
  meant for both directions.
- `authorized_keys` on this machine is now partly repo-managed and partly
  whatever was there before -- the sync only appends missing entries, it
  doesn't prune ones removed from the list.
