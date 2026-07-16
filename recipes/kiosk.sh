#!/bin/sh
# ============================================================================
# BayInit recipe: kiosk
# ----------------------------------------------------------------------------
# What : Install a fullscreen Chrome/Chromium kiosk that autostarts on login
#        and opens a fixed URL. Idempotent — safe to run repeatedly.
# Root : NOT required. Everything installs into the current user's $HOME.
# OS   : Linux with an XDG desktop session (GNOME, etc.) and google-chrome
#        or chromium already installed.
# Env  : KIOSK_URL   page to display    (default: https://desktop-mazda.stechoq-j.com/)
#        KIOSK_WAIT  startup delay secs  (default: 5)
#        KIOSK_DIR   install location    (default: $HOME/stechoq-kiosk)
# Usage: curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/kiosk.sh | sh
# ============================================================================
set -eu

KIOSK_URL="${KIOSK_URL:-https://desktop-mazda.stechoq-j.com/}"
KIOSK_WAIT="${KIOSK_WAIT:-5}"
KIOSK_DIR="${KIOSK_DIR:-$HOME/stechoq-kiosk}"
AUTOSTART_DIR="$HOME/.config/autostart"

echo "==> kiosk: detecting browser"
BROWSER=""
for b in google-chrome google-chrome-stable chromium chromium-browser; do
    if command -v "$b" >/dev/null 2>&1; then
        BROWSER="$b"
        break
    fi
done
if [ -z "$BROWSER" ]; then
    echo "    no Chrome/Chromium found. Install one first, e.g.:" >&2
    echo "      sudo apt install -y chromium-browser   # Debian/Ubuntu" >&2
    exit 1
fi
echo "    using $BROWSER"
# TODO(rifky): auto-install the browser when missing instead of aborting?

echo "==> kiosk: creating $KIOSK_DIR"
mkdir -p "$KIOSK_DIR" "$AUTOSTART_DIR"

echo "==> kiosk: writing launcher"
cat > "$KIOSK_DIR/kiosk.sh" <<'LAUNCHER'
#!/bin/sh
# Launched at login by the BayInit kiosk autostart entry.
set -eu
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/config"
sleep "${WAIT:-5}"
pkill -f "$BROWSER" 2>/dev/null || true
sleep 1
exec "$BROWSER" \
    --password-store=basic \
    --kiosk \
    --no-first-run \
    --disable-session-crashed-bubble \
    --disable-infobars \
    "$URL"
LAUNCHER
chmod +x "$KIOSK_DIR/kiosk.sh"

# Config holds the tunable values. Keep it on re-run so hand-edits survive.
if [ -f "$KIOSK_DIR/config" ]; then
    echo "==> kiosk: config exists, keeping it (edit $KIOSK_DIR/config to change URL)"
else
    echo "==> kiosk: writing config"
    cat > "$KIOSK_DIR/config" <<CONFIG
# BayInit kiosk config. Edit and log out/in to apply.
URL=$KIOSK_URL
WAIT=$KIOSK_WAIT
BROWSER=$BROWSER
CONFIG
fi

echo "==> kiosk: installing autostart entry"
cat > "$AUTOSTART_DIR/bayinit-kiosk.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Exec=/bin/sh -c "$KIOSK_DIR/kiosk.sh"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=BayInit Kiosk
DESKTOP

echo "==> kiosk: done. URL=$KIOSK_URL — log out and back in to start."
