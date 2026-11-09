# 69. prime-agent on work-coder

Date: 2026-11-02

## Status

Accepted

Extends [65. prime-agent setup in dotfiles](0065-prime-agent-setup-in-dotfiles.md).

## Context

ADR 0065 gave `work` no `prime/models.<role>.json`, and said nothing about `work-coder`. On a Coder workspace `prime.sh` skipped the models link, so prime-agent had no provider until a `models.json` was hand-written pointing at Coder's AI Bridge (`/api/v2/aibridge/anthropic` and `/openai/v1`).

That file reads its key from `PRIME_AGENT_CODER_AIGATEWAY_SESSION_TOKEN`, and nothing set it. The bridge accepts the workspace owner's Coder session token. The template puts that token in Claude Code's managed settings (`/etc/claude-code/managed-settings.d/10-coder.json`, `env.ANTHROPIC_AUTH_TOKEN`) and deliberately keeps it out of the shell environment. The file is readable by the `coder` user.

prime-agent also sends usage telemetry by default. It honors `PRIME_AGENT_TELEMETRY=0`, `DO_NOT_TRACK=1`, or `telemetry.enabled=false` in `~/.prime/agent/settings.json`.

## Decision

- On `work-coder`, `prime.sh` generates `~/.prime/agent/models.json` with the AI Bridge's anthropic and openai providers instead of linking a committed file. The bridge URL names internal infrastructure and this repo is public, so it comes from the same managed settings file (`env.ANTHROPIC_BASE_URL`); the openai URL swaps the trailing `/anthropic` for `/openai/v1`.
- On `work-coder`, wrap `prime-agent` in a shell function (fish `conf.d/prime-agent.fish`, bash `home/.bashrc`) that reads the token from the managed settings file and sets `PRIME_AGENT_CODER_AIGATEWAY_SESSION_TOKEN` for that one call. A value already in the environment wins.
- Export `PRIME_AGENT_TELEMETRY=0` on every role, from the same two files.

Rejected: a long-lived `coder tokens create` token stored on the workspace. It's a second credential to rotate, and the template already provides one.

## Consequences

- The token stays out of the shell environment, matching the template's intent; only the prime-agent process sees it.
- No internal hostname in the repo, and the config follows the template if the deployment moves.
- `prime.sh` overwrites `models.json` on each run under `work-coder`, so hand edits there don't survive. Add providers to the generator instead.
- The wrapper and generator depend on the template's file path and key names. If the template moves them, prime-agent fails with a missing credential or no provider, and the fix is the path in `prime.sh` and both shell files.
- The daemon appears to take the key per request (a daemon started without the token served a later call that had it, 2026-11-02), so no daemon restart is needed when the token rotates.
- Telemetry is off only for runs launched from a dotfiles shell. Settings-file opt-out stays a manual per-machine step.
- It's a shell function, so anything that execs the binary directly (`timeout prime-agent`, `xargs`, scripts) skips it and gets a 403 from the bridge. Those callers set the variable themselves.
- zsh isn't covered; it isn't used on any role that runs prime-agent.
