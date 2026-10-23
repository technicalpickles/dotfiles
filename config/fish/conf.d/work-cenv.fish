# Gusto accounts sign in through SSO, and cenv login defaults to plain `claude auth login`.
# Named work-* so it sorts after dotpickles-role.fish, which sets DOTPICKLES_ROLE.
if test "$DOTPICKLES_ROLE" = work
    set -gx CENV_LOGIN_FLAGS --sso
end
