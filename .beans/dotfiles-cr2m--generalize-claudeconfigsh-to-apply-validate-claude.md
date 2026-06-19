---
# dotfiles-cr2m
title: Generalize claudeconfig.sh to apply + validate Claude config (agent SSH key)
status: completed
type: feature
priority: normal
created_at: 2026-06-15T19:40:12Z
updated_at: 2026-06-15T19:44:44Z
---

Generalize `claudeconfig.sh` from "apply Claude config" to "apply AND validate my
Claude config," starting with the agent SSH key (the motivating gap from
dotfiles-w4tk).

## Behavior

After the existing apply phases (symlink CLAUDE.md, sandbox dirs, generate
settings.json, marketplaces), add a final **validate** phase that runs
`bin/check-agent-ssh-key "$ROLE"` for the active role. Fail-loud: validation
failure makes `claudeconfig.sh` exit non-zero. Apply always completes first, so a
validation failure never leaves config half-written -- it only affects exit code.

## Email is derived, not hardcoded

`check-agent-ssh-key` needs `--email`. The agent email already lives in the role's
gitconfig include (`home/.gitconfig.d/claude-agent-<role>` -> `user.email`). Read it
with `git config --file`, so there's one source of truth (no work->gusto.com /
home->gmail.com mapping to drift).

## Skip when nothing to check

If a role has no `claude-agent-<role>` include (e.g. `base`), there's no agent
identity -> validate phase is a no-op for that role.

## Escape hatch: --skip-ssh-check

`--skip-ssh-check` flag (and `SKIP_SSH_CHECK=1` for non-interactive) bypasses only
the key validation, leaving apply intact. Needed because on a fresh machine
claudeconfig runs (setup step 4) BEFORE the key is registered/SSO-authorized
(steps 2/3/6), and for offline runs. setup-agent-ssh-key's "re-run claudeconfig.sh"
step becomes `claudeconfig.sh --skip-ssh-check`.

## Structured for growth

Validate phase is its own function so future config checks (settings.json schema,
plugin health) can be added there later. Not building those now (YAGNI).

## Known consequence

Turning this on means the next `claudeconfig.sh` run fails until `gh auth refresh -h
github.com -s user:email` (the real gap check flags today) or `--skip-ssh-check`.
Fail-loud working as intended.

## Checklist
- [x] Arg/env parse for --skip-ssh-check / SKIP_SSH_CHECK
- [x] validate_agent_ssh_key() phase (derive email, skip when no agent, fail loud)
- [x] Wire into setup-agent-ssh-key step 4 (--skip-ssh-check)
- [x] Test: arg parse, --help, bad-arg (exit 2), email derivation (work -> +agent@gusto.com), base no-op, --skip-ssh-check early-return, and live check exit=1 (fail-loud trigger via current user:email gh-scope gap)
