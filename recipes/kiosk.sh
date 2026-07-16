#!/bin/sh
# ============================================================================
# BayInit recipe: kiosk
# ----------------------------------------------------------------------------
# What : Install a fullscreen Chrome/Chromium kiosk that opens a URL and
#        (optionally) autostarts on login. Idempotent — safe to run repeatedly.
# Root : NOT required. Everything installs into the current user's $HOME.
# OS   : Linux with an XDG desktop session (GNOME, etc.) and google-chrome
#        or chromium already installed.
# Env  : KIOSK_URL        page to display     (default: https://example.com)
#        KIOSK_WAIT       startup delay secs  (default: 5)
#        KIOSK_DIR        install location    (default: $HOME/.bayinit-kiosk)
#        KIOSK_AUTOSTART  start on login 1/0  (default: 1)
#        Unset values are prompted for when run interactively (Enter = default);
#        set them beforehand to skip the prompts (profiles / automation).
# Usage: curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/kiosk.sh | sh
# ============================================================================
set -eu

# BayInit prompt helper — ask VAR "Prompt" "default": an env var wins; else, if a
# terminal can be opened, prompt (Enter = default); else use the default. The
# prompt runs in a subshell so a missing controlling terminal (cron, CI, or
# curl|sh without a TTY) degrades to the default instead of aborting the script.
ask() {
    eval "_val=\${$1:-}"
    if [ -z "$_val" ]; then
        _ans="$( { exec 3<>/dev/tty; } 2>/dev/null && {
            printf '%s [%s]: ' "$2" "$3" >&3
            IFS= read -r _r <&3 && printf '%s' "$_r"
        } )" || _ans=""
        _val="${_ans:-$3}"
    fi
    eval "$1=\$_val"
}

ask KIOSK_URL       "Dashboard URL"            "https://example.com"
ask KIOSK_WAIT      "Startup delay in seconds" "5"
ask KIOSK_AUTOSTART "Autostart on login (1/0)" "1"
KIOSK_DIR="${KIOSK_DIR:-$HOME/.bayinit-kiosk}"
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
mkdir -p "$KIOSK_DIR"

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

DESKTOP_ENTRY="$AUTOSTART_DIR/bayinit-kiosk.desktop"
if [ "$KIOSK_AUTOSTART" = "0" ]; then
    echo "==> kiosk: autostart disabled (KIOSK_AUTOSTART=0)"
    rm -f "$DESKTOP_ENTRY"
    echo "==> kiosk: done. Run $KIOSK_DIR/kiosk.sh to start manually."
else
    echo "==> kiosk: installing autostart entry"
    mkdir -p "$AUTOSTART_DIR"
    cat > "$DESKTOP_ENTRY" <<DESKTOP
[Desktop Entry]
Type=Application
Exec=/bin/sh -c "$KIOSK_DIR/kiosk.sh"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=BayInit Kiosk
DESKTOP
    echo "==> kiosk: done. URL=$KIOSK_URL — log out and back in to start."
fi
