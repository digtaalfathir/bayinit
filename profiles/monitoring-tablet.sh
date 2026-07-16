#!/bin/sh
# ============================================================================
# BayInit profile: monitoring-tablet
# ----------------------------------------------------------------------------
# What : Turn a fresh desktop into a fullscreen monitoring tablet — installs
#        Google Chrome (chrome recipe) then configures the kiosk (kiosk recipe).
#        A profile is just recipes run in order.
# Root : Run as the TABLET'S user, NOT root. The Chrome step calls sudo itself.
# OS   : Debian/Ubuntu desktop, x86_64.
# Env  : KIOSK_URL / KIOSK_WAIT / KIOSK_AUTOSTART  passed through to the kiosk recipe.
#        BAYINIT_BASE  recipe base URL  (default: the GitHub Pages recipes dir)
# Usage: KIOSK_URL=https://dash.local \
#          curl -fsSL https://digtaalfathir.github.io/bayinit/profiles/monitoring-tablet.sh | sh
# ============================================================================
set -eu

BASE="${BAYINIT_BASE:-https://digtaalfathir.github.io/bayinit/recipes}"

if [ "$(id -u)" -eq 0 ]; then
    echo "monitoring-tablet: run this as the tablet's user, not root." >&2
    echo "  (the Chrome step uses sudo on its own)" >&2
    exit 1
fi

echo "### monitoring-tablet [1/2]: chrome (uses sudo)"
curl -fsSL "$BASE/chrome.sh" | sudo sh

echo "### monitoring-tablet [2/2]: kiosk"
# kiosk runs as this user and inherits KIOSK_* from the environment.
curl -fsSL "$BASE/kiosk.sh" | sh

echo "### monitoring-tablet: done. Log out and back in to launch."
