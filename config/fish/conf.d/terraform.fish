# Share one provider cache across every `terraform init`. Without it each
# template's .terraform/providers gets a full copy (~780M for coder + docker),
# which adds up fast across worktrees. The dir must exist or terraform warns
# and falls back to per-directory copies.
set -gx TF_PLUGIN_CACHE_DIR $HOME/.cache/terraform/plugins
mkdir -p $TF_PLUGIN_CACHE_DIR
