#!/bin/sh
# ============================================================================
# BayInit recipe: chrome
# ----------------------------------------------------------------------------
# What : Install Google Chrome from Google's official .deb. The package also
#        registers Google's apt repo, so future updates arrive via apt.
#        Idempotent — skips if the requested channel is already installed.
# Root : REQUIRED (installs a system package).
# OS   : Debian/Ubuntu (apt), x86_64 only.
# Env  : CHROME_CHANNEL  stable | beta | unstable  (default: stable)
# Usage: curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/chrome.sh | sudo sh
# ============================================================================
set -eu

CHROME_CHANNEL="${CHROME_CHANNEL:-stable}"
case "$CHROME_CHANNEL" in
    stable|beta|unstable) ;;
    *) echo "chrome: CHROME_CHANNEL must be stable, beta or unstable (got '$CHROME_CHANNEL')" >&2; exit 1 ;;
esac
PKG="google-chrome-$CHROME_CHANNEL"

if [ "$(id -u)" -ne 0 ]; then
    echo "chrome needs root. Re-run with sudo:" >&2
    echo "  curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/chrome.sh | sudo sh" >&2
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
    echo "chrome: this recipe targets Debian/Ubuntu (apt-get not found)." >&2
    exit 1
fi

arch="$(uname -m)"
if [ "$arch" != "x86_64" ]; then
    echo "chrome: Google Chrome for Linux is x86_64 only (this host is $arch)." >&2
    echo "        On ARM, install Chromium instead." >&2
    exit 1
fi

if command -v "$PKG" >/dev/null 2>&1; then
    echo "==> chrome: $PKG already installed, nothing to do"
    exit 0
fi

deb="$(mktemp --suffix=.deb)"
trap 'rm -f "$deb"' EXIT
echo "==> chrome: downloading $PKG"
curl -fsSL -o "$deb" "https://dl.google.com/linux/direct/${PKG}_current_amd64.deb"

echo "==> chrome: installing (apt resolves dependencies)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y "$deb"

echo "==> chrome: done. $("$PKG" --version 2>/dev/null || echo installed)"
