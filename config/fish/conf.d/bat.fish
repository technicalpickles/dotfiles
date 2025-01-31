if command -q bat
  set -gx MANPAGER "sh -c 'col -bx | bat --language man --style=plain --paging=always'"

  set -gx HOMEBREW_BAT 1

  alias less="bat --style=plain"
end
