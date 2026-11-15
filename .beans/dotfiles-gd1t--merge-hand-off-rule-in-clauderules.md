---
# dotfiles-gd1t
title: Merge hand-off rule in claude/rules
status: in-progress
type: task
created_at: 2026-11-15T21:26:17Z
updated_at: 2026-11-15T21:26:17Z
---

Add claude/rules/merging.md so hand-backs state PR/order/SHA/CI instead of 'Merging is yours'. Baseline (2026-11-15): ~1/3 of Oct/Nov hand-backs used ownership wording; 13 classifier denials in ~350 gh pr merge attempts. Re-measure after ~2 weeks with merge_baseline.py / merge_outcomes.py (currently in session scratchpad; move into repo if kept).

## Checklist
- [x] Draft claude/rules/merging.md
- [x] Run ./claudeconfig.sh to link the new rule
- [ ] Decide where the baseline scripts live
- [ ] Re-measure wording share, SHA share, denial rate after 2 weeks
