# 66. Turn off the command sandbox for the home role

Date: 2026-10-26

## Status

2026-10-26 accepted

## Context

The home role ran Claude Code's Bash sandbox (Seatbelt, `sandbox.enabled: true` from `base.jsonc`). Over the past few weeks of brineworks and pickleclaw work, a steady share of the agent friction logged in taskwarrior traced back to it rather than to the work itself:

- `mise run ci` fails sandboxed: the CI containers' pip can't reach PyPI through the sandbox proxy, so every run is retried unsandboxed.
- `bw email` token refresh can't write the Keychain.
- `.git/config` is in the "denied within allowed" set, so `git push -u`, `git branch -D` and `wt remove` do their ref work and then half-fail, leaving orphaned `branch.*` sections behind (see `claude/rules/worktrees.md`).
- `wt switch` fails writing a repo-shipped `.vscode/settings.json`, and a backgrounded server can't be signalled from a later command.
- Skills that keep state under `~/.claude/skills` (the pickleclaw status page) need an escape on every run.

Each one already has a known workaround (`dangerouslyDisableSandbox` on the one command), so the sandbox mostly bought a retry and a prompt, not protection. The paths it guards that matter most (`~/.claude/settings.json`, hooks, skills) are the same ones the workarounds open up anyway.

## Decision

Set `sandbox.enabled: false` in `claude/roles/home.jsonc`. `base.jsonc` keeps it on, so other roles are unchanged unless they already turn it off (`work-coder`, `claude-code-remote` do).

The home role's `allowedDomains` and `allowWrite` entries stay in place. They do nothing while the sandbox is off, and keeping them means turning it back on is a one-line change.

## Consequences

- `autoAllowBashIfSandboxed` no longer applies, so every Bash call goes to the auto-mode classifier (`defaultMode: auto`). That is now the only gate on Bash in home sessions. The classifier's own over-triggering (taskwarrior f54dd775, 7f54075f) matters more, not less.
- The sandbox's `GIT_SSH_COMMAND` proxy injection goes away, so agent git reaches github.com through `~/.ssh/config` and the agent-ssh-relay with no workaround needed. The `SessionStart` hook that forces `GIT_SSH_COMMAND=ssh` stays harmless.
- Sandbox-specific notes in brineworks and pickleclaw docs (CI needing the sandbox off, the escapes list) become moot for home sessions; the matching tasks can be checked and closed.
- Nothing stops a misbehaving command from writing anywhere the user can. The classifier and the agent's own judgement are the remaining guard.
