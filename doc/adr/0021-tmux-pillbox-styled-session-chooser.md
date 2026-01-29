# 21. Tmux Pillbox-Styled Session Chooser

Date: 2026-01-28

## Status

Accepted

## Context

The tmux status bar uses a consistent pillbox visual style with Catppuccin Mocha colors—rounded separators, colored backgrounds, and semantic color coding (green for active, blue for info, etc.). The built-in session chooser (`prefix+s`, which invokes `choose-tree -Zs`) uses plain default formatting, creating visual inconsistency.

Goals:

1. Apply pillbox styling to the session chooser for visual consistency
2. Add semantic color coding (green for attached sessions, blue for others)
3. Display useful metadata (window count) in a compact format

## Decision

Customize the `choose-tree` format using the `-F` flag with pillbox styling that matches the status bar.

### Implementation

```tmux
set -g @_icon_windows "󱂬 " # nf-md-dock_window
set -g @_chooser_format "\
#{?session_attached,#[fg=#a6e3a1],#[fg=#89b4fa]}\
#{@_pill_left}\
#{?session_attached,#[fg=#11111b]#[bg=#a6e3a1],#[fg=#11111b]#[bg=#89b4fa]} \
#{session_windows} #{@_icon_windows}\
#{?session_attached,#[fg=#a6e3a1],#[fg=#89b4fa]}#[bg=default]\
#{@_pill_right}#[default]"

bind-key s choose-tree -Zs -F "#{E:@_chooser_format}"
```

### Key Constraint Discovered

The `choose-tree` command hardcodes a prefix before the custom format:

```
(shortcut) indicator session-name: <custom format>
```

The session name before the colon **cannot be removed, styled, or replaced**. The `-F` format only controls what appears after the colon. This limits alignment possibilities since session names vary in length.

### Alternatives Considered

1. **Include session path in format**

   - Tried: `#{s|$HOME|~|:session_path}` with padding/truncation
   - Rejected: Path often duplicates session name; varying session name lengths before the colon prevent clean alignment regardless of padding

2. **Pad path to fixed width for alignment**

   - Tried: `#{p-40:#{=/38/...:path}}` (40-char left-aligned field with truncation)
   - Rejected: Pills align relative to path column, but the column itself shifts based on session name length—the part we can't control

3. **Use fzf-based picker instead**

   - `sesh` already provides this on `prefix+T` with full format control
   - Rejected for `prefix+s`: Keep the built-in for quick access; fzf picker serves different use case (fuzzy search, zoxide integration)

4. **Include activity/recency timestamp**
   - Available via `#{t:session_activity}`
   - Deferred: Adds clutter; may revisit if needed

## Consequences

### Positive

- **Visual consistency**: Session chooser now matches status bar styling
- **Semantic coloring**: Green pills for attached sessions provide instant visual scanning
- **Compact metadata**: Window count visible at a glance with icon
- **Preserves functionality**: Built-in choose-tree behavior unchanged; just styled

### Negative

- **Limited control**: Cannot style or remove the hardcoded session name prefix
- **Alignment impossible**: Varying session name lengths cause pills to appear at different horizontal positions
- **Nerd font dependency**: Requires nerd fonts for pill separators and window icon

### Files

- `home/.tmux.conf`: Format definition and keybinding
