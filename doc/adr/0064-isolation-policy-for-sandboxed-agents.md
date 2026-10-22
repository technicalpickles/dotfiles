# 64. isolation policy for sandboxed agents

Date: 2026-10-21

## Status

Proposed

## Context

[ADR 0060](0060-agent-safehouse-wrapper.md) and [ADR 0063](0063-per-invocation-grants-for-safe.md) give `safe` its grants one at a time, as each tool hit an EPERM. That works, but it has no stated rule for what _should_ be shared with a sandboxed agent, isolated from it, or denied. Without one, every new tool re-argues the same questions (its cache dir, its config, its credentials), and the grants accrete.

Two questions decide the treatment of any path or credential:

1. **Execute-later:** can a write there run outside the sandbox without anyone choosing to run it? Shell rc files, git hooks and config, mise config and tasks, shims on `PATH`, LaunchAgent sources.
2. **Secret:** can a read there leak a credential? Cloud SSO token caches, Keychain-held tokens, personal ssh keys, npm tokens.

## Decision

Treatments, strongest first. Pick the strongest one the tool can still work under.

1. **Deny:** not granted.
2. **Isolate:** a private per-tool copy, such as its own XDG cache and state root, or a generated config file holding only what the tool needs.
3. **Narrow:** a scoped, short-lived substitute for the real credential, passed through the environment. [ADR 0031](0031-role-scoped-agent-git-identity.md) did this for git (a dedicated agent ssh-agent and identity); other credential domains follow the same pattern.
4. **Share read-only.**
5. **Share read-write:** the workdir, by design, and the exceptions below.

| Category                                                                  | Treatment                                       |
| ------------------------------------------------------------------------- | ----------------------------------------------- |
| Credentials (SSO caches, Keychain tokens, personal keys)                  | Deny the store; narrow what the agent gets      |
| Execute-later config (shell rc, git hooks and config, mise config, tasks) | Read-only or deny, never writable               |
| Harmless shared config (git config, editor config)                        | Read-only                                       |
| Caches                                                                    | Isolate per tool                                |
| State and IPC (daemon sockets, venvs, locks, histories)                   | Isolate per tool, with dedicated socket dirs    |
| Installed runtimes and gems (mise installs, shims, global gem dir)        | **Shared read-write, accepted for now** (below) |
| Project-local deps (`vendor/bundle`, `node_modules`, `.venv`)             | Workdir, read-write                             |

Tool-specific grants and env belong in per-tool profiles, not `common.sb`. Anything specific to an employer or a repo is layered on by the caller, outside this repo.

### Tool profiles

`bin/safe` picks the tool from `SAFE_TOOL`, else the basename of the command, and looks in `config/agent-safehouse/tools/`:

- `<tool>.sb` is appended after `common.sb`.
- `<tool>.sh` is sourced. It sets variables, lists the ones the tool needs in `SAFE_TOOL_ENV` (passed through safehouse's env strip), and may set `SAFE_SOCKET_DIRS` and `SAFE_XDG_ISOLATE=1`. `safe` creates the tool's private root (`~/.local/share/safe/<tool>`, mode 700) and grants it read-write.
- `SAFE_XDG_ISOLATE=1` redirects `XDG_CACHE_HOME` and `XDG_STATE_HOME` into that root. Config and data stay real, because redirecting them hides mise config and installs. mise's trust state lives in its state dir, so the isolated copy is seeded one way from the real `trusted-configs` and `tracked-configs` (no-clobber, each run). Existing repos stay trusted, but a `mise trust` run by the tool lands in its own root and never in yours. On macOS mise's cache is `~/Library/Caches/mise`, not under XDG, so it stays shared.

First profiles: `prime-agent` (the real `~/.prime/agent` shared, plus a private daemon socket, kernel venv and worker sockets) and `pi` (the plannotator grant, moved out of `common.sb`). Neither isolates XDG yet: pi hasn't been run under that to see what it needs, and dedicated caches are parked for later. mcporter's grants also stay in `common.sb` until its users are known.

### Accepted exception: agent state shared with the unsandboxed tool

An agent's own state dir (`~/.pi`, `~/.prime/agent`) is shared read-write, so sessions and settings are one history whether or not the run was sandboxed. Safehouse's built-in `pi.sb` already does this for pi; `prime-agent` follows it. Two things stay private anyway: the daemon socket (a sandboxed and an unsandboxed run must not attach to each other's daemon) and the kernel venv (code the tool imports, which an unsandboxed run would otherwise execute). Known gaps: runtime files in the shared dir (session leases, worker dirs) are common to both, and a credential written by `/login` is readable inside the sandbox.

### Accepted exception: shared mise and bundler

Agents must be able to run `mise install`, `bundle install` and dependency updates, and they do so routinely (after every new worktree, on every dependency bump). Making the shared install dirs read-only would block that, and warming them outside the sandbox would stop an agent from adding a missing tool mid-task.

So mise's data dir and the gem dirs stay writable to sandboxed agents. This is a known gap, not a position: a sandboxed write there (a shim, an installed gem or tool) can run outside the sandbox later. It is the same execute-later class the escape guard in `role-work.sb` covers for other paths.

### Where to improve

- A per-tool `MISE_DATA_DIR`, with the real install dir as a read-only fallback if mise supports a shared lookup dir. Installs then land in the isolated root.
- `BUNDLE_PATH` pointed into the workdir, so gems stop going to the shared gem dir.
- Warm installs outside the sandbox for bounded jobs (crews), keeping the shared dirs read-only there.
- Seeding isolated caches from the real ones, to avoid slow first runs.

## Consequences

- New tools get a profile that follows the table instead of a one-off grant. The inventory of what each tool actually touches should come from running it under `safe` and collecting the sandbox's allow and deny traces, not from guessing.
- Until the shared-install exception is closed, a compromised or misbehaving agent can plant code in mise and gem dirs. Installing from the workdir keeps its effect to that worktree; installing globally does not.
- Credentials that are narrowed instead of shared expire. The failure shows up in the tool's own words, far from the cause, and a long-lived daemon pins its old env. Diagnostics help here: a way to show which grant a deny maps to, a stale-profile warning for daemons, and a doctor check for missing setup steps.
- Network access is a separate axis and isn't covered here.
