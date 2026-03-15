# Architecture

## Role-Based Configuration System

The central architectural pattern is **role-based adaptation**. The role is determined once during installation and affects:

- **Git identity & signing**: Different email/name and SSH key selection
- **Brewfile selection**: `Brewfile` + `Brewfile.$ROLE` are merged during brew bundle
- **Shell environment**: Various configs conditionally load based on role

Role detection logic is in [install.sh:12-23](../install.sh#L12-L23). The role defaults to "work" for hostnames matching `josh-nichols-*`, otherwise "personal".

## Symlink-Based File Management

Configuration files live in the repo under `home/` and `config/`, then [symlinks.sh](../symlinks.sh) creates symlinks:

- `home/*` → `$HOME/*` (dotfiles like `.bashrc`, `.tmux.conf`)
- `config/*` → `$HOME/.config/*` (modern XDG config directories)
- `LaunchAgents/*.plist` → `$HOME/Library/LaunchAgents/*` (macOS only)

The `link_directory_contents()` function in [functions.sh:58-76](../functions.sh#L58-L76) handles the symlinking with safety checks.

## Dynamic Git Configuration

Git settings are **generated**, not static. [gitconfig.sh](../gitconfig.sh) rebuilds `~/.gitconfig.local` by:

1. Deleting the old version
2. Enabling git maintenance for all repos in `~/workspace/`
3. Conditionally including config fragments from `home/.gitconfig.d/` based on:
   - Available commands (delta, gh, git-duet, fzf, code/code-insiders)
   - Operating system (macOS)
   - Role (personal/work)
   - 1Password availability (for SSH signing on personal)

`~/.gitconfig.local` should never be edited manually or committed. The base config at [home/.gitconfig](../home/.gitconfig) includes this generated file.

## SSH Configuration

SSH settings are managed through `ssh/config.d/` fragments using SSH's native `Include` directive. See [ADR 0024](adr/0024-versioned-ssh-config-with-config-d.md) for the full rationale.

`sshconfig.sh` symlinks the versioned fragments, generates local-only ones, and ensures `~/.ssh/config` starts with `Include ~/.ssh/config.d/*`. Called by `install.sh`.

See [ssh/CLAUDE.md](../ssh/CLAUDE.md) for working with SSH config.

## Shell Environment Structure

**Fish** is the primary shell. Configuration is modular:

- [config/fish/config.fish](../config/fish/config.fish) is the main entry point
- [config/fish/conf.d/](../config/fish/conf.d/) contains autoloaded configs

**Starship** provides the shell prompt across all shells (fish, bash, zsh) for consistency. See [ADR 0007](adr/0007-switch-to-starship.md).

**Bash** configs in [home/.bash_profile](../home/.bash_profile) and [home/.bashrc](../home/.bashrc) provide fallback support.

See [config/fish/CLAUDE.md](../config/fish/CLAUDE.md) for working with shell config.

## Environment Detection with envsense

The repo uses [envsense](https://github.com/technicalpickles/envsense) for detecting runtime environments (IDEs, agents, CI, terminals). This allows adaptive behavior like setting the correct `EDITOR` when running inside Cursor vs Claude Code vs a terminal.

See [ADR 0009](adr/0009-use-envsense-for-environment-detection.md).

## Brewfile Management

Homebrew packages are managed through **merged Brewfiles**:

- [Brewfile](../Brewfile): Common packages (fish, git, nvim, fzf, jq, etc.)
- `Brewfile.$ROLE`: Role-specific additions (personal or work)

The `brew_bundle()` function in [functions.sh:99-103](../functions.sh#L99-L103) concatenates these files and pipes to `brew bundle`.

## LaunchAgents for macOS Automation

The [LaunchAgents/](../LaunchAgents/) directory contains `.plist` files for macOS launch agents. These are symlinked and can be managed with [launchagents.sh](../launchagents.sh).

## Synthetic Workspace Symlink (Work Only)

On **work** machines running **macOS**, the installation automatically creates a `/workspace` symlink pointing to `~/workspace` via macOS's synthetic filesystem feature (`/etc/synthetic.conf`).

The `setup_synthetic_workspace()` function in [functions.sh:172-211](../functions.sh#L172-L211) manages this. Called only when `DOTPICKLES_ROLE=work`.

## Key Utilities

[functions.sh](../functions.sh) provides reusable helpers:

- `running_macos()` / `running_codespaces()`: Platform detection
- `command_available()`: Check if command exists
- `brew_available()` / `fzf_available()` / `fish_available()`: Tool checks
- `load_brew_shellenv()`: Load Homebrew environment in scripts
- `vscode_command()`: Detect code vs code-insiders
- `link_directory_contents()` / `link()`: Safe symlink creation with overwrite prompts

## Tool Choices

- **mise**: Version manager for ruby, node, python, etc. (see [ADR 0006](adr/0006-switch-to-mise.md))
- **starship**: Cross-shell prompt (see [ADR 0007](adr/0007-switch-to-starship.md))
- **envsense**: Environment detection (see [ADR 0009](adr/0009-use-envsense-for-environment-detection.md))
- **prettier**: Code formatting (see [ADR 0005](adr/0005-editorconfig-and-prettier.md))
- **fzf.fish**: Enhanced fzf integration (see [ADR 0004](adr/0004-switch-to-fzf-fish.md))
