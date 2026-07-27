---
# dotfiles-lx04
title: Fix Karabiner slow-to-reactivate after wake from sleep
status: in-progress
type: bug
priority: normal
created_at: 2026-07-27T00:30:18Z
updated_at: 2026-07-27T01:00:46Z
---

On this machine, Karabiner's caps->control remap takes ~13.8s to reactivate after wake from sleep.
Confirmed via /var/log/karabiner/core_service.log timeline (wake event at 18:04:43.512):
- ~10s of dead silence between event tap teardown (18:04:43.687) and device_grabber
  restart/receiver reinit (18:04:53.518) -- no retries, no errors logged, just idle.
- Root daemon is Karabiner-Core-Service (org.pqrs.service.daemon.Karabiner-Core-Service),
  the unified v16 replacement for the old karabiner_grabber.
- virtual_hid_device_service.log confirms the VirtualHIDDevice daemon responds instantly
  once Core-Service actually retries (both logs show reconnect at 18:04:56.269) -- so the
  driver isn't the bottleneck, Core-Service's own internal retry/backoff is.
- Checked upstream: https://github.com/pqrs-org/Karabiner-Elements/issues/3808 reports the
  same symptom, still open, no maintainer fix or workaround.

Fix: use sleepwatcher to force Karabiner-Core-Service to restart immediately on wake
(`launchctl kickstart -k system/org.pqrs.service.daemon.Karabiner-Core-Service`), skipping
its internal delay. This needs root, so it needs a scoped NOPASSWD sudoers rule -- following
the exact pattern already documented in LaunchAgents/README.md's "Sudo password required"
section (previously only theoretical, now actually implemented). See ADR 0045.

## Checklist
- [x] Add `brew 'sleepwatcher'` to Brewfile.home
- [x] Add bin/karabiner-wake-fix.sh (guarded, idempotent kickstart script)
- [x] Add LaunchAgents/com.technicalpickles.karabiner-wake-fix.plist (runs sleepwatcher -w)
- [x] Add config/sudoers.d/karabiner-wake-fix template (scoped NOPASSWD rule)
- [x] Add karabinerconfig.sh (home-role gated: installs sudoers file, symlinks plist)
- [x] Wire karabinerconfig.sh into install.sh
- [x] Document new agent in LaunchAgents/README.md
- [x] Write ADR for the sudoers.d templating pattern (0045)
- [x] Installed sleepwatcher, sudoers rule, and LaunchAgent on this machine; confirmed
      the NOPASSWD rule works (`sudo -n launchctl kickstart ...` ran without a password)
      and the agent is loaded and running sleepwatcher with the right args
- [ ] Verify end-to-end with a real sleep/wake cycle (check core_service.log timeline
      shrinks from ~13.8s to ~1-2s after wake)
