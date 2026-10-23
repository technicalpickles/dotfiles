# cenv login runs plain `claude auth login` unless told otherwise.
# Gusto accounts sign in through SSO, so make that the default for bare `cenv login <env>`.
set -gx CENV_LOGIN_FLAGS --sso
