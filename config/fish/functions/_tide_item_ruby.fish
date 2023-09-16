# set -U tide_ruby_bg_color CC342D                                                                                                                                                     ─╯
# set -U tide_ruby_color 000000
# set -U tide_ruby_icon ''
function _tide_item_ruby
    if test -e .ruby-version -o -n "$RUBY_VERSION" || test -e .tool-versions && grep -q ruby .tool-versions 2>/dev/null
      _tide_print_item ruby $tide_ruby_icon' ' (ruby --version | sed -e 's/ruby //' -e 's/p.*$//')
    end
end
