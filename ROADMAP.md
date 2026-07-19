# BayInit Roadmap

> **Initialize anything. Instantly.**

BayInit is growing from a handful of setup scripts into a lightweight
provisioning toolkit for Linux systems. The goal stays simple:

> One command should turn a fresh machine into exactly what it needs to be.

This document tracks where the project is and where it's headed. It's a plan,
not a promise — scope and order may shift.

---

## Status at a glance

| Milestone | Focus | Status |
|-----------|-------|--------|
| [v1.0](#v10--foundation) | Foundation — static hosting, first recipes | ✅ Done |
| [v1.1](#v11--core-recipes) | Core recipes (reusable building blocks) | ✅ Done |
| [v1.2](#v12--profiles) | Profiles (bundle recipes into deployments) | 🚧 In progress |
| [v1.3](#v13--interactive-configuration) | Interactive configuration (prompt when env unset) | ✅ Done |
| [v1.4](#v14--verification) | Verification (`bay verify`) | 📋 Planned |
| [v1.5](#v15--uninstall) | Uninstall (`bay uninstall`) | 📋 Planned |
| [v2.0](#v20--bay-cli) | Bay CLI | 💡 Exploring |
| [v2.5](#v25--package-registry) | Package registry | 💡 Exploring |
| [v3.0](#v30--bayinit-center) | BayInit Center (web UI) | 💡 Exploring |

---

## Vision

BayInit is built around **repeatable provisioning**.

Instead of hand-configuring each machine, BayInit provides small, transparent,
idempotent recipes that can be combined into complete system profiles. Over
time it should become the easiest way to bootstrap targets such as:

- Industrial monitoring tablets
- Kiosk systems
- Developer workstations
- Printer servers
- IoT gateways
- Camera servers
- RFID stations
- Factory edge devices

---

## Principles

Every addition to BayInit follows these principles:

- **POSIX shell only** — no external framework
- **One job per recipe** — small, composable, does exactly one thing
- **Configurable** — sensible defaults, overridable at runtime; never hardcode machine-specific values
- **Idempotent** — safe to run again
- **Transparent** — every step echoes what it does; the script is the documentation
- **Public & auditable** — anyone can read a recipe before running it, and no secret ever lives inside one
- **Easy to debug and extend**

---

## Modular by design

A recipe should never be locked to a single machine. Every tunable value
follows the same pattern:

> **environment variable → sensible default → (later) interactive prompt when unset**

`curl | sh` with no arguments still works — it just uses the defaults. To adapt
a recipe to your machine, override the values:

```sh
KIOSK_URL=https://dashboard.local KIOSK_WAIT=3 \
  curl -fsSL .../kiosk.sh | sh
```

Every new recipe ships configurable from day one (see [v1.1](#v11--core-recipes));
the interactive-prompt fallback landed in [v1.3](#v13--interactive-configuration).

---

## Security model

BayInit recipes are **public and auditable by design** — no login, no gated
download. That is the point: you can read exactly what will run on your machine
before it runs.

This works because a recipe carries **logic, never secrets**:

- The **script** is generic — *how* to set up a VPN, a kiosk, a printer.
- The **sensitive values** — keys, credentials, internal URLs — are injected at
  runtime via environment variables (or a prompt), and never committed.

So even a company-specific recipe is safe to publish: without the injected
values it does nothing useful for anyone else.

```sh
# the script is public; the secret is not
WG_PRIVATE_KEY="$(cat ~/wg.key)" \
  curl -fsSL .../vpn.sh | sh
```

> **Rule:** if a value would be unsafe in public git history, it comes from the
> environment or a prompt — not from the script.

---

## Milestones

### v1.0 — Foundation ✅

Establish the project.

- [x] GitHub Pages hosting
- [x] README
- [x] Static recipe hosting
- [x] `curl | sh` install flow
- [x] Recipe documentation
- [x] MIT License

Current recipes:

- `kiosk` — ready
- `dcs-prep` — skeleton (see `TODO(rifky)` markers)

### v1.1 — Core recipes ✅

The core set. Each does one job and is configurable via env vars from day one
(see [Modular by design](#modular-by-design)).

- [x] `kiosk` — fullscreen dashboard kiosk (reference recipe)
- [x] `chrome` — install Google Chrome
- [x] `nodejs` — install Node.js
- [x] `pm2` — install and set up PM2
- [x] `openssh` — install / enable the SSH server
- [x] `vpn` — SoftEther client; public script, secret `.vpn` files fetched from a private repo via token (see [Security model](#security-model))

Everything else (git, docker, nginx, cups/printer, touchscreen & power tweaks,
tailscale/wireguard, …) waits in the [backlog](#recipe-backlog) until pulled in.

### v1.2 — Profiles 🚧

Profiles bundle several recipes into one deployment — run one command, get a
fully configured machine. A profile is just recipes run in order (using `sudo`
for the ones that need root); env vars flow through to them.

First profile (more slot in as device recipes land):

```
monitoring-tablet
├── chrome   → install the browser
└── kiosk    → fullscreen dashboard + autostart
```

```sh
KIOSK_URL=https://dashboard.local \
  curl -fsSL .../profiles/monitoring-tablet.sh | sh
```

Planned profiles: `monitoring-tablet`, `printer-server`, `developer-machine`,
`rfid-reader`, `camera-server`, `edge-gateway`, plus company profiles such as
`manufactura-connect` and `stechoq-ops-center-client` — public scripts whose
sensitive values are injected via env (see [Security model](#security-model)).

### v1.3 — Interactive configuration ✅

Env-var overrides exist from day one (see [Modular by design](#modular-by-design)).
This milestone adds the fallback for when a value isn't supplied: recipes prompt
for it when run interactively, and Enter accepts the default.

Resolution order per value: **env var → interactive prompt → default**. Non-
interactive runs (cron, CI, piped without a TTY) never block — they take the
defaults. Prompts read `/dev/tty`, so this works even under `curl … | sh`.

```
Dashboard URL [https://example.com]: https://dashboard.local
Startup delay in seconds [5]:
Autostart on login (1/0) [1]:
```

Applied to `kiosk`, `nodejs`, and `openssh` (the recipes with a real choice);
`chrome` and `pm2` keep unambiguous defaults.

### v1.4 — Verification 📋

Verify that a machine is configured correctly:

```sh
bay verify kiosk
```

```
chrome         ✓
autostart      ✓
rotate-screen  ✓
touchscreen    ✓
Done.
```

### v1.5 — Uninstall 📋

Every recipe should support clean removal:

```sh
bay uninstall kiosk
```

### v2.0 — Bay CLI 💡

An optional CLI. Recipes stay plain shell scripts; the CLI just finds,
downloads, and runs them.

```sh
bay search
bay install kiosk
bay list
bay update
```

### v2.5 — Package registry 💡

Let recipes be published and installed by namespace, inspired by Homebrew,
npm, and Docker Hub.

```sh
bay install rifky/kiosk
bay install stechoq/printer
bay install company/monitoring
```

### v3.0 — BayInit Center 💡

A web interface for managing deployments: install and update recipes,
configure devices, view logs, and deploy to multiple machines at once.

---

## Recipe backlog

A categorized wishlist. Recipes graduate from here into a versioned milestone
(most feed **v1.1**) once picked up.

**Desktop:** Chrome · Chromium · Firefox · VS Code · Cursor · Claude Desktop

**Development:** Node.js · Python · Docker · Git · PM2 · NVM

**Networking:** OpenSSH · WireGuard · Tailscale · VPN client · Firewall

**Industrial:** Chrome kiosk · RFID bridge · Camera AO · Camera QI · Printer
server · Monitoring dashboard · Edge gateway

**System:** Rotate touchscreen · Disable sleep · Disable lock screen · Disable
screen blank · Timezone · Locale · Hostname · Static IP

---

## Target architecture

```
┌─────────────────────────────────────┐
│           BayInit Center             │  GUI + device management
├─────────────────────────────────────┤
│              Bay CLI                 │  search / install / update
├─────────────────────────────────────┤
│              Recipes                 │  chrome · node · pm2 · kiosk · …
├─────────────────────────────────────┤
│            Linux machine             │
└─────────────────────────────────────┘
```

Each layer is optional: the recipes work on their own via `curl | sh`, the CLI
is a convenience on top, and the Center is a management layer on top of that.

---

## Non-goals

BayInit is **not** trying to replace:

- Ansible · Puppet · Chef · Salt · Kubernetes

It intentionally stays lightweight, script-based, human-readable, and easy to
audit, copy, and modify.

---

## Contributing

New recipes are welcome. See the **How to add a recipe** section in the
[README](README.md) for the required conventions (header comment, `set -eu`,
idempotency, transparent output, no hardcoded secrets).

---

## Philosophy

> Small recipes. Simple scripts. Predictable machines. Zero magic.
