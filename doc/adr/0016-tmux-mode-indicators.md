# 16. Mode Indicators in tmux Status Bar

Date: 2026-01-21

## Status

Accepted

## Context

While re-learning tmux after years away from terminal multiplexers, I encountered confusion about what "mode" tmux was in at any given time.

The specific trigger: using the `tmux-mighty-scroll` plugin for mouse scrolling, the terminal would sometimes get "stuck" in a state where normal key commands (Escape, q, Ctrl-C) wouldn't work. Without visual feedback about the current mode, I couldn't diagnose whether I was:

- In copy mode (vi-style navigation active)
- Waiting for prefix key completion (after pressing Ctrl-b)
- In synchronized pane mode (commands broadcast to all panes)
- In normal mode (just terminal passthrough)

The existing `tmux2k` theme didn't provide explicit mode indicators, only a `prefix_highlight` color option that wasn't documented clearly.

## Decision

Switch to Catppuccin theme with custom mode indicators showing four distinct states:

### Mode States

| State  | Color            | Label  | Trigger                            |
| ------ | ---------------- | ------ | ---------------------------------- |
| Normal | Green (#a6e3a1)  | `TMUX` | Default state                      |
| Prefix | Blue (#89b4fa)   | `WAIT` | After pressing prefix key (Ctrl-b) |
| Copy   | Yellow (#f9e2af) | `COPY` | In copy/scroll mode                |
| Sync   | Red (#f38ba8)    | `SYNC` | Synchronized panes active          |

### Implementation

Custom status-left using tmux conditionals and Catppuccin Mocha palette:

```tmux
set -g @_mode "#{?client_prefix,#[bg=#89b4fa]#[fg=#11111b]  WAIT ,#{?pane_in_mode,#[bg=#f9e2af]#[fg=#11111b]  COPY ,#{?pane_synchronized,#[bg=#f38ba8]#[fg=#11111b]  SYNC ,#[bg=#a6e3a1]#[fg=#11111b]  TMUX }}}"
```

### Why Catppuccin Over tmux2k

1. **Better documentation**: Clear examples for custom status bar elements
2. **Module system**: Pre-built components (date, time) that integrate cleanly
3. **Consistent palette**: Named colors match other Catppuccin-themed tools (Ghostty, etc.)
4. **Active maintenance**: Regular updates and community support

### Alternatives Considered

1. **tmux-prefix-highlight plugin**

   - Pros: Dedicated plugin for this exact purpose
   - Cons: Another plugin dependency; limited to prefix/copy/sync modes
   - Rejected: Custom implementation gives more control and fewer dependencies

2. **Stay with tmux2k + custom additions**

   - Pros: No theme switch required
   - Cons: Less documented, harder to customize
   - Rejected: Catppuccin better fits the "mode indicator first" requirement

3. **No mode indicators, just learn the modes**
   - Pros: Simpler config
   - Cons: Slower learning curve, frustration during scroll-stuck incidents
   - Rejected: Visual feedback significantly improves usability

## Consequences

### Positive

- **Immediate mode awareness**: Glance at status bar to know current state
- **Faster debugging**: "Stuck" states immediately identifiable as COPY mode
- **Consistent aesthetics**: Catppuccin Mocha matches Ghostty terminal theme
- **Self-documenting**: Mode names in status bar teach tmux concepts

### Negative

- **Custom config complexity**: Nested conditionals in status-left are hard to read
- **Theme migration effort**: Required rewriting status bar configuration
- **Color dependency**: Assumes terminal supports true color (Ghostty does)

### Files

- `home/.tmux.conf`: Mode indicator configuration in status-left
