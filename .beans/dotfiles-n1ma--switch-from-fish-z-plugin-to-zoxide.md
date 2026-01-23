---
# dotfiles-n1ma
title: Switch from fish z plugin to zoxide
status: completed
type: task
priority: normal
created_at: 2026-01-22T14:20:26Z
updated_at: 2026-01-22T20:41:55Z
---

Replace the fish z plugin with zoxide shell integration to unify directory frecency tracking with sesh.

## Context

Currently running two separate frecency databases:

- Fish z plugin: `~/.local/share/z/data` (111 entries)
- Zoxide: `~/Library/Application Support/zoxide/db.zo` (9 entries, populated by sesh)

Sesh calls zoxide directly for session discovery and adds paths on connect, so switching to zoxide for shell navigation unifies the experience.

## Current state

The fish z plugin was installed separately (not git-tracked in dotfiles):

- `config/fish/conf.d/z.fish` - plugin initialization
- `config/fish/functions/__z.fish` - main function
- `config/fish/functions/__z_add.fish` - add directory to history
- `config/fish/functions/__z_clean.fish` - clean invalid entries
- `config/fish/functions/__z_complete.fish` - completions

(Files were in the symlinked directory but not committed to git)

Data format (fish z): `path|frecency_score|timestamp`

## Plan

### Phase 1: Import history (preserve frecency data)

```bash
# Import fish z history into zoxide (merge with existing sesh entries)
zoxide import --from z --merge ~/.local/share/z/data
```

### Phase 2: Add zoxide shell integration

Create `config/fish/conf.d/zoxide.fish`:

```fish
# Initialize zoxide for fish shell
# Replaces the fish z plugin with zoxide
if command -q zoxide
    zoxide init fish | source
end
```

### Phase 3: Remove fish z plugin files

Delete from dotfiles:

- `config/fish/conf.d/z.fish`
- `config/fish/functions/__z.fish`
- `config/fish/functions/__z_add.fish`
- `config/fish/functions/__z_clean.fish`
- `config/fish/functions/__z_complete.fish`

### Phase 4: Clean up universal variables

The fish z plugin sets universal variables that persist. Clean them up:

```fish
set -e Z_CMD
set -e ZO_CMD
set -e Z_DATA
set -e Z_DATA_DIR
set -e Z_EXCLUDE
```

### Phase 5: Verify

- [ ] `z <partial>` jumps to correct directory
- [ ] `zi` opens interactive selection (if fzf installed)
- [ ] `sesh list -z` shows merged history
- [ ] New `cd` activity feeds into zoxide

## Rollback

If needed, fish z data remains at `~/.local/share/z/data` and can be restored by reverting the dotfiles changes.

## Checklist

- [x] Import fish z history to zoxide with `--merge` (9 → 84 entries)
- [x] Create `config/fish/conf.d/zoxide.fish` with init
- [x] Remove fish z plugin files (weren't git-tracked, removed from filesystem)
- [x] Clean up fish universal variables
- [x] Verify `z` works (`z zen` → `/Users/josh.nichols/workspace/zenpayroll`)
- [x] Verify `sesh list -z` shows unified history (84 entries match zoxide)
- [ ] Commit changes
