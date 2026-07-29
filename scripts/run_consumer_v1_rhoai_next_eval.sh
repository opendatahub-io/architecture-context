#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

TREE_A="$ROOT_DIR/architecture/rhoai.next.bak"
TREE_B="$ROOT_DIR/architecture/rhoai.next"
MODEL="opus"
MAX_CONCURRENT=2
SEED=42
CONDITION="baseline"
OUTPUT_DIR=""
DRY_RUN=false
QUESTION_ARGS=()

usage() {
    cat <<'EOF'
Usage: scripts/run_consumer_v1_rhoai_next_eval.sh [options]

Run the consumer-v1 benchmark comparing the checked-in rhoai.next.bak fixture
against the current architecture/rhoai.next tree. Raw outputs are written under
tmp/evaluations by default and should not be committed.

Options:
  --tree-a DIR             Baseline architecture tree (default: architecture/rhoai.next.bak)
  --tree-b DIR             Candidate architecture tree (default: architecture/rhoai.next)
  --output-dir DIR         Output directory (default: tmp/evaluations/consumer-v1-rhoai-next-<UTC timestamp>)
  --model MODEL            Evaluation model shorthand: opus, sonnet, haiku (default: opus)
  --max-concurrent N       Concurrent evaluation sessions (default: 2)
  --seed N                 Presentation-order seed (default: 42)
  --condition ID           Evaluation condition (default: baseline)
  --question-id ID         Limit to one question; repeat for multiple IDs
  --dry-run                Print commands without launching evaluation agents
  -h, --help               Show this help

Examples:
  scripts/run_consumer_v1_rhoai_next_eval.sh
  scripts/run_consumer_v1_rhoai_next_eval.sh --question-id FACT-001 --question-id INTG-001
  scripts/run_consumer_v1_rhoai_next_eval.sh --model sonnet --max-concurrent 4
EOF
}

abspath_dir() {
    local path=$1
    if [[ "$path" != /* ]]; then
        path="$ROOT_DIR/$path"
    fi
    mkdir -p "$path"
    cd "$path" && pwd
}

existing_abspath_dir() {
    local path=$1
    if [[ "$path" != /* ]]; then
        path="$ROOT_DIR/$path"
    fi
    cd "$path" && pwd
}

print_command() {
    printf '  '
    printf '%q ' "$@"
    printf '\n'
}

while (($#)); do
    case "$1" in
        --tree-a)
            TREE_A=$2
            shift 2
            ;;
        --tree-b)
            TREE_B=$2
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR=$2
            shift 2
            ;;
        --model)
            MODEL=$2
            shift 2
            ;;
        --max-concurrent)
            MAX_CONCURRENT=$2
            shift 2
            ;;
        --seed)
            SEED=$2
            shift 2
            ;;
        --condition)
            CONDITION=$2
            shift 2
            ;;
        --question-id)
            QUESTION_ARGS+=(--question-id "$2")
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$ROOT_DIR/tmp/evaluations/consumer-v1-rhoai-next-$(date -u +%Y%m%dT%H%M%SZ)"
fi

TREE_A=$(existing_abspath_dir "$TREE_A")
TREE_B=$(existing_abspath_dir "$TREE_B")
OUTPUT_DIR=$(abspath_dir "$OUTPUT_DIR")

cd "$ROOT_DIR"

VALIDATE_CONSUMER=(uv run python3 benchmark/consumer-v1/validate.py)
VALIDATE_EXPERIMENT=(uv run python3 benchmark/analyzer-assisted-v1/validate.py)
VALIDATE_CORPUS=(uv run python3 benchmark/analyzer-assisted-v1/validate_corpus.py)
LINT_ARCHITECTURE=(uv run python scripts/lint_architecture_docs.py)

EVAL_COMMAND=(
    uv run python3 benchmark/consumer-v1/run_evaluation.py
    --tree-a "$TREE_A"
    --tree-b "$TREE_B"
    --model "$MODEL"
    --output-dir "$OUTPUT_DIR"
    --max-concurrent "$MAX_CONCURRENT"
    --seed "$SEED"
    --condition "$CONDITION"
    "${QUESTION_ARGS[@]}"
)

SCORE_COMMAND=(
    uv run python3 benchmark/consumer-v1/score_results.py
    --results "$OUTPUT_DIR/raw-results.json"
    --corpus benchmark/consumer-v1/corpus.json
    --output "$OUTPUT_DIR/scored-results.json"
)

REPORT_COMMAND=(
    uv run python3 benchmark/consumer-v1/generate_report.py
    --scored-results "$OUTPUT_DIR/scored-results.json"
    --output "$OUTPUT_DIR/report.md"
)

echo "=== consumer-v1 rhoai.next evaluation ==="
echo "Tree A:       $TREE_A"
echo "Tree B:       $TREE_B"
echo "Output dir:   $OUTPUT_DIR"
echo "Model:        $MODEL"
echo "Concurrency:  $MAX_CONCURRENT"
echo "Seed:         $SEED"
echo "Condition:    $CONDITION"
if ((${#QUESTION_ARGS[@]})); then
    echo "Question IDs: ${QUESTION_ARGS[*]}"
else
    echo "Question IDs: all active corpus questions"
fi
echo

if [[ "$DRY_RUN" == true ]]; then
    echo "Commands that would run:"
    print_command "${VALIDATE_CONSUMER[@]}"
    print_command "${VALIDATE_EXPERIMENT[@]}"
    print_command "${VALIDATE_CORPUS[@]}"
    print_command "${LINT_ARCHITECTURE[@]}"
    print_command "${EVAL_COMMAND[@]}"
    print_command "${SCORE_COMMAND[@]}"
    print_command "${REPORT_COMMAND[@]}"
    exit 0
fi

echo "--- Phase 0: Validating benchmark inputs ---"
"${VALIDATE_CONSUMER[@]}"
"${VALIDATE_EXPERIMENT[@]}"
"${VALIDATE_CORPUS[@]}"
"${LINT_ARCHITECTURE[@]}"

echo
echo "--- Phase 1: Running evaluation ---"
"${EVAL_COMMAND[@]}"

echo
echo "--- Phase 2: Scoring results ---"
"${SCORE_COMMAND[@]}"

echo
echo "--- Phase 3: Generating report ---"
"${REPORT_COMMAND[@]}"

echo
echo "=== Complete ==="
echo "Raw results:     $OUTPUT_DIR/raw-results.json"
echo "Scored results:  $OUTPUT_DIR/scored-results.json"
echo "Report:          $OUTPUT_DIR/report.md"
