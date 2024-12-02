if test -d ~/golang
  set -x --global GOPATH ~/golang
  fish_add_path --global $GOPATH/bin
end
