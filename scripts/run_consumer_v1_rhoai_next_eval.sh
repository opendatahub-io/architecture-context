#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

TREE_A="$ROOT_DIR/tmp/architecture-context/architecture/rhoai.next"
TREE_B="$ROOT_DIR/tmp/architecture-corpus-runs/rhoai.next-20260802T222449Z-2813199/architecture/rhoai.next"
CORPUS="$ROOT_DIR/benchmark/consumer-v1/corpus.json"
MODEL="opus"
MAX_CONCURRENT=10
SEED=42
CONDITION="baseline"
CONDITION_MANIFEST="$ROOT_DIR/benchmark/analyzer-assisted-v1/experiment.json"
OUTPUT_DIR=""
DRY_RUN=false
SKIP_CORPUS_VALIDATION=false
SKIP_EXPERIMENT_VALIDATION=false
QUESTION_ARGS=()

usage() {
    cat <<'EOF'
Usage: scripts/run_consumer_v1_rhoai_next_eval.sh [options]

Run the consumer-v1 benchmark comparing the prior generated rhoai.next tree
under tmp/architecture-context against the latest full-run rhoai.next artifact.
Raw outputs are written under tmp/evaluations by default and should not be
committed.

Options:
  --tree-a DIR             Baseline architecture tree (default: tmp/architecture-context/architecture/rhoai.next)
  --tree-b DIR             Candidate architecture tree (default: latest full-run artifact)
  --corpus FILE            Benchmark corpus (default: benchmark/consumer-v1/corpus.json)
  --output-dir DIR         Output directory (default: tmp/evaluations/consumer-v1-rhoai-next-<UTC timestamp>)
  --model MODEL            Evaluation model shorthand: opus, sonnet, haiku (default: opus)
  --max-concurrent N       Concurrent evaluation sessions (default: 10)
  --seed N                 Presentation-order seed (default: 42)
  --condition ID           Evaluation condition (default: baseline)
  --condition-manifest FILE  Condition manifest (default: analyzer-assisted-v1/experiment.json)
  --skip-corpus-validation  Skip consumer schema validation for an external corpus
  --skip-experiment-validation  Skip the canonical analyzer-assisted manifest checks
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

materialize_eval_tree() {
    local source_dir=$1
    local target_dir=$2
    if [[ -z "$target_dir" || "$target_dir" == "/" || "$target_dir" == "$ROOT_DIR" ]]; then
        echo "Refusing unsafe eval tree target: $target_dir" >&2
        exit 2
    fi
    rm -rf "$target_dir"
    mkdir -p "$target_dir"
    while IFS= read -r -d '' source_file; do
        local rel target_file target_parent
        rel=${source_file#"$source_dir"/}
        target_file="$target_dir/$rel"
        target_parent=$(dirname "$target_file")
        mkdir -p "$target_parent"
        cp "$source_file" "$target_file"
    done < <(
        find "$source_dir" -type f \
            ! -path '*/.analyzer/*' \
            ! -path '*/.generation/*' \
            -print0
    )

    # Version trees do not contain the parent architecture directory's symlink
    # metadata. Materialize that metadata as a readable benchmark document so
    # navigation questions do not depend on filesystem tools unavailable to
    # evaluation agents.
    {
        echo "# Architecture Symlinks"
        echo
        echo "Symlinks at the repository architecture root:"
        echo
        echo "| Link | Target |"
        echo "| --- | --- |"
        while IFS=$'\t' read -r link target; do
            [[ -n "$link" ]] || continue
            printf '| `architecture/%s` | `%s` |\n' "$link" "$target"
        done < <(find "$ROOT_DIR/architecture" -maxdepth 1 -type l -printf '%f\t%l\n' | sort)
    } > "$target_dir/ARCHITECTURE_SYMLINKS.md"
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
        --corpus)
            CORPUS=$2
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
        --condition-manifest)
            CONDITION_MANIFEST=$2
            shift 2
            ;;
        --skip-corpus-validation)
            SKIP_CORPUS_VALIDATION=true
            shift
            ;;
        --skip-experiment-validation)
            SKIP_EXPERIMENT_VALIDATION=true
            shift
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
if [[ "$CORPUS" != /* ]]; then
    CORPUS="$ROOT_DIR/$CORPUS"
fi
CORPUS=$(cd "$(dirname "$CORPUS")" && pwd)/$(basename "$CORPUS")
if [[ "$CONDITION_MANIFEST" != /* ]]; then
    CONDITION_MANIFEST="$ROOT_DIR/$CONDITION_MANIFEST"
fi
CONDITION_MANIFEST=$(cd "$(dirname "$CONDITION_MANIFEST")" && pwd)/$(basename "$CONDITION_MANIFEST")
OUTPUT_DIR=$(abspath_dir "$OUTPUT_DIR")

cd "$ROOT_DIR"

export UV_CACHE_DIR="${UV_CACHE_DIR:-$ROOT_DIR/tmp/uv-cache}"
mkdir -p "$UV_CACHE_DIR"

EVAL_TREE_A="$OUTPUT_DIR/eval-trees/tree-a"
EVAL_TREE_B="$OUTPUT_DIR/eval-trees/tree-b"

VALIDATE_CONSUMER=()
if [[ "$SKIP_CORPUS_VALIDATION" != true ]]; then
    VALIDATE_CONSUMER=(uv run python3 benchmark/consumer-v1/validate.py --corpus "$CORPUS")
fi
VALIDATE_EXPERIMENT=(uv run python3 benchmark/analyzer-assisted-v1/validate.py)
VALIDATE_CORPUS=(uv run python3 benchmark/analyzer-assisted-v1/validate_corpus.py)
if [[ "$SKIP_EXPERIMENT_VALIDATION" == true ]]; then
    VALIDATE_EXPERIMENT=()
    VALIDATE_CORPUS=()
fi
LINT_ARCHITECTURE=(uv run python scripts/lint_architecture_docs.py)

EVAL_COMMAND=(
    uv run python3 benchmark/consumer-v1/run_evaluation.py
    --corpus "$CORPUS"
    --tree-a "$EVAL_TREE_A"
    --tree-b "$EVAL_TREE_B"
    --model "$MODEL"
    --output-dir "$OUTPUT_DIR"
    --max-concurrent "$MAX_CONCURRENT"
    --seed "$SEED"
    --condition "$CONDITION"
    --condition-manifest "$CONDITION_MANIFEST"
    "${QUESTION_ARGS[@]}"
)

SCORE_COMMAND=(
    uv run python3 benchmark/consumer-v1/score_results.py
    --results "$OUTPUT_DIR/raw-results.json"
    --corpus "$CORPUS"
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
echo "Corpus:       $CORPUS"
echo "Corpus questions: $(jq '.questions | length' "$CORPUS")"
echo "Eval Tree A:  $EVAL_TREE_A"
echo "Eval Tree B:  $EVAL_TREE_B"
echo "Output dir:   $OUTPUT_DIR"
echo "Model:        $MODEL"
echo "Concurrency:  $MAX_CONCURRENT"
echo "Seed:         $SEED"
echo "Condition:    $CONDITION"
echo "Condition manifest: $CONDITION_MANIFEST"
if ((${#QUESTION_ARGS[@]})); then
    echo "Question IDs: ${QUESTION_ARGS[*]}"
else
    echo "Question IDs: all active corpus questions"
fi
echo

if [[ "$DRY_RUN" == true ]]; then
    echo "Commands that would run:"
    if ((${#VALIDATE_CONSUMER[@]})); then
        print_command "${VALIDATE_CONSUMER[@]}"
    else
        echo "  corpus validation skipped"
    fi
    if ((${#VALIDATE_EXPERIMENT[@]})); then
        print_command "${VALIDATE_EXPERIMENT[@]}"
        print_command "${VALIDATE_CORPUS[@]}"
    else
        echo "  canonical experiment validation skipped"
    fi
    print_command "${LINT_ARCHITECTURE[@]}"
    echo "  materialize_eval_tree '$TREE_A' '$EVAL_TREE_A'"
    echo "  materialize_eval_tree '$TREE_B' '$EVAL_TREE_B'"
    print_command "${EVAL_COMMAND[@]}"
    print_command "${SCORE_COMMAND[@]}"
    print_command "${REPORT_COMMAND[@]}"
    exit 0
fi

echo "--- Phase 0: Validating benchmark inputs ---"
if ((${#VALIDATE_CONSUMER[@]})); then
    "${VALIDATE_CONSUMER[@]}"
fi
if ((${#VALIDATE_EXPERIMENT[@]})); then
    "${VALIDATE_EXPERIMENT[@]}"
    "${VALIDATE_CORPUS[@]}"
fi
"${LINT_ARCHITECTURE[@]}"

echo
echo "--- Phase 0b: Materializing consumer-facing eval trees ---"
materialize_eval_tree "$TREE_A" "$EVAL_TREE_A"
materialize_eval_tree "$TREE_B" "$EVAL_TREE_B"

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
