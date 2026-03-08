# 20. tmux prefix C-Space

Date: 2026-01-23

## Status

Accepted

## Context

The default tmux prefix `C-b` conflicts with vim's page-up command, causing friction when working in vim inside tmux. Pressing `C-b` expecting to scroll up in vim would instead activate the tmux prefix, breaking flow.

Additionally, `C-b` doesn't have strong muscle memory associations, making it feel arbitrary rather than intuitive.

Note: Caps Lock is remapped to Control system-wide, which makes `C-Space` particularly ergonomic (left pinky on Caps Lock + thumb on Space).

## Decision

Change the tmux prefix from `C-b` to `C-Space`.

The configuration is placed at the very top of `.tmux.conf`, before any plugins or bindings. This ordering is intentional: plugins like `tmux-sensible` detect whether the prefix has been changed from the default and adjust their behavior accordingly. Setting the prefix before TPM runs ensures plugins see the intended configuration.

```tmux
# Prefix Key (set early so plugins like tmux-sensible detect it)
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix
```

### Alternatives Considered

1. **`C-a`** (GNU Screen default)

   - Popular alternative, especially for Screen users
   - Conflicts with readline's "beginning of line" in shells
   - Rejected: readline conflict is frequent and annoying

2. **Backtick (`` ` ``)**

   - Used by some power users
   - Conflicts with writing markdown and code with backticks
   - Rejected: too disruptive for documentation-heavy work

3. **`C-Space`**
   - Ergonomic: thumb on Ctrl, easy reach to Space
   - No common conflicts in terminal workflows
   - Used as "set mark" in Emacs, but not a frequent operation
   - **Chosen**

## Consequences

### Positive

- No more accidental tmux activation when scrolling in vim
- Ergonomic key combination (pinky on Caps Lock-as-Ctrl + thumb on Space)
- Clean separation: vim has `C-b`/`C-f` for scrolling, tmux has `C-Space`

### Negative

- Muscle memory adjustment period for existing `C-b` habits
- May conflict with input method switching on some systems (not observed in current setup)
- Nested tmux sessions require `C-Space C-Space` to send prefix to inner session
