# 9. Use envsense for environment detection

Date: 2025-10-21

## Status

Accepted

## Context and Problem Statement

Dotfiles need to detect different runtime environments (IDEs, coding agents, CI systems, terminals) to adapt behavior appropriately. For example, setting the appropriate `EDITOR` based on which IDE or terminal is running.

Previously, this was done through manual environment variable checks scattered across different config files. For example, in `editor.fish`, we checked `TERM_PROGRAM` and `TERM_PROGRAM_VERSION` directly.

Issues with this approach:

- Detection logic duplicated across multiple files
- Difficult to maintain as new IDEs and environments emerge
- Complex logic needed to distinguish similar environments (e.g., Cursor vs VS Code Insiders vs VS Code, which all set `TERM_PROGRAM=vscode`)
- No centralized source of truth for environment detection
- Priority handling is manual and error-prone

## Decision

Use [envsense](https://github.com/technicalpickles/envsense) for detecting runtime environments across dotfiles.

envsense is a cross-language library and CLI tool that provides standardized environment detection through:

- Declarative environment mappings with priority-based matching
- Detection for agents (Cursor, Claude Code, Replit, Aider, etc.)
- Detection for IDEs (VS Code, VS Code Insiders, Cursor)
- Detection for CI systems (GitHub Actions, GitLab CI, CircleCI, etc.)
- Terminal capability detection (TTY, color support, interactivity)

## Why envsense?

- **Centralized logic**: Single source of truth for environment detection
- **Self-maintained**: Maintained by the same author as these dotfiles, so it can evolve with specific needs
- **Priority-based matching**: Correctly handles overlapping indicators (e.g., Cursor sets `TERM_PROGRAM=vscode` but also sets `CURSOR_TRACE_ID`)
- **Structured output**: JSON API allows programmatic parsing with `jq`
- **Declarative**: Easy to add new environment detection without code changes
- **Cross-shell**: Can be used consistently across Fish, Bash, and Zsh

## Implementation Strategy

- Check for envsense availability before using (graceful degradation if not installed)
- Use `envsense info --json` to get environment data once, then parse with `jq`
- Fall back to simpler heuristics or terminal editors if envsense not available
- Starting with `editor.fish` as proof of concept and initial implementation

Example usage:

```fish
if which envsense >/dev/null
    set -l ide_id (envsense info --json 2>/dev/null | jq -r '.traits.ide.id // empty')
    if test "$ide_id" = cursor && which cursor >/dev/null
        set -gx EDITOR "cursor -w"
    end
end
```

## Consequences

### Positive

- Consistent environment detection across all dotfiles
- Easier to add support for new IDEs/environments as they emerge
- Better Cursor detection (previously couldn't distinguish from VS Code)
- Can share detection logic with work environments
- Single command call per shell initialization (efficient)
- Enables more sophisticated environment-aware behavior

### Negative

- Adds external dependencies (envsense + jq)
- Requires envsense to be installed for full functionality (though graceful fallback exists)
- Initial migration effort to update existing environment checks
- Adds small overhead to shell startup (one envsense call)

### Neutral

- Need to keep envsense updated as new environments and IDEs emerge
- May need to contribute IDE detection back to envsense for broader benefit

## Links

- [envsense repository](https://github.com/technicalpickles/envsense)
- [Initial implementation in editor.fish](../../config/fish/conf.d/editor.fish)
