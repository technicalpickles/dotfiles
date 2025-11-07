#!/usr/bin/env node

/**
 * Parse Buildkite URL to extract components
 *
 * Usage:
 *   parse-buildkite-url.js <url>
 *
 * Examples:
 *   parse-buildkite-url.js "https://buildkite.com/gusto/payroll-building-blocks/builds/29627"
 *   parse-buildkite-url.js "https://buildkite.com/gusto/payroll-building-blocks/builds/29627/steps/canvas?sid=019a5f23..."
 *
 * Output:
 *   JSON object with: org, pipeline, buildNumber, stepId (if present)
 */

function usage() {
  console.error('Usage: parse-buildkite-url.js <url>');
  console.error('');
  console.error('Examples:');
  console.error(
    '  parse-buildkite-url.js "https://buildkite.com/gusto/payroll-building-blocks/builds/29627"'
  );
  console.error(
    '  parse-buildkite-url.js "https://buildkite.com/gusto/payroll-building-blocks/builds/29627/steps/canvas?sid=019a5f..."'
  );
  process.exit(1);
}

function parseBuildkiteUrl(url) {
  // Match build URL pattern
  const buildMatch = url.match(
    /buildkite\.com\/([^/]+)\/([^/]+)\/builds\/(\d+)/
  );

  if (!buildMatch) {
    throw new Error(
      'Invalid Buildkite URL - expected format: https://buildkite.com/{org}/{pipeline}/builds/{number}'
    );
  }

  const result = {
    org: buildMatch[1],
    pipeline: buildMatch[2],
    buildNumber: buildMatch[3],
  };

  // Check for step ID query parameter
  const sidMatch = url.match(/[?&]sid=([^&]+)/);
  if (sidMatch) {
    result.stepId = sidMatch[1];
    result.note =
      'stepId is for UI routing only - use API to get job UUID for log retrieval';
  }

  // Check for job UUID in path
  const jobMatch = url.match(/\/jobs\/([0-9a-f-]+)/i);
  if (jobMatch) {
    result.jobUuid = jobMatch[1];
    result.note = 'jobUuid can be used directly for log retrieval';
  }

  return result;
}

function main() {
  const args = process.argv.slice(2);

  if (args.length !== 1 || args.includes('--help') || args.includes('-h')) {
    usage();
  }

  const url = args[0];

  try {
    const parsed = parseBuildkiteUrl(url);
    console.log(JSON.stringify(parsed, null, 2));
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

main();
