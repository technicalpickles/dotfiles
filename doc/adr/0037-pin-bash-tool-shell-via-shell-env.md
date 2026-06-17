# 37. Pin the Bash tool shell via SHELL env

Date: 2026-06-17

## Status

Accepted

## Context

Our login shell is fish. Claude Code's Bash tool does not, and cannot, run
fish. The two facts collide in a way that quietly degrades Claude's reasoning.

Reading the bundled JS (v2.1.178) shows two separate functions both read
`process.env.SHELL` and then do opposite things with it:

- **The system prompt's `Shell:` line.** A helper builds the line as
  `Shell: ${value}`, where `value` is `"zsh"` or `"bash"` only when `$SHELL`
  contains those substrings, and otherwise the raw `$SHELL` verbatim. fish is
  not special-cased, so the prompt prints `Shell: /opt/homebrew/bin/fish`.
- **The Bash tool's shell resolver.** It accepts a shell path only if it
  contains `bash` or `zsh` (after an optional `CLAUDE_CODE_SHELL` override,
  which is validated the same way). When `$SHELL` is neither (fish), it is
  dropped from the candidate list entirely and the resolver falls back to a
  detection list ordered `zsh`, then `bash`, across `/bin`, `/usr/bin`,
  `/usr/local/bin`, `/opt/homebrew/bin`. On macOS that resolves to `/bin/zsh`.

Net effect: the prompt tells Claude the shell is **fish**, while every Bash
command actually runs in **zsh** (confirmed live: `ZSH_VERSION=5.9`,
`$SHELL` inside the tool is `/bin/zsh`). Claude has no signal that the
substitution happened.

The observable symptom is misattribution. When a command misbehaves on
quoting, globbing, or `!`, Claude reaches for the one shell name it was given
and blames fish, even though fish never ran the command. The clearest tell:
`!`-mangling is zsh history expansion, a thing fish does not even do. Past
sessions also "explained" a grep `--include` failure as fish not expanding a
flag, which is not a shell concern at all. The wrong mental model produces
confidently wrong diagnoses.

The Bash tool genuinely cannot be made to run fish (it sources shell snapshots
written in bash/zsh syntax: `shopt`, `setopt NO_EXTENDED_GLOB`, `.zshrc`). So
the fix is not to change the shell. It is to stop lying to Claude about which
shell it already uses.

This is a known upstream gap: anthropics/claude-code#68349 documents the same
resolver behavior and the undocumented `CLAUDE_CODE_SHELL` override.

## Decision

Set `SHELL=/bin/zsh` in the `env` block of `claude/roles/base.jsonc`, so it
applies to every role.

`claudeconfig.sh` merges `base.jsonc` into `~/.claude/settings.json` (see
[ADR 0013](0013-claude-code-configuration-management.md)), and Claude Code
applies the `env` block to `process.env` at session init (the same mechanism
[ADR 0031](0031-role-scoped-agent-git-identity.md) uses for
`GIT_CONFIG_GLOBAL`). Both functions above then read `/bin/zsh` instead of the
fish path:

- The prompt's `Shell:` line normalizes it to `Shell: zsh`. Honest now.
- The resolver was already selecting `/bin/zsh`, so execution is unchanged.

The change corrects what Claude is _told_, not what it _does_. `/bin/zsh` is the
exact binary the resolver lands on, and it exists on every macOS host. The
resolver guards each candidate (including a pinned `$SHELL`) with an existence
check, so even on a host without `/bin/zsh` the value falls back to detection
rather than breaking commands.

### Alternatives Considered

1. **`CLAUDE_CODE_SHELL=/bin/zsh` instead of `SHELL`**

   - Pros: the purpose-built override for the Bash tool's shell
   - Cons: it only feeds the resolver, which already picks zsh, so it changes
     nothing observable. The prompt's `Shell:` line reads `SHELL`, not
     `CLAUDE_CODE_SHELL`, so it would stay wrong
   - Rejected: wrong knob for the actual problem (the misleading prompt line)

2. **Do nothing, rely on a memory note telling Claude "Bash runs zsh, not fish"**

   - Pros: no config change; works in sessions where the note is loaded
   - Cons: depends on the note being recalled every session and on every
     machine; the prompt keeps actively asserting "fish" underneath it
   - Rejected as the sole fix: treats the symptom, leaves the false signal in
     place. Still worth keeping as a belt-and-suspenders

3. **Switch the login shell to zsh**
   - Pros: removes the mismatch at the source
   - Cons: throws out the fish setup this whole repo is built around for a
     problem scoped entirely to one tool's prompt line
   - Rejected: wildly disproportionate

## Consequences

### Positive

- The prompt's `Shell:` line matches the shell that actually runs commands, so
  the fish-blaming misattribution stops
- No change to command execution: the Bash tool already ran zsh
- Applies to every role via `base.jsonc`, including fresh machines, without
  per-role setup

### Negative

- `SHELL` is now overridden for the Claude process and everything it spawns.
  Interactive fish is launched by the terminal, not by Claude, so it is
  untouched. But any hook, MCP server, or `$SHELL -c` subprocess that keys off
  `$SHELL` now sees zsh instead of fish. This is more internally consistent
  (everything is zsh), not less, but it is a real behavior change
- Takes effect on the next fresh session, not the current one, since `env` is
  applied once at session init
- The pinned path assumes macOS. The resolver's existence check makes a missing
  path safe (it falls back to detection), but the literal `/bin/zsh` is a
  macOS-shaped choice
