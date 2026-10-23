# 65. prime-agent setup in dotfiles

Date: 2026-10-23

## Status

Accepted

## Context

mise installs `prime-agent` (`config/mise/config.toml`), and [ADR 0064](0064-isolation-policy-for-sandboxed-agents.md) gave it a `safe` profile. Nothing set it up. On a fresh home machine `safe prime-agent` failed twice:

- `could not lease the fresh session file: Operation not permitted`. The profile grants `~/.prime/agent`, but the sandbox can't create it, because that needs write on `~/.prime`.
- `couldn't resolve OPENROUTER_API_KEY with fnox`. The profile's default key comes from fnox, and the home role has no fnox config.

The work role also links a vault-held skill into `~/.prime/agent/skills`, and nothing in the repo did that link or granted its read on home.

## Decision

- `prime.sh`, run from `install.sh` next to `herdr.sh`, creates `~/.prime/agent/skills` and symlinks vault skills into it (today: `writing-voice`). It skips when `prime-agent` or the vault skill is missing.
- Lockfile skills from `skills.sh` need nothing new: prime-agent reads `~/.agents/skills` (checked with `prime-agent config`, sandboxed and not), so `bb-cli` and the rest show up already. `prime.sh` only covers vault-local skills, which aren't in the lockfile.
- `tools/prime-agent.sh` also makes `~/.prime/agent`. The hook runs unsandboxed, so `safe prime-agent` works on a machine where `install.sh` hasn't run yet.
- `role-home.sb` grants the read-only access to each linked vault skill, as `role-work.sb` does. Seatbelt checks the resolved path, so the link alone isn't enough. Adding a skill to `prime.sh` means adding its grant to both role files that apply.
- Home authenticates with `/login` inside prime-agent, not fnox. The credential lands in `~/.prime/agent`, which ADR 0064 already lists as a known gap for shared agent state. The fnox default for `OPENROUTER_API_KEY` now applies to the other roles only.

## Consequences

- A fresh home machine runs `./install.sh` (or just `./prime.sh`), then `prime-agent` once to `/login`.
- A credential written by `/login` is readable inside the sandbox. Narrowing it later means a dedicated key passed through `SAFE_FNOX_KEYS` or the environment.
- The skill list lives in `prime.sh`, and its grants live in the role files. They can drift, with the same symptom as before: EPERM on `SKILL.md`.
