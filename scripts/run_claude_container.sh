#!/usr/bin/env bash
set -Eeuo pipefail

# Run a non-interactive Claude task in a Podman container named
# `claude-task-runner`.
#
# Basic usage from the repository root:
#
#   scripts/run_claude_container.sh --model claude-opus-4-6 \
#       "Inspect the repository, implement the requested change, and test it."
#
# The current checkout is mounted read/write at /workspace, and Claude runs
# with --dangerously-skip-permissions. This is intentionally a task runner,
# not an isolation harness: Claude can modify any file in this checkout.
# Review prompts before running them. Use --dry-run to inspect the Podman
# command and --build to rebuild the underlying image.
# Claude output is emitted as newline-delimited streaming JSON events, including
# partial text chunks, so progress and tool activity appear while the task is
# running.
#
# Authentication is loaded from .env (if present) and the calling shell's
# exported environment variables. Caller exports take precedence over .env.
# The host ADC file, when present, is mounted read-only at
# /home/evaluator/.config/gcloud/application_default_credentials.json.

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE_NAME="claude-task-runner"
CONTAINER_NAME="claude-task-runner"
IMAGE_CONTAINERFILE="$ROOT_DIR/scripts/Dockerfile.claude"
PROMPT=""
PROMPT_FILE=""
MODEL=""
BUILD=false
DRY_RUN=false
OTEL=false
API_DUMP=false
OTEL_DIR=""

ENV_VARS=(
    ANTHROPIC_API_KEY
    ANTHROPIC_AUTH_TOKEN
    ANTHROPIC_BASE_URL
    CLAUDE_CODE_USE_VERTEX
    ANTHROPIC_VERTEX_PROJECT_ID
    CLOUD_ML_REGION
    ANTHROPIC_DEFAULT_OPUS_MODEL
    ANTHROPIC_DEFAULT_SONNET_MODEL
    ANTHROPIC_DEFAULT_HAIKU_MODEL
)

# Source .env for authentication/configuration variables (e.g. Vertex).
# Caller-exported variables take precedence over .env values.
if [[ -f "$ROOT_DIR/.env" ]]; then
    declare -A _SAVED_ENV
    for _v in "${ENV_VARS[@]}"; do
        [[ -n "${!_v:-}" ]] && _SAVED_ENV[$_v]="${!_v}"
    done
    # shellcheck disable=SC1091
    set -a
    source "$ROOT_DIR/.env"
    set +a
    for _v in "${!_SAVED_ENV[@]}"; do
        export "$_v=${_SAVED_ENV[$_v]}"
    done
    unset _SAVED_ENV _v
fi

usage() {
    cat <<'EOF'
Usage: scripts/run_claude_container.sh [options] [PROMPT]

Run a non-interactive Claude task in Podman with this repository mounted
read/write at /workspace. Claude is given --dangerously-skip-permissions and
emits streaming JSON events, including partial message chunks, to stdout.

Options:
  --prompt TEXT       Prompt text (may also be supplied as the final argument)
  --prompt-file PATH  Read the prompt from a file
  --model MODEL       Claude model name or shorthand
  --image NAME        Container image name (default: claude-task-runner)
  --build             Rebuild the image before running
  --dry-run           Print the Podman command without executing it
  --otel [DIR]        Enable local OTel capture (metrics, traces) to DIR
                      (default: tmp/otel-capture). Does not capture prompts
                      or tool details unless --api-dump is also set.
  --api-dump          Include raw API bodies in OTel capture. Bodies are
                      redacted inline via a streaming filter before any
                      persistent write. Implies --otel.
  -h, --help          Show this help

Authentication variables are loaded from .env (if present) and the calling
shell's exports. Caller exports take precedence. Recognized variables:
ANTHROPIC_API_KEY, CLAUDE_CODE_USE_VERTEX, ANTHROPIC_VERTEX_PROJECT_ID,
CLOUD_ML_REGION, and ANTHROPIC_DEFAULT_*_MODEL. If present, the host's
Google ADC file is mounted read-only at the container's standard path.

WARNING: The container can modify any file in this checkout and Claude's
permission checks are disabled. Review the prompt before running it.
EOF
}

while (($#)); do
    case "$1" in
        --prompt)
            [[ $# -ge 2 ]] || { echo "--prompt requires a value" >&2; exit 2; }
            PROMPT=$2
            shift 2
            ;;
        --prompt-file)
            [[ $# -ge 2 ]] || { echo "--prompt-file requires a path" >&2; exit 2; }
            PROMPT_FILE=$2
            shift 2
            ;;
        --model)
            [[ $# -ge 2 ]] || { echo "--model requires a value" >&2; exit 2; }
            MODEL=$2
            shift 2
            ;;
        --image)
            [[ $# -ge 2 ]] || { echo "--image requires a value" >&2; exit 2; }
            IMAGE_NAME=$2
            shift 2
            ;;
        --build)
            BUILD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --otel)
            OTEL=true
            if [[ $# -ge 2 && "$2" != --* ]]; then
                OTEL_DIR=$2
                shift 2
            else
                shift
            fi
            ;;
        --api-dump)
            API_DUMP=true
            OTEL=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            PROMPT="${PROMPT:-$*}"
            break
            ;;
        *)
            if [[ -n "$PROMPT" ]]; then
                PROMPT+=" $1"
            else
                PROMPT=$1
            fi
            shift
            ;;
    esac
done

if [[ -n "$PROMPT" && -n "$PROMPT_FILE" ]]; then
    echo "Error: use either a prompt argument or --prompt-file, not both" >&2
    exit 2
fi

if [[ -n "$PROMPT_FILE" ]]; then
    if [[ ! -f "$PROMPT_FILE" ]]; then
        echo "Error: prompt file does not exist: $PROMPT_FILE" >&2
        exit 2
    fi
    PROMPT=$(<"$PROMPT_FILE")
fi

if [[ -z "$PROMPT" ]]; then
    echo "Error: a prompt is required" >&2
    usage >&2
    exit 2
fi

# --- OTel / API-dump setup ---------------------------------------------------
OTEL_ENV_ARGS=()
if $OTEL; then
    [[ -z "$OTEL_DIR" ]] && OTEL_DIR="$ROOT_DIR/tmp/otel-capture"
    mkdir -p "$OTEL_DIR" 2>/dev/null || true

    OTEL_ENV_ARGS+=(
        --env CLAUDE_CODE_ENABLE_TELEMETRY=1
        --env OTEL_METRICS_EXPORTER=console
        --env OTEL_TRACES_EXPORTER=console
        --env OTEL_LOGS_EXPORTER=console
    )

    if $API_DUMP; then
        OTEL_ENV_ARGS+=(
            --env OTEL_LOG_RAW_API_BODIES=1
        )
    fi
fi

if ! $DRY_RUN && ($BUILD || ! podman image exists "$IMAGE_NAME" 2>/dev/null); then
    echo "Building container image: $IMAGE_NAME"
    podman build -t "$IMAGE_NAME" -f "$IMAGE_CONTAINERFILE" "$ROOT_DIR"
fi

ENV_ARGS=()
for var in "${ENV_VARS[@]}"; do
    if [[ -n "${!var:-}" ]]; then
        ENV_ARGS+=(--env "${var}=${!var}")
    fi
done

ADC_PATH="${HOME}/.config/gcloud/application_default_credentials.json"
ADC_ARGS=()
if [[ -f "$ADC_PATH" ]]; then
    ADC_ARGS+=(--volume "${ADC_PATH}:/home/evaluator/.config/gcloud/application_default_credentials.json:ro")
fi

CLAUDE_ARGS=(claude --dangerously-skip-permissions --print
    --output-format stream-json --include-partial-messages --verbose)
if [[ -n "$MODEL" ]]; then
    CLAUDE_ARGS+=(--model "$MODEL")
fi
CLAUDE_ARGS+=(-- "$PROMPT")

CMD=(
    podman run --rm
    --name "$CONTAINER_NAME"
    --userns=keep-id
    --workdir /workspace
    --volume "${ROOT_DIR}:/workspace:rw"
    "${ADC_ARGS[@]}"
    "${ENV_ARGS[@]}"
    "${OTEL_ENV_ARGS[@]}"
    --entrypoint claude
    "$IMAGE_NAME"
    "${CLAUDE_ARGS[@]:1}"
)

echo "=== Claude task container ==="
echo "  Project:  $ROOT_DIR -> /workspace (rw)"
echo "  Image:    $IMAGE_NAME"
echo "  Container: $CONTAINER_NAME"
echo "  Model:    ${MODEL:-default}"
echo "  Permissions: --dangerously-skip-permissions"
echo "  ADC:      ${#ADC_ARGS[@]} mount arguments"
if $OTEL; then
    echo "  OTel:     enabled -> ${OTEL_DIR}"
    if $API_DUMP; then
        echo "  API dump: enabled (streaming redaction -> otel-console.log)"
    fi
fi

if $DRY_RUN; then
    printf '  '
    printf '%q ' "${CMD[@]}"
    printf '\n'
    exit 0
fi

if $OTEL; then
    OTEL_LOG_FILE="${OTEL_DIR}/otel-console.log"
    OTEL_FIFO="${OTEL_DIR}/.stderr-fifo"

    rm -f "$OTEL_FIFO"
    mkfifo "$OTEL_FIFO"
    _cleanup_fifo() { rm -f "$OTEL_FIFO" 2>/dev/null; }
    trap _cleanup_fifo EXIT

    python3 "$ROOT_DIR/lib/telemetry_redact.py" "$OTEL_LOG_FILE" \
        < "$OTEL_FIFO" >&2 &
    FILTER_PID=$!

    "${CMD[@]}" 2>"$OTEL_FIFO"
    CMD_EXIT=$?

    wait "$FILTER_PID" 2>/dev/null
    exit "$CMD_EXIT"
else
    exec "${CMD[@]}"
fi
