# 19. Fish Plugin Drift Detection

Date: 2026-01-22

## Status

Accepted

## Context

Previously, `fish.sh` had a hardcoded list of fish plugins directly in the script. This caused several problems:

1. **Plugin drift**: Users could manually install plugins via `fisher install`, but running `fish.sh` again would overwrite `fish_plugins` and lose those additions
2. **No visibility**: The script didn't show what plugins it was managing or detect manually-added ones
3. **Brittle updates**: Changing the plugin list required editing bash script code rather than a simple config file

The fish plugin manager (fisher) tracks installed plugins in `~/.config/fish/fish_plugins`, but the old approach deleted and rebuilt this file on every run.

## Decision

Implement a drift detection system with the following architecture:

### Core plugins file

Create `config/fish/core_plugins` - a simple text file listing base plugins:

```
jorgebucaran/fisher
jorgebucaran/autopair.fish
```

Comments (lines starting with `#`) and blank lines are ignored. Conditional plugins (like `fzf.fish` when `fzf` is available) are handled in `fish.sh`, not in this file.

### Drift detection

When `fish.sh` runs, it:

1. Reads core plugins from `config/fish/core_plugins`
2. Adds conditional plugins based on available commands (fzf, direnv)
3. Compares against current `fish_plugins` to find "extra" plugins
4. In interactive mode: prompts user to keep or drop extras
5. In non-interactive mode: auto-preserves extras (safe default for CI/automation)

### Fisher handling

Fisher requires special handling:

- **Never remove fisher** - it must exist to manage other plugins
- **Install/update fisher first** before processing other plugins
- **Remove-then-install** approach for other plugins to handle orphaned files (files exist but not tracked in `fish_plugins`)

### Alternatives Considered

1. **Keep hardcoded list in fish.sh**

   - Pros: Simple, no extra files
   - Cons: No drift detection, easy to lose manual additions
   - Rejected: Doesn't solve the core problem

2. **Use fisher's lock file approach**

   - Pros: Fisher-native solution
   - Cons: Requires manual fish_plugins management, no conditional plugin support
   - Rejected: Doesn't handle conditional plugins or drift detection

3. **Prompt for every plugin individually**
   - Pros: Maximum control
   - Cons: Tedious, bad UX for automation
   - Rejected: Over-engineered for the use case

## Consequences

### Positive

- Manually-installed plugins survive `fish.sh` runs
- Clear separation: core plugins in config file, conditionals in script
- Interactive prompt gives users control over drift
- Non-interactive mode is safe for automation (preserves extras)
- Easy to see what plugins are "managed" vs "extra"

### Negative

- More complex `fish.sh` script
- Running `fish.sh` always does remove-then-install (slightly slower, more verbose output)
- Users must understand the core vs extra distinction

## Links

- Design doc: [doc/plans/2025-01-22-fish-plugin-drift-detection-design.md](../plans/2025-01-22-fish-plugin-drift-detection-design.md)
- Implementation plan: [doc/plans/2025-01-22-fish-plugin-drift-detection-implementation.md](../plans/2025-01-22-fish-plugin-drift-detection-implementation.md)
