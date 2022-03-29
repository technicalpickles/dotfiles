function _tide_item_ruby
    test -e .ruby-version -o -n "$RUBY_VERSION" && _tide_print_item chruby $tide_chruby_icon' ' (ruby --version | sed -e 's/ruby //' -e 's/p.*$//')
end
