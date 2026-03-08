# 14. Re-adopt tmux for Claude Code Workflows

Date: 2026-01-21

## Status

Accepted

## Context

While experimenting with [Gastown](https://github.com/anthropics/claude-code-gastown), a tool that uses tmux to structure and manage multiple Claude Code instances, I rediscovered the value of terminal multiplexers for AI-assisted development workflows.

Key pain points with alternatives:

1. **VS Code/Cursor integrated terminals**: IDE crashes or restarts lose terminal state and any running Claude sessions
2. **Plain terminal tabs**: No session persistence across terminal app restarts, no ability to detach/reattach
3. **iTerm2 native tmux integration**: Less portable, ties workflow to specific terminal app

Previous experience with `screen` (years ago) provided familiarity with the concept, but I hadn't actively used tmux in modern workflows.

The shift to running Claude Code primarily in terminals (vs IDE integrated terminal) created new requirements:

- **Session persistence**: Claude sessions can be long-running; need to survive terminal disconnects
- **Multi-session management**: Working across multiple projects means multiple Claude instances
- **Visual organization**: Clear separation between projects and their associated Claude sessions

## Decision

Adopt tmux as the primary terminal environment for Claude Code sessions, with a modern configuration stack:

### Core Stack

- **TPM (Tmux Plugin Manager)**: Plugin management for extensibility
- **tmux-sensible**: Reasonable defaults as a baseline
- **tmux-pain-control**: Standardized pane navigation (vim-style)
- **Catppuccin theme**: Modern aesthetics consistent with other tools (Ghostty, etc.)

### Session Workflow

Use `sesh` (session manager) for quickly switching between project sessions, where each session corresponds to a project directory.

### Configuration Philosophy

- Keep `.tmux.conf` readable with clear section comments
- Use plugins for complex behaviors (scroll handling, pane management)
- Custom status bar for workflow-specific information (mode indicators, Claude spend)

## Consequences

### Positive

- **Stability**: Claude sessions survive VS Code crashes, terminal restarts, and SSH disconnects
- **Context switching**: Easy to jump between projects with preserved terminal state
- **Consistency**: Same workflow whether SSH'd to a server or working locally
- **Extensibility**: Rich plugin ecosystem for adding capabilities
- **Visual feedback**: Custom status bar shows exactly what I need to know

### Negative

- **Learning curve**: tmux keybindings and concepts take time to internalize (especially coming from screen)
- **Configuration complexity**: Custom status bars require understanding tmux's format strings
- **Plugin debugging**: When plugins conflict, diagnosis can be tedious
- **Copy/paste quirks**: Terminal copy mode differs from native OS selection

### Related ADRs

- [ADR 0015](0015-auto-session-naming.md): Auto-naming sessions based on directory
- [ADR 0016](0016-tmux-mode-indicators.md): Mode indicators in status bar
- [ADR 0017](0017-claude-spend-tmux-status.md): Claude spend tracking in status bar
