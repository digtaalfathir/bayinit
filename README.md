# BayInit

> **Initialize anything. Instantly.**

One command turns a fresh Linux machine into a fully set-up one — no tools to
install first, no agent, no backend:

```sh
curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/kiosk.sh | sh
```

## Philosophy

BayInit is a set of **recipes**. A recipe is a single POSIX shell script that
performs one repeatable setup procedure (a kiosk, a dev box, …) by pulling and
wiring up repos you already own. The recipe *is* the documentation — reading it
tells you exactly what the machine will become.

- **Thin & lazy.** Pure shell. No framework. This is not Ansible.
- **Idempotent.** Every recipe is safe to run again; it checks state before changing it.
- **Static hosting.** Served straight from GitHub Pages — nothing to run server-side.
- **Transparent.** Every step echoes what it does, and you can read the whole
  script before running it (see below).

## Quick start

| Recipe | What it does | Command |
|--------|--------------|---------|
| **kiosk** | Fullscreen Chrome/Chromium kiosk that autostarts on login | `curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/kiosk.sh \| sh` |
| **chrome** | Install Google Chrome (Debian/Ubuntu, x86_64) | `curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/chrome.sh \| sudo sh` |
| **nodejs** | Install Node.js from NodeSource (default v22) | `curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/nodejs.sh \| sudo sh` |
| **pm2** | Install PM2 + resurrect-on-boot | `curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/pm2.sh \| sudo sh` |
| **openssh** | Install and enable the SSH server | `curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/openssh.sh \| sudo sh` |
| **vpn** | SoftEther client + auto-connect *(needs private repo + token)* | `BAY_VPN_TOKEN=… VPN_CLIENT_IP=10.10.1.173 curl -fsSL …/recipes/vpn.sh \| sudo -E sh` |
| **dcs-prep** | Prepare a machine for DCS work *(work in progress)* | `curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/dcs-prep.sh \| sh` |

The `kiosk` recipe takes optional overrides via environment variables:

```sh
KIOSK_URL=https://example.com KIOSK_WAIT=3 \
  curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/kiosk.sh | sh
```

## Inspect before you run

**Never pipe a script into your shell without reading it first.** Every recipe
is plain text — open it, or pipe it to a pager instead of `sh`:

```sh
# read in the terminal
curl -fsSL https://digtaalfathir.github.io/bayinit/recipes/kiosk.sh | less
```

Or read the raw source of any recipe in a browser — they all live at the same
path: `https://raw.githubusercontent.com/digtaalfathir/bayinit/main/recipes/<name>.sh`

## Pin a version

`main` moves. For anything you depend on, pin to a git tag so you get the exact
same script every time. Curl the **raw** URL at a tag instead of the Pages URL:

```sh
# always the v1.0 script, forever
curl -fsSL https://raw.githubusercontent.com/digtaalfathir/bayinit/v1.0/recipes/kiosk.sh | sh
```

Tags are cut per release (`v1.0`, `v1.1`, …). The Pages URLs above always track
`main` (latest) — use them for convenience, use a pinned tag for production.

## Recipes

| Recipe | Root? | Target OS | Status |
|--------|-------|-----------|--------|
| `kiosk` | no | Linux + desktop session | ready |
| `chrome` | yes | Debian/Ubuntu, x86_64 | ready |
| `nodejs` | yes | Debian/Ubuntu | ready |
| `pm2` | yes | Debian/Ubuntu + systemd | ready |
| `openssh` | yes | Debian/Ubuntu + systemd | ready |
| `vpn` | yes | Debian/Ubuntu/Zorin + systemd, x86_64 | ready — needs private `.vpn` repo + token |
| `dcs-prep` | TBD | Linux | skeleton — see `TODO(rifky)` markers |

## Profiles

A **profile** bundles several recipes into one deployment — run one command,
get a fully configured machine. Profiles live in `profiles/` and are just
recipes run in the right order (using `sudo` for the ones that need root).

| Profile | Bundles | Command |
|---------|---------|---------|
| **monitoring-tablet** | chrome + kiosk | `curl -fsSL https://digtaalfathir.github.io/bayinit/profiles/monitoring-tablet.sh \| sh` |

Env vars flow through to the recipes — point the tablet at your dashboard:

```sh
KIOSK_URL=https://dashboard.local \
  curl -fsSL https://digtaalfathir.github.io/bayinit/profiles/monitoring-tablet.sh | sh
```

## How to add a recipe

1. Drop a new `recipes/<name>.sh`. Every recipe must:
   - start with `#!/bin/sh` and `set -eu`;
   - carry a header comment: **what** it does, whether it needs **root**, target **OS**, any **env** vars;
   - be **idempotent** — check state before changing it;
   - `echo "==> ..."` before each step so the run is transparent;
   - read secrets from the environment or a prompt — **never hardcode credentials**.
2. Add it to the table above and to `index.html`.
3. Commit, and tag a release when it's stable.

## Tech

Pure POSIX shell (`/bin/sh`), hosted statically on GitHub Pages. No build step,
no dependencies.

## License

MIT © Rifky Andigta Al-Fathir. See [LICENSE](LICENSE).
