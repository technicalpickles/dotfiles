# Disable homebrew's mise auto-activation. We activate mise ourselves, in shims
# mode, in config.fish (both the gusto branch via ~/.gusto/init.sh and the else
# branch). Homebrew additionally ships
# /opt/homebrew/share/fish/vendor_conf.d/mise-activate.fish, which runs a *full*
# activation on top of that. Full mode conflicts with shims mode and installs
# PWD/fish_prompt/fish_preexec handlers that each shell out to `mise hook-env`.
# Measured 2026-07-31: ~80ms at startup, ~50ms per cd, ~13ms per prompt.
#
# TWO mechanisms here, deliberately:
#
# 1. The FILENAME. fish sources conf.d as user -> sysconf -> vendor, skipping any
#    file whose basename it has already seen ("Implement precedence (User > Admin
#    > Extra (e.g. vendors) > Fish) by basically doing 'basename'" in fish's own
#    config.fish). Naming this `mise-activate.fish` means the vendor file is never
#    sourced at all. This is the load-bearing part.
#
# 2. The variable. Belt and suspenders, in case homebrew renames its file. Note
#    `0` is the ONLY value that disables it -- the vendor guard is
#    `if [ "$MISE_FISH_AUTO_ACTIVATE" != "0" ]`. ~/.gusto/init.fish sets `1`
#    intending to disable it, which has never worked.
#
# Don't move this to config.fish: that runs AFTER every conf.d file, including
# vendor, so the variable would be set too late to matter. (A universal variable
# is the other way to beat the ordering, but that lives in fish_variables, which
# isn't version controlled, so a fresh machine silently loses it.)
#
# Tradeoff: per-directory mise `[env]` no longer applies on cd. Tool versions are
# unaffected (that's what shims do). Repos relying on it: repos/web
# (SHARP_IGNORE_GLOBAL_LIBVIPS), repos/dotfiles-devcontainer.
set -gx MISE_FISH_AUTO_ACTIVATE 0
