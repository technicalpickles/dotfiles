# 17. Claude Spend Tracking in tmux Status Bar

Date: 2026-01-21

## Status

Accepted

## Context

After switching from Claude Powerline to CCline status (ccstatusline package) for Claude Code's status display, one feature was notably absent: **aggregated daily spend across all sessions**.

CCline status shows per-conversation metrics, which is useful within a single session. However, with the shift to running Claude Code in tmux (see [ADR 0014](0014-readopt-tmux-for-claude-code-workflows.md)), the workflow changed:

- Multiple concurrent Claude sessions across different projects
- Sessions persist across terminal restarts
- Daily spend matters more than per-prompt cost when managing multiple agents

The `/cost` command in Claude Code shows session totals, but requires:

1. Switching to each session
2. Running the command
3. Mentally aggregating across sessions

This friction meant I rarely checked spend until end of day, missing opportunities to catch runaway costs early.

## Decision

Implement a custom `claude-spend-today` script that aggregates daily Claude Code spend and displays it in the tmux status bar.

### Architecture

The implementation was guided by a detailed plan document: [`doc/plans/2025-01-17-claude-spend-tmux.md`](../plans/2025-01-17-claude-spend-tmux.md)

**Data Source**: Claude Code stores session transcripts at `~/.claude/projects/<project>/<session>.jsonl`. Each assistant response includes token usage:

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

**Cost Calculation**: Per-model pricing (Opus/Sonnet/Haiku) applied to token counts:

| Model  | Input | Output | Cache Write | Cache Read |
| ------ | ----- | ------ | ----------- | ---------- |
| Opus   | $15/M | $75/M  | $18.75/M    | $1.50/M    |
| Sonnet | $3/M  | $15/M  | $3.75/M     | $0.30/M    |
| Haiku  | $1/M  | $5/M   | $1.25/M     | $0.10/M    |

**Performance**:

- First run: <3 seconds (scans files modified in last 2 days)
- Cached runs: <100ms (60-second cache TTL)

### tmux Integration

```tmux
set -g status-right "#[bg=#313244,fg=#a6e3a1] ☉ #(~/.pickles/bin/claude-spend-today) #[default]#{E:@catppuccin_status_date_time}"
```

### Output Formats

The script supports three formats via argument:

- `cost` (default): `$5.23`
- `tokens`: `45.2M`
- `both`: `$5.23 (45.2M)`

### Alternatives Considered

1. **Use Claude Powerline instead of CCline status**

   - Pros: Has built-in spend tracking
   - Cons: Different UX, didn't want to switch back
   - Rejected: Prefer CCline status for in-prompt display

2. **Browser-based dashboard**

   - Pros: Richer visualization possible
   - Cons: Requires context switch, not always-visible
   - Rejected: tmux status bar is always visible

3. **Polling from Anthropic API**

   - Pros: Authoritative source, includes web console usage
   - Cons: Requires API key, rate limits, doesn't distinguish local sessions
   - Rejected: Local transcript parsing is sufficient and faster

4. **Notification-based (alerts at thresholds)**
   - Pros: Less visual noise
   - Cons: Misses gradual spend awareness
   - Rejected: Continuous visibility preferred for budget consciousness

## Consequences

### Positive

- **Continuous awareness**: Daily spend always visible without action required
- **Cross-session aggregation**: Single number across all projects
- **Model-aware pricing**: Accurate costs for mixed Opus/Sonnet/Haiku usage
- **Fast updates**: 60-second cache keeps display current without performance impact

### Negative

- **Local-only**: Doesn't include API usage outside Claude Code
- **Assumes transcript format stability**: Script breaks if Claude Code changes JSONL structure
- **No budget alerts**: Passive display only, no active notifications

### Files

- `bin/claude-spend-today`: Cost aggregation script
- `home/.tmux.conf`: Status bar integration
- `doc/plans/2025-01-17-claude-spend-tmux.md`: Implementation plan
