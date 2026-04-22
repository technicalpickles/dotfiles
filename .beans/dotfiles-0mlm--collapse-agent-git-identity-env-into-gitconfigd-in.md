---
# dotfiles-0mlm
title: Collapse agent git identity env into gitconfig.d include
status: in-progress
type: task
priority: normal
created_at: 2026-04-18T23:34:32Z
updated_at: 2026-04-18T23:40:39Z
---

Refactor the role-scoped agent git identity (ADR 0031) to reduce env var bloat in `claude/roles/personal.jsonc`. Today the env block has 11 keys (author email x2, SSH_COMMAND, and 4 pairs of GIT_CONFIG_COUNT/KEY_N/VALUE_N). Collapse to a single `GIT_CONFIG_GLOBAL` pointing at a gitconfig.d include file.

## Background

Verified in conversation on 2026-04-18:

- `user.email` in a gitconfig correctly sets both author and committer when `GIT_AUTHOR_EMAIL`/`GIT_COMMITTER_EMAIL` env vars are unset.
- `core.sshCommand` in gitconfig replaces `GIT_SSH_COMMAND` env var.
- `~/.gitconfig.d/` is already symlinked to `home/.gitconfig.d/` (via `link_directory_contents home`), so dropping a file in the repo just works.
- `GIT_CONFIG_GLOBAL` does NOT expand `~` or `$HOME` (both fail). Must be absolute, OR claudeconfig.sh expands it before writing settings.json.

Decision: teach claudeconfig.sh to expand leading `~/` in `.env` string values, so JSONC stays portable.

## Target shape

`claude/roles/personal.jsonc` env block becomes:

```jsonc
"env": {
  "GIT_CONFIG_GLOBAL": "~/.gitconfig.d/claude-agent-personal"
}
```

New file `home/.gitconfig.d/claude-agent-personal`:

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

The `[include]` pulls in main gitconfig first (transitively including `~/.gitconfig.d/1password` and its `op-ssh-sign`); later sections in our file override. Last-write-wins, so `gpg.ssh.program = ssh-keygen` still defeats 1Password.

## Checklist

- [x] Modify `claudeconfig.sh` to expand leading `~/` in `.env` string values (jq post-process, ~8 lines)
- [x] Create `home/.gitconfig.d/claude-agent-personal` with include + overrides
- [x] Collapse env block in `claude/roles/personal.jsonc` to single `GIT_CONFIG_GLOBAL` key
- [x] Rework check #6 in `bin/check-agent-ssh-key`: validate `GIT_CONFIG_GLOBAL` is set in settings.json, target file exists, and contains the required overrides (user.email, core.sshCommand, gpg.ssh.program=ssh-keygen)
- [x] Update `doc/adr/0031-role-scoped-agent-git-identity.md` Implementation section to describe the collapsed shape (keep the "three subtleties" explanation, but reframe them as gitconfig settings rather than env vars)
- [x] Run `claudeconfig.sh` to regenerate `~/.claude/settings.json`
- [ ] Verify: commit + SSH push from a new Claude session still works, Verified badge still green
- [x] Run `bin/check-agent-ssh-key personal` — all checks pass

## Out of scope

Work-role identity: ADR 0031 already flags this as a drop-in parallel (separate bean when needed).
