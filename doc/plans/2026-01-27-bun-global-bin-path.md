# Bun Global Bin PATH via mise

**Date:** 2026-01-27
**Status:** Implemented

## Problem

Tools installed globally via `bun install -g` (like `qmd`) are placed in `~/.bun/bin`, which isn't in PATH by default.

### Why not bunx?

Investigated using `bunx` to avoid PATH modification, but it doesn't work with qmd because:

- bunx expects the package's `bin` field to point to a JS/TS file
- qmd's bin points to a bash wrapper script (designed to find bun in various locations)
- bunx errors with "could not determine executable to run"

### Why not mise-managed bun's bin?

Even though mise manages bun (`~/.local/share/mise/installs/bun/1.3.1/`), bun hardcodes global package installs to `~/.bun/bin` regardless of where bun itself is installed.

```bash
$ bun pm bin -g
/Users/josh.nichols/.bun/bin
```

## Solution

Add `~/.bun/bin` to PATH via mise's env configuration, keeping all PATH management centralized.

### Change

In `~/.config/mise/config.toml`:

```toml
[env]
_.path = [
  "~/bin",
  "~/.local/bin",
  "~/.cargo/bin",
  "~/.bun/bin",   # Added for bun global packages (qmd, etc.)
]
```

## Verification

After reloading shell:

```bash
which qmd
# Should show: /Users/josh.nichols/.bun/bin/qmd

qmd --help
# Should work without full path
```

## Alternatives Considered

1. **Shell config** - Add to `.zshrc`/fish config directly. Rejected: splits PATH management between mise and shell.
2. **Full paths** - Use `/Users/josh.nichols/.bun/bin/qmd` everywhere. Rejected: verbose, fragile.
3. **Modify qmd** - Change bin to point at `.ts` file. Rejected: loses bun-finding feature, requires upstream change.
