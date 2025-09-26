if [ "$CURSOR_AGENT" = "1" ]
  # use a much simpler starship config for the agent
  # assumes that starship init happens after this file is sourced
  set -gx STARSHIP_CONFIG "$HOME/.config/starship-agent.toml"

  # Functionally disable pager so commands like `git log` get stuck waiting for input
  set -gx PAGER "cat"

  # override git config explicitly, since we use core.pager in our global config
  set -gx GIT_PAGER "cat"

  # no direnv log
  set -gx DIRENV_LOG_FORMAT ""

  # no motd, less noise when starting up
  set -gx WELCOME2U 0
end
