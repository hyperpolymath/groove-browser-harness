// SPDX-License-Identifier: MPL-2.0
// (PMPL-1.0-or-later preferred; MPL-2.0 required for browser extension stores)
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// Groove Discovery — Background script for the Groove Browser Harness.
//
// Probes well-known localhost ports for groove-aware services and maintains
// a live registry of available capabilities. Any web page (with appropriate
// permissions) can query the extension for available grooves.
//
// Design: stateless-resumable pattern (works with both Firefox persistent
// background and Chrome MV3 service worker lifecycle).
//
// The groove connectors are formally verified in Gossamer's Groove.idr:
// - CapabilityType proves what each service offers
// - IsSubset proves consumers can only connect if capabilities match
// - GrooveHandle is linear — connections are properly lifecycle-managed

// Well-known groove targets matching Groove.idr and groove.zig.
const GROOVE_TARGETS = [
  { id: 0, name: "burble",          port: 6473 },
  { id: 1, name: "vext",            port: 6480 },
  { id: 2, name: "verisimdb",       port: 8080 },
  { id: 3, name: "hypatia",         port: 9090 },
  { id: 4, name: "panll",           port: 8000 },
  { id: 5, name: "echidna",         port: 9000 },
  { id: 6, name: "rpa-elysium",     port: 7800 },
  { id: 7, name: "conflow",         port: 7700 },
  { id: 8, name: "panic-attacker",  port: 7600 },
  { id: 9, name: "gitbot-fleet",    port: 7500 },
];

// Probe interval (60 seconds).
const PROBE_INTERVAL_MS = 60_000;

// Connection timeout for probes (2 seconds).
const PROBE_TIMEOUT_MS = 2_000;

// Current groove registry — populated by discovery.
// Stored in browser.storage.local for persistence across service worker restarts.
let grooveRegistry = new Map();

// ============================================================================
// Discovery
// ============================================================================

/**
 * Probe a single groove target by fetching GET /.well-known/groove.
 * Returns the parsed manifest on success, null on failure.
 *
 * @param {Object} target - { id, name, port }
 * @returns {Promise<Object|null>} Parsed manifest or null
 */
async function probeTarget(target) {
  const url = `http://127.0.0.1:${target.port}/.well-known/groove`;
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), PROBE_TIMEOUT_MS);

  try {
    const response = await fetch(url, {
      method: "GET",
      headers: { "Accept": "application/json" },
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    if (!response.ok) return null;

    const manifest = await response.json();

    // Validate required groove fields.
    if (!manifest.groove_version || !manifest.service_id || !manifest.capabilities) {
      console.warn(`Groove: ${target.name} returned invalid manifest`);
      return null;
    }

    return manifest;
  } catch {
    clearTimeout(timeoutId);
    return null;
  }
}

/**
 * Discover all groove targets by probing well-known ports.
 * Updates the registry and persists to storage.
 *
 * @returns {Promise<number>} Number of connected grooves
 */
async function discoverAll() {
  const results = await Promise.allSettled(
    GROOVE_TARGETS.map(async (target) => {
      const manifest = await probeTarget(target);
      return { target, manifest };
    })
  );

  let connected = 0;
  const registry = {};

  for (const result of results) {
    if (result.status !== "fulfilled") continue;
    const { target, manifest } = result.value;

    if (manifest) {
      registry[target.name] = {
        id: target.id,
        name: target.name,
        port: target.port,
        status: "connected",
        serviceId: manifest.service_id,
        version: manifest.service_version || "unknown",
        capabilities: Object.keys(manifest.capabilities || {}),
        consumes: manifest.consumes || [],
        endpoints: manifest.endpoints || {},
        lastProbe: new Date().toISOString(),
      };
      connected++;
    } else {
      registry[target.name] = {
        id: target.id,
        name: target.name,
        port: target.port,
        status: "not_found",
        capabilities: [],
        consumes: [],
        lastProbe: new Date().toISOString(),
      };
    }
  }

  // Persist to storage (survives service worker restart).
  grooveRegistry = new Map(Object.entries(registry));
  await browser.storage.local.set({ grooveRegistry: registry });

  console.log(`Groove: discovered ${connected}/${GROOVE_TARGETS.length} services`);
  return connected;
}

// ============================================================================
// Message API
// ============================================================================

/**
 * Send a JSON message to a grooved service.
 *
 * @param {string} serviceName - Target service name (e.g. "burble")
 * @param {Object} message - JSON payload to send
 * @returns {Promise<Object>} Response from the service
 */
async function sendToGroove(serviceName, message) {
  const entry = grooveRegistry.get(serviceName);
  if (!entry || entry.status !== "connected") {
    return { ok: false, error: `${serviceName} not connected` };
  }

  const url = `http://127.0.0.1:${entry.port}/.well-known/groove/message`;
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(message),
    });
    return await response.json();
  } catch (err) {
    return { ok: false, error: err.message };
  }
}

/**
 * Receive pending messages from a grooved service.
 *
 * @param {string} serviceName - Target service name
 * @returns {Promise<Array>} Array of pending messages
 */
async function recvFromGroove(serviceName) {
  const entry = grooveRegistry.get(serviceName);
  if (!entry || entry.status !== "connected") {
    return [];
  }

  const url = `http://127.0.0.1:${entry.port}/.well-known/groove/recv`;
  try {
    const response = await fetch(url, {
      method: "GET",
      headers: { "Accept": "application/json" },
    });
    return await response.json();
  } catch {
    return [];
  }
}

/**
 * Find which groove service provides a given capability.
 *
 * @param {string} capabilityName - Capability type (e.g. "voice", "integrity")
 * @returns {Object|null} The registry entry, or null
 */
function findCapability(capabilityName) {
  for (const [, entry] of grooveRegistry) {
    if (entry.status === "connected" && entry.capabilities.includes(capabilityName)) {
      return entry;
    }
  }
  return null;
}

// ============================================================================
// Extension message handler
// ============================================================================

browser.runtime.onMessage.addListener((message, _sender) => {
  switch (message.type) {
    case "groove:discover":
      return discoverAll().then((count) => ({ connected: count }));

    case "groove:status":
      return Promise.resolve(Object.fromEntries(grooveRegistry));

    case "groove:send":
      return sendToGroove(message.service, message.payload);

    case "groove:recv":
      return recvFromGroove(message.service);

    case "groove:find-capability":
      return Promise.resolve(findCapability(message.capability));

    case "groove:summary":
      return browser.storage.local.get("grooveRegistry").then((data) => {
        return data.grooveRegistry || {};
      });

    default:
      return Promise.resolve({ error: "unknown message type" });
  }
});

// ============================================================================
// Lifecycle
// ============================================================================

// Discover on startup.
discoverAll();

// Re-probe periodically.
setInterval(discoverAll, PROBE_INTERVAL_MS);

// Also re-probe when the extension is woken (MV3 pattern).
browser.runtime.onStartup?.addListener(discoverAll);
browser.runtime.onInstalled?.addListener(discoverAll);

console.log("Groove Harness: background script loaded");
