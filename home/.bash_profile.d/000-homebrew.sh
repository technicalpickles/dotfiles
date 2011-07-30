export BREW_CELLAR=$(brew --cellar)
export BREW_PREFIX=$(brew --prefix)
# use /usr/local stuff (ie homebrew) before 
export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:${PATH}"
