#!/usr/bin/env bash
set -e

rm -f ~/.gh-shorthand.yml

cat > ~/.gh-shorthand.yml <<EOF
---
# The default repository, if none is provided. This can be empty/unset.
# default_repo:

# The repository shorthand map
repos:
  # gs: "zerowidth/gh-shorthand"

# The user shorthand map
users:
  tp: technicalpickles

# Project directory listing:
project_dirs:
  - ~/src/*

# The command or script to open the editor.
editor: "/usr/local/bin/code-insiders -n"

# GitHub API token (requires 'read:org,repo,user' permission)
# enables live search results and annotations
EOF


token=$(security find-internet-password -a technicalpickles -s github.com -l 'gh-shorthand token' -w)
if [ -z "$token" ]; then
	echo "missing Token. Run the following to set: security add-internet-password -a technicalpickles -s github.com -l 'gh-shorthand token' -w"
fi

echo "token: ${token}" >> ~/.gh-shorthand.yml