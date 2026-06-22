# Set DOTPICKLES_ROLE early.
#
# This lives in conf.d/ (not config.fish) on purpose: fish sources conf.d/*.fish
# BEFORE config.fish, and conf.d files load alphabetically. The starship prompt
# (conf.d/starship-init.fish) reads DOTPICKLES_ROLE to build STARSHIP_CTX, so the
# role must be set before it runs. "dotpickles-role" sorts before "starship-init",
# so this wins. Setting it in config.fish would be too late and the prompt would
# fall back to its default, showing the wrong role.
#
# Canonical role names are "home" / "work" (see doc/adr/0035-canonical-dotpickles-role-names.md).
if not set -q DOTPICKLES_ROLE
    if string match --quiet --regex '^josh-nichols-' (hostname)
        set -gx DOTPICKLES_ROLE work
    else
        set -gx DOTPICKLES_ROLE home
    end
end
