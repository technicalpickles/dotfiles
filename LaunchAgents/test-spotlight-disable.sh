#!/usr/bin/env bash
#
# Test script for disabling Spotlight
# This is what the LaunchAgent will run
#
# Usage: ./LaunchAgents/test-spotlight-disable.sh

set -e

echo "=== Testing Spotlight Disable ==="
echo "Date: $(date)"
echo

# Check current status
echo "Current Spotlight status:"
sudo mdutil -a -s
echo

# Disable Spotlight
echo "Disabling Spotlight indexing..."
sudo mdutil -a -i off

echo
echo "Waiting 2 seconds..."
sleep 2
echo

# Verify it's disabled
echo "New Spotlight status:"
sudo mdutil -a -s

echo
echo "✓ Test complete"
echo
echo "If all volumes show 'Indexing disabled', the command works!"
echo "To re-enable: sudo mdutil -a -i on"
