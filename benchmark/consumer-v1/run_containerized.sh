#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="consumer-eval-harness"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run the consumer evaluation harness inside a Podman container with a clean
environment (no Claude memories, no CLAUDE.md, no host settings leakage).

Required:
  --tree-a PATH        Path to first architecture doc tree (baseline)
  --tree-b PATH        Path to second architecture doc tree (candidate)

Optional:
  --corpus PATH        Path to corpus.json (default: bundled in image)
  --model MODEL        Model shorthand: opus, sonnet, haiku (default: opus)
  --output-dir PATH    Output directory on host (default: ./results)
  --max-concurrent N   Max concurrent agent sessions (default: 1)
  --seed N             Random seed for presentation order (default: 42)
  --build              Rebuild the container image before running
  --dry-run            Print the podman command without executing
  -h, --help           Show this help message
EOF
}

TREE_A=""
TREE_B=""
CORPUS=""
MODEL="opus"
OUTPUT_DIR="$REPO_ROOT/benchmark/consumer-v1/results"
MAX_CONCURRENT=1
SEED=42
BUILD=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tree-a)    TREE_A="$2"; shift 2 ;;
        --tree-b)    TREE_B="$2"; shift 2 ;;
        --corpus)    CORPUS="$2"; shift 2 ;;
        --model)     MODEL="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        --max-concurrent) MAX_CONCURRENT="$2"; shift 2 ;;
        --seed)      SEED="$2"; shift 2 ;;
        --build)     BUILD=true; shift ;;
        --dry-run)   DRY_RUN=true; shift ;;
        -h|--help)   usage; exit 0 ;;
        *)           echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [[ -z "$TREE_A" || -z "$TREE_B" ]]; then
    echo "Error: --tree-a and --tree-b are required" >&2
    usage >&2
    exit 1
fi

TREE_A="$(cd "$TREE_A" && pwd)"
TREE_B="$(cd "$TREE_B" && pwd)"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

if $BUILD || ! podman image exists "$IMAGE_NAME" 2>/dev/null; then
    echo "Building container image: $IMAGE_NAME"
    podman build \
        -t "$IMAGE_NAME" \
        -f "$SCRIPT_DIR/Containerfile" \
        "$REPO_ROOT"
    echo
fi

ADC_PATH="${HOME}/.config/gcloud/application_default_credentials.json"
ADC_MOUNT=""
if [[ -f "$ADC_PATH" ]]; then
    ADC_MOUNT="-v ${ADC_PATH}:/home/evaluator/.config/gcloud/application_default_credentials.json:ro"
fi

ENV_ARGS=()
for var in CLAUDE_CODE_USE_VERTEX ANTHROPIC_VERTEX_PROJECT_ID CLOUD_ML_REGION ANTHROPIC_DEFAULT_OPUS_MODEL; do
    if [[ -n "${!var:-}" ]]; then
        ENV_ARGS+=(-e "${var}=${!var}")
    fi
done

CORPUS_ARGS=()
CORPUS_MOUNT=""
if [[ -n "$CORPUS" ]]; then
    CORPUS="$(cd "$(dirname "$CORPUS")" && pwd)/$(basename "$CORPUS")"
    CORPUS_MOUNT="-v ${CORPUS}:/home/evaluator/app/corpus.json:ro"
    CORPUS_ARGS=(--corpus /home/evaluator/app/corpus.json)
fi

CMD=(
    podman run --rm -it
    --userns=keep-id
    -v "${TREE_A}:/data/tree-a:ro"
    -v "${TREE_B}:/data/tree-b:ro"
    -v "${OUTPUT_DIR}:/data/output"
    ${ADC_MOUNT}
    ${CORPUS_MOUNT}
    "${ENV_ARGS[@]+"${ENV_ARGS[@]}"}"
    "$IMAGE_NAME"
)

EVAL_ARGS=(
    "${CORPUS_ARGS[@]+"${CORPUS_ARGS[@]}"}"
    --tree-a /data/tree-a
    --tree-b /data/tree-b
    --model "$MODEL"
    --output-dir /data/output
    --max-concurrent "$MAX_CONCURRENT"
    --seed "$SEED"
    --check-isolation
)

echo "=== Consumer Evaluation (Containerized) ==="
echo "  Tree A:    $TREE_A -> /data/tree-a (ro)"
echo "  Tree B:    $TREE_B -> /data/tree-b (ro)"
echo "  Output:    $OUTPUT_DIR -> /data/output (rw)"
echo "  Model:     $MODEL"
echo "  Seed:      $SEED"
echo "  ADC:       ${ADC_MOUNT:+mounted}${ADC_MOUNT:-not found}"
echo

if $DRY_RUN; then
    echo "[dry-run] Would execute:"
    echo "  ${CMD[*]} ${EVAL_ARGS[*]}"
    echo
    echo "Then score and generate report inside the container."
    exit 0
fi

echo "--- Phase 1: Running evaluation ---"
"${CMD[@]}" "${EVAL_ARGS[@]}"

echo
echo "--- Phase 2: Scoring results ---"
podman run --rm \
    --userns=keep-id \
    -v "${OUTPUT_DIR}:/data/output" \
    ${CORPUS_MOUNT} \
    --entrypoint python3 \
    "$IMAGE_NAME" \
    benchmark/consumer-v1/score_results.py \
    --results /data/output/raw-results.json \
    "${CORPUS_ARGS[@]+"${CORPUS_ARGS[@]}"}"

echo
echo "--- Phase 3: Generating report ---"
podman run --rm \
    --userns=keep-id \
    -v "${OUTPUT_DIR}:/data/output" \
    --entrypoint python3 \
    "$IMAGE_NAME" \
    benchmark/consumer-v1/generate_report.py \
    --scored-results /data/output/scored-results.json \
    --output /data/output/report.md

echo
echo "=== Complete ==="
echo "Results:  $OUTPUT_DIR/raw-results.json"
echo "Scores:   $OUTPUT_DIR/scored-results.json"
echo "Report:   $OUTPUT_DIR/report.md"
