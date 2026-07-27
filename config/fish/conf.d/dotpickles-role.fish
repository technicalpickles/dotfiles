# Set DOTPICKLES_ROLE early.
#
# This lives in conf.d/ (not config.fish) on purpose: fish sources conf.d/*.fish
# BEFORE config.fish, and conf.d files load alphabetically. The starship prompt
# (conf.d/starship-init.fish) reads DOTPICKLES_ROLE to build STARSHIP_CTX, so the
# role must be set before it runs. "dotpickles-role" sorts before "starship-init",
# so this wins. Setting it in config.fish would be too late and the prompt would
# fall back to its default, showing the wrong role.
#
# Canonical role names are "home" / "work" / "container" / "claude-code-remote"
# (see doc/adr/0035-canonical-dotpickles-role-names.md and 0040). Precedence:
# claude-code-remote (cloud is also a container, so it must win) -> container ->
# work (hostname) -> home. Kept in sync with install.sh and home/.zshenv.
if not set -q DOTPICKLES_ROLE
    if test "$CLAUDE_CODE_REMOTE" = true
        set -gx DOTPICKLES_ROLE claude-code-remote
    else if test -f /.dockerenv; or grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2>/dev/null; or set -q DOCKER_BUILD
        set -gx DOTPICKLES_ROLE container
    else if string match --quiet --regex '^josh-nichols-' (hostname)
        set -gx DOTPICKLES_ROLE work
    else
        set -gx DOTPICKLES_ROLE home
    end
end
