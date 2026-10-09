# 58. Automic Vault for git signing and agent SSH, gated per machine

Date: 2026-10-06

## Status

Accepted

## Context

Git signing and agent SSH had three separate key paths:

- interactive commits signed with a 1Password SSH key through `op-ssh-sign`
  (Touch ID per signature);
- Claude Code sessions signed and pushed with a dedicated agent key at
  `~/.ssh/agents/<role>/id_ed25519` ([ADR 0031](0031-role-scoped-agent-git-identity.md),
  [ADR 0039](0039-align-agent-key-dir-with-role.md)), loaded into ssh-agents
  by `bin/load-agent-ssh-keys`;
- that agent key's private half sat on disk, readable by any same-user process.
  On the home machine it had no passphrase.

Automic Vault (AV) now offers a GPG Signing Gate (`av-gpg` → `av gpg-sign`,
per-launcher credential, Approval Required or Allow Signing) and an SSH Agent
Gate (its own agent socket, per-launcher policy). On 2026-10-02 AV's managed
block at the top of `~/.ssh/config` started routing every host to its agent
([ADR 0048](0048-agent-session-ssh-key-override-via-match-exec.md) update).
That gives gating and push-notification approval without 1Password and
without an ungated key file, but only on machines where AV is installed and set up.

Three things got in the way:

1. AV's **Settings → GPG Signing → Configure Git** runs `git config --global`.
   `~/.gitconfig` is a symlink into this repo, so it edited tracked
   `home/.gitconfig`.
2. Claude sessions use `GIT_CONFIG_GLOBAL=~/.gitconfig.d/claude-agent-<role>`,
   which never reads `~/.gitconfig`, so AV's config was invisible to agents.
3. Agent pushes failed on 2026-10-03/04 with `agent refused operation`
   (bean `dotfiles-083x`). AV's history records those as **"Approval
   presentation interrupted"**: the SSH gate was Approval Required and the
   prompt was dismissed, or approved via a disallowed source. It was not the
   Claude Code sandbox; AV's XPC approval works sandboxed and AV reports a
   distinct "blocked by this process's sandbox" error for real sandbox denials.
   Setting the SSH gate's Claude policy to Allow Authentication resolved it.

## Decision

Use AV as the signing and agent-SSH backend **wherever it is actually set up**,
decided by observed machine state, not by `DOTPICKLES_ROLE`. The role still
picks the identity (email, which key); AV's presence is per machine.

**Signing.** `home/.gitconfig.d/av-signing` holds `gpg.format=openpgp`,
`gpg.program=…/av-gpg`, `commit.gpgSign`, `tag.gpgSign`. `gitconfig.sh` writes
an untracked `~/.gitconfig.signing.local` that includes it only when
`/Applications/Automic Vault.app/Contents/MacOS/av-gpg` exists, and in that case
skips the 1Password / SSH signing setup. `~/.gitconfig.local` and both
`claude-agent-*` configs include `~/.gitconfig.signing.local`, the agent configs
as their **last** section so it overrides their SSH signing. Git ignores missing
includes, so machines without AV keep SSH signing unchanged. Don't use AV's
Configure Git button.

**Agent SSH.** `bin/av-ssh-agent-holds-key <pub>` passes only when `ssh -G`
resolves to AV's agent socket and that agent serves the key. It's the gate for:

- `bin/load-agent-ssh-keys`: skips keys AV serves (loading them elsewhere would
  make an ungated copy).
- `bin/check-agent-ssh-key`: accepts a missing private key file, probes GitHub
  through AV's agent, and warns if the private file still exists.
- `bin/retire-agent-ssh-key`: deletes the private key file only after the gate
  passes **and** a live `ssh -T git@github.com` succeeds through AV alone
  (identity = the `.pub`, `-F /dev/null`), then asks for confirmation. Keeps the
  `.pub`, which ssh config and gitconfig still reference.

## Consequences

- Interactive commits no longer involve 1Password. `gitconfig.sh` no longer calls
  `op` when AV is present.
- AV picks the GPG credential per Verified Launcher. Agent commits use the
  alternate credential whose uid is the agent email, so they verify on GitHub. Your
  own commits need AV's _default_ credential to carry your own email and be
  uploaded to GitHub, or they show Unverified.
- `user.signingkey` is ignored by `av-gpg` (it doesn't honour `-u`), so the
  leftover SSH `signingkey` values are harmless.
- **Open risk:** unattended launchd jobs (e.g. scheduled commits) have no Verified
  Launcher. AV requires one for SSH even with manual Approval, so those jobs may
  fail closed on push or signing on AV machines. Verify per job before retiring
  the key on a machine that runs them.
- Each machine is migrated by hand: enable AV's SSH Agent and GPG Signing, re-run
  `gitconfig.sh`, check with `bin/check-agent-ssh-key <role>`, then
  `bin/retire-agent-ssh-key <role>`. The work machine follows the same steps on
  its own schedule.
