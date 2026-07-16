#!/bin/sh
# ============================================================================
# BayInit recipe: pm2
# ----------------------------------------------------------------------------
# What : Install PM2 globally and (optionally) set it up to resurrect running
#        processes on boot via a systemd unit. Idempotent — safe to re-run.
# Root : REQUIRED (global npm install + systemd startup unit).
# OS   : Debian/Ubuntu with systemd. Needs Node.js/npm (see the nodejs recipe).
# Env  : PM2_USER     user PM2 runs as on boot  (default: the sudo/login user)
#        PM2_STARTUP  install boot unit 1/0     (default: 1)
# Usage: curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/pm2.sh | sudo sh
# ============================================================================
set -eu

PM2_USER="${PM2_USER:-${SUDO_USER:-$(id -un)}}"
PM2_STARTUP="${PM2_STARTUP:-1}"

if [ "$(id -u)" -ne 0 ]; then
    echo "pm2 needs root. Re-run with sudo:" >&2
    echo "  curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/pm2.sh | sudo sh" >&2
    exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
    echo "pm2: npm not found. Install Node.js first:" >&2
    echo "  curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/nodejs.sh | sudo sh" >&2
    exit 1
fi

if command -v pm2 >/dev/null 2>&1; then
    echo "==> pm2: already installed ($(pm2 -v))"
else
    echo "==> pm2: installing globally"
    npm install -g pm2
fi

if [ "$PM2_STARTUP" = "0" ]; then
    echo "==> pm2: skipping boot setup (PM2_STARTUP=0)"
else
    home="$(getent passwd "$PM2_USER" | cut -d: -f6)"
    if [ -z "$home" ]; then
        echo "pm2: unknown user '$PM2_USER' (set PM2_USER)" >&2
        exit 1
    fi
    echo "==> pm2: enabling boot startup for user $PM2_USER"
    pm2 startup systemd -u "$PM2_USER" --hp "$home"
    # Save the user's current process list so it resurrects; empty is fine.
    su - "$PM2_USER" -c "pm2 save" || echo "    (pm2 save: nothing to save yet)"
fi

echo "==> pm2: done."
