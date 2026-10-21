# 63. per-invocation grants for safe

Date: 2026-10-21

## Status

Accepted

## Context

[ADR 0060](0060-agent-safehouse-wrapper.md) put dotfiles' safehouse overrides in `common.sb` and `role-<role>.sb`. Those are per machine role. Some tools need extra grants that belong to the tool or the repo, not the role: a daemon that binds unix sockets, a toolchain that writes a cache dir, a credential profile to read. Putting those in a role file would make every `safe` run carry them, and would pull tool- and employer-specific paths into a public repo.

Safehouse already has env knobs for most of this (`SAFEHOUSE_ADD_DIRS`, `SAFEHOUSE_ADD_DIRS_RO`, `SAFEHOUSE_ENV_PASS`), and `safe` forwards its arguments, so `--append-profile` and `--env-pass` work per call. The gap is unix sockets: safehouse has no flag for them, so a tool that runs a daemon has to hand-write a `.sb` file.

## Decision

`bin/safe` reads `SAFE_SOCKET_DIRS` (colon-separated). Each dir is created if missing, resolved with `pwd -P`, and granted bind, inbound and outbound for unix sockets through a temp profile appended after `common.sb` and before the role profile, so role denies still win. Without it `safe` still `exec`s safehouse; with it, `safe` stays resident to remove the temp file and passes the exit status through.

Per-tool wrappers (a daemon-based agent, a repo-specific preset) live with the tool and set these env vars before calling `safe`. Nothing tool- or employer-specific lands in this repo.

`bin/safe-tmux` is the tool-neutral version of driving `safe $SHELL` from a detached tmux session.

## Consequences

- Wrappers get sockets, write dirs, read dirs and env passthrough without editing dotfiles.
- A grant given through these knobs is only as narrow as the caller makes it. Grant a dedicated socket dir, not a state dir or `$HOME`.
- The daemon-pins-its-sandbox behavior of some tools is the tool's problem: grants don't reach a daemon started earlier under a different profile.
