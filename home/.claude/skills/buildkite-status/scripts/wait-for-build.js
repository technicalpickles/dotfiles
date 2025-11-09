#!/usr/bin/env node
/**
 * Background build monitor for Buildkite
 *
 * Polls a build until it reaches a terminal state (passed, failed, canceled)
 * with configurable timeout and polling interval.
 *
 * Usage:
 *   wait-for-build.js <org> <pipeline> <build-number> [options]
 *
 * Options:
 *   --timeout <seconds>    Maximum time to wait (default: 1800 = 30 minutes)
 *   --interval <seconds>   Polling interval (default: 30)
 *   --quiet               Suppress progress updates
 *
 * Exit codes:
 *   0 - Build passed
 *   1 - Build failed
 *   2 - Build canceled
 *   3 - Timeout reached
 *   4 - Error occurred
 */

const { execSync } = require('child_process');

// Parse command line arguments
const args = process.argv.slice(2);
if (args.length < 3 || args[0] === '--help' || args[0] === '-h') {
  console.error(
    'Usage: wait-for-build.js <org> <pipeline> <build-number> [options]'
  );
  console.error('Options:');
  console.error(
    '  --timeout <seconds>    Maximum time to wait (default: 1800)'
  );
  console.error('  --interval <seconds>   Polling interval (default: 30)');
  console.error('  --quiet               Suppress progress updates');
  process.exit(4);
}

const org = args[0];
const pipeline = args[1];
const buildNumber = args[2];

// Parse options
let timeout = 1800; // 30 minutes default
let interval = 30; // 30 seconds default
let quiet = false;

for (let i = 3; i < args.length; i++) {
  if (args[i] === '--timeout' && i + 1 < args.length) {
    timeout = parseInt(args[++i], 10);
  } else if (args[i] === '--interval' && i + 1 < args.length) {
    interval = parseInt(args[++i], 10);
  } else if (args[i] === '--quiet') {
    quiet = true;
  }
}

const startTime = Date.now();
const timeoutMs = timeout * 1000;

function log(message) {
  if (!quiet) {
    console.log(`[${new Date().toISOString()}] ${message}`);
  }
}

function getBuildStatus() {
  try {
    const cmd = `npx bktide build --format json gusto/${pipeline}#${buildNumber}`;
    const output = execSync(cmd, {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    return JSON.parse(output);
  } catch (error) {
    if (error.stdout) {
      try {
        return JSON.parse(error.stdout);
      } catch {}
    }
    throw new Error(`Failed to get build status: ${error.message}`);
  }
}

function isTerminalState(state) {
  return ['passed', 'failed', 'canceled', 'blocked', 'skipped'].includes(state);
}

function getExitCode(state) {
  switch (state) {
    case 'passed':
      return 0;
    case 'failed':
      return 1;
    case 'canceled':
      return 2;
    default:
      return 4;
  }
}

log(`Monitoring build: ${org}/${pipeline}#${buildNumber}`);
log(`Timeout: ${timeout}s, Polling interval: ${interval}s`);

async function main() {
  while (true) {
    const elapsed = Math.floor((Date.now() - startTime) / 1000);

    // Check timeout
    if (elapsed >= timeout) {
      log(`Timeout reached after ${elapsed}s`);
      process.exit(3);
    }

    try {
      const build = getBuildStatus();
      const state = build.state;

      log(`Build state: ${state} (elapsed: ${elapsed}s)`);

      if (isTerminalState(state)) {
        log(`Build finished with state: ${state}`);
        log(`Build URL: ${build.web_url}`);

        // Show job summary if available
        if (build.job_summary) {
          const summary = build.job_summary;
          log(`Jobs: ${summary.total} total`);
          if (summary.by_state) {
            const states = Object.entries(summary.by_state)
              .map(([s, count]) => `${count} ${s}`)
              .join(', ');
            log(`  ${states}`);
          }
        }

        process.exit(getExitCode(state));
      }

      // Wait before next poll
      await new Promise((resolve) => setTimeout(resolve, interval * 1000));
    } catch (error) {
      log(`Error checking build status: ${error.message}`);
      log('Retrying...');
      await new Promise((resolve) => setTimeout(resolve, interval * 1000));
    }
  }
}

main().catch((error) => {
  console.error('Fatal error:', error.message);
  process.exit(4);
});
