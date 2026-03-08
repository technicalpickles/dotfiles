# 18. Switch from Fish z Plugin to Zoxide

Date: 2026-01-22

## Status

Accepted

## Context

The fish z plugin ([jethrokuan/z](https://github.com/jethrokuan/z)) provided directory jumping via frecency tracking, storing history in `~/.local/share/z/data`. This worked well in isolation.

When adopting [sesh](https://github.com/joshmedeski/sesh) for tmux session management (see [ADR 0015](0015-auto-session-naming.md)), I discovered sesh integrates deeply with [zoxide](https://github.com/ajeetdsouza/zoxide):

- `sesh list -z` queries zoxide's database directly via `zoxide query --list --score`
- `sesh connect` adds paths to zoxide via `zoxide add <path>` on every connection
- This happens regardless of whether zoxide shell integration is configured

The result was **two separate frecency databases**:

| Tool              | Database                                     | Entries |
| ----------------- | -------------------------------------------- | ------- |
| Fish z plugin     | `~/.local/share/z/data`                      | 111     |
| Zoxide (via sesh) | `~/Library/Application Support/zoxide/db.zo` | 9       |

The `z` command and `sesh list -z` showed different directories, creating cognitive overhead.

Zoxide had been on the backlog as part of the broader trend of adopting "oxidized" tools - modern Rust rewrites of classic Unix utilities (like `ripgrep`, `bat`, `fd`, `eza`). Sesh adoption was the catalyst to finally make the switch.

## Decision

Replace the fish z plugin with zoxide shell integration to unify directory frecency tracking.

### Migration Steps

1. **Import existing history**: `zoxide import --from z --merge ~/.local/share/z/data`
2. **Add zoxide init**: Create `config/fish/conf.d/zoxide.fish` with `zoxide init fish | source`
3. **Remove fish z plugin**: Delete the untracked plugin files from the fish config directory
4. **Clean up universal variables**: Remove `Z_CMD`, `Z_DATA`, etc. set by the old plugin

### Key Insight

Zoxide's binary is the requirement, not shell integration. Sesh works with zoxide even without `zoxide init` because it calls the binary directly. However, shell integration unifies the experience so `z` and `sesh list -z` share the same frecency data.

## Consequences

### Positive

- **Unified frecency database**: Shell navigation and sesh session discovery use the same data
- **Consistent mental model**: `z` suggestions match `sesh list -z` results
- **Future-proof**: Zoxide is actively maintained with better performance than fish z
- **Cross-shell**: Zoxide works across fish, bash, zsh if needed

### Negative

- **Slight behavior differences**: Zoxide's frecency algorithm differs slightly from fish z
- **Additional binary**: Requires zoxide installed (already was for sesh)

### Rollback

Fish z data remains at `~/.local/share/z/data`. Reverting the dotfiles changes and reinstalling the fish z plugin would restore the old setup.
