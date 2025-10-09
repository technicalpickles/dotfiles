#!/usr/bin/env bash
#
# Helper script to manage LaunchAgents
#
# Usage:
#   ./launchagents.sh load <agent-name>
#   ./launchagents.sh unload <agent-name>
#   ./launchagents.sh reload <agent-name>
#   ./launchagents.sh status <agent-name>
#   ./launchagents.sh logs <agent-name>
#   ./launchagents.sh list
#   ./launchagents.sh validate <agent-name>

set -e

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

success() {
  echo -e "${GREEN}✓ $1${NC}"
}

info() {
  echo -e "${BLUE}ℹ $1${NC}"
}

warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# Get the full label from agent name
get_label() {
  local name="$1"
  if [[ "$name" == *.plist ]]; then
    basename "$name" .plist
  else
    echo "$name"
  fi
}

# Get the plist path
get_plist_path() {
  local name="$1"
  local label=$(get_label "$name")
  echo "$LAUNCH_AGENTS_DIR/${label}.plist"
}

# Validate plist syntax
validate_agent() {
  local name="$1"
  local plist=$(get_plist_path "$name")

  if [[ ! -f "$plist" ]]; then
    error "Agent not found: $plist"
  fi

  info "Validating $plist..."

  if plutil -lint "$plist" > /dev/null 2>&1; then
    success "Plist syntax is valid"
  else
    error "Invalid plist syntax. Run: plutil -lint $plist"
  fi

  # Check if it's a symlink (should be if installed via dotfiles)
  if [[ -L "$plist" ]]; then
    local target=$(readlink "$plist")
    info "Symlinked to: $target"
  else
    warning "Not a symlink. Consider managing this via dotfiles."
  fi
}

# Load an agent
load_agent() {
  local name="$1"
  local label=$(get_label "$name")
  local plist=$(get_plist_path "$name")

  if [[ ! -f "$plist" ]]; then
    error "Agent not found: $plist"
  fi

  info "Loading $label..."

  # Validate first
  if ! plutil -lint "$plist" > /dev/null 2>&1; then
    error "Invalid plist. Run: ./launchagents.sh validate $name"
  fi

  # Load it
  if launchctl load "$plist" 2>&1; then
    success "Loaded $label"
    info "Check status with: ./launchagents.sh status $name"
    info "Check logs with: ./launchagents.sh logs $name"
  else
    warning "Load command completed (may already be loaded)"
    info "Check status with: ./launchagents.sh status $name"
  fi
}

# Unload an agent
unload_agent() {
  local name="$1"
  local label=$(get_label "$name")
  local plist=$(get_plist_path "$name")

  info "Unloading $label..."

  if launchctl unload "$plist" 2>&1; then
    success "Unloaded $label"
  else
    warning "Unload command completed (may not have been loaded)"
  fi
}

# Reload an agent (unload then load)
reload_agent() {
  local name="$1"
  info "Reloading agent..."
  unload_agent "$name" 2> /dev/null || true
  sleep 1
  load_agent "$name"
}

# Check agent status
status_agent() {
  local name="$1"
  local label=$(get_label "$name")

  info "Status for $label:"
  echo

  # Check if it's loaded
  if launchctl list | grep -q "$label"; then
    success "Agent is loaded"
    echo
    # Show detailed info
    launchctl list | grep "$label" | while read -r pid status label; do
      echo "  PID:    $pid"
      echo "  Status: $status"
      echo "  Label:  $label"
    done
  else
    warning "Agent is not loaded"
  fi

  echo

  # Check if plist exists
  local plist=$(get_plist_path "$name")
  if [[ -f "$plist" ]]; then
    info "Plist file: $plist"
    if [[ -L "$plist" ]]; then
      echo "  → Symlinked to: $(readlink "$plist")"
    fi
  else
    warning "Plist file not found: $plist"
  fi
}

# Show logs
show_logs() {
  local name="$1"
  local label=$(get_label "$name")

  info "Logs for $label:"
  echo

  # Check standard log files
  local stdout_log="/tmp/${label}.out"
  local stderr_log="/tmp/${label}.err"

  if [[ -f "$stdout_log" ]]; then
    echo -e "${GREEN}=== Standard Output ($stdout_log) ===${NC}"
    cat "$stdout_log"
    echo
  else
    info "No stdout log found at $stdout_log"
  fi

  if [[ -f "$stderr_log" ]]; then
    echo -e "${RED}=== Standard Error ($stderr_log) ===${NC}"
    cat "$stderr_log"
    echo
  else
    info "No stderr log found at $stderr_log"
  fi

  # Check system logs (last 5 minutes)
  echo -e "${BLUE}=== System Logs (last 5 minutes) ===${NC}"
  log show --predicate "processImagePath CONTAINS '$label' OR eventMessage CONTAINS '$label'" --last 5m --style compact 2> /dev/null || {
    warning "Unable to read system logs. Try: log show --predicate 'eventMessage CONTAINS \"$label\"' --last 5m"
  }
}

# List all agents
list_agents() {
  info "LaunchAgents in $LAUNCH_AGENTS_DIR:"
  echo

  if [[ ! -d "$LAUNCH_AGENTS_DIR" ]]; then
    warning "LaunchAgents directory doesn't exist: $LAUNCH_AGENTS_DIR"
    return
  fi

  # List all plist files
  local found=0
  for plist in "$LAUNCH_AGENTS_DIR"/*.plist; do
    if [[ -f "$plist" ]]; then
      found=1
      local label=$(basename "$plist" .plist)
      local status_marker="○"

      # Check if loaded
      if launchctl list | grep -q "$label"; then
        status_marker="${GREEN}●${NC}"
      fi

      echo -e "  $status_marker $label"

      # Show if it's from dotfiles
      if [[ -L "$plist" ]]; then
        echo "     ↳ $(readlink "$plist")"
      fi
    fi
  done

  if [[ $found -eq 0 ]]; then
    warning "No LaunchAgents found"
  fi

  echo
  info "Legend: ${GREEN}●${NC} loaded  ○ not loaded"
}

# Show usage
usage() {
  cat << EOF
Usage: $(basename "$0") <command> [agent-name]

Commands:
  load <agent>      Load an agent (start it)
  unload <agent>    Unload an agent (stop it)
  reload <agent>    Reload an agent (stop and start)
  status <agent>    Show agent status
  logs <agent>      Show agent logs
  validate <agent>  Validate plist syntax
  list              List all agents

Examples:
  $(basename "$0") load com.technicalpickles.disable-spotlight
  $(basename "$0") status com.technicalpickles.disable-spotlight
  $(basename "$0") logs com.technicalpickles.disable-spotlight
  $(basename "$0") list

Agent name can be:
  - Full label: com.technicalpickles.disable-spotlight
  - With .plist: com.technicalpickles.disable-spotlight.plist
EOF
}

# Main script
main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  local command="$1"
  local agent="$2"

  case "$command" in
    load)
      [[ -z "$agent" ]] && error "Agent name required"
      load_agent "$agent"
      ;;
    unload)
      [[ -z "$agent" ]] && error "Agent name required"
      unload_agent "$agent"
      ;;
    reload)
      [[ -z "$agent" ]] && error "Agent name required"
      reload_agent "$agent"
      ;;
    status)
      [[ -z "$agent" ]] && error "Agent name required"
      status_agent "$agent"
      ;;
    logs)
      [[ -z "$agent" ]] && error "Agent name required"
      show_logs "$agent"
      ;;
    validate)
      [[ -z "$agent" ]] && error "Agent name required"
      validate_agent "$agent"
      ;;
    list)
      list_agents
      ;;
    help | --help | -h)
      usage
      ;;
    *)
      error "Unknown command: $command\n$(usage)"
      ;;
  esac
}

main "$@"
