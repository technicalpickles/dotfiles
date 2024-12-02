#!/usr/bin/env bash
set -e

rm -f ~/.gh-shorthand.yml

editor=$(which code-insiders || which code)

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
editor: "${editor} -n"

# GitHub API token (requires 'read:org,repo,user' permission)
# enables live search results and annotations
EOF


# FIXME when empty, this fails and stops the script with:
# SecKeychainSearchCopyNext: The specified item could not be found in the keychain
token=$(security find-internet-password -a technicalpickles -s github.com -l 'gh-shorthand token' -w)
if [ -z "$token" ]; then
  echo "missing Token. Run the following to set: security add-internet-password -a technicalpickles -s github.com -l 'gh-shorthand token' -w"
fi

echo "token: ${token}" >> ~/.gh-shorthand.yml
