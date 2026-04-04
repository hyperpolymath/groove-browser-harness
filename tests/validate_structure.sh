#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# validate_structure.sh — CRG C structural tests for groove-browser-harness
#
# Verifies the browser extension has the required structure for a
# valid Manifest V3 extension before publishing.
#
# Usage: bash tests/validate_structure.sh [repo-root]

set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
PASS=0; FAIL=0

check() {
    local desc="$1"; local path="$2"
    if [ -e "$ROOT/$path" ]; then
        echo "  PASS: $desc"
        ((PASS++)) || true
    else
        echo "  FAIL: $desc — missing $path"
        ((FAIL++)) || true
    fi
}

echo "=== groove-browser-harness structure validation ==="
echo ""

# Required extension files
check "manifest.json present"       "manifest.json"
check "background/ directory"       "background"
check "content/ directory"          "content"
check "icons/ directory"            "icons"

# RSR required files
check "EXPLAINME.adoc"              "EXPLAINME.adoc"
check "0-AI-MANIFEST.a2ml"         "0-AI-MANIFEST.a2ml"
check "Justfile"                    "Justfile"

# Validate manifest.json is valid JSON
if [ -f "$ROOT/manifest.json" ]; then
    if command -v python3 >/dev/null 2>&1; then
        python3 -m json.tool "$ROOT/manifest.json" >/dev/null 2>&1 \
            && echo "  PASS: manifest.json is valid JSON" && ((PASS++)) || true \
            || { echo "  FAIL: manifest.json invalid JSON"; ((FAIL++)) || true; }
    fi
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
