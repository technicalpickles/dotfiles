# Cloudflare Zero Trust SSL certificate
# Cloudflare Zero Trust performs SSL inspection, so Node.js needs to trust the Cloudflare root CA
# This fixes "self signed certificate in certificate chain" errors in Claude Code and other Node.js tools

set -l cloudflare_cert "$HOME/workspace/cpe-chef/cookbooks/gusto_helpers/files/cloudflare-gateway-ca.crt"

if test -f "$cloudflare_cert"
    set -gx NODE_EXTRA_CA_CERTS "$cloudflare_cert"
end
