#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export UV_CACHE_DIR="${UV_CACHE_DIR:-$ROOT_DIR/tmp/uv-cache}"
mkdir -p "$UV_CACHE_DIR"
PLATFORM="${PLATFORM:-rhoai.next}"
COMPONENT="${COMPONENT:-kserve}"
REPO="${REPO:-}"
MODEL="${MODEL:-opus}"
MAX_CONCURRENT="${MAX_CONCURRENT:-1}"
ARCHITECTURE_DIR="${ARCHITECTURE_DIR:-tmp/architecture-corpus-runs/rhoai.next-20260730T215609Z-929041/architecture}"
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
PHASES=(static-analysis generate-architecture)
PHASE_SPECIFIED=false

usage() {
  cat <<'EOF'
Usage: ./custom-test.sh [options]

Run one component through the targeted pipeline. The no-argument invocation
targets the KServe deployment-classification replay using the existing
isolated architecture tree, static analysis, and evidence-gated generation.

Options:
  --component NAME          Component key (default: kserve)
  --repo SELECTOR           Use a component-map repository selector instead
  --phase NAME              Pipeline phase; repeatable and ordered
  --platform NAME           Platform (default: rhoai.next)
  --architecture-dir DIR    Architecture root (default: existing isolated run)
  --checkouts-dir DIR       Checkout root (default: checkouts)
  --run-dir DIR             Isolated root; uses DIR/architecture and DIR/logs/agents
  --log-dir DIR             Agent log directory (default: KServe role replay logs)
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
  ./custom-test.sh --component kserve \
    --phase generate-architecture
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
      COMPONENT=$2
      REPO=""
      shift 2
      ;;
    --repo)
      [[ $# -ge 2 ]] || { echo "--repo requires a value" >&2; exit 2; }
      REPO=$2
      COMPONENT=""
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
    LOG_DIR="$ROOT_DIR/tmp/architecture-corpus-runs/rhoai.next-20260730T215609Z-929041/logs/agents-kserve-deployment-profile"
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
  COMMAND+=(--component "$COMPONENT")
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

echo "Component:       ${COMPONENT:-$REPO}"
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
