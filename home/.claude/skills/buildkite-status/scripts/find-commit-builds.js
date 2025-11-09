#!/usr/bin/env node
/**
 * Find Buildkite builds for a specific commit
 *
 * Searches across pipelines for builds matching a commit SHA.
 * Useful for post-push workflows to find which builds are running.
 *
 * Usage:
 *   find-commit-builds.js <org> <commit-sha> [options]
 *
 * Options:
 *   --pipeline <slug>     Limit search to specific pipeline
 *   --branch <name>       Limit to specific branch
 *   --format <json|plain> Output format (default: plain)
 *
 * Exit codes:
 *   0 - Builds found
 *   1 - No builds found
 *   2 - Error occurred
 */

const { execSync } = require('child_process');

// Parse command line arguments
const args = process.argv.slice(2);
if (args.length < 2 || args[0] === '--help' || args[0] === '-h') {
  console.error('Usage: find-commit-builds.js <org> <commit-sha> [options]');
  console.error('Options:');
  console.error('  --pipeline <slug>     Limit search to specific pipeline');
  console.error('  --branch <name>       Limit to specific branch');
  console.error('  --format <json|plain> Output format (default: plain)');
  process.exit(2);
}

const org = args[0];
const commit = args[1];

// Parse options
let pipelineSlug = null;
let branch = null;
let format = 'plain';

for (let i = 2; i < args.length; i++) {
  if (args[i] === '--pipeline' && i + 1 < args.length) {
    pipelineSlug = args[++i];
  } else if (args[i] === '--branch' && i + 1 < args.length) {
    branch = args[++i];
  } else if (args[i] === '--format' && i + 1 < args.length) {
    format = args[++i];
  }
}

function getPipelines() {
  try {
    const cmd = `npx bktide pipelines --format json ${org}`;
    const output = execSync(cmd, {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    return JSON.parse(output);
  } catch (error) {
    throw new Error(`Failed to get pipelines: ${error.message}`);
  }
}

function getBuildsForPipeline(pipeline, commit, branch) {
  try {
    let cmd = `npx bktide builds --format json ${org}/${pipeline}`;
    if (commit) {
      // Note: bktide might not support commit filtering directly,
      // so we'll fetch recent builds and filter
      cmd += ` --state running --state scheduled`;
    }
    const output = execSync(cmd, {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    const builds = JSON.parse(output);

    // Filter by commit
    return builds.filter((build) => {
      const commitMatch = !commit || build.commit?.startsWith(commit);
      const branchMatch = !branch || build.branch === branch;
      return commitMatch && branchMatch;
    });
  } catch (error) {
    // Pipeline might not exist or be accessible, return empty array
    return [];
  }
}

function main() {
  try {
    const allBuilds = [];

    if (pipelineSlug) {
      // Search single pipeline
      const builds = getBuildsForPipeline(pipelineSlug, commit, branch);
      allBuilds.push(...builds);
    } else {
      // Search all pipelines
      const pipelines = getPipelines();
      for (const pipeline of pipelines) {
        const builds = getBuildsForPipeline(pipeline.slug, commit, branch);
        if (builds.length > 0) {
          allBuilds.push(...builds);
        }
      }
    }

    if (format === 'json') {
      console.log(JSON.stringify(allBuilds, null, 2));
    } else {
      if (allBuilds.length === 0) {
        console.log(`No builds found for commit ${commit}`);
        process.exit(1);
      }

      console.log(`Found ${allBuilds.length} build(s) for commit ${commit}:\n`);
      for (const build of allBuilds) {
        console.log(
          `  ${build.pipeline.slug}#${build.number} - ${build.state}`
        );
        console.log(`    Branch: ${build.branch}`);
        console.log(`    URL: ${build.web_url}`);
        console.log();
      }
    }

    process.exit(allBuilds.length > 0 ? 0 : 1);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(2);
  }
}

main();
