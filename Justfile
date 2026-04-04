# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for browser extension stores)
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
#
# Justfile — Groove Browser Harness (Firefox extension)
# Run with: just <recipe>

set shell := ["bash", "-euo", "pipefail", "-c"]

# Default recipe: show help
default:
    @just --list

# ── Run ──────────────────────────────────────────────────────

# Launch Firefox with extension loaded (auto-reload on changes)
run:
    web-ext run --source-dir . --firefox firefox

# Launch with a specific Firefox binary
run-with binary:
    web-ext run --source-dir . --firefox {{binary}}

# ── Package ──────────────────────────────────────────────────

# Build .xpi package for distribution
package:
    web-ext build --source-dir . --overwrite-dest
    @echo "Package built in web-ext-artifacts/"

# Lint the extension manifest and source
lint:
    web-ext lint --source-dir .

# ── Security ─────────────────────────────────────────────────

# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"

# ── Onboarding ───────────────────────────────────────────────

# Check all required tools are installed
doctor:
    #!/usr/bin/env bash
    set -euo pipefail
    ok=0; fail=0
    check() {
        if "$@" >/dev/null 2>&1; then
            echo "  [ok] $1"
            ((ok++))
        else
            echo "  [MISSING] $1 — $2"
            ((fail++))
        fi
    }
    echo "=== Groove Browser Harness Doctor ==="
    check firefox --version "sudo dnf install firefox"
    check just --version "cargo install just"
    echo ""
    echo "--- Optional (dev workflow) ---"
    if command -v web-ext >/dev/null 2>&1; then
        echo "  [ok] web-ext ($(web-ext --version 2>&1 | head -1))"
        ((ok++))
    else
        echo "  [MISSING] web-ext — deno install -g npm:web-ext"
        ((fail++))
    fi
    echo ""
    echo "--- Extension files ---"
    if [ -f "manifest.json" ]; then
        echo "  [ok] manifest.json"
        ((ok++))
    else
        echo "  [MISSING] manifest.json — not in expected location"
        ((fail++))
    fi
    if [ -f "background/groove-discovery.js" ]; then
        echo "  [ok] background/groove-discovery.js"
        ((ok++))
    else
        echo "  [MISSING] background/groove-discovery.js"
        ((fail++))
    fi
    if [ -f "popup/popup.html" ]; then
        echo "  [ok] popup/popup.html"
        ((ok++))
    else
        echo "  [MISSING] popup/popup.html"
        ((fail++))
    fi
    if [ -f "content/groove-bridge.js" ]; then
        echo "  [ok] content/groove-bridge.js"
        ((ok++))
    else
        echo "  [MISSING] content/groove-bridge.js"
        ((fail++))
    fi
    echo ""
    echo "Result: $ok passed, $fail failed"
    if [ "$fail" -gt 0 ]; then
        echo "Fix the MISSING items above, then re-run: just doctor"
        exit 1
    else
        echo "All prerequisites satisfied."
    fi

# Auto-install missing tools where possible
heal:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Groove Browser Harness Heal ==="
    if ! command -v firefox &>/dev/null; then
        echo "Firefox missing — run: sudo dnf install firefox"
    fi
    if ! command -v web-ext &>/dev/null; then
        echo "Installing web-ext..."
        if command -v deno &>/dev/null; then
            deno install -g npm:web-ext || echo "Try: npm install -g web-ext"
        elif command -v npm &>/dev/null; then
            npm install -g web-ext
        else
            echo "Install web-ext manually: https://github.com/mozilla/web-ext"
        fi
    fi
    echo ""
    echo "Re-run 'just doctor' to verify."

# Guided tour of the codebase
tour:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Groove Browser Harness Tour ==="
    echo ""
    echo "1. WHAT IS IT?"
    echo "   Firefox extension that discovers localhost services using"
    echo "   the Groove protocol. Probes well-known ports and exposes"
    echo "   capabilities to web pages via window.groove."
    echo ""
    echo "2. STRUCTURE"
    echo "   manifest.json                 Extension manifest (MV2)"
    echo "   background/groove-discovery.js  Service discovery engine"
    echo "   content/groove-bridge.js        Injects window.groove API"
    echo "   popup/popup.html + popup.js     Extension popup UI"
    echo ""
    echo "3. GROOVE TARGETS (10 services)"
    echo "   burble:6473  vext:6480  verisimdb:8080  hypatia:9090"
    echo "   panll:8000   echidna:9000  rpa-elysium:7800"
    echo "   conflow:7700  panic-attacker:7600  gitbot-fleet:7500"
    echo ""
    echo "4. HOW DISCOVERY WORKS"
    echo "   Every 60s, probes GET /.well-known/groove on each port."
    echo "   Valid JSON manifest = connected. Otherwise = not_found."
    echo "   Registry persisted to browser.storage.local."
    echo ""
    echo "5. PAGE API"
    echo "   window.groove.discover()       Re-probe all targets"
    echo "   window.groove.status()         Get registry"
    echo "   window.groove.findCapability() Find by capability"
    echo "   window.groove.send(svc, msg)   Send to service"
    echo "   window.groove.recv(svc)        Receive from service"
    echo ""
    echo "6. SECURITY"
    echo "   Only localhost/127.0.0.1 on specific ports."
    echo "   No data leaves your machine."
    echo "   XSS protection via escapeHtml in popup."
    echo ""
    echo "7. LICENSE"
    echo "   MPL-2.0 (required for browser extension stores)."
    echo "   PMPL-1.0-or-later preferred."

# What to do when things go wrong
help-me:
    #!/usr/bin/env bash
    echo "=== Groove Browser Harness Help ==="
    echo ""
    echo "LOADING THE EXTENSION:"
    echo "  1. Open Firefox -> about:debugging#/runtime/this-firefox"
    echo "  2. Click 'Load Temporary Add-on'"
    echo "  3. Select manifest.json from this directory"
    echo "  OR: just run (uses web-ext, auto-reloads)"
    echo ""
    echo "NO SERVICES SHOWING:"
    echo "  Services must be running on their assigned ports AND"
    echo "  serve GET /.well-known/groove with a valid JSON manifest."
    echo "  Example: curl http://localhost:8080/.well-known/groove"
    echo ""
    echo "EXTENSION NOT LOADING:"
    echo "  Check manifest.json is valid JSON"
    echo "  Check Firefox version >= 109"
    echo "  Check about:debugging for error messages"
    echo ""
    echo "WEB-EXT ISSUES:"
    echo "  'command not found' -> just heal"
    echo "  'Firefox not found' -> just run-with /path/to/firefox"
    echo ""
    echo "STILL STUCK?"
    echo "  1. just doctor   (check prerequisites)"
    echo "  2. just heal     (install web-ext)"
    echo "  3. Check Firefox console (Ctrl+Shift+J) for errors"


# Print the current CRG grade (reads from READINESS.md '**Current Grade:** X' line)
crg-grade:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    echo "$$grade"

# Generate a shields.io badge markdown for the current CRG grade
# Looks for '**Current Grade:** X' in READINESS.md; falls back to X
crg-badge:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    case "$$grade" in \
      A) color="brightgreen" ;; B) color="green" ;; C) color="yellow" ;; \
      D) color="orange" ;; E) color="red" ;; F) color="critical" ;; \
      *) color="lightgrey" ;; esac; \
    echo "[![CRG $$grade](https://img.shields.io/badge/CRG-$$grade-$$color?style=flat-square)](https://github.com/hyperpolymath/standards/tree/main/component-readiness-grades)"
