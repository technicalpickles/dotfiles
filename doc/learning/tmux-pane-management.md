# Tmux Pane Management

## Goal

Learn to manage tmux panes effectively, specifically:

- Splitting windows into panes (editor + terminal side-by-side)
- **Pulling existing windows into panes** (not just creating new empty splits)

Background: Transitioning from GNU screen experience; looking for intuitive workflows.

## Key Concepts

### Terminology

| Screen Term | Tmux Term | Description                  |
| ----------- | --------- | ---------------------------- |
| regions     | panes     | Subdivisions within a window |
| windows     | windows   | Containers for panes         |
| -           | sessions  | Containers for windows       |

### Mental Model Shift

**Important realization**: In tmux, you don't create an empty split and then fill it. Instead, you _pull_ an existing window into your current window, and tmux creates the split automatically.

## Basic Pane Commands (defaults)

| Action                          | Keybinding         | Notes            |
| ------------------------------- | ------------------ | ---------------- |
| Split vertically (left/right)   | `Ctrl-b %`         | Hard to remember |
| Split horizontally (top/bottom) | `Ctrl-b "`         | Hard to remember |
| Navigate between panes          | `Ctrl-b ←↑↓→`      | Arrow keys       |
| Close current pane              | `Ctrl-b x`         | Or type `exit`   |
| Resize pane                     | `Ctrl-b Ctrl-←↑↓→` | Hold Ctrl        |
| Zoom pane (toggle fullscreen)   | `Ctrl-b z`         | Great for focus  |

## Joining Existing Windows into Panes

This is the key workflow we were trying to solve.

### Method 1: Mark and Join

1. Go to window you want to move: `Ctrl-b 2`
2. Mark it: `Ctrl-b m` (shows `M` in status bar)
3. Go to target window: `Ctrl-b 0`
4. Join marked pane: `Ctrl-b :join-pane -h` + Enter

The `-h` flag creates a horizontal (side-by-side) split.

### Method 2: Direct Command

From your target window:

```
Ctrl-b :join-pane -hs :2
```

This pulls window 2 into your current window as a right-side split.

### Method 3: Custom Keybindings (recommended)

Add to `.tmux.conf`:

```bash
bind m select-pane -m # mark current pane
bind M join-pane -h   # join marked pane here (side-by-side)
```

Workflow becomes:

1. Go to window to move → `Ctrl-b m`
2. Go to target → `Ctrl-b M`

### Opposite Operation: Break Pane

To turn a pane back into its own window:

```
Ctrl-b :break-pane
```

Or `Ctrl-b !` (default binding)

## Plugins Installed

### tmux-pain-control

Provides more intuitive keybindings for splits:

| Keybinding       | Action                          |
| ---------------- | ------------------------------- |
| `Ctrl-b \|`      | Split vertically (side-by-side) |
| `Ctrl-b -`       | Split horizontally (top/bottom) |
| `Ctrl-b h/j/k/l` | Navigate panes (vim-style)      |
| `Ctrl-b H/J/K/L` | Resize panes                    |

Mnemonic: `|` looks like a vertical line, `-` looks like a horizontal line.

### tmux-menus

Provides popup menus for discoverable operations:

- Trigger: `Ctrl-b \`
- Navigate menus to explore available pane operations

## Still To Do

- [ ] Add custom `m`/`M` keybindings for mark/join workflow
- [ ] Practice the mark → navigate → join workflow
- [ ] Explore tmux-menus pane options more thoroughly

## Resources

- [tmux-pain-control](https://github.com/tmux-plugins/tmux-pain-control)
- [tmux-menus](https://github.com/jaclu/tmux-menus)
