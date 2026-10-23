#!/usr/bin/env bash
# rung3-fullsend.sh — ladder rung 3: the arch-context harness through
# `fullsend run` against the local OpenShell gateway (podman driver).
#
# Prerequisites:
#   - local OpenShell gateway (0.1.4, fullsend-pinned ref 5a7728c3) running
#     detached — see scripts/rung2-openshell.sh header + LESSONS.md; the
#     gateway config must set BOTH driver images to the from-source local
#     supervisor image (supervisor_image + sandbox_runtime_image)
#   - podman images: localhost/fullsend-archctx:v1 (repo Containerfile) and
#     localhost/openshell/supervisor:local (both 0.1.4 binaries: the
#     openshell-sandbox crate at /openshell-sandbox for the workload side,
#     the openshell-supervisor crate at /openshell-supervisor for the
#     sidecar)
#   - fullsend binary built from the checkout (zero modifications)
#
# Usage:
#   scripts/rung3-fullsend.sh [--keep-target] [fullsend-run-args...]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENSHELL_BIN="${OPENSHELL_BIN:-$(cd "$REPO_ROOT/../openshell/target/release" 2>/dev/null && pwd)/openshell}"
FULLSEND_BIN="${FULLSEND_BIN:-/tmp/fullsend}"
TARGET="${ARCHCTX_TARGET:-/tmp/archctx-target}"
OUT="${ARCHCTX_RUNG3_OUT:-/tmp/fullsend-rung3}"

die() { echo "rung3: $*" >&2; exit 1; }

KEEP_TARGET=0
[ "${1:-}" = "--keep-target" ] && { KEEP_TARGET=1; shift; }

[ -x "$FULLSEND_BIN" ] || die "fullsend binary not found at $FULLSEND_BIN (FULLSEND_BIN=...; build: go build -o \$FULLSEND_BIN ./cmd/fullsend from the fullsend checkout)"
[ -x "$OPENSHELL_BIN" ] || die "openshell CLI not found at $OPENSHELL_BIN (set OPENSHELL_BIN)"
export PATH="$(dirname "$OPENSHELL_BIN"):$PATH"
timeout 15 "$OPENSHELL_BIN" sandbox list >/dev/null 2>&1 || die "no gateway reachable"
podman image inspect localhost/fullsend-archctx:v1 >/dev/null 2>&1 || die "image localhost/fullsend-archctx:v1 not built"

# 1. Lean target repo: the full repo's committed tree minus ~1GB of upstream
#    platform docs (fullsend's upload tars the whole dir; gitignored NOT
#    respected). The pre_script verifies/stages the checkouts into it.
if [ ! -f "$TARGET/architecture/breadboard/components.json" ]; then
	echo "rung3: building lean target at $TARGET"
	mkdir -p "$TARGET"
	rsync -a --exclude='/.git' --exclude='/.venv' --exclude='/tmp' --exclude='/bin' \
		--exclude='/workflow-runs' --exclude='/logs' --exclude='/.env' --exclude='__pycache__' \
		"$REPO_ROOT/" "$TARGET/"
	# find -exec (not ls|xargs: whitespace-safe, no symlink traversal
	# beyond the pruned names)
	find "$TARGET/architecture" -mindepth 1 -maxdepth 1 ! -name breadboard -exec rm -rf {} +
fi
# 2. The run.
echo "rung3: fullsend run arch-context -> $OUT"
set +e
"$FULLSEND_BIN" run arch-context --fullsend-dir "$REPO_ROOT/.fullsend" \
	--target-repo "$TARGET" --output-dir "$OUT" "$@"
RC=$?
set -e

# 3. Verify: usage folding + oracle cross-check + event contract.
python3 - "$OUT" "$RC" << 'EOF'
import json, sys
from pathlib import Path

out, rc = Path(sys.argv[1]), int(sys.argv[2])
errors = []
if rc != 0:
    errors.append(f"fullsend exited {rc}")

run = sorted(out.glob("fs-arc-*"), key=lambda p: p.stat().st_mtime)[-1] if list(out.glob("fs-arc-*")) else None
if run is None or not (run / "metrics.json").exists():
    errors.append("no metrics.json in output")
else:
    m = json.loads((run / "metrics.json").read_text())
    folded = m.get("per_model_usage", {})
    children = folded.get("test-child/echo", {})
    parent = folded.get("workflow-engine/v1", {})
    print(f"metrics: children {children.get('requests')} requests, parent {parent.get('requests')} request, "
          f"parent tokens in/out {parent.get('input_tokens')}/{parent.get('output_tokens')}, "
          f"cost ${m.get('total_cost_usd')}")
    if children.get("requests") != 6:
        errors.append(f"children folded {children.get('requests')} != 6 (5 components + platform)")
    if parent.get("requests") != 1 or parent.get("input_tokens") or parent.get("output_tokens"):
        errors.append("parent usage not honest-zero")

    # Oracle: the runner-folded subagent usage file vs metrics
    oracle_files = sorted((run / "iteration-1" / "transcripts").glob("*subagents-usage.jsonl"))
    if oracle_files:
        oracle = [json.loads(l) for l in oracle_files[-1].read_text().splitlines() if l.strip()]
        match = len(oracle) == children.get("requests")
        print(f"oracle: {len(oracle)} subagent usage records == {children.get('requests')} folded: {match}")
        if not match:
            errors.append("oracle cross-check failed")
    else:
        errors.append("no subagent usage transcript found")

    # Event contract from the iteration's stdout stream
    streams = sorted((run / "iteration-1").glob("output.jsonl"))
    if streams:
        events = [json.loads(l) for l in streams[-1].read_text().splitlines() if l.strip().startswith("{")]
        ends = [e for e in events if e.get("type") == "tool_execution_end" and e.get("toolName") == "workflow"]
        contract = (
            len(ends) == 1 and not ends[0].get("isError")
            and any(e.get("type") == "agent_settled" for e in events)
            and any(e.get("type") == "agent_end" and e.get("willRetry") is False for e in events)
        )
        print(f"event contract: {'OK' if contract else 'BROKEN'} ({len(events)} events)")
        if not contract:
            errors.append("event contract broken")
    else:
        errors.append("no iteration output stream")

for e in errors:
    print(f"  - {e}")
print("RUNG3-CHECK:", "PASS" if not errors else "FAIL")
sys.exit(1 if errors else 0)
EOF
