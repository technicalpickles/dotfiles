#!/usr/bin/env bash
#
# Forces Karabiner's Core-Service daemon to restart immediately on wake.
#
# Core-Service normally reconnects to the virtual HID driver and re-grabs the
# keyboard on its own after wake, but observed behavior on this machine shows
# it sitting idle for ~10s between tearing down its event tap and retrying --
# no errors, no retries logged in /var/log/karabiner/core_service.log, just a
# gap. Kicking the daemon directly skips that wait; it reconnects in ~1-2s
# instead. See https://github.com/pqrs-org/Karabiner-Elements/issues/3808 for
# the (unresolved, upstream) report of the same symptom.
#
# Invoked by sleepwatcher's wake watcher --
# see LaunchAgents/com.technicalpickles.karabiner-wake-fix.plist.

set -euo pipefail

LABEL="org.pqrs.service.daemon.Karabiner-Core-Service"

# No-op on machines without Karabiner installed/running, so this script is
# safe to ship to every role even though it's only wired up for home.
if ! /bin/launchctl print "system/$LABEL" > /dev/null 2>&1; then
  exit 0
fi

/usr/bin/sudo /bin/launchctl kickstart -k "system/$LABEL"
