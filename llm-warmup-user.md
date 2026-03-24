# Groove Browser Harness — LLM Context (User)

## What It Is

Firefox browser extension that discovers localhost services implementing
the Groove protocol. Probes well-known ports for services like Burble,
VeriSimDB, Hypatia, PanLL, and others. Exposes their capabilities to web
pages via `window.groove`. No data leaves your machine.

## Structure

```
manifest.json                 Firefox extension manifest (MV2)
background/groove-discovery.js  Service discovery + registry
content/groove-bridge.js        Injects window.groove API into pages
popup/popup.html + popup.js     Extension popup (status dashboard)
icons/groove-48.png, groove-96.png
```

## How It Works

1. Background script probes `GET /.well-known/groove` on 10 localhost ports
2. Valid JSON manifest = "connected", otherwise = "not_found"
3. Registry persisted to browser.storage.local
4. Re-probes every 60 seconds
5. Content script injects `window.groove` API for page access

## Groove Targets (10 services)

| Service | Port | Purpose |
|---------|------|---------|
| burble | 6473 | Voice/audio |
| vext | 6480 | Validation/linting |
| verisimdb | 8080 | Database |
| hypatia | 9090 | Security scanning |
| panll | 8000 | Panel management |
| echidna | 9000 | Formal verification |
| rpa-elysium | 7800 | Browser automation |
| conflow | 7700 | Workflow orchestration |
| panic-attacker | 7600 | Static analysis |
| gitbot-fleet | 7500 | Bot orchestration |

## Page API

```javascript
window.groove.discover()              // Re-probe all targets
window.groove.status()                // Get full registry
window.groove.findCapability("voice") // Find by capability
window.groove.send("burble", {...})   // Send message
window.groove.recv("burble")          // Receive messages
window.groove.summary()               // Registry summary
```

## Install

1. Firefox -> `about:debugging#/runtime/this-firefox`
2. "Load Temporary Add-on" -> select `manifest.json`

Or with web-ext: `just run`

## License

MPL-2.0 (required for browser extension stores).
PMPL-1.0-or-later preferred.
