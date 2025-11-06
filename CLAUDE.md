# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository that manages shell configurations, git settings, and macOS system preferences. The repository uses a **role-based configuration system** that adapts settings based on whether the environment is "personal" or "work".

**Important**: This repository uses Architecture Decision Records (ADRs) to document why architectural choices were made. See [doc/adr/](doc/adr/) for the full history. When making significant architectural changes, create a new ADR using `bin/adr new "title"`.

## Installation & Setup

```bash
git clone https://github.com/technicalpickles/dotfiles ~/.pickles
~/.pickles/install.sh
```

The installation script:

1. Determines the role (personal/work) based on hostname or `DOTPICKLES_ROLE` env var
2. Initializes git submodules
3. Symlinks files from `home/` to `$HOME` and `config/` to `$HOME/.config`
4. Runs `gitconfig.sh` to build `~/.gitconfig.local` dynamically
5. On macOS: installs Homebrew, runs `brew bundle`, configures system defaults
6. Sets up shell environments (fish, bash, tmux)

## Development Commands

### Linting & Formatting

```bash
npm run typecheck    # Run TypeScript type checking
npm run format       # Format all files with Prettier
npm run format:check # Check formatting without modifying
npm run lint         # Run both typecheck and format:check
npm run test         # Alias for lint
```

### Pre-commit Hooks

Managed by `lefthook`. Install with `lefthook install`. On commit:

- Prettier formats staged files
- TypeScript type checks if `.ts` files are staged

### Devcontainer Development

The devcontainer provides a consistent Linux environment for developing dotfiles:

**Live Editing:** Changes to files in the workspace are immediately visible at `~/.pickles` via symlink created during post-create. Most changes (shell configs, scripts) take effect when you restart the terminal or source configs.

**When to re-run install.sh:** Structural changes that affect symlinks or generated configs may require running:

```bash
bash ~/.pickles/install.sh
```

**How it works:**

1. Dockerfile builds image and installs dotfiles to `/home/vscode/.pickles`
2. Container starts, workspace mounts to `/workspaces/dotfiles`
3. `post-create.sh` swaps the directory: `~/.pickles` → symlink to `/workspaces/dotfiles`
4. `install.sh` runs again to regenerate configs like `~/.gitconfig.local`

See [doc/plans/2025-11-06-devcontainer-live-editing.md](doc/plans/2025-11-06-devcontainer-live-editing.md) for design details.

### Architecture Decision Records (ADRs)

```bash
bin/adr new "title" # Create new ADR in doc/adr/
bin/adr list        # List all ADRs
```

This repository documents all significant architectural decisions in [doc/adr/](doc/adr/). Before making major changes, review existing ADRs to understand the context and rationale behind current implementations. When making new architectural decisions, create an ADR documenting the context, decision, alternatives considered, and consequences.

## Architecture

### Role-Based Configuration System

The central architectural pattern is **role-based adaptation**. The role is determined once during installation and affects:

- **Git identity & signing**: Different email/name and SSH key selection
- **Brewfile selection**: `Brewfile` + `Brewfile.$ROLE` are merged during brew bundle
- **Shell environment**: Various configs conditionally load based on role

Role detection logic is in [install.sh:12-23](install.sh#L12-L23). The role defaults to "work" for hostnames matching `josh-nichols-*`, otherwise "personal".

### Dynamic Git Configuration

Git settings are **generated**, not static. [gitconfig.sh](gitconfig.sh) rebuilds `~/.gitconfig.local` by:

1. Deleting the old version
2. Enabling git maintenance for all repos in `~/workspace/`
3. Conditionally including config fragments from `home/.gitconfig.d/` based on:
   - Available commands (delta, gh, git-duet, fzf, code/code-insiders)
   - Operating system (macOS)
   - Role (personal/work)
   - 1Password availability (for SSH signing on personal)

This means `~/.gitconfig.local` should never be edited manually or committed. The base config at [home/.gitconfig](home/.gitconfig) includes this generated file.

### Symlink-Based File Management

Configuration files live in the repo under `home/` and `config/`, then [symlinks.sh](symlinks.sh) creates symlinks:

- `home/*` → `$HOME/*` (dotfiles like `.bashrc`, `.tmux.conf`)
- `config/*` → `$HOME/.config/*` (modern XDG config directories)
- `LaunchAgents/*.plist` → `$HOME/Library/LaunchAgents/*` (macOS only)

The `link_directory_contents()` function in [functions.sh:58-76](functions.sh#L58-L76) handles the symlinking with safety checks.

### Shell Environment Structure

**Fish** is the primary shell. Configuration is modular:

- [config/fish/config.fish](config/fish/config.fish) is the main entry point
- [config/fish/conf.d/](config/fish/conf.d/) contains autoloaded configs for:
  - Environment detection ([editor.fish](config/fish/conf.d/editor.fish) uses `envsense`)
  - Tool initialization (starship, homebrew, bat, git-duet, etc.)
  - IDE-specific behaviors (cursor_agent.fish, ghostty.fish, obsidian.fish)

**Starship** provides the shell prompt across all shells (fish, bash, zsh) for consistency. See [ADR 0007](doc/adr/0007-switch-to-starship.md) for why we switched from tide.

**Bash** configs in [home/.bash_profile](home/.bash_profile) and [home/.bashrc](home/.bashrc) provide fallback support.

### Environment Detection with envsense

The repo uses [envsense](https://github.com/technicalpickles/envsense) for detecting runtime environments (IDEs, agents, CI, terminals). This allows adaptive behavior like setting the correct `EDITOR` when running inside Cursor vs Claude Code vs a terminal.

Example: [config/fish/conf.d/editor.fish](config/fish/conf.d/editor.fish) checks `envsense info --json` to determine the IDE and sets `EDITOR` accordingly.

**Why envsense?** See [ADR 0009](doc/adr/0009-use-envsense-for-environment-detection.md) - replaces scattered environment variable checks with centralized, priority-based detection that correctly distinguishes similar environments (e.g., Cursor vs VS Code).

### Brewfile Management

Homebrew packages are managed through **merged Brewfiles**:

- [Brewfile](Brewfile): Common packages (fish, git, nvim, fzf, jq, etc.)
- `Brewfile.$ROLE`: Role-specific additions (personal or work)

The `brew_bundle()` function in [functions.sh:99-103](functions.sh#L99-L103) concatenates these files and pipes to `brew bundle`.

### LaunchAgents for macOS Automation

The [LaunchAgents/](LaunchAgents/) directory contains `.plist` files for macOS launch agents. These are symlinked and can be managed with [launchagents.sh](launchagents.sh).

The LaunchAgent infrastructure is available for automating tasks at login or on schedules. Currently, no launch agents are configured by default.

### Spotlight Exclusion Management

This repository provides tools for managing Spotlight exclusions on macOS. Spotlight is kept enabled system-wide (for Alfred and other tools), but specific directories can be excluded from indexing to reduce resource consumption.

**Pattern-Based Exclusions (Recommended):**

- [config/spotlight-exclusions](config/spotlight-exclusions): Gitignore-style pattern file (symlinked to `~/.config/spotlight-exclusions`)
- [bin/spotlight-expand-patterns](bin/spotlight-expand-patterns): Expands patterns to concrete directory paths
- [bin/spotlight-apply-exclusions](bin/spotlight-apply-exclusions): Applies exclusions from pattern file

**Quick Start:**

```bash
# Preview what would be excluded
bin/spotlight-apply-exclusions --dry-run ~/.config/spotlight-exclusions

# Apply exclusions from pattern file
bin/spotlight-apply-exclusions ~/.config/spotlight-exclusions
```

The pattern file supports:

- **Literal paths**: `~/.cache`, `~/.npm/_cacache`
- **Single-level globs** (fast): `~/workspace/*/node_modules`
- **Recursive globstar** (slow): `~/workspace/**/node_modules`

**Manual Exclusions:**

- [bin/spotlight-add-exclusion](bin/spotlight-add-exclusion): Add specific directories via AppleScript UI automation
- [bin/spotlight-list-exclusions](bin/spotlight-list-exclusions): List current exclusions from VolumeConfiguration.plist

**Documentation:**

- [doc/spotlight-exclusions.md](doc/spotlight-exclusions.md): Comprehensive usage guide
- [ADR 0011](doc/adr/0011-pattern-based-spotlight-exclusions.md): Architecture decision for pattern-based exclusions
- [ADR 0010](doc/adr/0010-manage-spotlight-exclusions-with-applescript.md): Architecture decision for AppleScript-based approach

**Note:** Previously (ADR 0008), Spotlight was disabled entirely via LaunchAgent. This was superseded because Alfred requires Spotlight to function.

## Key Utilities & Helper Functions

[functions.sh](functions.sh) provides reusable helpers:

- `running_macos()` / `running_codespaces()`: Platform detection
- `command_available()`: Check if command exists
- `brew_available()` / `fzf_available()` / `fish_available()`: Tool checks
- `load_brew_shellenv()`: Load Homebrew environment in scripts
- `vscode_command()`: Detect code vs code-insiders
- `link_directory_contents()` / `link()`: Safe symlink creation with overwrite prompts

## Tool Choices

Key tools and why they were chosen:

- **mise**: Version manager for ruby, node, python, etc. (see [ADR 0006](doc/adr/0006-switch-to-mise.md) for switch from asdf)
- **starship**: Cross-shell prompt (see [ADR 0007](doc/adr/0007-switch-to-starship.md) for switch from tide)
- **envsense**: Environment detection (see [ADR 0009](doc/adr/0009-use-envsense-for-environment-detection.md))
- **prettier**: Code formatting (see [ADR 0005](doc/adr/0005-editorconfig-and-prettier.md))
- **fzf.fish**: Enhanced fzf integration for Fish with mnemonic key bindings (see [ADR 0004](doc/adr/0004-switch-to-fzf-fish.md) for switch from basic fzf Fish extension)

## Important Files Not to Modify Manually

- `~/.gitconfig.local`: Generated by [gitconfig.sh](gitconfig.sh)
- `~/.gitconfig.d/1password`: Generated during git config setup
- Any symlinked files (edit the source in `home/` or `config/` instead)

## TypeScript Files

TypeScript is used for:

- [home/.finicky.ts](home/.finicky.ts): Finicky browser routing config
- Type definitions: [home/finicky.d.ts](home/finicky.d.ts)

These are type-checked but not compiled (configuration files for external tools).

## Code Quality & Formatting

Code formatting and consistency is enforced via EditorConfig and Prettier (see [ADR 0005](doc/adr/0005-editorconfig-and-prettier.md)). EditorConfig provides editor-agnostic settings, while Prettier enforces consistent formatting across supported file types.

There are no traditional unit tests. "Testing" means:

1. Running `npm run lint` (typecheck + format check)
2. Manually verifying installation in a clean environment (VM, Docker, fresh machine)
3. Checking shell initialization doesn't error

CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs linting on push/PR.

## Custom Binaries

[bin/](bin/) contains wrapper scripts and utilities:

- `bin/prettier`: Wraps npm prettier with custom ignore and config paths
- `bin/adr`: Wrapper for adr-tools
- `bin/shell`: Helper for shell-related operations

**Spotlight Management:**

- `bin/spotlight-expand-patterns`: Expands gitignore-style patterns to directory paths (uses `fd`)
- `bin/spotlight-apply-exclusions`: Applies Spotlight exclusions from pattern file
- `bin/spotlight-add-exclusion`: Add directories to Spotlight exclusions via AppleScript
- `bin/spotlight-list-exclusions`: List current Spotlight exclusions
- `bin/spotlight-analyze-activity`: Analyze what Spotlight is actively indexing (identifies high-activity directories)
- `bin/spotlight-monitor-live`: Live monitoring of Spotlight process activity

**Monorepo Management:**

- Skill: `working-in-monorepos` - Helps Claude work in monorepos by ensuring commands use absolute paths
- Script: `~/.claude/skills/working-in-monorepos/scripts/monorepo-init` - Auto-detect subprojects and generate `.monorepo.json` config
- Command: `/monorepo-init` - Activates skill and runs init script interactively

When working in repositories with multiple subprojects, use `/monorepo-init` to activate the working-in-monorepos skill and set up configuration. The skill prevents directory confusion by requiring absolute paths for all commands.

These are used by other scripts and hooks.
