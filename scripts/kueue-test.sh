#!/usr/bin/env bash
# Quick smoke test: fetch kueue-operator via glob branch resolution,
# discover components, and run static analysis.
#
# Usage:
#   scripts/kueue-test.sh [PLATFORM]
#
# PLATFORM defaults to rhoai-3.6-ea.1 (the current EA release).

set -euo pipefail

PLATFORM="${1:-rhoai-3.6-ea.1}"

uv run python main.py pipeline \
    --platform "$PLATFORM" \
    --phase fetch \
    --phase discover-components \
    --phase static-analysis \
    --component kueue-operator \
    --force

echo ""
echo "Check architecture/$PLATFORM/kueue-operator/ for output."
