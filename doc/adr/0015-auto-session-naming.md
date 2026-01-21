# 15. Auto-Session Naming Based on Directory

Date: 2026-01-21

## Status

Accepted

## Context

When working with multiple tmux sessions across different projects, the default numeric session names (0, 1, 2, ...) provide no context about what each session contains.

With `sesh` as a session switcher, meaningful session names become even more valuable—the switcher list becomes useful navigation rather than a guessing game.

Manual session naming (`tmux new -s project-name`) requires:

1. Remembering to name sessions when creating them
2. Knowing what to name them (often the project directory anyway)
3. Consistency in naming conventions

## Decision

Implement automatic session renaming via a tmux hook that triggers when sessions are created:

### Mechanism

A `session-created` hook invokes `bin/tmux-auto-rename-session` which:

1. **Skips explicit names**: If the session already has a non-numeric name (user deliberately named it), leave it alone
2. **Renames to directory basename**: Otherwise, rename to the basename of `$PWD`

### Configuration

```tmux
set-hook -g session-created 'run-shell "~/.pickles/bin/tmux-auto-rename-session \"#{session_name}\" \"#{pane_current_path}\""'
```

### Script Logic

```bash
# Skip if session has an explicit name (default names are numeric: 0, 1, 2, ...)
if [[ ! "$session_name" =~ ^[0-9]+$ ]]; then
  exit 0
fi

# Rename to directory basename
new_name="$(basename "$pane_path")"
tmux rename-session -t "$session_name" "$new_name"
```

### Alternatives Considered

1. **Always rename regardless of explicit name**

   - Rejected: Breaks intentional naming when `tmux new -s specific-name` is used

2. **Use full path as session name**

   - Rejected: Too long, clutters status bar and session switcher

3. **Hash-based unique names**

   - Rejected: Not human-readable, defeats the purpose of meaningful names

4. **Plugin-based solution**
   - Rejected: Simple enough to implement inline; no plugin provides exactly this behavior

## Consequences

### Positive

- **Zero-friction naming**: Sessions get useful names without manual intervention
- **Consistent conventions**: All auto-named sessions follow same pattern (directory basename)
- **Sesh integration**: Session switcher immediately shows project context
- **Respects intent**: Explicit names are preserved when user provides them

### Negative

- **Duplicate names possible**: Two sessions in directories with same basename get same name (tmux handles this with suffixes)
- **Short names can be ambiguous**: `dotfiles` is less specific than `~/workspace/dotfiles`
- **Hook execution timing**: Runs after session creation, so there's a brief flash of the numeric name

### Files

- `bin/tmux-auto-rename-session`: The renaming script
- `home/.tmux.conf`: Hook configuration
