if string match -q "$TERM_PROGRAM" "vscode-insiders"
  . (code --locate-shell-integration-path fish)
else if string match -q "$TERM_PROGRAM" "vscode"
  . (code-insiders --locate-shell-integration-path fish)
end
