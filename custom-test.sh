#!/usr/bin/env bash
set -euo pipefail

MODEL="${MODEL:-opus}"
MAX_CONCURRENT="${MAX_CONCURRENT:-1}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="logs/pipeline/partial-route-soft-budget-replay-${STAMP}/generate-architecture"

uv run main.py pipeline \
  --platform rhoai.next \
  --phase static-analysis \
  --phase generate-architecture \
  --component notebooks-downstream \
  --component odh-gitops \
  --component pipelines-components \
  --component modelmesh \
  --force \
  --max-concurrent "${MAX_CONCURRENT}" \
  --model "${MODEL}" \
  --log-dir "${LOG_DIR}"
