#!/usr/bin/env bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Model providers are per role: prime/models.<role>.json (home is local Ollama,
# whose cloud models ride through it). A role with no file gets no models.json,
# so it keeps whatever /login or its safe hook provides.
#
# work-coder is generated instead: the AI Bridge URL names internal infrastructure
# and this repo is public, so it's read from the Coder template's Claude Code
# managed settings, which already carry it (ADR 0069).
coder_settings=/etc/claude-code/managed-settings.d/10-coder.json
if [ -f "$DIR/prime/models.$DOTPICKLES_ROLE.json" ]; then
  link "prime/models.$DOTPICKLES_ROLE.json" "$agent_dir/models.json"
elif [ "$DOTPICKLES_ROLE" = work-coder ] && [ -r "$coder_settings" ]; then
  anthropic_url="$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$coder_settings")"
  case "$anthropic_url" in
    */aibridge/anthropic)
      models="$agent_dir/models.json"
      [ -L "$models" ] && rm "$models"
      jq -n --arg anthropic "$anthropic_url" --arg openai "${anthropic_url%/anthropic}/openai/v1" '
        {providers: {
          anthropic: {baseUrl: $anthropic, apiKey: "PRIME_AGENT_CODER_AIGATEWAY_SESSION_TOKEN"},
          openai: {baseUrl: $openai, apiKey: "PRIME_AGENT_CODER_AIGATEWAY_SESSION_TOKEN"}
        }}' > "$models"
      echo "  📝 models.json -> Coder AI Bridge (anthropic, openai)"
      ;;
    *)
      echo "  ⚠ models.json -> no AI Bridge URL in $coder_settings, skipping" >&2
      ;;
  esac
else
  echo "  ⏭  models.json -> none for role $DOTPICKLES_ROLE, skipping"
fi

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
