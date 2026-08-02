#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export UV_CACHE_DIR="${UV_CACHE_DIR:-$ROOT_DIR/tmp/uv-cache}"
mkdir -p "$UV_CACHE_DIR"
PLATFORM="${PLATFORM:-rhoai.next}"
COMPONENT_OVERRIDE="${COMPONENT:-}"
DEFAULT_COMPONENTS=(mlflow)
COMPONENTS=()
COMPONENTS_SPECIFIED=false
if [[ -n "$COMPONENT_OVERRIDE" ]]; then
  COMPONENTS=("$COMPONENT_OVERRIDE")
  COMPONENTS_SPECIFIED=true
else
  COMPONENTS=("${DEFAULT_COMPONENTS[@]}")
fi
REPO="${REPO:-}"
MODEL="${MODEL:-opus}"
MAX_CONCURRENT="${MAX_CONCURRENT:-1}"
ARCHITECTURE_DIR="${ARCHITECTURE_DIR:-tmp/architecture-corpus-runs/rhoai.next-20260802T182238Z-2696509/architecture}"
CHECKOUTS_DIR="${CHECKOUTS_DIR:-checkouts}"
RUN_DIR="${RUN_DIR:-}"
LOG_DIR="${LOG_DIR:-}"
VERSION="${VERSION:-}"
TIER="${TIER:-all}"
FORCE=true
EVIDENCE_GATED=true
SKIP_SCHEMAS=false
STRACE=false
DRY_RUN=false
PHASES=(generate-architecture)
PHASE_SPECIFIED=false

usage() {
  cat <<'EOF'
Usage: ./custom-test.sh [options]

Run a targeted component set through the pipeline. The no-argument invocation
targets the current partial-route runtime tail using the latest full-run
architecture tree and serialized, evidence-gated generation.

Options:
  --component NAME          Component key; repeat for multiple components
                             (default: mlflow)
  --repo SELECTOR           Use a component-map repository selector instead
  --phase NAME              Pipeline phase; repeatable and ordered (default:
                             generate-architecture)
  --platform NAME           Platform (default: rhoai.next)
  --architecture-dir DIR    Architecture root (default: latest full-run tree)
  --checkouts-dir DIR       Checkout root (default: checkouts)
  --run-dir DIR             Isolated root; uses DIR/architecture and DIR/logs/agents
  --log-dir DIR             Agent log directory (default: MLflow replay logs)
  --version LABEL           Explicit generation version
  --model MODEL             opus, sonnet, or haiku (default: opus)
  --max-concurrent N        Agent concurrency (default: 1)
  --tier TIER               all, significant, or core (default: all)
  --force                   Force selected phases (default)
  --no-force                Do not force selected phases
  --evidence-gated-merge    Preserve analyzer-owned sections (default)
  --no-evidence-gated-merge Use legacy whole-document promotion
  --skip-schemas            Skip CRD schema extraction
  --strace                  Run agents under strace
  --dry-run                 Print the command without launching it
  -h, --help                Show this help

Examples:
  ./custom-test.sh --component model-registry --phase generate-architecture
  ./custom-test.sh --component mlflow \
    --component kubeflow --phase generate-architecture
  ./custom-test.sh --repo red-hat-data-services/model-registry \
    --architecture-dir tmp/architecture-corpus-runs/existing/architecture \
    --phase generate-architecture
EOF
}

print_command() {
  printf '  '
  printf '%q ' "$@"
  printf '\n'
}

while (($#)); do
  case "$1" in
    --component)
      [[ $# -ge 2 ]] || { echo "--component requires a value" >&2; exit 2; }
      if [[ "$COMPONENTS_SPECIFIED" == false ]]; then
        COMPONENTS=()
        COMPONENTS_SPECIFIED=true
      fi
      COMPONENTS+=("$2")
      REPO=""
      shift 2
      ;;
    --repo)
      [[ $# -ge 2 ]] || { echo "--repo requires a value" >&2; exit 2; }
      REPO=$2
      COMPONENTS=()
      shift 2
      ;;
    --phase)
      [[ $# -ge 2 ]] || { echo "--phase requires a value" >&2; exit 2; }
      if [[ "$PHASE_SPECIFIED" == false ]]; then
        PHASES=()
        PHASE_SPECIFIED=true
      fi
      PHASES+=("$2")
      shift 2
      ;;
    --platform)
      PLATFORM=$2
      shift 2
      ;;
    --architecture-dir)
      ARCHITECTURE_DIR=$2
      shift 2
      ;;
    --checkouts-dir)
      CHECKOUTS_DIR=$2
      shift 2
      ;;
    --run-dir)
      RUN_DIR=$2
      shift 2
      ;;
    --log-dir)
      LOG_DIR=$2
      shift 2
      ;;
    --version)
      VERSION=$2
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
    --tier)
      TIER=$2
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --no-force)
      FORCE=false
      shift
      ;;
    --evidence-gated-merge)
      EVIDENCE_GATED=true
      shift
      ;;
    --no-evidence-gated-merge)
      EVIDENCE_GATED=false
      shift
      ;;
    --skip-schemas)
      SKIP_SCHEMAS=true
      shift
      ;;
    --strace)
      STRACE=true
      shift
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

if [[ -n "$RUN_DIR" ]]; then
  [[ "$RUN_DIR" = /* ]] || RUN_DIR="$ROOT_DIR/$RUN_DIR"
  ARCHITECTURE_DIR="$RUN_DIR/architecture"
  if [[ -z "$LOG_DIR" ]]; then
    LOG_DIR="$RUN_DIR/logs/agents"
  fi
fi

if [[ "$ARCHITECTURE_DIR" != /* ]]; then
  ARCHITECTURE_DIR="$ROOT_DIR/$ARCHITECTURE_DIR"
fi
if [[ "$CHECKOUTS_DIR" != /* ]]; then
  CHECKOUTS_DIR="$ROOT_DIR/$CHECKOUTS_DIR"
fi
if [[ -z "$LOG_DIR" ]]; then
  if [[ -n "$RUN_DIR" ]]; then
    LOG_DIR="$RUN_DIR/logs/agents"
  else
    LOG_DIR="$ROOT_DIR/tmp/architecture-corpus-runs/rhoai.next-20260802T182238Z-2696509/logs/agents-mlflow-auth-contract"
  fi
elif [[ "$LOG_DIR" != /* ]]; then
  LOG_DIR="$ROOT_DIR/$LOG_DIR"
fi

COMMAND=(
  uv run main.py pipeline
  --platform "$PLATFORM"
  --architecture-dir "$ARCHITECTURE_DIR"
  --checkouts-dir "$CHECKOUTS_DIR"
  --max-concurrent "$MAX_CONCURRENT"
  --model "$MODEL"
  --tier "$TIER"
  --log-dir "$LOG_DIR"
)
for phase in "${PHASES[@]}"; do
  COMMAND+=(--phase "$phase")
done
if [[ -n "$REPO" ]]; then
  COMMAND+=(--repo "$REPO")
else
  for component in "${COMPONENTS[@]}"; do
    COMMAND+=(--component "$component")
  done
fi
if [[ -n "$VERSION" ]]; then
  COMMAND+=(--version "$VERSION")
fi
if [[ "$FORCE" == true ]]; then
  COMMAND+=(--force)
fi
if [[ "$EVIDENCE_GATED" == true ]]; then
  COMMAND+=(--evidence-gated-merge)
else
  COMMAND+=(--no-evidence-gated-merge)
fi
if [[ "$SKIP_SCHEMAS" == true ]]; then
  COMMAND+=(--skip-schemas)
fi
if [[ "$STRACE" == true ]]; then
  COMMAND+=(--strace)
fi

if [[ -n "$REPO" ]]; then
  echo "Repository:      $REPO"
else
  echo "Components:      ${COMPONENTS[*]}"
fi
echo "Platform:        $PLATFORM"
echo "Phases:          ${PHASES[*]}"
echo "Architecture:    $ARCHITECTURE_DIR"
echo "Logs:            $LOG_DIR"
echo "Evidence-gated:  $EVIDENCE_GATED"
echo "Force:           $FORCE"
if [[ "$DRY_RUN" == true ]]; then
  echo "Command:"
  print_command "${COMMAND[@]}"
  exit 0
fi

mkdir -p "$LOG_DIR"
cd "$ROOT_DIR"
exec "${COMMAND[@]}"
