#!/bin/sh
# ============================================================================
# BayInit recipe: nodejs
# ----------------------------------------------------------------------------
# What : Install Node.js system-wide from NodeSource (adds their apt repo, so
#        updates arrive via apt). Idempotent — skips if the requested major
#        version is already installed.
# Root : REQUIRED (adds an apt repo and installs a system package).
# OS   : Debian/Ubuntu (apt).
# Env  : NODE_MAJOR  major version to install  (default: 22)
# Usage: curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/nodejs.sh | sudo sh
# ============================================================================
set -eu

NODE_MAJOR="${NODE_MAJOR:-22}"
case "$NODE_MAJOR" in
    *[!0-9]*|"") echo "nodejs: NODE_MAJOR must be a number (got '$NODE_MAJOR')" >&2; exit 1 ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    echo "nodejs needs root. Re-run with sudo:" >&2
    echo "  curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/nodejs.sh | sudo sh" >&2
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
    echo "nodejs: this recipe targets Debian/Ubuntu (apt-get not found)." >&2
    exit 1
fi

if command -v node >/dev/null 2>&1; then
    cur="$(node -v 2>/dev/null | sed 's/^v\([0-9]*\).*/\1/')"
    if [ "$cur" = "$NODE_MAJOR" ]; then
        echo "==> nodejs: Node $(node -v) already installed, nothing to do"
        exit 0
    fi
    echo "==> nodejs: found Node $(node -v), switching to major $NODE_MAJOR"
fi

echo "==> nodejs: adding NodeSource repo for v$NODE_MAJOR"
curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -

echo "==> nodejs: installing"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y nodejs

echo "==> nodejs: done. node $(node -v), npm $(npm -v)"
