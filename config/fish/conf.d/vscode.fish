if string match -q "vscode" "$TERM_PROGRAM"
  if string match -q "*Cursor.app*" "$XDG_DATA_DIRS" && type -q cursor
    . (cursor --locate-shell-integration-path fish)
  else if type -q code
    . (code --locate-shell-integration-path fish)
  end
else if string match -q "vscode-insiders" "$TERM_PROGRAM" && type -q code-insiders
  . (code-insiders --locate-shell-integration-path fish)
end
