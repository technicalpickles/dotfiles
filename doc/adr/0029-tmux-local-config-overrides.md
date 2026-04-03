# 29. tmux local config overrides

Date: 2026-04-03

## Status

Accepted

## Context

The same dotfiles get deployed to multiple machines (personal laptop, work machines, remote servers), and sometimes tmux needs to look or behave differently depending on where it's running. The motivating case: using a different catppuccin flavor on a remote server so SSH tabs are visually distinct from local ones at a glance.

Git config already solves this with `.gitconfig.local` (generated per-machine, never committed). SSH config uses `config.d/` fragments. tmux had no equivalent, so any per-machine customization meant either maintaining forks of `.tmux.conf` or just not doing it.

## Decision

Source `~/.tmux.local.conf` at the very end of `.tmux.conf`, guarded by an existence check:

```tmux
if-shell '[ -f ~/.tmux.local.conf ]' 'source-file ~/.tmux.local.conf'
```

It loads last so it can override anything: theme flavor, status bar layout, keybindings, plugin options.

The file is not committed to the dotfiles repo. Each machine creates its own (or doesn't, and gets the defaults).

### Why at the end?

Catppuccin's tmux plugin reads `@catppuccin_flavor` at plugin init time, but `source-file` after TPM init can still override computed styles and status bar config. For theme flavor changes to take full effect, a `tmux source ~/.tmux.conf` reload is needed (same as any config change).

### Alternatives Considered

1. **Conditional logic in .tmux.conf based on hostname**
   - `if-shell '[ "$(hostname)" = "myserver" ]' 'set ...'`
   - Rejected: puts machine-specific knowledge in the committed config. Grows into a mess.

2. **Separate .tmux.conf per machine**
   - Rejected: duplication. The configs are 95% identical.

3. **Environment variable toggles**
   - `if-shell '[ "$TMUX_THEME" = "frappe" ]' 'set ...'`
   - Not bad, but requires setting env vars in shell config, which is another layer of indirection. The local file is more self-contained.

## Consequences

### Positive

- Per-machine tmux customization without forking or branching the config
- Follows the same `.local` pattern as gitconfig, so it's a familiar convention
- Zero impact on machines that don't create the file

### Negative

- The local file isn't tracked anywhere, so it's on you to remember what you set. (But that's true of `.gitconfig.local` too, and it's been fine.)
- Theme flavor overrides after TPM init may not apply 100% cleanly without a reload. In practice this is fine since you reload after editing config anyway.
