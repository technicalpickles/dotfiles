#!/usr/bin/env fish

# ls.fish - Enhanced ls function using eza
#
# Purpose: Replace ls with eza for better visual output and Git integration
# Created: 2025-01-08
# Usage: Provides drop-in replacement for ls with enhanced features
#
# Features:
# - Interactive: Enhanced eza with colors, icons, and Git integration
# - Non-interactive: Standard system ls for scripts and automation
# - Git status integration (can be disabled with EZA_OVERRIDE_GIT=--no-git)
# - Better file size formatting
# - Full ls compatibility with all options
#
# To disable Git integration in large repositories:
#   export EZA_OVERRIDE_GIT=--no-git
#   # or for a single command:
#   EZA_OVERRIDE_GIT=--no-git ls -l

function ls --description "Enhanced ls using eza"
    # Use eza only in interactive contexts, system ls for scripts/automation
    if not status is-interactive
        command ls $argv
        return
    end

    # Check if eza is available, fallback to system ls if not
    if not command -q eza
        command ls $argv
        return
    end

    # Use eza with Git integration (can be overridden with EZA_OVERRIDE_GIT)
    # eza automatically handles:
    # - Color/icon detection based on terminal capabilities
    # - All standard ls options. Any not supported are recognized by eza (e.g. -t requires the specifying which time to use)
    # - Non-interactive contexts (pipes, redirects, scripts)
    # - Environment variable overrides (EZA_OVERRIDE_GIT)
    command eza --git $argv
end
