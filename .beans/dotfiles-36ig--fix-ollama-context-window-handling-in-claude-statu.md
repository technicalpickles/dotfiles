---
# dotfiles-36ig
title: Fix ollama context window handling in claude-status-line
status: completed
type: feature
priority: high
created_at: 2026-08-01T17:22:40Z
updated_at: 2026-08-01T17:42:35Z
---

## Problem

Claude Code assumes 200K context window for unknown models (including ollama). This causes premature compaction issues when using ollama models that report different context windows.

## Ollama Cloud Models Context Windows

Capture all ollama cloud model context windows from the API:

- glm-5.2:cloud: 1000000 (1M)
- mistral-large-3:675b-cloud: 262144
- devstral-small-2:24b-cloud: 262144
- ministral-3:14b-cloud: 262144
- ministral-3:8b-cloud: 262144
- ministral-3:3b-cloud: 262144
- gemma3:27b-cloud: 131072
- gemma3:12b-cloud: 32768
- gemma3:4b-cloud: 32768
- minimax-m3:cloud: 524288
- gemma4:cloud: 262144
- gemini-3-flash-preview:cloud: 1048576
- qwen3.5:cloud: 262144
- gpt-oss:20b-cloud: 131072

## Solution

Created `bin/claude-ollama` - a Claude Code launcher that:
1. Queries ollama API for the model's actual context_length
2. Sets CLAUDE_CODE_AUTO_COMPACT_WINDOW to 80% of that value
3. Launches claude with the correct environment

Usage:
```bash
claude-ollama qwen3.5:cloud    # Launch with specific model
claude-ollama                  # Uses $OLLAMA_MODEL or qwen3.5:cloud default
OLLAMA_MODEL=gemini-3-flash-preview:cloud claude-ollama
```

Also updated `bin/claude-status-line` to explicitly pass through ollama cloud models without modification.

## Checklist

- [x] Update claude-status-line to detect and pass through ollama context windows
- [x] Test with qwen3.5:cloud (262144)
- [x] Create bin/claude-ollama launcher
- [x] Test with multiple models (glm, gemma, gemini, minimax)
- [x] Document in bin/CLAUDE.md
