// Finicky configuration
// See: https://github.com/johnste/finicky/wiki/Configuration

/// <reference path="./finicky.d.ts" />
import type { FinickyConfig } from 'finicky';

// System-specific Chrome profiles
// Edit these values for each system, or add hostname-based conditionals below
let personalChromeProfile = 'Profile 1'; // default
let workChromeProfile = 'Profile 1'; // default

// Example: Customize per hostname
// const hostname = finicky.getSystemInfo().name;
// if (hostname === 'your-macbook-name') {
//   personalChromeProfile = 'Profile 3';
//   workChromeProfile = 'Profile 1';
// }
//

const config: FinickyConfig = {
  // Chrome is the default for everything not explicitly routed
  defaultBrowser: 'com.google.Chrome',

  // Rewrite URLs before opening them
  rewrite: [
    {
      // Remove common tracking parameters
      match: (url: URL) => url.search.includes('utm_'),
      url: (url: URL) => {
        const params = [
          'utm_source',
          'utm_medium',
          'utm_campaign',
          'utm_term',
          'utm_content',
          'fbclid',
          'gclid',
          'ref',
        ];
        params.forEach((param) => url.searchParams.delete(param));
        return url;
      },
    },
    {
      // Rewrite Zoom URLs to open in Zoom app with password
      // @https://github.com/johnste/finicky/wiki/Configuration-ideas#open-zoom-links-in-zoom-app-with-or-without-password
      match: (url: URL) =>
        url.host.includes('zoom.us') && url.pathname.includes('/j/'),
      url: (url: URL) => {
        try {
          const match = url.search.match(/pwd=(\w*)/);
          var pass = match ? '&pwd=' + match[1] : '';
        } catch {
          var pass = '';
        }
        const pathMatch = url.pathname.match(/\/j\/(\d+)/);
        var conf = 'confno=' + (pathMatch ? pathMatch[1] : '');
        url.search = conf + pass;
        url.pathname = '/join';
        url.protocol = 'zoommtg';
        return url;
      },
    },
  ],

  // Route specific URLs to specific browsers
  handlers: [
    // Open Slack links in Slack app
    // @https://github.com/johnste/finicky/wiki/Configuration-ideas#open-slack-link-in-slack-app
    {
      match: (url) => url.protocol === 'slack:' || url.protocol === 'slack',
      browser: 'Slack',
    },
    {
      match: '*.slack.com/*',
      browser: 'Slack',
    },

    // Open Spotify links in Spotify app
    {
      match: ['open.spotify.com/*', '*.open.spotify.com/*'],
      browser: 'Spotify',
    },

    // Open Zoom links in Zoom app
    {
      match: /zoom\.us\/join/,
      browser: 'us.zoom.xos',
    },

    // Google Meet works better in Chrome
    {
      match: ['meet.google.com/*', '*.meet.google.com/*'],
      browser: {
        name: 'Google Chrome',
        profile: workChromeProfile,
      },
    },

    // Google Calendar - open in Chrome installed app
    {
      match: 'calendar.google.com/*',
      browser: 'Google Calendar',
    },

    // Other Google Workspace apps that might work better in Chrome
    {
      match: [
        'docs.google.com/*',
        'sheets.google.com/*',
        'slides.google.com/*',
        'drive.google.com/*',
      ],
      browser: {
        name: 'Google Chrome',
        profile: workChromeProfile,
      },
    },

    // Datadog - open in Chrome
    {
      match: ['*.datadoghq.com/*', 'datadoghq.com/*'],
      browser: {
        name: 'Google Chrome',
        profile: workChromeProfile,
      },
    },

    // YouTube - open in Chrome
    {
      match: ['youtube.com/*', '*.youtube.com/*', 'youtu.be/*'],
      browser: {
        name: 'Google Chrome',
        profile: personalChromeProfile,
      },
    },

    // Sites that commonly have Chrome-specific optimizations
    {
      match: ['*.figma.com/*', 'figma.com/*', '*.notion.so/*', 'notion.so/*'],
      browser: 'Google Chrome',
    },

    // Development/localhost - might want these in Chrome for DevTools
    {
      match: [
        'localhost*',
        '*.localhost*',
        '127.0.0.1*',
        '*.local*',
        '*.test*',
        '*.dev*',
      ],
      browser: {
        name: 'Google Chrome',
        profile: workChromeProfile,
      },
    },
  ],

  // Optional: log what Finicky is doing for debugging
  options: {
    // Uncomment to see logs in Console.app
    // logRequests: true,
  },
};

export default config;
