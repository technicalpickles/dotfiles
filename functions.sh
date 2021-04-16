link() {
  linkable="$1"
  target="$2"
  display_target="${target/$HOME/~}"

  if [ ! -L "$target" ]; then
    echo "🔗 $display_target → linking from $linkable"
    ln -Ff -s "$DIR/$linkable" "$target"
  else
    echo "🔗 $display_target → already linked"
  fi
}

brew_bundle() {
  if [ "$(uname)" == Darwin ]; then
    echo "🍻 running brew bundle"
    brew bundle | sed 's/^/  → /'
    echo
  fi
}

vim_plugins() {
  vim +PlugInstall +qall
}