# 71. Share ssh connections in agent sessions

Date: 2026-11-18

## Status

Accepted

## Context

Every new ssh connection signed by Automic Vault's ssh-agent takes about 13 seconds, even though the signature is auto-approved (`av history` shows "Allow Authentication from Claudefordesktop"). Measured 2026-11-18 from an agent session: `ssh picklelab true` took 13.57, 13.74 and 13.59 seconds, and `ssh -T git@github.com` took 14. `ssh -v` puts the whole delay between "Server accepts key" and "Authenticated"; the SOCKS relay connect takes under 1 second and the remote command runs in milliseconds after auth.

`just deploy-openclaw` in picklehome runs about 10 separate ssh/scp calls before `deploy.sh` even starts (file mtimes on the host were 12 to 13 seconds apart), so about 2 minutes of an 11 minute deploy was auth wait.

No ssh config in this repo sets `ControlMaster`, `ControlPath` or `ControlPersist`.

## Decision

Add `ssh/config.d/agent-mux`, a `Match exec` block keyed on `$CLAUDECODE` / `$AGENT_SESSION` like `auth` and `agent-relay`, setting `ControlMaster auto`, `ControlPath ~/.ssh/cm-agent/%C` and `ControlPersist 5m`. `sshconfig.sh` creates `~/.ssh/cm-agent` (mode 700) and links the fragment on macOS only.

Tested in the sandbox with a temporary config: three connections took 13, 0 and 1 seconds; with the agent env vars unset `ssh -G` showed `controlmaster false`.

### Alternatives Considered

1. **`Host *` multiplexing for every session**
   - Pros: helps human terminals too.
   - Cons: the relay allowlist in `config/gost/agent-ssh-relay.yml` limits which hosts agents can reach. A master opened by a human terminal to a host outside that list could be reused by an agent session through a shared socket. Whether a plain terminal is slow at all is unmeasured.
   - Rejected: do it separately, with its own socket directory, once the plain-terminal baseline is known.
2. **Batch the deploy's calls into one ssh**
   - Pros: no config change.
   - Cons: rewrites several recipes, and every other agent ssh use keeps paying 13 seconds per call.
   - Rejected for now; sharing helps all of them at once.
3. **Fix the signing latency in Automic Vault**
   - Pros: removes the cause.
   - Cons: not ours to change. Worth reporting upstream if a plain terminal is also slow.

## Consequences

### Positive

- Later ssh/scp calls to the same host in an agent session take about 0 to 1 seconds instead of 13.
- Agent sessions get their own socket directory, so human-opened masters are not reachable from them.

### Negative

- Multiplexed sessions skip the ssh-agent, so `av history` records one authentication per master instead of one per use.
- A network blip kills every session on the master. A stuck master needs `ssh -O exit <host>` or `rm ~/.ssh/cm-agent/*`.
- macOS only, because `Match exec` with escaped quotes breaks OpenSSH 9.6 on Linux (see `ssh/CLAUDE.md`).
- Not verified: whether git pushes benefit, since git only reads this config when `GIT_SSH_COMMAND=ssh` is in effect.
