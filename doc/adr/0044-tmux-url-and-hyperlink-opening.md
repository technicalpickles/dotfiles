# 44. tmux URL and hyperlink opening

Date: 2026-07-26

## Status

Accepted

## Context

Text in a tmux pane can point at a URL in two different ways:

1. **A bare URL as visible text** -- e.g. someone pastes `https://example.com/foo`, or a tool prints the URL literally.
2. **An OSC 8 hyperlink** -- the terminal escape sequence that attaches a URL to arbitrary display text, so what you see (e.g. "FR: Add/remove passkeys to an existing user · Issue #15071") isn't the URL itself. Claude Code emits these for issue/PR references in its output.

These need different handling, and until now only the first was actually wired up. Investigating why an OSC 8 hyperlink from Claude Code output couldn't be clicked in Ghostty surfaced two separate gaps:

- tmux only forwards OSC 8 sequences to the outer terminal if that terminal is declared to support them via `terminal-features`. Without it, tmux silently strips the escape codes and only the display text survives -- there's nothing left to click.
- `home/.tmux.conf` sets `mouse on` (for pane resize, scroll, selection via tmux-pain-control etc.), which means tmux -- not Ghostty -- owns mouse clicks by default. A plain click, even with a modifier, is a tmux mouse-mode event first. Ghostty's own hyperlink-open behavior only fires when the click bypasses tmux's mouse capture, via Shift+Cmd+Click.

Separately, `home/.tmux.conf` already unbinds `DoubleClick1Pane` (see commit `963038f`, "use full path for pickletown..." -- the unbind was bundled into an unrelated commit) in favor of the `tmux-open` plugin. `bin/tmux-smart-open`, a script that piped double-click selections through `open` if they looked like a URL, was the mechanism this replaced. The script is still in the repo and still documented in `bin/CLAUDE.md`, but nothing calls it anymore.

## Decision

Two separate, complementary mechanisms cover the two link types:

### Bare-text URLs

Double-click to select the word (tmux's native mouse behavior), then press `o` (bound by the `tmux-open` plugin, `home/.tmux.conf:108`) to open the selection in the default browser. `word-separators` is kept minimal (`home/.tmux.conf:79`) specifically so a double-click selects a whole URL, not just a fragment of it.

### OSC 8 hyperlinks

1. Tell tmux the outer terminal supports hyperlinks, so it passes OSC 8 sequences through instead of stripping them:

   ```tmux
   set -as terminal-features ',xterm-ghostty:hyperlinks'
   ```

   This is negotiated once per client at attach time, not re-read on `source-file` -- after changing this setting (or its first install), detach and reattach (`tmux detach` / `tmux attach`) for it to take effect. Confirm it applied via `tmux list-clients -F '#{client_termfeatures}'` -- look for `hyperlinks` in the list.

2. Click with **Shift+Cmd+Click** in Ghostty, not a plain Cmd+click. Since `mouse on` makes tmux the default click handler, the Shift modifier is what tells Ghostty to take the click for itself instead of forwarding it to tmux's mouse reporting.

### tmux-smart-open

Removed. It was dead code -- nothing had bound it since the `DoubleClick1Pane` unbind -- and its `bin/CLAUDE.md` entry described behavior (double-click to open) that the current config no longer provides.

### Alternatives Considered

1. **`set -g mouse off`**

   - Makes plain Cmd+click work for hyperlinks (Ghostty gets all mouse events unconditionally).
   - Rejected: gives up tmux-native mouse pane resize, scrolling, and drag-selection, which are used daily. Not worth trading away for one less modifier key.

2. **Re-bind `DoubleClick1Pane` to `tmux-smart-open` for hyperlinks too**
   - Doesn't work: double-click-and-pipe only ever sees the plain-text selection tmux copies out, never the underlying OSC 8 URL. The hyperlink's target isn't recoverable from copy-mode text at all -- it has to be opened by the terminal emulator's own hyperlink handling, which requires giving it the raw click.

## Consequences

### Positive

- Both plain URLs and OSC 8 hyperlinks (as emitted by Claude Code, `gh`, etc.) are now clickable inside tmux, each via the input path suited to how they're actually represented.
- The fix generalizes: any future OSC 8-aware tool's links work the same way, no per-tool config needed.

### Negative

- Two different gestures for two kinds of links (`o` after double-click vs. Shift+Cmd+Click) is not obvious and will be forgotten; this ADR is the reference for "how do I click this."
- `terminal-features` hardcodes `xterm-ghostty` -- switching terminal emulators means updating this value (and confirming the new terminal supports OSC 8 hyperlinks and has an equivalent bypass-the-multiplexer click modifier).
