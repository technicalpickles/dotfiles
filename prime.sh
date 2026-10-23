#!/usr/bin/env bash

set -e

# shellcheck source=./functions.sh
source ./functions.sh

echo "🤖 configuring prime-agent"

if ! command_available prime-agent; then
  echo "  ⚠ prime-agent not found, skipping (mise installs it)"
  exit 0
fi

# Agent state: sessions, settings, skills. `safe prime-agent` grants this dir but
# can't create it (the parent isn't writable in the sandbox), so make it here.
# Auth is /login inside prime-agent, which stores its credential in this dir.
agent_dir="$HOME/.prime/agent"
mkdir -p "$agent_dir/skills"
echo "  📁 ~/.prime/agent -> ready"

# Skills from skills.sh (the lockfile ones) already reach prime-agent through
# ~/.agents/skills. These are vault-local, so they get linked here.
# Skills that live in the Obsidian vault. Seatbelt checks the resolved path, so
# role-<role>.sb grants a read on each one. Add the grant when adding a skill.
vault="$HOME/Vaults/pickled-knowledge"
vault_skills=("2.🏡 Areas/writing/writing-voice")
for skill in "${vault_skills[@]}"; do
  name="$(basename "$skill")"
  source="$vault/$skill"
  target="$agent_dir/skills/$name"
  if [ ! -d "$source" ]; then
    echo "  ⏭  $name -> not in vault, skipping"
  elif [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    echo "  🔗 $name -> already linked"
  elif [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "  ⚠ $name -> exists and isn't a symlink, leaving it" >&2
  else
    ln -sfn "$source" "$target"
    echo "  🔗 $name -> linked"
  fi
done

echo
