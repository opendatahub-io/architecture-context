#!/usr/bin/env bash
# archctx.sh — local convenience wrapper for the architecture-context
# workflow-engine port.
#
# NOT used by fullsend (the harness invokes pi directly with its own
# env machinery); this exists so local runs are one command instead of
# a paragraph of env vars.
#
# Usage:
#   scripts/archctx.sh prepare [--platform NAME]          # host-side P0: fetch + analyze + manifest
#   scripts/archctx.sh fetch   [--platform NAME]          # host-side: clone component repos
#   scripts/archctx.sh analyze [--platform NAME]          # host-side: arch-analyzer baselines
#   scripts/archctx.sh manifest [--platform NAME]         # regenerate component-map + components.json
#   scripts/archctx.sh run [options]                      # the workflow under pi
#   scripts/archctx.sh check [--runs N]                   # rung-1 verification suite
#
# run options:
#   --real              children on a real model (default: offline test-child/echo)
#   --model SPEC        child model spec (default: enmaas-glm-5-3/rits/zai-org/glm-5-3;
#                       provider = first path segment, key read from ~/.pi/agent/auth.json)
#   --components A,B    limit to specific components
#   --stages A,B        stage selection (default: analyze,generate,collect,platform)
#   --concurrency N     fan-out concurrency (default 2)
#   --timeout-ms N      per-child timeout (default 600000 for --real)
#   --platform NAME     platform (default: breadboard)
#
# Examples:
#   scripts/archctx.sh run                                   # offline, full platform
#   scripts/archctx.sh run --real                            # GLM, full platform
#   scripts/archctx.sh run --real --components jira-emulator # one component
#   scripts/archctx.sh run --stages analyze                  # validation only, no inference
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="$REPO_ROOT/.fullsend/plugins/workflow-engine"
PLATFORM="${ARCHCTX_PLATFORM:-breadboard}"
DEFAULT_MODEL="enmaas-glm-5-3/rits/zai-org/glm-5-3"

die() { echo "archctx: $*" >&2; exit 1; }

cmd="${1:-help}"; [ $# -gt 0 ] && shift || true
case "$cmd" in
	fetch|analyze|manifest|prepare|run|check) ;;
	-h|--help|help) cmd=help ;;
	*) die "unknown command '$cmd' (try: prepare, fetch, analyze, manifest, run, check, or --help)" ;;
esac

# ---------------------------------------------------------------- host-side
hostside() {
	cd "$REPO_ROOT"
	# main.py hard-requires .env; placeholder is fine for non-agent phases
	[ -f .env ] || printf 'ANTHROPIC_API_KEY=placeholder-not-a-real-credential\n' > .env
	case "$1" in
	fetch)
		uv run main.py fetch --platform "$PLATFORM" ;;
	analyze)
		uv run main.py static-analysis --platform "$PLATFORM" ;;
	manifest)
		uv run scripts/make_static_component_map.py --platform "$PLATFORM" --workflow-input ;;
	esac
}

# ---------------------------------------------------------------- run
do_run() {
	local REAL=0 STAGES="" COMPONENTS="" CONCURRENCY="" TIMEOUT="" MODEL="$DEFAULT_MODEL"
	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help)
				sed -n "2,30p" "$0" | sed 's/^# \{0,1\}//'
				return 0 ;;
			--real) REAL=1 ;;
			--model) MODEL="$2"; shift ;;
			--components) COMPONENTS="$2"; shift ;;
			--stages) STAGES="$2"; shift ;;
			--concurrency) CONCURRENCY="$2"; shift ;;
			--timeout-ms) TIMEOUT="$2"; shift ;;
			--platform) PLATFORM="$2"; shift ;;
			*) die "unknown run option '$1'" ;;
		esac
		shift
	done
	command -v pi >/dev/null || die "pi not found in PATH"
	[ -f "$REPO_ROOT/architecture/$PLATFORM/components.json" ] \
		|| die "no architecture/$PLATFORM/components.json — run 'scripts/archctx.sh prepare' first"
	[ "$REAL" = 0 ] && [ -z "$TIMEOUT" ] && TIMEOUT=300000
	[ "$REAL" = 1 ] && [ -z "$TIMEOUT" ] && TIMEOUT=600000

	local INPUT
	INPUT=$(python3 - "$PLATFORM" "$STAGES" "$COMPONENTS" "$CONCURRENCY" "$TIMEOUT" << 'EOF'
import json, sys
platform, stages, components, concurrency, timeout = sys.argv[1:6]
d = {"platform": platform}
if stages: d["stages"] = [s.strip() for s in stages.split(",") if s.strip()]
if components: d["components"] = [c.strip() for c in components.split(",") if c.strip()]
if concurrency: d["concurrency"] = int(concurrency)
if timeout: d["timeoutMs"] = int(timeout)
print(json.dumps(d))
EOF
	)

	local SCRATCH="$(mktemp -d /tmp/archctx-run.XXXXXX)"
	mkdir -p "$SCRATCH/home" "$SCRATCH/session"

	local RUNENV=()
	RUNENV+=(HOME="$SCRATCH/home"
		WORKFLOW_COMMAND=run-arch-context
		WORKFLOW_INPUT="$INPUT"
		WORKFLOW_INPUT_FILE="$REPO_ROOT/architecture/$PLATFORM/components.json")

	if [ "$REAL" = 1 ]; then
		local AUTH="$HOME/.pi/agent/auth.json"
		local PROVIDER="${MODEL%%/*}"
		[ -f "$AUTH" ] || die "real mode needs $AUTH (provider key store)"
		local KEY
		KEY=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d[sys.argv[2]]['key'])" "$AUTH" "$PROVIDER") \
			|| die "no auth entry for provider '$PROVIDER' in $AUTH"
		# mktemp, not a predictable path (CWE-377/59): a pre-created
		# symlink at a fixed name would let another local user rewrite
		# the child provider config (and redirect the API key).
		local MODELS
		MODELS="$(mktemp "/tmp/archctx-$PROVIDER-models.XXXXXXXX")"
		python3 - "$PROVIDER" "$MODELS" << 'EOF'
import json, os, sys
provider, out = sys.argv[1], sys.argv[2]
src = json.load(open(os.path.expanduser("~/.pi/agent/models.json")))
for p in src["providers"].values():
    p["apiKey"] = "$ENMAAS_API_KEY"
json.dump(src, open(out, "w"), indent=1)
EOF
		RUNENV+=(WORKFLOW_CHILD_MODEL="$MODEL"
			WORKFLOW_CHILD_MODELS_JSON="$MODELS"
			WORKFLOW_CHILD_ENV="ENMAAS_API_KEY=$KEY")
		echo "archctx: real inference — model $MODEL (key env-only, never on disk)"
	else
		echo "archctx: offline (test-child/echo, no inference)"
		echo "archctx: WARNING — an offline run that publishes will overwrite real"
		echo "archctx:          markdown under architecture/$PLATFORM/ with fixture content"
	fi

	echo "archctx: input $INPUT"
	echo "archctx: scratch $SCRATCH"
	# set -e would kill the script before the failure report; capture rc.
	local RC=0
	env "${RUNENV[@]}" \
		pi --print --mode json --no-approve --no-extensions --no-prompt-templates --no-themes \
			--session-dir "$SCRATCH/session" \
			-e "$PLUGIN" \
			--model workflow-engine/v1 --tools workflow \
			"Run the architecture context workflow" > "$SCRATCH/stdout.jsonl" 2> "$SCRATCH/stderr.txt" || RC=$?

	echo
	if grep -q "workflow failed" "$SCRATCH/stdout.jsonl"; then
		grep -o "workflow failed[^\"]*" "$SCRATCH/stdout.jsonl" | head -1
		echo "archctx: FAILED (rc=$RC) — scratch: $SCRATCH"
		exit 1
	fi
	grep -o "workflow complete[^\"]*" "$SCRATCH/stdout.jsonl" | head -1 || true
	local RUN_DIR
	RUN_DIR=$(ls -dt "$REPO_ROOT"/workflow-runs/*/ 2>/dev/null | head -1)
	echo "archctx: run dir   $RUN_DIR"
	echo "archctx: published $REPO_ROOT/architecture/$PLATFORM/"
	if [ -f "$RUN_DIR/usage.jsonl" ]; then
		python3 -c "
import json, sys
recs=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
i=sum(r['usage']['input'] for r in recs); o=sum(r['usage']['output'] for r in recs)
print(f'archctx: usage     {len(recs)} records, input={i} output={o}')" "$RUN_DIR/usage.jsonl"
	fi
}

# ---------------------------------------------------------------- check
do_check() {
	local RUNS=3
	while [ $# -gt 0 ]; do
		case "$1" in
			--runs) RUNS="$2"; shift ;;
			*) die "unknown check option '$1'" ;;
		esac
		shift
	done
	local OUT="$(mktemp -d /tmp/archctx-check.XXXXXX)"
	echo "archctx: check output $OUT"
	python3 "$PLUGIN/check-archctx.py" --runs "$RUNS" --out "$OUT"
}

# ---------------------------------------------------------------- dispatch
case "$cmd" in
	fetch|analyze|manifest)
		while [ $# -gt 0 ]; do
			case "$1" in
				--platform) PLATFORM="$2"; shift ;;
				*) die "unknown option '$1'" ;;
			esac
			shift
		done
		hostside "$cmd" ;;
	prepare)
		while [ $# -gt 0 ]; do
			case "$1" in
				--platform) PLATFORM="$2"; shift ;;
				*) die "unknown option '$1'" ;;
			esac
			shift
		done
		hostside fetch && hostside analyze && hostside manifest
		echo "archctx: prepare complete — architecture/$PLATFORM/components.json" ;;
	run) do_run "$@" ;;
	check) do_check "$@" ;;
	help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
