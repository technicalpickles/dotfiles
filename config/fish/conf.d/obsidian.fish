if [ "$__CFBundleIdentifier" = "md.obsidian" ]
  # minimal, no nerd fonts
  set -gx STARSHIP_CONFIG "$HOME/.config/starship-obsidian.toml"
end
