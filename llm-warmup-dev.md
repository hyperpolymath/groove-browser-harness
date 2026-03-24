# Groove Browser Harness — LLM Context (Developer)

## Identity

Groove Browser Harness — Firefox extension for localhost service discovery
using the Groove protocol. License: MPL-2.0 (browser store requirement;
PMPL-1.0-or-later preferred). Author: Jonathan D.A. Jewell.

## Architecture

Pure JavaScript Firefox extension. No build step. Manifest V2 (with
MV3 compatibility patterns).

```
Background Script (groove-discovery.js)
  ├── Probes 10 well-known localhost ports
  ├── Maintains grooveRegistry (Map + browser.storage.local)
  ├── Handles message API (groove:discover, groove:status, etc.)
  └── Re-probes every 60s + on startup/install

Content Script (groove-bridge.js)
  ├── Injects window.groove API via <script> element
  ├── Bridges page ↔ extension via CustomEvent
  └── groove:request / groove:response event pairs

Popup (popup.html + popup.js)
  ├── Status dashboard showing all 10 targets
  ├── Connected (green) / not_found (grey) indicators
  └── "Probe All" button for manual re-scan
```

## Groove Protocol

Each target serves `GET /.well-known/groove` returning:

```json
{
  "groove_version": "1.0",
  "service_id": "burble",
  "service_version": "0.1.0",
  "capabilities": { "voice": true, "audio": true },
  "consumes": ["integrity"],
  "endpoints": { "message": "/.well-known/groove/message" }
}
```

Required fields: groove_version, service_id, capabilities.
Message endpoint: POST /.well-known/groove/message (JSON).
Receive endpoint: GET /.well-known/groove/recv (JSON array).

## Groove Targets

Hardcoded in GROOVE_TARGETS array (matches Groove.idr + groove.zig):

| ID | Name | Port |
|----|------|------|
| 0 | burble | 6473 |
| 1 | vext | 6480 |
| 2 | verisimdb | 8080 |
| 3 | hypatia | 9090 |
| 4 | panll | 8000 |
| 5 | echidna | 9000 |
| 6 | rpa-elysium | 7800 |
| 7 | conflow | 7700 |
| 8 | panic-attacker | 7600 |
| 9 | gitbot-fleet | 7500 |

## Message API (extension internal)

Content script and popup communicate with background via
`browser.runtime.sendMessage`:

| Type | Direction | Purpose |
|------|-----------|---------|
| `groove:discover` | -> background | Trigger full re-probe |
| `groove:status` | -> background | Get registry Map |
| `groove:send` | -> background | POST to service |
| `groove:recv` | -> background | GET from service |
| `groove:find-capability` | -> background | Search by capability |
| `groove:summary` | -> background | Get from storage |

## Page API (injected)

`window.groove` object injected by content script. Uses CustomEvent
bridge (groove:request / groove:response) with request IDs and 5s timeout.

Methods: discover(), status(), findCapability(cap), send(svc, payload),
recv(svc), summary().

Event: `groove:ready` fired when API is available.

## Security

- Only localhost/127.0.0.1 on specific ports (host_permissions)
- XSS protection: escapeHtml() in popup rendering
- No arbitrary HTTP — only groove protocol messages relayed
- Probe timeout: 2 seconds per target
- Content script uses CustomEvent bridge (no direct page access)

## MV2/MV3 Compatibility

- Uses `browser.runtime.onStartup?.addListener` (optional chaining)
- `browser.runtime.onInstalled?.addListener`
- Background declared as `"type": "module"` (MV3-ready)
- Stateless-resumable pattern (works with service worker lifecycle)
- Registry persisted to browser.storage.local

## Permissions

```json
"permissions": ["storage"],
"host_permissions": ["http://localhost:PORT/*", "http://127.0.0.1:PORT/*"]
```

Ports: 6473, 6480, 7500, 7600, 7700, 7800, 8000, 8080, 9000, 9090.

## Gecko Settings

- Extension ID: groove-harness@hyperpolymath.com
- Minimum Firefox: 109.0

## Formal Verification Link

The groove connectors are formally verified in Gossamer's Groove.idr:
- CapabilityType proves what each service offers
- IsSubset proves consumers can only connect if capabilities match
- GrooveHandle is linear — connections are lifecycle-managed

This extension is the browser-side implementation of those same targets.

## Commands

```bash
just run          # Launch Firefox with extension (web-ext)
just package      # Build .xpi for distribution
just lint         # Lint manifest + source
just doctor       # Check prerequisites
just heal         # Install missing tools
just tour         # Guided codebase walkthrough
just help-me      # Troubleshooting guide
```

## File Map

| Path | What |
|------|------|
| `manifest.json` | Extension manifest (MV2 + gecko settings) |
| `background/groove-discovery.js` | Discovery engine, registry, message handler |
| `content/groove-bridge.js` | Page API injection via CustomEvent bridge |
| `popup/popup.html` | Popup UI (dashboard) |
| `popup/popup.js` | Popup rendering + probe button |
| `icons/` | Extension icons (48px, 96px) |
