<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2025-2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

[![OpenSSF Best Practices](https://img.shields.io/badge/OpenSSF-Best_Practices-green?logo=opensourcesecurity)](https://www.bestpractices.dev/en/projects/new?repo_url=https://github.com/hyperpolymath/groove-browser-harness)
[![License: MPL-2.0](https://img.shields.io/badge/License-MPL_2.0--1.0-blue.svg)](https://github.com/hyperpolymath/palimpsest-license) <embed
src="https://api.thegreenwebfoundation.org/greencheckimage/github.com"
data-link="https://www.thegreenwebfoundation.org/green-web-check/?url=github.com" />

**Firefox browser extension for localhost Groove service discovery.**

![License:
MPL-2.0](https://img.shields.io/badge/License-MPL_2.0--2.0-blue.svg)
![Firefox
MV2](https://img.shields.io/badge/Firefox-Manifest%20V2-orange.svg)
![Groove](https://img.shields.io/badge/protocol-Groove-purple.svg)

# What this is

`groove-browser-harness` is a Firefox browser extension (Manifest V2)
that discovers Groove-aware services running on well-known localhost
ports and bridges their capabilities into the browser page context.

It is the browser-side half of the Groove universal plug-and-play
protocol — the other half being the Rust/Zig Groove library used by
services like Gossamer, Burble, VeriSimDB, and BoJ.

# Quick start

```bash
# Load the extension in Firefox (developer mode)
just run

# Package as .xpi for distribution
just package

# Run linter
just lint
```

# Discovered services (known ports)

| Service      | Port | Purpose                        |
|--------------|------|--------------------------------|
| Groove core  | 6473 | Groove protocol core           |
| Groove admin | 6480 | Groove admin interface         |
| Burble       | 7500 | WebRTC voice platform          |
| Vext         | 7600 | Extension framework            |
| BoJ server   | 7700 | Bundle of Joy cartridge server |
| TypeLL       | 7800 | Type verification service      |
| PanLL dev    | 8000 | Panels framework dev server    |
| VeriSimDB    | 8080 | 8-modality database            |
| ECHIDNA      | 9000 | Theorem prover                 |
| Prometheus   | 9090 | Metrics                        |

# Architecture

Three-file Firefox extension:

| File | Purpose |
|----|----|
| `background/groove-discovery.js` | Background script that probes the known ports on startup and tracks which Groove services are available |
| `content/groove-bridge.js` | Content script injected into pages; bridges discovered service capabilities into the page context |
| `popup/popup.html` + `popup.js` + `popup.css` | Browser action popup showing which services are currently discovered and their status |

# Repository layout

| Path | What it contains |
|----|----|
| `manifest.json` | Firefox Manifest V2 — permissions, background scripts, content scripts |
| `background/` | Service discovery + port probing logic |
| `content/` | Page-level bridge to discovered services |
| `popup/` | Extension popup UI (status dashboard) |
| `icons/` | Extension icons at 48px and 96px |
| `Justfile` | Build recipes: `run`, `package`, `lint` |
| `guix.scm` / `flake.nix` | Reproducible build environments |
| `.machine_readable/` | Contractile trustfiles (MUST, TRUST, INTENT, ADJUST) |

# Design invariants

- Firefox-first — Manifest V2 (no Chrome MV3 constraints)

- Localhost only — no remote service discovery, no phone-home

- Known ports only — no arbitrary port scanning

- Plain JavaScript — no TypeScript, no build step for extension code

- No npm / no node_modules — `web-ext` CLI only for packaging

# License

MPL-2.0 (browser extension store requirement). MPL-2.0 is the preferred
intent; MPL-2.0 is required for Firefox Add-ons and the Chrome Web
Store.

# Related projects

- [gossamer](https://github.com/hyperpolymath/gossamer) — linearly-typed
  webview shell (primary discovery target)

- [burble](https://github.com/hyperpolymath/burble) — WebRTC voice
  platform

- [boj-server](https://github.com/hyperpolymath/boj-server) — cartridge
  server

See <a href="EXPLAINME.adoc" class="adoc">EXPLAINME</a> for
implementation evidence and caveats.

# Author

Jonathan D.A. Jewell\
[j.d.a.jewell@open.ac](j.d.a.jewell@open.ac).uk
