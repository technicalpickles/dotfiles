# custom ruby item, which isn't hard-coded to chruby
function _tide_item_ruby
  # only show when there's an explicit configuration or environment variable to use a different ruby version
  # to avoid showing the default ruby
  if test -e .ruby-version \
    -o -n "$RUBY_VERSION" \
    -o -n "$RBENV_VERSION" \
    -o -n "$ASDF_RUBY_VERSION" \
    -o -n "$MISE_RUBY_VERSION"

    # example output: ruby 3.1.4p223 (2023-03-30 revision 957bb7cb81) [arm64-darwin22]
    # example output: ruby 3.2.2 (2023-03-30 revision 957bb7cb81) [arm64-darwin22]
    set ruby_version (ruby --version | sed -e 's/ruby //' -e 's/p.*$//' -e 's/ (.*$//')
    # re-use chruby so will appear the same for
    # print item     with this name   and this icon           with this text
    _tide_print_item chruby           $tide_chruby_icon' '    "$ruby_version"
  end
end
