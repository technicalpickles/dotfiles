// Finicky configuration
// See: https://github.com/johnste/finicky/wiki/Configuration

export default {
  // Horse Browser is the default for everything not explicitly routed
  defaultBrowser: 'Horse',

  // Rewrite URLs before opening them
  rewrite: [
    {
      // Remove common tracking parameters
      match: (url) => url.search.includes('utm_'),
      url: (url) => {
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
      match: (url) =>
        url.host.includes('zoom.us') && url.pathname.includes('/j/'),
      url: (url) => {
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

    // Open Zoom links in Zoom app
    {
      match: /zoom\.us\/join/,
      browser: 'us.zoom.xos',
    },

    // Google Meet works better in Chrome
    {
      match: ['meet.google.com/*', '*.meet.google.com/*'],
      browser: 'Google Chrome',
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
      browser: 'Google Chrome',
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
      browser: 'Google Chrome',
    },
  ],

  // Optional: log what Finicky is doing for debugging
  options: {
    // Uncomment to see logs in Console.app
    // logRequests: true,
  },
};
