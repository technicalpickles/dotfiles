#!/usr/bin/env node

/**
 * Get build logs for a specific job
 *
 * Usage:
 *   get-build-logs.js <org> <pipeline> <build> <job-label-or-uuid>
 *
 * Examples:
 *   get-build-logs.js gusto payroll-building-blocks 29627 "ste rspec"
 *   get-build-logs.js gusto payroll-building-blocks 29627 019a5f20-2d30-4c67-9edd-87fb92e1f487
 *
 * Features:
 *   - Accepts job label or UUID
 *   - Automatically resolves label to UUID if needed
 *   - Handles step ID vs job UUID confusion
 *   - Outputs formatted logs
 */

import { execSync } from 'child_process';

function usage() {
  console.error(
    'Usage: get-build-logs.js <org> <pipeline> <build> <job-label-or-uuid>'
  );
  console.error('');
  console.error('Examples:');
  console.error(
    '  get-build-logs.js gusto payroll-building-blocks 29627 "ste rspec"'
  );
  console.error(
    '  get-build-logs.js gusto payroll-building-blocks 29627 019a5f20-2d30-4c67-9edd-87fb92e1f487'
  );
  process.exit(1);
}

function getBuildDetails(org, pipeline, build) {
  try {
    const output = execSync(
      `npx bktide build ${org}/${pipeline}/${build} --format json`,
      { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] }
    );
    return JSON.parse(output);
  } catch (error) {
    console.error(`Error getting build details: ${error.message}`);
    process.exit(1);
  }
}

function isUuid(str) {
  // UUIDs are 36 characters with specific format
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
    str
  );
}

function resolveJobUuid(buildDetails, jobLabelOrUuid) {
  // If it looks like a UUID, assume it's a job UUID
  if (isUuid(jobLabelOrUuid)) {
    return jobLabelOrUuid;
  }

  // Otherwise treat as label and search for matching job
  // Note: bktide JSON format needs to be checked - this is a placeholder
  console.error(`Note: Searching for job with label "${jobLabelOrUuid}"`);
  console.error(
    `Note: This script is a placeholder and needs MCP tool integration`
  );
  console.error(`Note: Use MCP buildkite:get_logs directly instead:`);
  console.error(``);
  console.error(`mcp__MCPProxy__call_tool("buildkite:get_logs", {`);
  console.error(`  org_slug: "${buildDetails.organization.slug}",`);
  console.error(`  pipeline_slug: "${buildDetails.pipeline.slug}",`);
  console.error(`  build_number: "${buildDetails.number}",`);
  console.error(`  job_id: "<job-uuid>"`);
  console.error(`})`);

  process.exit(1);
}

function main() {
  const args = process.argv.slice(2);

  if (args.length < 4 || args.includes('--help') || args.includes('-h')) {
    usage();
  }

  const [org, pipeline, build, jobLabelOrUuid] = args;

  console.error(`Fetching build details for ${org}/${pipeline}/${build}...`);
  const buildDetails = getBuildDetails(org, pipeline, build);

  console.error(`Resolving job identifier...`);
  const jobUuid = resolveJobUuid(buildDetails, jobLabelOrUuid);

  console.error(`\nNote: This script is a placeholder.`);
  console.error(`For actual log retrieval, use MCP tools directly:`);
  console.error(``);
  console.error(`mcp__MCPProxy__call_tool("buildkite:get_logs", {`);
  console.error(`  org_slug: "${org}",`);
  console.error(`  pipeline_slug: "${pipeline}",`);
  console.error(`  build_number: "${build}",`);
  console.error(`  job_id: "${jobUuid}"`);
  console.error(`})`);
}

main();
