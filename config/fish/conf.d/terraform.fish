# Without a shared cache every init copies ~780M of providers; the dir must exist or terraform skips the cache.
set -gx TF_PLUGIN_CACHE_DIR $HOME/.cache/terraform/plugins
mkdir -p $TF_PLUGIN_CACHE_DIR
