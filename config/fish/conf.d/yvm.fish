if [ -n "$HOMEBREW_PREFIX" ]
  set -x YVM_DIR $HOMEBREW_PREFIX/opt/yvm

  if [ -r $YVM_DIR/yvm.fish ]
    source $YVM_DIR/yvm.fish
  end
end