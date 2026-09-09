---
# dotfiles-mo7y
title: Claude Code sandbox injects GIT_SSH_COMMAND that defeats the agent SSH relay
status: completed
type: bug
priority: high
created_at: 2026-09-09T00:06:00Z
updated_at: 2026-09-09T00:58:44Z
---

Agent git over SSH fails inside the Claude Code sandbox: `git push`/`ls-remote` against an SSH remote dies with

    ssh_dispatch_run_fatal: Connection to UNKNOWN port 65535: Broken pipe

Root cause: the sandbox injects its own `GIT_SSH_COMMAND` into every Bash tool call, pointing git at the harness's SOCKS proxy on a per-session localhost port. Git resolves that env var ahead of both `core.sshCommand` and `ssh_config`, so it silently defeats the agent-ssh-relay -- git never reaches the `Match` blocks at all. That is why `home/.gitconfig.d/claude-agent-home` carries no `core.sshCommand`: it could never win.

Plain `ssh` (not through git) is unaffected, since the variable only applies to git's own ssh invocations.

## Findings (2026-09-08, terminal CLI session)

**Not desktop-app-specific.** Reproduces identically in the terminal Claude Code CLI (`CLAUDE_CODE_ENTRYPOINT=cli`, Ghostty) under `DOTPICKLES_ROLE=home`. Earlier scoping to the desktop app's Code tab was wrong -- both surfaces get the same injection. The template string is hardcoded in the CLI binary (both an `nc -X 5 -x localhost:` and a `socat - PROXY:localhost:` variant), so it is not derived from `GIT_CONFIG_GLOBAL` or anything else in dotfiles.

Injected value observed:

    GIT_SSH_COMMAND=ssh -o ControlMaster=no -o ControlPath=none -o ProxyCommand='nc -X 5 -x localhost:59799 %h %p'

**The harness proxy refuses SSH by policy, it does not fail to tunnel it.** It answers the SSH handshake itself as `SSH-2.0-policy_refusal` and drops the connection right after KEXINIT, never dialing the real host. Probed raw with netcat, it states the reason in plaintext: "This proxy requires authentication, and this client did not offer an authentication method, so the connection was refused." The gost relay on 127.0.0.1:1080 returns GitHub's real banner (`SSH-2.0-cb4a187`) for the same destination.

This is **not** github.com missing from `sandbox.network.allowedDomains` -- a ruleset denial looks different (`SOCKS error 2`, seen on :443 through the same proxy). So the two proxies are the same architecture (git -> ssh -> SOCKS5 on localhost) racing each other, and only ours reaches GitHub.

**Overriding the variable fixes it, sandboxed.** All three tested in one sandboxed session:

| command | result |
| --- | --- |
| `git ls-remote` as injected | broken pipe |
| `env -u GIT_SSH_COMMAND git ls-remote` | real HEAD sha |
| `GIT_SSH_COMMAND=ssh git ls-remote` | real HEAD sha |

Bare `ssh` hands resolution back to `~/.ssh/config`, whose `$CLAUDECODE` Match blocks already select the home agent key and route github.com through the relay. So this is **not** the permanent "agent git needs dangerouslyDisableSandbox" caveat it looked like.

## Changes made

- `claude/roles/home.jsonc`: added `"GIT_SSH_COMMAND": "ssh"` to the role `env` block, with the reasoning inline.
- `ssh/CLAUDE.md`: new "The `GIT_SSH_COMMAND` conflict" subsection under Agent-Session SSH Relay.
- `bin/check-agent-ssh-key`: two fixes this exposed.
  - Check 6 demanded `core.sshCommand` reference the agent key, which the home role deliberately dropped -- this was failing `./claudeconfig.sh` outright. Now checks the *outcome*: `core.sshCommand` when set (work role), else `ssh -G` resolution under the role (home role).
  - Checks 7 and 8 use `-F /dev/null` for key isolation, which also discards the relay `ProxyCommand`, so they dialed port 22 directly and failed sandboxed for reasons unrelated to the key. They now re-add the relay when `$CLAUDECODE` is set.

## Checklist

- [x] Reproduce in a terminal-based Claude Code CLI session -- reproduces, so not desktop-app-specific
- [x] Determine whether the harness proxy could be made to work instead (allowlist, etc.) -- no, it refuses SSH by policy
- [x] Find an override that works from role env config -- `GIT_SSH_COMMAND=ssh`
- [x] Document the caveat in ssh/CLAUDE.md
- [x] Unblock `./claudeconfig.sh` (stale `core.sshCommand` expectation in check-agent-ssh-key)
- [x] **Verify from a session started after `./claudeconfig.sh`** -- done, and the answer is no: the harness wins.

## Verification result (fresh session, post-claudeconfig)

Sandboxed, `env` still shows the injected proxy command (new per-session port) and `git ls-remote` still fails with the broken pipe, even though `~/.claude/settings.json` correctly contains `"GIT_SSH_COMMAND": "ssh"`. So role env is applied *before* the harness's injection and loses.

Unsandboxed, `env` shows `GIT_SSH_COMMAND=ssh` (ours) and `git ls-remote` returns the real HEAD sha -- no injection happens there because there's no proxy. The role entry is therefore not useless, it just only governs the unsandboxed case.

Two other routes checked and ruled out:

- **No opt-out flag.** The injection is unconditional in the CLI binary, part of a blanket proxy env block (`ALL_PROXY`, `GRPC_PROXY`, `FTP_PROXY`, `RSYNC_PROXY`, Docker vars) emitted whenever the sandbox has a SOCKS port.
- **Shell startup files can't undo it.** Claude Code's shell snapshot captures only functions, aliases, setopts and `PATH`, so a guarded `unset GIT_SSH_COMMAND` in `.zshrc` never reaches the Bash tool.

## RESOLVED: SessionStart hook + $CLAUDE_ENV_FILE

`claude/roles/home.jsonc` now has a `SessionStart` hook appending `export GIT_SSH_COMMAND=ssh` to `$CLAUDE_ENV_FILE`. Verified on 2.1.263 from a fresh session: `env` shows bare `GIT_SSH_COMMAND=ssh`, and sandboxed `git fetch` / `git ls-remote` against `git@github.com:` both succeed through the agent-ssh-relay. Agent git no longer needs `dangerouslyDisableSandbox`.

The channel is the whole trick. Role `env` is applied *before* the harness injection and loses; `$CLAUDE_ENV_FILE` is read later into a cached session-environment script and wins. It's only populated for SessionStart/Setup/CwdChanged/FileChanged hooks.

## Upstream

This is [anthropics/claude-code#70684](https://github.com/anthropics/claude-code/issues/70684), open since 2026-06-24, unfixed as of 2.1.263, plus duplicate #82255 (closed as stale by a bot 2026-09-07, not fixed; someone commented 2026-09-08 that it still reproduces). Root cause is in `sandbox-runtime`'s `generateProxyEnvVars()`: the macOS branch builds the SOCKS5 `nc -X 5` ProxyCommand with no credentials even when a proxy auth token is set, while the Linux branch passes `proxyauth` to `socat`. Regressed by a June PR that added proxy auth. The source comment documents the incompatibility and sets the broken value anyway.

Worth knowing from that thread: `sandbox.excludedCommands` does NOT help (the var is inherited anyway, tracked as #89931), and the `SessionStart` hook was reported *not* working on 2.1.191 in June, which is why the thread moved on to HTTP CONNECT helper scripts and `insteadOf` HTTPS rewrites. It works on 2.1.263. Most of those people need the harness proxy because they have no local relay; we don't.

## Follow-ups

Split out to its own bean: posting the positive `SessionStart` result on #70684, since the thread's current conclusion is that no config-level fix exists.

If a CLI upgrade brings the broken-pipe error back, the env ordering changed. Fall back to `GIT_SSH_COMMAND=ssh git ...` per command and re-check which channel wins.
