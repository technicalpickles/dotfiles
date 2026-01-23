# Claude Spend for tmux Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Display today's Claude Code spend in tmux status bar, aggregated across all projects.

**Architecture:** Shell script reads Claude Code transcript files (`~/.claude/projects/**/*.jsonl`), extracts usage data for today, calculates cost using model pricing, caches results, and outputs formatted string for tmux.

**Tech Stack:** Bash, jq, bc (arithmetic)

---

## Context

### Data Source

Claude Code stores session transcripts at `~/.claude/projects/<project-dir>/<session-id>.jsonl`. Each line is a JSON object. Assistant responses include usage data:

```json
{
  "timestamp": "2026-01-17T18:07:40.459Z",
  "type": "assistant",
  "message": {
    "model": "claude-opus-4-5-20251101",
    "usage": {
      "input_tokens": 10,
      "output_tokens": 6,
      "cache_creation_input_tokens": 6524,
      "cache_read_input_tokens": 23641
    }
  }
}
```

### Scale

- ~100 project directories
- ~2500 transcript files
- ~400MB total data
- Need to scan files modified in last 2 days to catch today's entries

### Pricing (per million tokens)

| Model Family | Input | Output | Cache Write | Cache Read |
| ------------ | ----- | ------ | ----------- | ---------- |
| Opus         | $15   | $75    | $18.75      | $1.50      |
| Sonnet       | $3    | $15    | $3.75       | $0.30      |
| Haiku        | $1    | $5     | $1.25       | $0.10      |

### Performance Target

- First run: <3 seconds (full scan)
- Cached run: <100ms
- Cache TTL: 60 seconds

---

## Task 1: Minimal Data Extraction Proof

**Goal:** Prove we can read and count today's transcript entries.

**Files:**

- Create: `bin/claude-spend-today`

**Step 1: Create minimal script that counts today's entries**

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECTS_DIR="${HOME}/.claude/projects"
TODAY=$(date +%Y-%m-%d)

count=$(find "$PROJECTS_DIR" -name "*.jsonl" -mtime -2 -print0 2> /dev/null \
  | xargs -0 grep -h "\"timestamp\":\"${TODAY}" 2> /dev/null \
  | grep -c '"message":' || echo 0)

echo "Found $count assistant messages today"
```

**Step 2: Run and verify**

Run: `chmod +x bin/claude-spend-today && ./bin/claude-spend-today`
Expected: "Found N assistant messages today" where N > 0

**Step 3: Commit**

```bash
git add bin/claude-spend-today
git commit -m "feat: add claude-spend-today script - data extraction proof"
```

---

## Task 2: Extract Raw Token Counts

**Goal:** Sum up token usage for today across all projects.

**Files:**

- Modify: `bin/claude-spend-today`

**Step 1: Add jq aggregation for tokens**

Replace script content with:

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECTS_DIR="${HOME}/.claude/projects"
TODAY=$(date +%Y-%m-%d)

if [[ ! -d "$PROJECTS_DIR" ]]; then
  echo "0 tokens"
  exit 0
fi

# Extract all usage objects for today and sum tokens
result=$(find "$PROJECTS_DIR" -name "*.jsonl" -mtime -2 -print0 2> /dev/null \
  | xargs -0 grep -h "\"timestamp\":\"${TODAY}" 2> /dev/null \
  | grep '"usage":' \
  | jq -s '
        map(.message.usage // empty) |
        {
            input: (map(.input_tokens // 0) | add // 0),
            output: (map(.output_tokens // 0) | add // 0),
            cache_create: (map(.cache_creation_input_tokens // 0) | add // 0),
            cache_read: (map(.cache_read_input_tokens // 0) | add // 0)
        } |
        . + {total: (.input + .output + .cache_create + .cache_read)}
    ')

echo "$result" | jq -r '"Input: \(.input), Output: \(.output), Cache Create: \(.cache_create), Cache Read: \(.cache_read), Total: \(.total)"'
```

**Step 2: Run and verify**

Run: `./bin/claude-spend-today`
Expected: Token counts that look reasonable (thousands to millions for an active day)

**Step 3: Commit**

```bash
git add bin/claude-spend-today
git commit -m "feat(claude-spend): add token aggregation"
```

---

## Task 3: Add Cost Calculation

**Goal:** Calculate dollar cost from token counts using model pricing.

**Files:**

- Modify: `bin/claude-spend-today`

**Step 1: Add pricing and cost calculation to jq**

Update the jq filter to include cost calculation:

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECTS_DIR="${HOME}/.claude/projects"
TODAY=$(date +%Y-%m-%d)

if [[ ! -d "$PROJECTS_DIR" ]]; then
  echo "\$0.00"
  exit 0
fi

# Pricing per million tokens (using Opus as default since that's what's being used)
# TODO: Could extract model from each entry for precise pricing
result=$(find "$PROJECTS_DIR" -name "*.jsonl" -mtime -2 -print0 2> /dev/null \
  | xargs -0 grep -h "\"timestamp\":\"${TODAY}" 2> /dev/null \
  | grep '"usage":' \
  | jq -s '
        # Opus pricing per million tokens
        def pricing: {input: 15, output: 75, cache_create: 18.75, cache_read: 1.5};

        map(.message.usage // empty) |
        {
            input: (map(.input_tokens // 0) | add // 0),
            output: (map(.output_tokens // 0) | add // 0),
            cache_create: (map(.cache_creation_input_tokens // 0) | add // 0),
            cache_read: (map(.cache_read_input_tokens // 0) | add // 0)
        } |
        . + {
            total_tokens: (.input + .output + .cache_create + .cache_read),
            cost: (
                (.input * pricing.input / 1000000) +
                (.output * pricing.output / 1000000) +
                (.cache_create * pricing.cache_create / 1000000) +
                (.cache_read * pricing.cache_read / 1000000)
            )
        }
    ')

cost=$(echo "$result" | jq -r '.cost')
tokens=$(echo "$result" | jq -r '.total_tokens')

# Format output
if (($(echo "$cost < 0.01" | bc -l))); then
  echo "<\$0.01"
else
  printf "\$%.2f\n" "$cost"
fi
```

**Step 2: Run and verify**

Run: `./bin/claude-spend-today`
Expected: Dollar amount like "$5.23" or "<$0.01"

**Step 3: Commit**

```bash
git add bin/claude-spend-today
git commit -m "feat(claude-spend): add cost calculation with opus pricing"
```

---

## Task 4: Add Caching

**Goal:** Cache results for 60 seconds to avoid repeated expensive file scans.

**Files:**

- Modify: `bin/claude-spend-today`

**Step 1: Add cache check and save functions**

Add at the top of the script after variable declarations:

```bash
CACHE_DIR="${HOME}/.claude/powerline/usage"
CACHE_FILE="${CACHE_DIR}/tmux-today.json"
CACHE_TTL=60

check_cache() {
  [[ ! -f "$CACHE_FILE" ]] && return 1

  local cache_mtime now
  cache_mtime=$(stat -f %m "$CACHE_FILE" 2> /dev/null || stat -c %Y "$CACHE_FILE" 2> /dev/null)
  now=$(date +%s)

  ((now - cache_mtime < CACHE_TTL)) && cat "$CACHE_FILE" && return 0
  return 1
}

save_cache() {
  mkdir -p "$CACHE_DIR"
  echo "$1" > "$CACHE_FILE"
}
```

**Step 2: Use cache in main logic**

Update main to check cache first:

```bash
# Check cache first
if cached=$(check_cache); then
  echo "$cached"
  exit 0
fi

# ... existing calculation logic ...

# Save result to cache before outputting
save_cache "$formatted_output"
echo "$formatted_output"
```

**Step 3: Run and verify caching**

Run: `time ./bin/claude-spend-today && time ./bin/claude-spend-today`
Expected: First run ~1-3s, second run <100ms

**Step 4: Commit**

```bash
git add bin/claude-spend-today
git commit -m "feat(claude-spend): add 60s result caching"
```

---

## Task 5: Add Output Format Options

**Goal:** Support cost, tokens, or both output formats for tmux flexibility.

**Files:**

- Modify: `bin/claude-spend-today`

**Step 1: Add format argument handling**

```bash
format="${1:-cost}" # cost, tokens, both

format_tokens() {
  local t="$1"
  if ((t >= 1000000)); then
    printf "%.1fM" "$(echo "$t / 1000000" | bc -l)"
  elif ((t >= 1000)); then
    printf "%.1fK" "$(echo "$t / 1000" | bc -l)"
  else
    echo "$t"
  fi
}

# At output time:
case "$format" in
  tokens) format_tokens "$tokens" ;;
  both) printf "%s (%s)\n" "$cost_formatted" "$(format_tokens "$tokens")" ;;
  *) echo "$cost_formatted" ;;
esac
```

**Step 2: Test all formats**

Run:

```bash
./bin/claude-spend-today cost
./bin/claude-spend-today tokens
./bin/claude-spend-today both
```

Expected:

- cost: "$5.23"
- tokens: "45.2M"
- both: "$5.23 (45.2M)"

**Step 3: Commit**

```bash
git add bin/claude-spend-today
git commit -m "feat(claude-spend): add format options (cost/tokens/both)"
```

---

## Task 6: tmux Integration

**Goal:** Wire up the script in tmux status bar.

**Files:**

- Modify: `home/.tmux.conf`

**Step 1: Add Claude spend to status-right**

In `.tmux.conf`, update the status-right line:

```bash
# Right: Claude spend + time
set -g status-right "#[bg=#1a1a1a,fg=#98fb98] ☉ #(~/.pickles/bin/claude-spend-today) #[default]#{E:@catppuccin_status_date_time}"
```

**Step 2: Reload tmux and verify**

Run: `tmux source-file ~/.tmux.conf`
Expected: Claude spend appears in status bar, updates every 60s

**Step 3: Commit**

```bash
git add home/.tmux.conf
git commit -m "feat(tmux): add claude daily spend to status bar"
```

---

## Verification Checklist

- [ ] Script runs in <3s on first invocation
- [ ] Cached invocations complete in <100ms
- [ ] Cost roughly matches `/cost` command total across sessions
- [ ] tmux status bar shows spend and updates
- [ ] Works in both macOS and Linux (stat command compatibility)

---

## Future Enhancements (Not in scope)

- Per-model pricing extraction (currently assumes Opus)
- 5-hour rate limit window tracking (like claude-powerline's "block" segment)
- Week/month totals
- Budget warnings when approaching limits
