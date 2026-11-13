# 70. Disable fish terminal queries for Claude desktop's panel

Date: 2026-11-13

## Status

Accepted

## Context

fish 4.x writes a Primary Device Attributes query (`ESC[0c`) at startup and waits up to 10 seconds for the terminal to answer. Claude desktop's Terminal panel never answers, so every panel tab sat for about 10 seconds, printed "fish could not read response to Primary Device Attribute query", and swallowed any command sent during the wait. Ghostty and tmux answer, so they never stall. Reported upstream as [anthropics/claude-code#109546](https://github.com/anthropics/claude-code/issues/109546).

Load order, traced on a pty that never answers: `conf.d/*.fish` and `config.fish` run first, then fish writes the query and waits. Setting `fish_features` from `conf.d` or `config.fish` (or `-C`) still stalls 10.1s, though, because fish reads the flag once at startup and ignores later changes. Only three inputs are read in time, and each took the prompt from about 10.1s to under 0.2s:

- `fish_features` in the process environment.
- `fish_features` as a universal variable (`~/.config/fish/fish_variables`).
- `fish --features no-query-term` on the command line, also with `-l`.

Nothing in fish's own config files can set it.

A panel-only route was tried and failed. Claude desktop captures a login-shell env by running `$SHELL -l -i -c env` with `CLAUDE_DESKTOP_RESOLVING_ENVIRONMENT=1`, and a `conf.d` guard on that marker did export the flag in a simulated capture. After restarting the app, new panel tabs still stalled and `echo $fish_features` was empty there. From the app bundle (minified, so inference), that capture feeds the agent process env. The panel shell is built from the app's own `process.env`, which fish config can't reach. Settings-level `env` keys don't reach it either (checked against the live panel shells).

## Decision

Set a universal variable once per machine:

```fish
set -Ua fish_features no-query-term
```

It lives in `~/.config/fish/fish_variables`, which this repo doesn't track, so a new machine needs the command run once. Undo with `set -Ue fish_features`.

Rejected:

- A `conf.d` guard on `CLAUDE_DESKTOP_RESOLVING_ENVIRONMENT`. Tested on the live panel, no effect.
- `fish_features` in `config.fish` or `conf.d`. Too late, see the load order above.
- A wrapper shell that adds `--features no-query-term` only when `TERM_PROGRAM=claude-desktop`. It would be panel-only, and the CLI flag works. It needs the login shell changed to the wrapper (`chsh`, an `/etc/shells` entry), because the panel runs the passwd shell as `fish -l` (the app's own env has no `SHELL`, inferred, not traced in the bundle). That touches every login on the machine, which is more than a one-line setting is worth.
- `launchctl setenv`. Same blast radius as the universal variable, plus it affects every GUI app.
- Waiting for the panel to answer the query. The right fix, and filed upstream, but not in our hands.

## Consequences

What `no-query-term` turns off, measured by running fish 4.7.1 on a pty that answers every query, with and without the flag. With the flag, fish stops sending these:

- `ESC[0c` (Primary Device Attributes), the stall itself.
- `ESC[6n` (cursor position report). The docs say it truncates multiline autosuggestions at the screen bottom, feeds `scrollback-push`, and backs OSC 133 `click_events` mouse clicks.
- `ESC]11;?` (background color). `$fish_terminal_color_theme` becomes `unknown` instead of `dark`/`light`, so fish can't pick the light or dark variant of a theme that defines both.
- `ESC[>0q` (XTVERSION), which fish uses only for workarounds on incompatible terminals.
- `ESC[?u` (kitty keyboard protocol query).
- XTGETTCAP for `indn` (`scroll-content-up`, which gates `ctrl-l` using `scrollback-push`) and `query-os-name` (`status terminal-os`).
- A short alternate-screen toggle used to carry the DCS queries.

Still sent either way, so unaffected: bracketed paste (`?2004`), color theme change notifications (`?2031`), and `ESC[>4;1m` (modifyOtherKeys).

Not measured:

- Whether kitty keyboard protocol support is lost in practice. My fake terminal never got fish to enable it in either mode, so the sequence diff says nothing about it. Check in Ghostty with `fish_key_reader` (press `shift-enter` and `ctrl-i` before and after).
- Whether `ctrl-l` still pushes content to scrollback in Ghostty. `status test-terminal-feature scroll-content-up` returned "not detected" in both runs on the fake terminal, so run it in Ghostty with and without the flag.
- Visual effect of `$fish_terminal_color_theme` being `unknown` with the default theme. Not checked.

It applies to every terminal, not just the panel. If Claude desktop starts answering the query, drop the variable.
