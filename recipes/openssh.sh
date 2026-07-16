#!/bin/sh
# ============================================================================
# BayInit recipe: openssh
# ----------------------------------------------------------------------------
# What : Install the OpenSSH server and enable it on boot. Optionally set a
#        custom port via a drop-in (the main sshd_config is left untouched).
#        Idempotent — safe to re-run.
# Root : REQUIRED (installs a package, manages a service).
# OS   : Debian/Ubuntu with systemd.
# Env  : SSH_PORT  listen port  (default: unset → keep sshd default, port 22)
#        Prompted for when unset and interactive (blank = keep default); set to skip.
# Usage: curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/openssh.sh | sudo sh
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

if [ "$(id -u)" -ne 0 ]; then
    echo "openssh needs root. Re-run with sudo:" >&2
    echo "  curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/openssh.sh | sudo sh" >&2
    exit 1
fi
if ! command -v apt-get >/dev/null 2>&1; then
    echo "openssh: this recipe targets Debian/Ubuntu (apt-get not found)." >&2
    exit 1
fi

ask SSH_PORT "SSH port (blank = keep default 22)" ""

if dpkg -s openssh-server >/dev/null 2>&1; then
    echo "==> openssh: openssh-server already installed"
else
    echo "==> openssh: installing openssh-server"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y openssh-server
fi

if [ -n "$SSH_PORT" ]; then
    case "$SSH_PORT" in
        *[!0-9]*) echo "openssh: SSH_PORT must be numeric (got '$SSH_PORT')" >&2; exit 1 ;;
    esac
    echo "==> openssh: setting port $SSH_PORT (drop-in)"
    mkdir -p /etc/ssh/sshd_config.d
    printf 'Port %s\n' "$SSH_PORT" > /etc/ssh/sshd_config.d/bayinit.conf
    # ponytail: on socket-activated hosts (Ubuntu 22.10+/24.04) the port also
    # lives in ssh.socket; add ssh.socket handling here if you hit that.
fi

echo "==> openssh: enabling and starting service"
if systemctl enable --now ssh 2>/dev/null; then :
elif systemctl enable --now sshd 2>/dev/null; then :
else
    echo "openssh: could not enable ssh/sshd via systemctl." >&2
    exit 1
fi

if [ -n "$SSH_PORT" ]; then
    echo "==> openssh: restarting to apply port $SSH_PORT"
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
fi

echo "==> openssh: done."
