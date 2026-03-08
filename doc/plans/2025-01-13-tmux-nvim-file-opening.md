# Plan: Tmux-Session-Aware File Opening in nvim

## Goal

Command-click on file paths (from `eza`, `fd`, etc.) opens files in an nvim instance running in the **current tmux session**, with smart fallback behavior.

## Desired Behavior

When Command-clicking a file path:

1. Find nvim instances running in panes of the **current tmux session**
2. If **one nvim** found → open file there
3. If **multiple nvim** → show selection (fzf popup)
4. If **no nvim** → create new nvim in a new pane, using the git root of the current window's directory as pwd

## Current State (Already Implemented)

- `~/.config/nvim/lua/polish.lua` - Has server mode with `/tmp/nvim.sock`
- `bin/tmux-open-in-nvim` - Basic script (needs rewrite)
- `home/.tmux.conf` - Has copy-mode keybindings
- `config/fish/config.fish` - Has `eza --hyperlink` and `fd --hyperlink` aliases

## Architecture

```
Command-click "nvim:///path/to/file" in Ghostty
        ↓
macOS URL handler (nvim-handler.app)
        ↓
bin/nvim-open (smart opener script)
        ↓
┌─────────────────────────────────────────┐
│ 1. Detect current tmux session          │
│ 2. Find nvim panes in that session      │
│ 3. Match nvim PIDs to socket files      │
│ 4. Select target (auto or fzf)          │
│ 5. Open file or create new nvim         │
└─────────────────────────────────────────┘
```

## Implementation

### Step 1: Update nvim Server Sockets (Per-PID)

Change nvim to create sockets named by PID so we can match them to tmux panes.

**File:** `~/.config/nvim/lua/polish.lua`

```lua
-- Create socket at /tmp/nvim-<PID>.sock
local socket = "/tmp/nvim-" .. vim.fn.getpid() .. ".sock"
vim.fn.serverstart(socket)
```

Remove the single `/tmp/nvim.sock` - we'll discover sockets by PID instead.

### Step 2: Create Smart Opener Script

**File:** `bin/nvim-open`

This script:

1. Gets current tmux session (from `$TMUX` or active client)
2. Lists panes running nvim: `tmux list-panes -s -F "#{pane_pid}|#{pane_current_command}|#{window_index}.#{pane_index}"`
3. For each nvim pane, finds socket at `/tmp/nvim-<child_pid>.sock` (nvim is child of pane shell)
4. If one nvim → send file via `nvim --server <socket> --remote`
5. If multiple → use `fzf` in tmux popup to select
6. If none → find git root, create new pane, start nvim with file

**Key tmux commands:**

```bash
# Get current session
tmux display-message -p "#{session_name}"

# List nvim panes in session
tmux list-panes -s -t "$session" -F "#{pane_pid}|#{pane_current_command}|#{window_index}.#{pane_index}" \
  -f "#{==:#{pane_current_command},nvim}"

# Find child nvim process (nvim is child of fish/bash in pane)
pgrep -P "$pane_pid" nvim

# Get pane's current path for git root detection
tmux display-message -t "$session:$window" -p "#{pane_current_path}"

# Create new pane and run nvim
tmux split-window -c "$git_root" "nvim '$file'"
```

### Step 3: Create macOS URL Handler App

**Directory:** `macos/nvim-handler.app/`

Structure:

```
nvim-handler.app/
└── Contents/
    ├── Info.plist          # Registers nvim:// scheme
    └── MacOS/
        └── nvim-handler    # Shell script that calls bin/nvim-open
```

**Info.plist:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>nvim-handler</string>
    <key>CFBundleIdentifier</key>
    <string>com.pickles.nvim-handler</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>nvim</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

**MacOS/nvim-handler:** Shell script that parses `nvim:///path/to/file` and calls `~/.pickles/bin/nvim-open`

### Step 4: Update CLI Hyperlink Aliases

Change hyperlinks to use `nvim://` scheme instead of default `file://`.

**File:** `config/fish/config.fish`

```fish
# Use nvim:// scheme for hyperlinks so they open in nvim
if command -q eza
    alias ls="eza --hyperlink=always"
    alias ll="eza -l --hyperlink=always"
    alias la="eza -la --hyperlink=always"
end
```

**Problem:** `eza` and `fd` emit `file://` URLs, not custom schemes.

**Solution:** Create wrapper scripts that post-process output to convert `file://` → `nvim://`, OR configure the URL handler to intercept `file://` for terminal clicks.

**Alternative:** Register handler for `file://` scheme (risky - affects all apps) OR use Ghostty-specific config if available.

### Step 5: Installation

**File:** `install.sh` additions

```bash
# Symlink nvim-handler.app to ~/Applications
link "$HOME/.pickles/macos/nvim-handler.app" "$HOME/Applications/nvim-handler.app"

# Register the URL handler (may need to run once manually)
# macOS auto-discovers apps in ~/Applications
```

## Files Summary

**Modified:**

- `~/.config/nvim/lua/polish.lua` - PID-based sockets
- `config/fish/config.fish` - Update hyperlink handling
- `install.sh` - Add app symlink

**Rewritten:**

- `bin/tmux-open-in-nvim` → `bin/nvim-open` - Smart session-aware opener

**New:**

- `macos/nvim-handler.app/Contents/Info.plist`
- `macos/nvim-handler.app/Contents/MacOS/nvim-handler`

## Verification

1. Start nvim in a tmux pane, verify `/tmp/nvim-<PID>.sock` exists
2. Run `ls` (eza), verify hyperlinks appear
3. Command-click a file path
4. Verify it opens in the nvim instance in current session
5. Start second nvim, Command-click → verify fzf selection appears
6. Close all nvim, Command-click → verify new nvim pane created at git root

## Open Questions

1. **Hyperlink scheme**: `eza`/`fd` emit `file://` not `nvim://`. Options:

   - Wrapper scripts that sed-replace the scheme (adds latency)
   - Override `file://` handler system-wide (risky)
   - Ghostty-specific URL handler config (if available)

2. **Detecting "current" session from URL handler**: The handler runs outside tmux. We need to determine which session is "current":

   - Use the most recently attached client: `tmux list-clients -F "#{client_session}" | head -1`
   - Or track focus via a background process

3. **fzf selection UI**: Use `tmux display-popup` with fzf, or a native macOS picker?
