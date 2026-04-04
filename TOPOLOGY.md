<!-- SPDX-License-Identifier: MPL-2.0 -->
<!-- (PMPL-1.0-or-later preferred; MPL-2.0 required for browser extension stores) -->
<!-- Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk> -->

# TOPOLOGY.md — groove-browser-harness

## Purpose

Type-safe localhost service discovery for Groove-aware systems (Gossamer, Burble, Vext, etc.). Browser extension that discovers local services and bridges their Groove-protocol capabilities to the web UI, enabling seamless client-service integration.

## Module Map

```
groove-browser-harness/
├── manifest.json              # Firefox/Chrome extension manifest
├── src/
│   ├── discovery.ts           # Localhost service scanning
│   ├── groove_client.ts       # Groove protocol client
│   ├── bridge.ts              # Web UI ↔ Service bridge
│   └── types.ts               # TypeScript types for Groove
├── test/
│   └── ... (integration tests)
└── README.adoc                # Extension documentation
```

## Data Flow

```
[Localhost] ◄──► [Discovery] ──► [Groove Client] ──► [Bridge] ──► [Web UI]
                                        ↓
                                  [Service Capabilities]
```

## Key Invariants

- Type-safe Groove protocol implementation
- Discovers services on standard ports and custom configurations
- Isolates browser security context from local service calls
- Works with Firefox and Chrome (MV3 compatible)
