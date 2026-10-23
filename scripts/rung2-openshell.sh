#!/usr/bin/env bash
# rung2-openshell.sh — ladder rung 2: the arch-context workflow inside an
# OpenShell sandbox (podman driver), WITHOUT fullsend.
#
# Exercises: the sandbox image (Containerfile), the plugin tree, the
# workflow's inputs (checkouts + analyzer baselines + components.json),
# and the child-spawning machinery — all inside the sandbox boundary.
#
# Prerequisites (see LESSONS.md / plan §P3):
#   - local OpenShell gateway running with the podman driver
#     (checkouts/openshell, built + gateway started on :18080)
#   - podman image localhost/fullsend-archctx:v1 (repo Containerfile)
#   - the openshell CLI (default: ../../openshell/target/release/openshell)
#
# Usage:
#   scripts/rung2-openshell.sh [--keep] [components...]
#
#   --keep        keep the sandbox after the run (inspection)
#   components    optional component filter (default: all)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENSHELL_BIN="${OPENSHELL_BIN:-$(cd "$REPO_ROOT/../openshell/target/release" 2>/dev/null && pwd)/openshell}"
IMAGE="${ARCHCTX_IMAGE:-localhost/fullsend-archctx:v1}"
SANDBOX="${ARCHCTX_SANDBOX:-archctx-rung2}"
PLATFORM="${ARCHCTX_PLATFORM:-breadboard}"

die() { echo "rung2: $*" >&2; exit 1; }

KEEP=0
COMPONENTS=""
while [ $# -gt 0 ]; do
	case "$1" in
		--keep) KEEP=1 ;;
		--help|-h) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*) COMPONENTS="$COMPONENTS${COMPONENTS:+,}$1" ;;
	esac
	shift
done

[ -x "$OPENSHELL_BIN" ] || die "openshell CLI not found at $OPENSHELL_BIN (set OPENSHELL_BIN)"
"$OPENSHELL_BIN" sandbox list >/dev/null 2>&1 || die "no gateway reachable (start the local openshell gateway first — IMPORTANT: detached from any process group that may be SIGTERM'd, e.g. 'setsid nohup openshell-gateway ... &'; a gateway killed mid-run wedges sandboxes and transfers)"
podman image inspect "$IMAGE" >/dev/null 2>&1 || die "image $IMAGE not built (podman build -t $IMAGE -f Containerfile .)"

OUT="$(mktemp -d /tmp/archctx-rung2.XXXXXX)"
echo "rung2: output $OUT"

# 1. Lean workspace closure: the plugin tree, the workflow inputs, the
#    component checkouts. (The repo's upstream architecture/ dirs are
#    ~900MB and irrelevant to the workflow.)
TAR="$OUT/workspace.tar.gz"
tar -czf "$TAR" -C "$REPO_ROOT" \
	.fullsend "architecture/$PLATFORM" checkouts
echo "rung2: workspace tar $(du -h "$TAR" | cut -f1)"

# 2. Fresh sandbox from the image (deletion is async — poll until gone).
timeout 60 "$OPENSHELL_BIN" sandbox delete "$SANDBOX" >/dev/null 2>&1 || true
for _ in $(seq 1 20); do
	timeout 10 "$OPENSHELL_BIN" sandbox get "$SANDBOX" >/dev/null 2>&1 || break
	sleep 1
done
timeout 60 "$OPENSHELL_BIN" sandbox delete "$SANDBOX" >/dev/null 2>&1 || true
for _ in $(seq 1 20); do
	timeout 10 "$OPENSHELL_BIN" sandbox get "$SANDBOX" >/dev/null 2>&1 || break
	sleep 1
done
timeout 90 "$OPENSHELL_BIN" sandbox create --name "$SANDBOX" --from "$IMAGE" -- true >/dev/null
echo "rung2: sandbox $SANDBOX created from $IMAGE"
trap '[ "$KEEP" = 1 ] || timeout 60 "$OPENSHELL_BIN" sandbox delete "$SANDBOX" >/dev/null 2>&1 || true' EXIT

# 3. Upload + extract. Bounded warmup probe: with a STABLE gateway,
# transfers work immediately; the earlier "needs 5 minutes to warm up"
# mirage was the gateway being SIGTERM'd mid-run by the driving shell's
# process group (a killed gateway wedges in-flight sandboxes/transfers).
# The probe stays as a cheap safety net.
echo "rung2: waiting for the sandbox transfer path to warm up (up to ~10 min)"
echo "rung2-probe" > "$OUT/probe.txt"
WARM=0
for _ in $(seq 1 60); do
	if timeout 15 "$OPENSHELL_BIN" sandbox upload "$SANDBOX" "$OUT/probe.txt" /tmp/.rung2-probe >/dev/null 2>&1; then
		WARM=1
		break
	fi
	sleep 10
done
[ "$WARM" = 1 ] || die "sandbox transfer path never warmed up (~10 min)"
echo "rung2: transfer path warm"

"$OPENSHELL_BIN" sandbox upload "$SANDBOX" "$TAR" /tmp/workspace.tar.gz >/dev/null
"$OPENSHELL_BIN" sandbox exec -n "$SANDBOX" -- mkdir -p "/sandbox/$PLATFORM-repo" >/dev/null
"$OPENSHELL_BIN" sandbox exec -n "$SANDBOX" -- tar -xzf /tmp/workspace.tar.gz -C "/sandbox/$PLATFORM-repo" >/dev/null
echo "rung2: workspace extracted to /sandbox/$PLATFORM-repo"

# 4. Run the workflow (offline children; the plugin path is the in-repo
#    copy — fullsend's runner-owned upload path is rung 3).
INPUT=$(python3 - "$PLATFORM" "$COMPONENTS" << 'EOF'
import json, sys
platform, components = sys.argv[1], sys.argv[2]
d = {"platform": platform, "stages": ["analyze", "generate", "collect", "platform"], "concurrency": 2}
if components: d["components"] = [c.strip() for c in components.split(",") if c.strip()]
print(json.dumps(d))
EOF
)
echo "rung2: input $INPUT"
REPO="/sandbox/$PLATFORM-repo"
set +e
"$OPENSHELL_BIN" sandbox exec -n "$SANDBOX" --workdir "$REPO" \
	--env WORKFLOW_COMMAND=run-arch-context \
	--env "WORKFLOW_INPUT=$INPUT" \
	--env "WORKFLOW_INPUT_FILE=architecture/$PLATFORM/components.json" \
	-- pi --print --mode json --no-approve --no-extensions --no-prompt-templates --no-themes \
		--session-dir /tmp/archctx-session \
		-e "$REPO/.fullsend/plugins/workflow-engine" \
		--model workflow-engine/v1 --tools workflow \
		"Run the architecture context workflow" > "$OUT/stdout.jsonl" 2> "$OUT/stderr.txt"
RC=$?
set -e
echo "rung2: pi exit $RC (stderr tail: $(tail -1 "$OUT/stderr.txt" | cut -c1-100))"

# 5. Pull the artifacts back (exec-tar-to-stdout — same reasoning as
# the upload path: the SSH-based `sandbox download` is flaky here).
"$OPENSHELL_BIN" sandbox exec -n "$SANDBOX" -- sh -c \
	"tar -czf - -C '$REPO' workflow-runs 'architecture/$PLATFORM'" > "$OUT/artifacts.tar.gz" 2>/dev/null \
	&& tar -xzf "$OUT/artifacts.tar.gz" -C "$OUT"

# 6. Assert the contract.
python3 - "$OUT" "$PLATFORM" "$RC" << 'EOF'
import json, sys
from pathlib import Path

out, platform, rc = Path(sys.argv[1]), sys.argv[2], int(sys.argv[3])
errors = []

if rc != 0:
    errors.append(f"pi exited {rc}")

events = []
for line in (out / "stdout.jsonl").read_text().splitlines():
    line = line.strip()
    if line.startswith("{"):
        try: events.append(json.loads(line))
        except ValueError: pass

ends = [e for e in events if e.get("type") == "tool_execution_end" and e.get("toolName") == "workflow"]
if len(ends) != 1 or ends[0].get("isError"):
    errors.append(f"expected one successful tool_execution_end, got {[bool(e.get('isError')) for e in ends]}")
if not any(e.get("type") == "agent_settled" for e in events):
    errors.append("no agent_settled")
finals = [e for e in events if e.get("type") == "message_end"
          and e.get("message", {}).get("role") == "assistant"
          and e["message"].get("stopReason") == "stop"]
text = "".join(b.get("text", "") for b in finals[0]["message"]["content"] if b.get("type") == "text") if finals else ""
if "workflow complete" not in text:
    errors.append(f"final message not a completion: {text[:120]!r}")

runs = sorted((out / "workflow-runs").glob("*/"), key=lambda p: p.stat().st_mtime) if (out / "workflow-runs").exists() else []
if not runs:
    errors.append("no workflow-runs downloaded")
else:
    run = runs[-1]
    art = json.loads((run / "artifact.json").read_text())
    if not art.get("complete") or art.get("analyzed") != art.get("expected"):
        errors.append(f"artifact incomplete: {art.get('summary')}")
    recs = [json.loads(l) for l in (run / "usage.jsonl").read_text().splitlines() if l.strip()]
    if len(recs) != art["analyzed"] + 1:
        errors.append(f"usage.jsonl has {len(recs)} records, expected {art['analyzed'] + 1}")
    if any(r.get("model") != "test-child/echo" for r in recs):
        errors.append("usage records not on test-child/echo")

arch = out / "architecture" / platform
plat = (arch / "PLATFORM.md").read_text() if (arch / "PLATFORM.md").exists() else ""
if not plat.startswith(f"# Platform Architecture — {platform}"):
    errors.append("published PLATFORM.md missing or wrong title")
for section in ("## Platform Overview", "## Analyzer Inventory"):
    if section not in plat:
        errors.append(f"PLATFORM.md missing {section!r}")
expected_keys = sorted(f"{c}.md" for c in art.get("components", []))
actual_keys = sorted(p.name for p in arch.glob("*.md") if p.name != "PLATFORM.md")
if actual_keys != expected_keys:
    errors.append(f"published component docs mismatch: {actual_keys} != {expected_keys}")

print(f"artifact: {art.get('summary') if runs else 'n/a'}")
print("usage:   ", f"{len(recs)} records" if runs else "n/a")
for err in errors:
    print(f"  - {err}")
print("RUNG2-CHECK:", "PASS" if not errors else "FAIL")
sys.exit(1 if errors else 0)
EOF
