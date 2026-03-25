# 27. tmux command palette

Date: 2026-03-20

## Status

Accepted

## Context

tmux keybindings accumulate over time from multiple sources: tmux defaults, plugins (tmux-sensible, tmux-pain-control), and custom bindings in `.tmux.conf`. Without a discovery mechanism, the only way to find available bindings is to read the config or run `tmux list-keys` manually.

Neovim solves this with which-key, which shows available bindings after pressing the leader key. We wanted something similar for tmux.

## Decision

Three parts:

### 1. Command palette script (`bin/tmux-command-palette`)

A custom script that pipes `tmux list-keys -N` through fzf-tmux, styled to match existing pickers (sesh, workspace). Bound to `prefix + ?`.

We chose a custom script over tmux-fzf's keybinding.sh because tmux-fzf uses `list-keys` (raw command format) instead of `list-keys -N` (human-readable descriptions). The custom script also gives us control over colors and formatting.

### 2. Key binding notes (`-N`) on all custom bindings

tmux's `bind-key -N "description"` flag attaches a human-readable note to a binding. These appear in `list-keys -N` output. All custom bindings in `.tmux.conf` now use `-N`.

### 3. Upstream contributions for plugin binding notes

Forked tmux-pain-control and tmux-sensible to add `-N` notes to their bindings, since there's no way to annotate an existing binding after the fact. PRs submitted upstream:

- [tmux-plugins/tmux-pain-control#37](https://github.com/tmux-plugins/tmux-pain-control/pull/37)
- [tmux-plugins/tmux-sensible#77](https://github.com/tmux-plugins/tmux-sensible/pull/77)

Using forks (pinned to `add-key-binding-notes` branch) until upstream merges.

### Alternatives Considered

1. **tmux-which-key** (alexwforsythe/tmux-which-key)
   - Manually curated menu system, not auto-discovered from actual bindings
   - Requires maintaining a separate `config.yaml` in sync with real bindings
   - Rejected: doesn't solve the discovery problem

2. **tmux-menus** (jaclu/tmux-menus)
   - Rich built-in menu system using tmux's native `display-menu`
   - No fuzzy finding, static navigation only
   - Rejected: not a command palette

3. **tmux-fzf keybinding mode** (sainnhe/tmux-fzf)
   - Fuzzy finding over keybindings, but uses raw `list-keys` format without descriptions
   - Rejected for keybinding discovery, but kept for its other features (session/window/pane management)

## Consequences

### Positive

- All bindings are discoverable via `prefix + ?` with fuzzy search
- Plugin bindings now have descriptions, matching tmux's own builtin bindings
- Styled consistently with existing fzf pickers (sesh, workspace)

### Negative

- Using forks of tmux-sensible and tmux-pain-control adds maintenance burden until upstream merges (both repos are slow-moving)
- New bindings in `.tmux.conf` need to remember to use `-N` flag
