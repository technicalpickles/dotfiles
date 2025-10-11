/**
 * TypeScript definitions for Finicky configuration
 * Based on: https://github.com/johnste/finicky
 */

declare module 'finicky' {
  /**
   * Main Finicky configuration object
   */
  export interface FinickyConfig {
    /**
     * The default browser to use when no handlers match
     * Can be a browser name, a function, or an array of browsers to try in order
     * Note: Modern API passes URL directly to functions, not wrapped in options object
     */
    defaultBrowser?:
      | string
      | BrowserSpec
      | ((url: URL) => string | BrowserSpec | undefined)
      | Array<
          | string
          | BrowserSpec
          | ((url: URL) => string | BrowserSpec | undefined)
        >;

    /**
     * URL rewrite rules to transform URLs before opening them
     */
    rewrite?: Rewriter[];

    /**
     * Handlers to route specific URLs to specific browsers
     */
    handlers?: Handler[];

    /**
     * Finicky options
     */
    options?: FinickyOptions;
  }

  /**
   * Handler to match URLs and route them to specific browsers
   */
  export interface Handler {
    /**
     * Pattern to match URLs against
     * Can be a string (glob), regex, or function
     * Note: Modern API passes URL directly, not wrapped in options object
     */
    match: string | string[] | RegExp | RegExp[] | ((url: URL) => boolean);

    /**
     * Browser to open the URL with
     * Can be a browser name, browser spec, or function
     */
    browser?:
      | string
      | BrowserSpec
      | BrowserFunction
      | Array<string | BrowserSpec | BrowserFunction>;

    /**
     * Optional URL transformation
     * Note: Modern API passes URL directly, not wrapped in options object
     */
    url?: string | ((url: URL) => string | URL);
  }

  /**
   * URL rewriter to transform URLs before opening
   */
  export interface Rewriter {
    /**
     * Pattern to match URLs against
     */
    match: string | string[] | RegExp | RegExp[] | ((url: URL) => boolean);

    /**
     * URL transformation
     * Can return a URL object or string
     */
    url: string | ((url: URL) => URL | string);
  }

  /**
   * Browser specification with options
   */
  export interface BrowserSpec {
    /**
     * Bundle identifier or name of the browser
     */
    name: string;

    /**
     * Additional command-line arguments to pass to the browser
     */
    args?: string[];

    /**
     * Browser profile to use
     */
    profile?: string;

    /**
     * Open in background without focusing the browser
     */
    openInBackground?: boolean;

    /**
     * App mode (Chrome-specific)
     */
    appMode?: boolean;
  }

  /**
   * Function that returns a browser name or spec
   * Note: Modern API passes URL directly, not wrapped in options object
   * Legacy API used MatchOptions but is deprecated
   */
  export type BrowserFunction = (url: URL) => string | BrowserSpec | undefined;

  /**
   * Options passed to match and browser functions
   */
  export interface MatchOptions {
    /**
     * Parsed URL object
     */
    url: URL;

    /**
     * Original URL string
     */
    urlString: string;

    /**
     * Bundle identifier of the source application
     */
    sourceBundleIdentifier?: string;

    /**
     * Path to the source application
     */
    sourceProcessPath?: string;

    /**
     * Keys pressed when opening the URL
     */
    keys?: {
      shift?: boolean;
      option?: boolean;
      command?: boolean;
      control?: boolean;
      capsLock?: boolean;
      function?: boolean;
    };
  }

  /**
   * Finicky options
   */
  export interface FinickyOptions {
    /**
     * Log all URL requests to Console.app
     */
    logRequests?: boolean;

    /**
     * Hide Finicky icon from the dock
     */
    hideIcon?: boolean;

    /**
     * Check for updates on startup
     */
    checkForUpdate?: boolean;

    /**
     * Show update notification
     */
    showUpdateNotification?: boolean;
  }
}
