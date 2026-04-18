# 31. Role-Scoped Agent Git Identity

Date: 2026-04-18

## Status

Accepted

## Context

Git commits in this repo (and everywhere else) are signed via 1Password's GPG
integration. 1Password also acts as the SSH agent for GitHub via `IdentityAgent`
in `ssh/config.d/auth` (see [ADR 26](0026-versioned-ssh-config-with-config-d.md)).
Both of those require interactive approval: a system prompt for the GPG signing
touch, a biometric or system prompt for each SSH auth.

That works great when a human is at the keyboard. It blocks autonomous Claude
Code sessions cold. An agent running in a `tmux` pane, under `claude-with`, or
in the background via `run_in_background` can't approve a prompt that the user
isn't looking at. Commits don't get signed, pushes to GitHub never authenticate,
and the session stalls.

We need a second identity the agent can use without any interactive approval,
while keeping the user's interactive 1Password flow intact for regular work.

### Constraints

- No interactive prompts during agent operations (the whole point)
- Keep the Verified badge on GitHub for agent commits (so audit trail is clear)
- Agent identity must be distinguishable from the human identity in git log and
  on GitHub
- Revocable: if the agent key leaks, a single GitHub keys page removal should
  stop it
- Shouldn't leak into non-agent shells: `git commit` from a regular terminal
  should keep using the 1Password GPG flow

### Related groundwork

- [ADR 30](0030-ssh-keychain-loading-at-login.md) already solves the
  "passphrase-protected SSH key loaded silently into the fish-managed agent
  socket" problem for macOS: `config/fish/conf.d/ssh-keychain.fish` runs
  `ssh-add --apple-load-keychain` on every shell start. Any key whose
  passphrase lives in Keychain is available to every shell, no prompts.
- [ADR 13](0013-claude-code-configuration-management.md) established the
  role-based config generation (`claudeconfig.sh` merges `roles/<role>.jsonc`
  with `stacks/*.jsonc` into `~/.claude/settings.json`). Claude Code reads the
  `env` block in `settings.json` and injects those variables into every shell
  it spawns.

Those two combined give us everything we need: a silent SSH key, and a hook to
override git identity per role.

## Decision

Every Claude Code session inherits its git identity from the active dotfiles
role via environment variables set in `claude/roles/<role>.jsonc`.

Under the personal role, Claude commits and pushes as
`joshua.nichols+personal-agent@gmail.com`, signed with a dedicated ed25519
key at `~/.ssh/agents/personal/id_ed25519`, with its passphrase in macOS
Keychain. The user's interactive shells are untouched.

### Implementation

**1. Key storage.** `~/.ssh/agents/<role>/id_ed25519` with a passphrase stored
in macOS Keychain. The existing `conf.d/ssh-keychain.fish` loads it into
fish-ssh-agent on every shell start, so the key is available to git without
any prompt.

The directory layout (`agents/<role>/`) leaves room for a future work-role
key without touching the personal setup.

**2. GitHub-side enrollment.** For each role, the public key is registered
on the GitHub account in two places:

- Authentication keys (for `git push`)
- Signing keys (so the Verified badge shows on signed commits)

The `+<role>-agent` plus-addressed email is added as a verified email on the
same GitHub account. Plus-addressing keeps it tied to one inbox while giving
GitHub a distinct email to attribute commits to.

**3. Per-role env injection.** `claude/roles/personal.jsonc` sets a single
env var pointing at an agent-specific gitconfig file:

```jsonc
"env": {
  "GIT_CONFIG_GLOBAL": "~/.gitconfig.d/claude-agent-personal"
}
```

`GIT_CONFIG_GLOBAL` tells git to read the pointed-at file instead of
`~/.gitconfig` for every git command in the session. The target is a
symlinked dotfiles-managed file (`home/.gitconfig.d/claude-agent-personal`
in the repo, surfaced via `link_directory_contents home`):

```ini
[include]
    path = ~/.gitconfig
[user]
    email = joshua.nichols+personal-agent@gmail.com
    signingkey = ~/.ssh/agents/personal/id_ed25519.pub
[core]
    sshCommand = ssh -i ~/.ssh/agents/personal/id_ed25519 -o IdentitiesOnly=yes -o IdentityAgent=SSH_AUTH_SOCK
[commit]
    gpgsign = true
[gpg]
    format = ssh
[gpg "ssh"]
    program = ssh-keygen
```

The `[include]` pulls in the real global gitconfig first (transitively
including `~/.gitconfig.d/1password` and its `op-ssh-sign`). Sections
below then override via last-write-wins, so `gpg.ssh.program = ssh-keygen`
still defeats 1Password's default.

Three subtleties worth noting:

- `IdentityAgent=SSH_AUTH_SOCK` is required in `core.sshCommand`. Without
  it, ssh still talks to 1Password's agent socket (from `Host *` in
  `ssh/config.d/auth`), which doesn't know about the agent key. The
  literal string `SSH_AUTH_SOCK` is specially recognized by ssh and
  resolved to the env variable's value, pointing back at fish-ssh-agent.
- `gpg.ssh.program = ssh-keygen` is required. The global gitconfig sets
  this to `op-ssh-sign` (1Password's signing helper), which only knows
  about keys in the 1Password vault. Without this override, signing a
  commit with the agent key fails with `failed to fill whole buffer`.
  Resetting it to `ssh-keygen` uses OpenSSH's native signing, which reads
  the signing key via the running ssh-agent.
- `GIT_CONFIG_GLOBAL` does not expand `~/`, so `claudeconfig.sh` expands
  leading `~/` in `.env` string values to `$HOME/...` before writing
  `settings.json`. JSONC stays portable; the resolved path is absolute.

**4. Setup helper.** `bin/setup-agent-ssh-key <role>` generates the key,
stores the passphrase in Keychain, and prints a numbered checklist of
GitHub-side steps with the public key ready to paste.

**5. Validator.** `bin/check-agent-ssh-key <role>` verifies each step of the
setup: local key files and perms, Keychain load, GitHub email verification,
auth key and signing key registration (via fingerprint comparison against
`gh api user/keys` and `gh api user/ssh_signing_keys`), that
`~/.claude/settings.json` wires `GIT_CONFIG_GLOBAL` to an include file with
the required overrides (`user.email`, `core.sshCommand`,
`gpg.ssh.program=ssh-keygen`), and end-to-end SSH auth to github.com.
It exits non-zero if anything is missing so it works as a health check.

### Why role-scoped, not claude-with-scoped

`claude-with` isolates Claude Code config (permissions, plugins, settings)
per named environment, but git identity isn't a config-isolation concern.
Every Claude Code session, in any `claude-with` env, still acts as the same
agent under a given role. Keeping identity on the role axis means:

- A new `claude-with` env doesn't need any extra setup to inherit the agent
  identity
- When a work-role identity is eventually needed, it's a parallel addition
  to `work.jsonc` with no changes to `claude-with` or per-env overlays
- One source of truth per role, loaded by `claudeconfig.sh` like any other
  role setting

### Alternatives Considered

1. **Keep using 1Password GPG, batch-approve in the morning**

   - Pros: no new keys, no new config
   - Cons: still interactive at the moment the agent needs to commit;
     unattended sessions die; no actual fix to the root problem
   - Rejected: doesn't solve the problem

2. **Use a claude-with overlay instead of the role file**

   - Pros: identity only applies to explicitly-opted-in envs
   - Cons: extra step for every new env; two envs that should share an
     identity have to both remember to apply the overlay; identity drift is
     easy
   - Rejected: identity belongs on the role axis, not the env axis

3. **Put the config in `~/.gitconfig` with `includeIf "gitdir:..."`**

   - Pros: works for any tool that reads `.gitconfig`, not just Claude
   - Cons: `includeIf` doesn't match on env vars, only directories or
     branches. Can't distinguish "Claude session" from "interactive shell"
     without segregating by directory, which breaks normal workflows
   - Rejected: wrong selector

4. **Use a machine user on GitHub instead of a second identity on the main account**
   - Pros: maximum isolation; full account revocation if compromised
   - Cons: loses the "commits attributed to me" audit trail; costs a seat
     on orgs that bill per user; more GitHub UI wrangling for repo access
   - Rejected for personal scope, worth reconsidering for work scope later

## Consequences

### Positive

- Autonomous Claude sessions can sign and push commits with zero interactive
  prompts after one-time Keychain enrollment
- Agent commits show as Verified on GitHub, with a distinct committer email
  that makes the agent's work easy to filter in `git log` or GitHub search
- Non-Claude shells are completely unchanged (still 1Password GPG for the
  user's own commits)
- Future work-role identity is a drop-in parallel: new key under
  `~/.ssh/agents/work/`, equivalent env block in `work.jsonc`
- Revocation is one click on the GitHub keys page; key file can be deleted
  from disk and regenerated via the setup script

### Negative

- The private key now exists on disk (vs. 1Password's vault storage). Risk
  is bounded: passphrase-protected, Keychain-locked, single-machine, easy
  to revoke on GitHub. But it's a weaker posture than the 1Password flow it
  sidesteps
- One-time manual GitHub enrollment per role (three web steps: verify email,
  upload auth key, upload signing key). The setup script prints the checklist
  but can't automate this side
- Two identities in `git log` for work done on the same machine. Easy to
  filter, but reviewers unfamiliar with the setup might be confused about
  which commits are "really" from Josh
- Two files to understand (the role's env block and the
  `home/.gitconfig.d/claude-agent-<role>` include file) rather than one env
  block. The trade is a more readable gitconfig vs. the opaque
  `GIT_CONFIG_COUNT/KEY/VALUE` scheme it replaced
