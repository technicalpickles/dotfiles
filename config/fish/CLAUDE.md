# Fish Shell Config

Fish is the primary shell. Config is modular via `conf.d/` autoloading.

## Structure

- `config.fish`: Main entry point, minimal -- delegates to conf.d/
- `conf.d/`: Autoloaded on shell start, alphabetical order

## Key conf.d Files

- `editor.fish`: Sets `EDITOR` based on `envsense` environment detection (Cursor vs Claude Code vs terminal)
- `ghostty.fish`: Ghostty-specific setup
- `cursor_agent.fish`, `obsidian.fish`: IDE-specific behaviors
- `atuin.fish`: Shell history with atuin
- Tool inits: starship, homebrew, bat, git-duet, mise, etc.

## Adding New Config

Drop a `.fish` file in `config/fish/conf.d/`. It autoloads on next shell start. No need to source manually.

## Starship Prompt

Configured at `config/starship.toml`. Uses `tide_rainbow` palette with hardcoded hex colors -- requires true color terminal support. See [ADR 0007](../../doc/adr/0007-switch-to-starship.md).

Variant configs: `config/starship-agent.toml` (Claude Code sessions), `config/starship-obsidian.toml`.
