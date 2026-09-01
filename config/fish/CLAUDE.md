# Fish Shell Config

Fish is the primary shell. Config is modular via `conf.d/` autoloading.

## Structure

- `config.fish`: Main entry point, minimal -- delegates to conf.d/
- `conf.d/`: Autoloaded on shell start, alphabetical order

## Key conf.d Files

- `dotpickles-role.fish`: Sets `DOTPICKLES_ROLE` (canonical names `home`/`work`, see [ADR 0035](../../doc/adr/0035-canonical-dotpickles-role-names.md))
- `editor.fish`: Sets `EDITOR` based on `envsense` environment detection (Cursor vs Claude Code vs terminal)
- `ghostty.fish`: Ghostty-specific setup
- `cursor_agent.fish`, `obsidian.fish`: IDE-specific behaviors
- Tool inits: starship, homebrew, bat, git-duet, pyenv, rustup, uv, zoxide, etc. (mise inits in `config.fish`, not conf.d)

## Load Order Gotcha

Fish sources `conf.d/*.fish` (alphabetically) **before** `config.fish`. Anything a
conf.d file reads at init time must be set by an earlier-sorting conf.d file, not
`config.fish` -- by the time `config.fish` runs, the prompt is already built.

This is why `DOTPICKLES_ROLE` lives in `conf.d/dotpickles-role.fish` and not
`config.fish`: `starship-init.fish` reads the role to build `STARSHIP_CTX`, and
`dotpickles-role` sorts before `starship-init`. When it lived in `config.fish` the
role was always unset at prompt-build time, so the prompt silently fell back to its
default and showed the wrong role.

## Adding New Config

Drop a `.fish` file in `config/fish/conf.d/`, then run `./fish.sh --check` (repo root) to symlink it into `~/.config/fish/conf.d/`. `~/.config/fish` is a real directory, not a symlinked one -- see "Why Not a Directory Symlink" below -- so a new file in the repo doesn't appear live until something links it. `fish.sh --check` does just that sync (no sudo, no chsh, no fisher), reports what it linked, and is safe to run any time to catch drift.

## Why Not a Directory Symlink

`symlinks.sh`'s generic `link_directory_contents` would normally symlink all of `config/fish` as one unit, same as other `config/*` dirs. It's explicitly excluded from that (`functions.sh`'s `skip=(... config/fish ...)`) because Fisher (the fish plugin manager) writes into `~/.config/fish` at runtime, and a whole-directory symlink would make those writes land in the git repo. Instead `fish.sh` keeps `~/.config/fish` a real directory and individually symlinks each file under `conf.d/` and `functions/`.

The tradeoff: per-file symlinks don't appear automatically when a new file is added to the repo -- nothing re-runs that link step on its own. A file added and forgotten silently has no effect (its own `conf.d` autoload just never happens) until someone runs `fish.sh` (or `fish.sh --check`) again. Confirmed happening in practice: `dotpickles-role.fish` sat unlinked in the repo for ~2 months, so `DOTPICKLES_ROLE` silently never got set in interactive shells and the prompt fell back to its default "home" role.

## Starship Prompt

Configured at `config/starship.toml`. Uses `tide_rainbow` palette with hardcoded hex colors -- requires true color terminal support. See [ADR 0007](../../doc/adr/0007-switch-to-starship.md).

Variant configs: `config/starship-agent.toml` (Claude Code sessions), `config/starship-obsidian.toml`.
