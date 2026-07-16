#!/bin/sh
# ============================================================================
# BayInit recipe: dcs-prep
# ----------------------------------------------------------------------------
# What : Prepare a machine for DCS work.
#        TODO(rifky): one-line description of what "DCS prep" sets up.
# Root : TODO(rifky): does this need root? Uncomment the check below if so.
# OS   : Linux
# Env  : TODO(rifky): list env vars / secrets here. Read them from the
#        environment or prompt — never hardcode credentials.
# Usage: curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/dcs-prep.sh | sh
# ============================================================================
set -eu

# --- root check (uncomment if dcs-prep must run as root) --------------------
# TODO(rifky): keep only if this recipe needs root.
# if [ "$(id -u)" -ne 0 ]; then
#     echo "dcs-prep needs root. Re-run with sudo:" >&2
#     echo "  curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/dcs-prep.sh | sudo sh" >&2
#     exit 1
# fi

echo "==> dcs-prep: starting"

# TODO(rifky): fill in the real steps. Keep each one idempotent — check state
# before changing it, so re-running is a no-op. Pattern:
#
#   if ! command -v foo >/dev/null 2>&1; then
#       echo "==> dcs-prep: installing foo"
#       sudo apt-get install -y foo
#   else
#       echo "==> dcs-prep: foo already present, skipping"
#   fi
#
# TODO(rifky): step 1 — clone/pull the DCS repo(s)
# TODO(rifky): step 2 — install dependencies
# TODO(rifky): step 3 — configure services

echo "==> dcs-prep: skeleton only — no steps defined yet."
echo "    Edit recipes/dcs-prep.sh and replace the TODO(rifky) markers."
