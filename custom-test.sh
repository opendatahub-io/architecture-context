#!/usr/bin/env bash
set -euo pipefail

MODEL="${MODEL:-opus}"
MAX_CONCURRENT="${MAX_CONCURRENT:-1}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="logs/pipeline/partial-route-gap-replay-${STAMP}/generate-architecture"

uv run main.py pipeline \
  --platform rhoai.next \
  --phase static-analysis \
  --phase generate-architecture \
  --component models-as-a-service \
  --component llm-d-inference-scheduler \
  --component eval-hub \
  --component odh-deployer \
  --force \
  --max-concurrent "${MAX_CONCURRENT}" \
  --model "${MODEL}" \
  --log-dir "${LOG_DIR}"
