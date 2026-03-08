# Fish Plugin Drift Detection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Detect manually-added fish plugins and handle them appropriately based on interactive vs non-interactive mode.

**Architecture:** Core plugins defined in `config/fish/core_plugins`. `fish.sh` reads this file, compares against current `fish_plugins`, detects drift, and prompts (interactive) or auto-preserves (non-interactive).

**Tech Stack:** Bash, Fisher (fish plugin manager)

---

## Task 1: Create core_plugins file

**Files:**

- Create: `config/fish/core_plugins`

**Step 1: Create the core plugins file**

```bash
# config/fish/core_plugins
# Core fish plugins - managed by fish.sh
# Extra plugins added via `fisher install` will be detected and preserved

jorgebucaran/fisher
jethrokuan/z
jorgebucaran/autopair.fish
```

Note: Conditional plugins (fzf.fish, fish-direnv) are NOT in this file - they're handled by conditionals in fish.sh.

**Step 2: Verify file is valid**

```bash
cat config/fish/core_plugins
```

Expected: File contents displayed, no errors.

**Step 3: Commit**

```bash
git add config/fish/core_plugins
git commit -m "feat(fish): add core_plugins file for drift detection"
```

---

## Task 2: Rewrite fish.sh with drift detection

**Files:**

- Modify: `fish.sh` (complete rewrite of plugin management section, lines 28-56)

**Step 1: Replace the plugin management section**

The new `fish.sh` should:

1. Read core plugins from `config/fish/core_plugins`
2. Apply conditionals (fzf, direnv)
3. Compare against current `fish_plugins`
4. Detect and handle drift

```bash
#!/usr/bin/env bash

# shellcheck source=./functions.sh
source ./functions.sh

if ! which fish > /dev/null 2> /dev/null; then
  echo "missing fish :("
  exit 1
fi

echo "🐟 configuring fish"
fish_path=$(which fish)
if test -f /etc/shells && ! grep -q "$fish_path" /etc/shells; then
  sudo bash -c "which fish >> /etc/shells"
fi

if running_macos; then
  if ! dscl . -read "$HOME" UserShell | grep -q "$fish_path"; then
    chsh -s "$fish_path"
  fi
fi

if ! fish -c "type fisher >/dev/null 2>/dev/null"; then
  echo "installing fisher"
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
fi

# Read core plugins from file (skip comments and blank lines)
core_plugins=()
core_plugins_file="$DIR/config/fish/core_plugins"
if [[ -f "$core_plugins_file" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and blank lines
    [[ "$line" =~ ^#.*$ || -z "${line// /}" ]] && continue
    core_plugins+=("$line")
  done < "$core_plugins_file"
else
  echo "Warning: $core_plugins_file not found, using empty core list"
fi

# Apply conditionals - add plugins that depend on available commands
if command_available fzf; then
  core_plugins+=(patrickf1/fzf.fish)
fi

if command_available direnv; then
  core_plugins+=(halostatue/fish-direnv)
fi

# Normalize plugin names to lowercase for comparison
normalize_plugin() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Read current fish_plugins if it exists
current_plugins=()
fish_plugins_file="$HOME/.config/fish/fish_plugins"
if [[ -f "$fish_plugins_file" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line// /}" ]] && continue
    current_plugins+=("$line")
  done < "$fish_plugins_file"
fi

# Find extra plugins (in current but not in core)
extra_plugins=()
for current in "${current_plugins[@]}"; do
  current_normalized=$(normalize_plugin "$current")
  is_core=false
  for core in "${core_plugins[@]}"; do
    core_normalized=$(normalize_plugin "$core")
    if [[ "$current_normalized" == "$core_normalized" ]]; then
      is_core=true
      break
    fi
  done
  if [[ "$is_core" == false ]]; then
    extra_plugins+=("$current")
  fi
done

# Display core plugins
echo
echo "Core plugins (${#core_plugins[@]}):"
for plugin in "${core_plugins[@]}"; do
  echo "  $plugin"
done

# Handle drift
preserve_extras=()
if [[ ${#extra_plugins[@]} -gt 0 ]]; then
  echo
  echo "Extra plugins found (${#extra_plugins[@]}):"
  for plugin in "${extra_plugins[@]}"; do
    echo "  $plugin"
  done

  if [[ -t 0 ]]; then
    # Interactive - prompt user
    echo
    read -r -p "Keep extra plugins? [Y/n] " response
    case "$response" in
      [nN] | [nN][oO])
        echo "Dropping extra plugins"
        ;;
      *)
        echo "Keeping extra plugins"
        preserve_extras=("${extra_plugins[@]}")
        ;;
    esac
  else
    # Non-interactive - auto-preserve
    echo
    echo "Non-interactive mode, auto-preserving extra plugins"
    preserve_extras=("${extra_plugins[@]}")
  fi
fi

# Remove old fish_plugins to rebuild
rm -f "$fish_plugins_file"

echo
echo "Installing plugins..."

# Install core plugins
for plugin in "${core_plugins[@]}"; do
  fish -c "fisher install $plugin"
done

# Install preserved extras
for plugin in "${preserve_extras[@]}"; do
  fish -c "fisher install $plugin"
done

echo
```

**Step 2: Verify syntax**

```bash
bash -n fish.sh
```

Expected: No output (no syntax errors).

**Step 3: Run shellcheck**

```bash
shellcheck fish.sh
```

Expected: No errors (warnings about sourced file are OK).

**Step 4: Commit**

```bash
git add fish.sh
git commit -m "feat(fish): add drift detection for manually-added plugins

- Read core plugins from config/fish/core_plugins
- Detect extra plugins not in core list
- Interactive: prompt to keep/drop extras
- Non-interactive: auto-preserve extras"
```

---

## Task 3: Manual testing

**Step 1: Test with current setup**

Run fish.sh to verify it works with existing plugins:

```bash
./fish.sh
```

Expected:

- Shows core plugins list
- Detects extra plugins (nvm.fish, abbreviation-tips, ssh-agent, starship.fish)
- Prompts to keep/drop (since interactive)
- Installs all plugins successfully

**Step 2: Test non-interactive mode**

```bash
echo "" | ./fish.sh
```

Expected:

- Shows "Non-interactive mode, auto-preserving extra plugins"
- No prompt

**Step 3: Test dropping extras**

```bash
# Answer 'n' to the prompt
./fish.sh
# Type: n
```

Expected:

- Shows "Dropping extra plugins"
- Only core plugins installed

---

## Task 4: Run linting

**Step 1: Run full lint suite**

```bash
npm run lint
```

Expected: All checks pass.

**Step 2: Commit any formatting fixes**

If prettier made changes:

```bash
git add -A
git commit -m "style: format files"
```

---

## Task 5: Final commit and summary

**Step 1: Verify all changes committed**

```bash
git status
git log --oneline -5
```

Expected: Clean working tree, commits for core_plugins file and fish.sh rewrite.
