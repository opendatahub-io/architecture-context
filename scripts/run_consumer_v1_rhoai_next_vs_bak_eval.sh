#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/tmp/evaluations/consumer-v1-rhoai-next-vs-bak-$STAMP}"
STRATEGY_CORPUS="$ROOT_DIR/benchmark/strategy-v1/corpus.json"
ALL_DOMAINS=false
FORWARD_ARGS=()

while (($#)); do
    case "$1" in
        --all-domains)
            ALL_DOMAINS=true
            shift
            ;;
        *)
            FORWARD_ARGS+=("$1")
            shift
            ;;
    esac
done

if [[ "$OUTPUT_DIR" != /* ]]; then
    OUTPUT_DIR="$ROOT_DIR/$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"

if [[ "$ALL_DOMAINS" == true ]]; then
    CORPUS="$STRATEGY_CORPUS"
    CONDITION_DIR="$OUTPUT_DIR/condition"
    mkdir -p "$CONDITION_DIR"
    cp "$ROOT_DIR/benchmark/analyzer-assisted-v1/experiment.json" \
        "$CONDITION_DIR/experiment.json"
    jq '{questions: [.questions[] | {id, status: "active"}]}' \
        "$STRATEGY_CORPUS" >"$CONDITION_DIR/corpus_manifest.json"
    CONDITION_MANIFEST="$CONDITION_DIR/experiment.json"
    echo "All-domain diagnostic mode: scheduling architecture, pipeline, and SME-context questions."
    FORWARD_ARGS+=(
        --corpus "$CORPUS"
        --condition-manifest "$CONDITION_MANIFEST"
        --skip-corpus-validation
        --skip-experiment-validation
    )
else
    CORPUS="$OUTPUT_DIR/architecture-corpus.json"
    jq '
        .questions |= [
            .[]
            | select(.domain == "architecture")
            | del(.domain)
        ]
    ' "$STRATEGY_CORPUS" >"$CORPUS"

    question_count=$(jq '.questions | length' "$CORPUS")
    if [[ "$question_count" != "40" ]]; then
        echo "Expected 40 architecture questions, found $question_count" >&2
        exit 2
    fi
    FORWARD_ARGS+=(--corpus "$CORPUS")
fi

exec "$ROOT_DIR/scripts/run_consumer_v1_rhoai_next_eval.sh" \
    "${FORWARD_ARGS[@]}" \
    --tree-a "$ROOT_DIR/architecture/rhoai.next.bak" \
    --tree-b "$ROOT_DIR/architecture/rhoai.next" \
    --output-dir "$OUTPUT_DIR"
