# 55. Agent git over SSH through the relay

Date: 2026-09-08

## Status

Accepted

## Context

How agent sessions talk to github.com has changed four times in about three
weeks. Each change was locally reasonable and none of them wrote down the
whole picture, so the next change kept rediscovering the same constraints.
The sequence:

1. **[ADR 0031](0031-role-scoped-agent-git-identity.md)** pointed git's
   `core.sshCommand` at a dedicated agent key with `-F /dev/null`, bypassing
   `~/.ssh/config` entirely to dodge 1Password's TouchID prompt.
2. **[ADR 0048](0048-agent-session-ssh-key-override-via-match-exec.md)** gave
   plain `ssh` the same key through `Match exec` blocks on `$CLAUDECODE`, so
   ssh config could finally do the job on its own.
3. **PR #34** added `com.technicalpickles.agent-ssh-relay`: a LaunchAgent
   running `gost`, an unsandboxed SOCKS5 proxy on `127.0.0.1:1080` with a
   host:port allowlist, plus a `ProxyCommand` in `ssh/config.d/agent-relay`.
   This exists because the Claude Code sandbox denies outbound port 22 at the
   TCP level but allows localhost. It shipped with no ADR.
4. **Separately**, agent git had been rewritten from `git@github.com:` to
   `https://github.com/` with `gh`'s credential helper, so pushes would work
   at all. That rewrite lived in `~/.gitconfig.local` for the home role and
   silently defeated the relay for every git command, since `insteadOf` can't
   be undone by a later config file once inherited.

The relay and the HTTPS rewrite were solving the same problem in opposite
directions, and the rewrite won by accident. Commit `d865817` untangled that:
it split the shared git settings into `home/.gitconfig.d/common` so
`claude-agent-home` could include them without inheriting the rewrite, and
dropped `core.sshCommand` on the grounds that ADR 0048's `Match` blocks
already select the key and the relay already routes the connection.

That should have worked, and did not. The Claude Code sandbox injects its own
`GIT_SSH_COMMAND` into every Bash tool call, pointing git at the harness's
SOCKS proxy. Git resolves that variable ahead of both `core.sshCommand` and
`ssh_config`, so it silently overrides everything above, and the harness proxy
refuses SSH: it answers the handshake itself as `SSH-2.0-policy_refusal` and
drops the connection without dialing the real host. The symptom is a bare
`ssh_dispatch_run_fatal: ... Broken pipe`, which looks nothing like a policy
denial and cost three sessions to characterize.

This is [anthropics/claude-code#70684](https://github.com/anthropics/claude-code/issues/70684),
open since 2026-06-24 and unfixed as of CLI 2.1.263. The root cause is in
`sandbox-runtime`'s `generateProxyEnvVars()`: the macOS branch builds a SOCKS5
`nc -X 5` `ProxyCommand` with no credentials even when a proxy auth token is
set, while the Linux branch passes `proxyauth` to `socat`. The credential is
present in `HTTPS_PROXY` in the same environment; it simply is not handed to
the SSH path.

## Decision

**Agent git in the home role uses real SSH through the agent-ssh-relay.** The
per-role agent key authenticates the push, not `gh`'s shared OAuth token.

Four layers, each doing exactly one job, none duplicating another:

| Layer         | File                                          | Job                                                                    |
| ------------- | --------------------------------------------- | ---------------------------------------------------------------------- |
| Key selection | `ssh/config.d/auth`                           | `Match exec` on `$CLAUDECODE` + `$DOTPICKLES_ROLE` picks the agent key |
| Transport     | `ssh/config.d/agent-relay`                    | `ProxyCommand` through gost on `127.0.0.1:1080`                        |
| Allowlist     | `config/gost/agent-ssh-relay.yml`             | which host:port pairs the relay will actually reach                    |
| Neutralizer   | `claude/roles/home.jsonc` `SessionStart` hook | `export GIT_SSH_COMMAND=ssh` into `$CLAUDE_ENV_FILE`                   |

The fourth layer is the new part, and the channel is the whole trick. Setting
`GIT_SSH_COMMAND` in the role's `env` block does not work: settings env is
applied _before_ the harness injection and loses. `$CLAUDE_ENV_FILE` is read
afterward, into a cached session-environment script, and wins. Same variable,
same value, different timing. It is only populated for `SessionStart`,
`Setup`, `CwdChanged` and `FileChanged` hooks.

Setting it to bare `ssh` is deliberately the smallest possible override. It
carries no key, no proxy and no policy of its own; it exists purely to stop
the harness value from shadowing `~/.ssh/config`, handing resolution back to
the three layers above.

Correspondingly, `claude-agent-home` carries **no** `core.sshCommand`. It
could never have won against the injected variable, and now that the variable
is neutralized it would only duplicate what ssh config already says. The work
role still sets one, and still uses HTTPS via `gh` (see
[ssh/CLAUDE.md](../../ssh/CLAUDE.md)); this ADR does not change work.

### Alternatives Considered

1. **`url.insteadOf` rewrite to HTTPS for agent git**

   - Pros: two lines, no relay, no hook, proven, unaffected by the sandbox bug
   - Cons: pushes authenticate as `gh`'s shared OAuth token rather than the
     per-role agent key, which is the identity separation ADR 0031 exists to
     provide; macOS `osxkeychain` is unreachable in the sandbox so it must be
     `gh auth setup-git`
   - Rejected: this is the thing `d865817` deliberately undid. Commit signing
     is unaffected either way, so the cost is narrow, but it is the specific
     cost we chose to stop paying.

2. **HTTP CONNECT helper script as `ProxyCommand`**

   - Pros: works through the harness proxy using the credentials already in
     `HTTP_PROXY`; the upstream thread's most complete workaround
   - Cons: a script to maintain, and unnecessary for us
   - Rejected: we already have a relay on localhost that works. This solves
     the problem for people who don't.

3. **Per-command `GIT_SSH_COMMAND=ssh git ...`**

   - Pros: no config at all
   - Cons: depends on every future session remembering
   - Rejected: kept as the documented fallback if the hook stops winning.

4. **`unset GIT_SSH_COMMAND` in a zsh startup file**

   - Rejected: does not work. Claude Code's shell snapshot captures only
     functions, aliases, setopts and `PATH`, so a bare `unset` never reaches
     the Bash tool.

5. **`sandbox.excludedCommands`**

   - Rejected: does not work. The injected variable is inherited by excluded
     commands anyway (upstream #89931).

6. **`dangerouslyDisableSandbox` for every git operation**
   - Rejected: was the status quo, and it means routine fetches and pushes run
     unsandboxed.

## Consequences

### Positive

- Sandboxed agent `git fetch`/`push`/`ls-remote` against SSH remotes work,
  authenticated by the per-role agent key end to end
- No `dangerouslyDisableSandbox` for routine git. The remaining documented
  need for it is `./claudeconfig.sh`'s write to `~/.claude/settings.json`
- Each layer is independently inspectable: `ssh -G git@github.com` shows key
  and proxy resolution, `env | grep GIT_SSH_COMMAND` shows whether the hook
  won, and the gost YAML shows what is reachable
- Adding a git host is still one line in the gost allowlist, unchanged

### Negative

- Depends on a bug staying bugged in a useful direction. If upstream fixes
  #70684 by making the injected value work, ours still wins and that is fine;
  but if the env ordering changes so `$CLAUDE_ENV_FILE` is applied earlier,
  agent git breaks again with the same opaque broken-pipe error
- Depends on `$CLAUDE_ENV_FILE`, which is undocumented and could change
- The `SessionStart` hook is invisible from the git side. Someone debugging a
  git failure has no reason to look at a Claude hook, which is why
  `ssh/CLAUDE.md` names `env | grep GIT_SSH_COMMAND` as the first check
- Home and work now differ in transport, key selection mechanism, and whether
  `core.sshCommand` is set. That is intentional but it is three differences to
  hold in mind
- `bin/check-agent-ssh-key` had to stop asserting `core.sshCommand` and check
  the resolved outcome instead, and its `-F /dev/null` probes had to re-add
  the relay by hand, since that flag discards the `ProxyCommand` along with
  the config leak it is there to prevent

## Links

- Supersedes the git half of [ADR 0031](0031-role-scoped-agent-git-identity.md)
  for the home role: `core.sshCommand` with `-F /dev/null` is replaced by ssh
  config resolution. ADR 0031 still stands for work.
- Builds on [ADR 0048](0048-agent-session-ssh-key-override-via-match-exec.md)
  (`Match exec` key selection), which this ADR now relies on for git too, not
  just plain `ssh`
- Retroactively documents the agent-ssh-relay from PR #34, which shipped
  without an ADR
- Constrains [ADR 0037](0037-validate-agent-ssh-identity-in-claudeconfig.md):
  the validation in `claudeconfig.sh` has to accept both key-selection
  mechanisms
- Upstream: [anthropics/claude-code#70684](https://github.com/anthropics/claude-code/issues/70684),
  duplicate #82255 (closed as stale, not fixed), related #89931
  (`excludedCommands` has no effect)
- Operational detail lives in [ssh/CLAUDE.md](../../ssh/CLAUDE.md); the full
  investigation is bean `dotfiles-mo7y`
