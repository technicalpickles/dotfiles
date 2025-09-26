# Fish completions for bktide CLI with dynamic completions
# Install by copying to ~/.config/fish/completions/bktide.fish
# Or run: bktide completions fish > ~/.config/fish/completions/bktide.fish

# Disable file completions for all bktide commands by default
complete -c bktide -f
complete -c bin/bktide -f

# Helper function to get organizations dynamically
function __fish_bktide_orgs
    # Try to get organizations, suppress errors
    bktide orgs --format json --quiet 2>/dev/null | jq -r '.[].slug' 2>/dev/null
end

# Helper function to get pipelines dynamically
function __fish_bktide_pipelines
    set -l org_arg
    # Try to find the --org value from the command line
    set -l cmd (commandline -opc)
    set -l found_org 0
    for i in (seq (count $cmd))
        if test "$found_org" = "1"
            set org_arg "--org $cmd[$i]"
            break
        end
        if test "$cmd[$i]" = "--org" -o "$cmd[$i]" = "-o"
            set found_org 1
        end
    end
    
    # Get pipelines for the org (or all if no org specified)
    if test -n "$org_arg"
        bktide pipelines $org_arg --format json --quiet 2>/dev/null | jq -r '.[].slug' 2>/dev/null
    else
        bktide pipelines --format json --quiet 2>/dev/null | jq -r '.[].slug' 2>/dev/null
    end
end

# Helper function to get branches (commonly used ones)
function __fish_bktide_branches
    # Common branch names - you could enhance this to get from git if in a repo
    echo main
    echo master
    echo develop
    echo staging
    echo production
    # Try to get branches from current git repo if available
    git branch -r 2>/dev/null | sed 's/.*origin\///' | grep -v HEAD 2>/dev/null
end

# Helper function to check if we're in the project directory for bin/bktide
function __fish_bktide_use_bin
    # Check if bin/bktide exists in current or parent directories
    if test -x ./bin/bktide
        return 0
    else if test -x ../bin/bktide
        return 0
    else if test -x ../../bin/bktide
        return 0
    end
    return 1
end

# Main commands
complete -c bktide -n __fish_use_subcommand -a viewer -d "Show logged in user information"
complete -c bktide -n __fish_use_subcommand -a orgs -d "List organizations"
complete -c bktide -n __fish_use_subcommand -a pipelines -d "List pipelines for an organization"
complete -c bktide -n __fish_use_subcommand -a builds -d "List builds for the current user"
complete -c bktide -n __fish_use_subcommand -a token -d "Manage API tokens"
complete -c bktide -n __fish_use_subcommand -a annotations -d "Show annotations for a build"
complete -c bktide -n __fish_use_subcommand -a completions -d "Generate shell completions"
complete -c bktide -n __fish_use_subcommand -a boom -d "Test error handling"

# Global options (available for all commands)
complete -c bktide -l log-level -d "Set logging level" -xa "trace debug info warn error fatal"
complete -c bktide -s d -l debug -d "Show debug information for errors"
complete -c bktide -l no-cache -d "Disable caching of API responses"
complete -c bktide -l cache-ttl -d "Set cache time-to-live in milliseconds" -x
complete -c bktide -l clear-cache -d "Clear all cached data before executing command"
complete -c bktide -s t -l token -d "Buildkite API token" -x
complete -c bktide -l save-token -d "Save the token to system keychain for future use"
complete -c bktide -s f -l format -d "Output format" -xa "plain json alfred"
complete -c bktide -l color -d "Color output mode" -xa "auto always never"
complete -c bktide -s q -l quiet -d "Suppress non-error output (plain format only)"
complete -c bktide -l tips -d "Show helpful tips and suggestions"
complete -c bktide -l no-tips -d "Hide helpful tips and suggestions"
complete -c bktide -l ascii -d "Use ASCII symbols instead of Unicode"
complete -c bktide -s h -l help -d "Show help"
complete -c bktide -s V -l version -d "Show version"

# Pipelines command options with dynamic org completion
complete -c bktide -n "__fish_seen_subcommand_from pipelines" -s o -l org -d "Organization slug" -xa "(__fish_bktide_orgs)"
complete -c bktide -n "__fish_seen_subcommand_from pipelines" -s n -l count -d "Limit to specified number of pipelines" -x
complete -c bktide -n "__fish_seen_subcommand_from pipelines" -l filter -d "Filter pipelines by name (case insensitive)" -x

# Builds command options with dynamic completions
complete -c bktide -n "__fish_seen_subcommand_from builds" -s o -l org -d "Organization slug" -xa "(__fish_bktide_orgs)"
complete -c bktide -n "__fish_seen_subcommand_from builds" -s p -l pipeline -d "Filter by pipeline slug" -xa "(__fish_bktide_pipelines)"
complete -c bktide -n "__fish_seen_subcommand_from builds" -s b -l branch -d "Filter by branch name" -xa "(__fish_bktide_branches)"
complete -c bktide -n "__fish_seen_subcommand_from builds" -s s -l state -d "Filter by build state" -xa "running scheduled passed failing failed canceled blocked canceling skipped not_run"
complete -c bktide -n "__fish_seen_subcommand_from builds" -s n -l count -d "Number of builds per page" -x
complete -c bktide -n "__fish_seen_subcommand_from builds" -l page -d "Page number" -x
complete -c bktide -n "__fish_seen_subcommand_from builds" -l filter -d "Fuzzy filter builds" -x

# Token command options
complete -c bktide -n "__fish_seen_subcommand_from token" -l check -d "Check if a token is stored"
complete -c bktide -n "__fish_seen_subcommand_from token" -l store -d "Store a token in the system keychain"
complete -c bktide -n "__fish_seen_subcommand_from token" -l reset -d "Delete the stored token"

# Annotations command - build reference examples
complete -c bktide -n "__fish_seen_subcommand_from annotations" -a "org/pipeline/123" -d "Example: org/pipeline/build-number"
complete -c bktide -n "__fish_seen_subcommand_from annotations" -l context -d "Filter annotations by context" -x

# Completions command options
complete -c bktide -n "__fish_seen_subcommand_from completions" -a "fish bash zsh" -d "Shell type"

# Boom command options (for testing)
complete -c bktide -n "__fish_seen_subcommand_from boom" -l type -d "Type of error to throw" -xa "basic api object"

# Also support bin/bktide for local development
# Copy all the same completions for bin/bktide
complete -c bin/bktide -n __fish_use_subcommand -a viewer -d "Show logged in user information"
complete -c bin/bktide -n __fish_use_subcommand -a orgs -d "List organizations"
complete -c bin/bktide -n __fish_use_subcommand -a pipelines -d "List pipelines for an organization"
complete -c bin/bktide -n __fish_use_subcommand -a builds -d "List builds for the current user"
complete -c bin/bktide -n __fish_use_subcommand -a token -d "Manage API tokens"
complete -c bin/bktide -n __fish_use_subcommand -a annotations -d "Show annotations for a build"
complete -c bin/bktide -n __fish_use_subcommand -a completions -d "Generate shell completions"
complete -c bin/bktide -n __fish_use_subcommand -a boom -d "Test error handling"

# Global options for bin/bktide
complete -c bin/bktide -l log-level -d "Set logging level" -xa "trace debug info warn error fatal"
complete -c bin/bktide -s d -l debug -d "Show debug information for errors"
complete -c bin/bktide -l no-cache -d "Disable caching of API responses"
complete -c bin/bktide -l cache-ttl -d "Set cache time-to-live in milliseconds" -x
complete -c bin/bktide -l clear-cache -d "Clear all cached data before executing command"
complete -c bin/bktide -s t -l token -d "Buildkite API token" -x
complete -c bin/bktide -l save-token -d "Save the token to system keychain for future use"
complete -c bin/bktide -s f -l format -d "Output format" -xa "plain json alfred"
complete -c bin/bktide -l color -d "Color output mode" -xa "auto always never"
complete -c bin/bktide -s q -l quiet -d "Suppress non-error output (plain format only)"
complete -c bin/bktide -l tips -d "Show helpful tips and suggestions"
complete -c bin/bktide -l no-tips -d "Hide helpful tips and suggestions"
complete -c bin/bktide -l ascii -d "Use ASCII symbols instead of Unicode"
complete -c bin/bktide -s h -l help -d "Show help"
complete -c bin/bktide -s V -l version -d "Show version"

# Command-specific options for bin/bktide with dynamic completions
complete -c bin/bktide -n "__fish_seen_subcommand_from pipelines" -s o -l org -d "Organization slug" -xa "(__fish_bktide_orgs)"
complete -c bin/bktide -n "__fish_seen_subcommand_from pipelines" -s n -l count -d "Limit to specified number of pipelines" -x
complete -c bin/bktide -n "__fish_seen_subcommand_from pipelines" -l filter -d "Filter pipelines by name (case insensitive)" -x

complete -c bin/bktide -n "__fish_seen_subcommand_from builds" -s o -l org -d "Organization slug" -xa "(__fish_bktide_orgs)"
complete -c bin/bktide -n "__fish_seen_subcommand_from builds" -s p -l pipeline -d "Filter by pipeline slug" -xa "(__fish_bktide_pipelines)"
complete -c bin/bktide -n "__fish_seen_subcommand_from builds" -s b -l branch -d "Filter by branch name" -xa "(__fish_bktide_branches)"
complete -c bin/bktide -n "__fish_seen_subcommand_from builds" -s s -l state -d "Filter by build state" -xa "running scheduled passed failing failed canceled blocked canceling skipped not_run"
complete -c bin/bktide -n "__fish_seen_subcommand_from builds" -s n -l count -d "Number of builds per page" -x
complete -c bin/bktide -n "__fish_seen_subcommand_from builds" -l page -d "Page number" -x
complete -c bin/bktide -n "__fish_seen_subcommand_from builds" -l filter -d "Fuzzy filter builds" -x

complete -c bin/bktide -n "__fish_seen_subcommand_from token" -l check -d "Check if a token is stored"
complete -c bin/bktide -n "__fish_seen_subcommand_from token" -l store -d "Store a token in the system keychain"
complete -c bin/bktide -n "__fish_seen_subcommand_from token" -l reset -d "Delete the stored token"

complete -c bin/bktide -n "__fish_seen_subcommand_from annotations" -a "org/pipeline/123" -d "Example: org/pipeline/build-number"
complete -c bin/bktide -n "__fish_seen_subcommand_from annotations" -l context -d "Filter annotations by context" -x

complete -c bin/bktide -n "__fish_seen_subcommand_from completions" -a "fish bash zsh" -d "Shell type"

complete -c bin/bktide -n "__fish_seen_subcommand_from boom" -l type -d "Type of error to throw" -xa "basic api object"

