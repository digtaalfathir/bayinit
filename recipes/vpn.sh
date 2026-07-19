#!/bin/sh
# ============================================================================
# BayInit recipe: vpn (SoftEther client)
# ----------------------------------------------------------------------------
# What : Install the SoftEther VPN client, import an internal account, and set
#        it to auto-connect on boot (systemd). Idempotent — safe to re-run.
# Root : REQUIRED (compiles software, writes /usr/local + systemd unit).
# OS   : Debian/Ubuntu/Zorin (apt) with systemd, x86_64.
# Secret: the account files (*.vpn) are NOT in this public repo. They are pulled
#        at run time from a PRIVATE repo using a token you supply via the
#        environment — the token never lives in this script. No token, no files,
#        no connection: the public script is useless on its own.
# Env  : BAY_VPN_TOKEN   (required) read-only token for the private .vpn repo
#        BAY_VPN_REPO    private repo "owner/name"   (default: digtaalfathir/bayinit-vpn)
#        BAY_VPN_REF     branch/tag                  (default: main)
#        VPN_ACCOUNTS    .vpn files to import        (default: "raspi.vpn srv4.stechoq.com.vpn")
#        VPN_CONNECT     account to auto-connect     (default: raspi)
#        VPN_NIC         virtual NIC name            (default: vpn  -> device vpn_vpn)
#        VPN_CLIENT_IP   e.g. 10.10.1.173 (prompted when unset & interactive)
#        VPN_MAP_PREFIX  /24 prefix the IP maps onto (default: 172.16.10)
#        VPN_NETMASK     assigned prefix length      (default: 23)
#        SOFTETHER_URL   client source tarball       (default: pinned v4.42 below)
# Usage: BAY_VPN_TOKEN=ghp_xxx VPN_CLIENT_IP=10.10.1.173 \
#          curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/vpn.sh | sudo -E sh
# ============================================================================
set -eu

BAY_VPN_REPO="${BAY_VPN_REPO:-digtaalfathir/bayinit-vpn}"
BAY_VPN_REF="${BAY_VPN_REF:-main}"
VPN_ACCOUNTS="${VPN_ACCOUNTS:-raspi.vpn srv4.stechoq.com.vpn}"
VPN_CONNECT="${VPN_CONNECT:-raspi}"
VPN_NIC="${VPN_NIC:-vpn}"
VPN_MAP_PREFIX="${VPN_MAP_PREFIX:-172.16.10}"   # ponytail: network knob — verify per site
VPN_NETMASK="${VPN_NETMASK:-23}"
# ponytail: pinned SoftEther version — bump/verify the URL when it rotates.
SOFTETHER_URL="${SOFTETHER_URL:-https://www.softether-download.com/files/softether/v4.42-9798-rtm-2023.06.30-tree/Linux/SoftEther_VPN_Client/64bit_-_Intel_x64_or_AMD64/softether-vpnclient-v4.42-9798-rtm-2023.06.30-linux-x64-64bit.tar.gz}"

VPNDIR="/usr/local/vpnclient"
DEVICE="vpn_$VPN_NIC"

die() { echo "vpn: $*" >&2; exit 1; }

# --- prompt helper (env wins -> prompt if a TTY -> default) -----------------
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

valid_ip() {
    case "$1" in *[!0-9.]*|.*|*.|*..*) return 1 ;; esac
    _old=$IFS; IFS=.; set -- $1; IFS=$_old
    [ $# -eq 4 ] || return 1
    for _o; do [ "$_o" -ge 0 ] 2>/dev/null && [ "$_o" -le 255 ] || return 1; done
}

# --- preconditions ----------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "needs root. Re-run with sudo -E (so BAY_VPN_TOKEN passes through)."
command -v apt-get >/dev/null 2>&1 || die "targets Debian/Ubuntu (apt-get not found)."
[ "$(uname -m)" = "x86_64" ] || die "SoftEther client here is x86_64 only (this host is $(uname -m))."
[ -n "${BAY_VPN_TOKEN:-}" ] || die "BAY_VPN_TOKEN is required (read-only token for $BAY_VPN_REPO). It is a secret — pass it via the environment, never hardcode it."

ask VPN_CLIENT_IP "VPN Client IP" ""
[ -n "$VPN_CLIENT_IP" ] || die "VPN_CLIENT_IP is required (e.g. 10.10.1.173)."
valid_ip "$VPN_CLIENT_IP" || die "VPN_CLIENT_IP '$VPN_CLIENT_IP' is not a valid IPv4 address."
MAPPED_IP="$VPN_MAP_PREFIX.${VPN_CLIENT_IP##*.}"
echo "==> vpn: $VPN_CLIENT_IP -> assigning $MAPPED_IP/$VPN_NETMASK on $DEVICE"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- 1. dependencies --------------------------------------------------------
echo "==> vpn: installing build dependencies"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y build-essential net-tools iproute2 curl >/dev/null

# --- 2. SoftEther client (skip if already built) ----------------------------
if [ -x "$VPNDIR/vpnclient" ]; then
    echo "==> vpn: SoftEther already installed at $VPNDIR, skipping build"
else
    echo "==> vpn: downloading SoftEther client"
    curl -fsSL -o "$WORK/softether.tar.gz" "$SOFTETHER_URL"
    echo "==> vpn: compiling"
    tar xzf "$WORK/softether.tar.gz" -C "$WORK"
    # the tarball extracts to vpnclient/; its make asks 3 license questions.
    ( cd "$WORK/vpnclient" && printf '1\n1\n1\n' | make >/dev/null )
    echo "==> vpn: installing to $VPNDIR"
    rm -rf "$VPNDIR"
    mv "$WORK/vpnclient" "$VPNDIR"
    chmod 600 "$VPNDIR"/* 2>/dev/null || true
    chmod 700 "$VPNDIR/vpnclient" "$VPNDIR/vpncmd" 2>/dev/null || true
fi

# --- 3. start the daemon ----------------------------------------------------
echo "==> vpn: starting client daemon"
"$VPNDIR/vpnclient" start >/dev/null 2>&1 || true
sleep 2
VPNCMD="$VPNDIR/vpncmd /CLIENT localhost /CMD"

# --- 4. virtual NIC (idempotent) --------------------------------------------
if $VPNCMD NicList 2>/dev/null | grep -qi "vpn_$VPN_NIC\|Adapter Name *|$VPN_NIC"; then
    echo "==> vpn: NIC $VPN_NIC already exists"
else
    echo "==> vpn: creating NIC $VPN_NIC"
    $VPNCMD NicCreate "$VPN_NIC" >/dev/null 2>&1 || true
fi

# --- 5. fetch + import accounts (secret .vpn from the private repo) ----------
for acct in $VPN_ACCOUNTS; do
    echo "==> vpn: fetching $acct from $BAY_VPN_REPO"
    curl -fsSL \
        -H "Authorization: Bearer $BAY_VPN_TOKEN" \
        -H "Accept: application/vnd.github.raw" \
        "https://api.github.com/repos/$BAY_VPN_REPO/contents/$acct?ref=$BAY_VPN_REF" \
        -o "$WORK/$acct" || die "could not fetch $acct (check BAY_VPN_TOKEN / BAY_VPN_REPO)."
    name="${acct%.vpn}"
    echo "==> vpn: importing account $name"
    $VPNCMD AccountDelete "$name" >/dev/null 2>&1 || true   # replace on re-run
    $VPNCMD AccountImport "$WORK/$acct" >/dev/null 2>&1 \
        || echo "    (import of $acct reported an issue — may already exist)"
done

# --- 6. auto-connect on daemon start ----------------------------------------
echo "==> vpn: setting $VPN_CONNECT to auto-connect"
$VPNCMD AccountStartupSet "$VPN_CONNECT" >/dev/null 2>&1 || true
$VPNCMD AccountConnect "$VPN_CONNECT" >/dev/null 2>&1 || true

# --- 7. boot script (IP baked in) -------------------------------------------
echo "==> vpn: writing /usr/local/bin/start-softether.sh"
cat > /usr/local/bin/start-softether.sh <<EOF
#!/bin/sh
# Generated by BayInit vpn recipe. Regenerated on each install.
set -eu
$VPNDIR/vpnclient start
sleep 5
$VPNDIR/vpncmd /CLIENT localhost /CMD AccountConnect $VPN_CONNECT
until ip link show $DEVICE >/dev/null 2>&1; do sleep 1; done
ip addr flush dev $DEVICE
ip addr add $MAPPED_IP/$VPN_NETMASK dev $DEVICE
EOF
chmod +x /usr/local/bin/start-softether.sh

# --- 8. systemd unit --------------------------------------------------------
echo "==> vpn: writing systemd unit softether-auto.service"
cat > /etc/systemd/system/softether-auto.service <<'EOF'
[Unit]
Description=SoftEther Auto Connect
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/start-softether.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# --- 9. enable + start ------------------------------------------------------
echo "==> vpn: enabling service"
systemctl daemon-reload
systemctl enable softether-auto >/dev/null 2>&1 || true
systemctl restart softether-auto

echo "==> vpn: done. $DEVICE should get $MAPPED_IP/$VPN_NETMASK; survives reboot."
