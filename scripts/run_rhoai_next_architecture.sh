#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PLATFORM="rhoai.next"
MODEL="opus"
WORKERS=10
PRIOR_WALL_SECONDS=3600
BASELINE_DIR="$ROOT_DIR/architecture/rhoai.next.bak"
COMPONENTS=""
RUN_DIR=""
DRY_RUN=false

usage() {
    cat <<'EOF'
Usage: scripts/run_rhoai_next_architecture.sh [options]

Run the analyzer-first rhoai.next component workflow and compare it with the
rhoai.next.bak regression fixture. PLATFORM.md synthesis and diagrams are not run.

Options:
  --run-dir DIR              Fresh output directory (default: tmp timestamped run)
  --baseline DIR             Fixture directory (default: architecture/rhoai.next.bak)
  --model MODEL              Component agent model (default: opus)
  --workers COUNT            Concurrent static and agent workers (default: 10)
  --components NAME,...      Run only the named component matrix
  --prior-wall-seconds SEC   Prior full-run reference (default: 3600)
  --dry-run                  Initialize metadata and print commands without running
  -h, --help                 Show this help
EOF
}

while (($#)); do
    case "$1" in
        --run-dir)
            RUN_DIR=$2
            shift 2
            ;;
        --baseline)
            BASELINE_DIR=$2
            shift 2
            ;;
        --model)
            MODEL=$2
            shift 2
            ;;
        --workers)
            WORKERS=$2
            shift 2
            ;;
        --components)
            COMPONENTS=$2
            shift 2
            ;;
        --prior-wall-seconds)
            PRIOR_WALL_SECONDS=$2
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

if [[ -z "$RUN_DIR" ]]; then
    RUN_DIR="$ROOT_DIR/tmp/architecture-corpus-runs/${PLATFORM}-$(date -u +%Y%m%dT%H%M%SZ)-$$"
elif [[ "$RUN_DIR" != /* ]]; then
    RUN_DIR="$ROOT_DIR/$RUN_DIR"
fi
if [[ "$BASELINE_DIR" != /* ]]; then
    BASELINE_DIR="$ROOT_DIR/$BASELINE_DIR"
fi

cd "$ROOT_DIR"

CORPUS_TOOL=(uv run python scripts/compare_architecture_corpus.py)
INIT_COMMAND=("${CORPUS_TOOL[@]}" init-run
    --repo-root "$ROOT_DIR"
    --source-architecture-dir "$ROOT_DIR/architecture"
    --platform "$PLATFORM"
    --platforms-file "$ROOT_DIR/platforms.yaml"
    --baseline "$BASELINE_DIR"
    --run-dir "$RUN_DIR"
    --model "$MODEL"
    --workers "$WORKERS"
    --prior-wall-seconds "$PRIOR_WALL_SECONDS")
if [[ -n "$COMPONENTS" ]]; then
    INIT_COMMAND+=(--components "$COMPONENTS")
fi
"${INIT_COMMAND[@]}"

RUN_MANIFEST="$RUN_DIR/run.json"
RUN_ARCHITECTURE="$RUN_DIR/architecture"
CANDIDATE_DIR="$RUN_ARCHITECTURE/$PLATFORM"
ANALYZER_DIR="$RUN_DIR/analyzer/$PLATFORM"
LOG_DIR="$RUN_DIR/logs"
REPORT_DIR="$RUN_DIR/reports"
ADJUDICATIONS="$RUN_DIR/preservation-adjudications.json"

STATIC_COMMAND=(
    uv run main.py static-analysis
    --platform="$PLATFORM"
    --architecture-dir="$RUN_ARCHITECTURE"
    --max-concurrent="$WORKERS"
    --force
)
AGENT_COMMAND=(
    uv run main.py generate-architecture
    --platform="$PLATFORM"
    --architecture-dir="$RUN_ARCHITECTURE"
    --max-concurrent="$WORKERS"
    --log-dir="$LOG_DIR/agents"
    --force
    --evidence-gated-merge
    --model="$MODEL"
)
COLLECT_COMMAND=(
    uv run main.py collect-architectures
    --platform="$PLATFORM"
    --architecture-dir="$RUN_ARCHITECTURE"
)

print_command() {
    printf '  '
    printf '%q ' "$@"
    printf '\n'
}

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run initialized at: $RUN_DIR"
    echo "Commands that would run:"
    print_command "${STATIC_COMMAND[@]}"
    print_command "${CORPUS_TOOL[@]}" snapshot-analyzers \
        --run-manifest "$RUN_MANIFEST"
    print_command "${AGENT_COMMAND[@]}"
    print_command "${COLLECT_COMMAND[@]}"
    print_command "${CORPUS_TOOL[@]}" compare \
        --baseline "$BASELINE_DIR" \
        --candidate "$CANDIDATE_DIR" \
        --analyzer "$ANALYZER_DIR" \
        --preservation-adjudications "$ADJUDICATIONS" \
        --merge-report-dir "$LOG_DIR/agents" \
        --run-manifest "$RUN_MANIFEST" \
        --output-json "$REPORT_DIR/comparison.json" \
        --output-markdown "$REPORT_DIR/comparison.md"
    exit 0
fi

run_phase() {
    local phase=$1
    local log_file=$2
    shift 2
    local time_file="$LOG_DIR/${phase}.seconds"
    local started_at started_epoch ended_at ended_epoch wall_seconds status
    local command_text

    started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    started_epoch=$(date +%s.%N)
    printf -v command_text '%q ' "$@"

    set +e
    /usr/bin/time -f '%e' -o "$time_file" "$@" 2>&1 | tee "$log_file"
    status=${PIPESTATUS[0]}
    set -e

    ended_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    ended_epoch=$(date +%s.%N)
    wall_seconds=$(tail -n 1 "$time_file" | tr -d '[:space:]')
    "${CORPUS_TOOL[@]}" record-phase \
        --run-manifest "$RUN_MANIFEST" \
        --phase "$phase" \
        --started-at "$started_at" \
        --ended-at "$ended_at" \
        --started-epoch "$started_epoch" \
        --ended-epoch "$ended_epoch" \
        --wall-seconds "$wall_seconds" \
        --exit-code "$status" \
        --phase-command "$command_text" \
        --log "$log_file"
    return "$status"
}

run_phase static_analysis "$LOG_DIR/static-analysis.log" "${STATIC_COMMAND[@]}"
"${CORPUS_TOOL[@]}" snapshot-analyzers --run-manifest "$RUN_MANIFEST"
run_phase component_generation "$LOG_DIR/component-generation.log" \
    "${AGENT_COMMAND[@]}"
run_phase collection "$LOG_DIR/collection.log" "${COLLECT_COMMAND[@]}"

set +e
"${CORPUS_TOOL[@]}" compare \
    --baseline "$BASELINE_DIR" \
    --candidate "$CANDIDATE_DIR" \
    --analyzer "$ANALYZER_DIR" \
    --preservation-adjudications "$ADJUDICATIONS" \
    --merge-report-dir "$LOG_DIR/agents" \
    --run-manifest "$RUN_MANIFEST" \
    --output-json "$REPORT_DIR/comparison.json" \
    --output-markdown "$REPORT_DIR/comparison.md" \
    2>&1 | tee "$LOG_DIR/comparison.log"
comparison_status=${PIPESTATUS[0]}
set -e

echo "Run artifacts: $RUN_DIR"
exit "$comparison_status"
