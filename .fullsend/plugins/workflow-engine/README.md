# workflow-engine plugin (architecture-context port)

A deterministic workflow engine as a pi provider (`workflow-engine/v1`,
zero inference on the parent) whose `workflow` tool dispatches to
workflow modules. First-class citizen: `workflows/arch-context.mjs` —
the architecture-context pipeline port (analyzer-baseline validation →
per-component analysis fan-out → platform synthesis), composed from
`lib/primitives.mjs`.

Layout:

| Path | Purpose |
|----|----|
| `index.js` | Provider + `workflow` tool (thin module dispatcher) — verbatim from the breadboard PoC |
| `lib/host.js` | `agent()`/`parallel()`/`pipeline()` (schema-validated, journaled) — verbatim from the PoC |
| `lib/primitives.mjs` | Workflow-level primitives: `validateInput`, `fanout` (with retries), `assertComplete`, `writeResults`, `writeArtifact` |
| `workflows/arch-context.mjs` | The port: 3 swappable data blocks (schemas, prompts, renderers) over the primitives |
| `workflows/org-scan.mjs` | Refactored onto the primitives (second consumer / portability proof) |
| `test-child/index.js` | Offline scripted child provider (`test-child/echo`) + deliberate-failure fixtures |
| `check-archctx.py` | Rung-1 check: contract, determinism, negatives, recovery |

## Running it yourself

The easy way — `scripts/archctx.sh` (local convenience only; fullsend
invokes pi directly):

```bash
scripts/archctx.sh prepare                     # host-side P0: fetch + analyze + manifest
scripts/archctx.sh run                         # offline workflow (no inference)
scripts/archctx.sh run --real                  # real inference (GLM via EnMaaS)
scripts/archctx.sh run --real --components jira-emulator,entra-id-emulator
scripts/archctx.sh run --stages analyze        # validation only, no inference
scripts/archctx.sh check --runs 3              # full rung-1 verification suite
```

Real mode reads the provider key from `~/.pi/agent/auth.json`
(provider = first segment of the model spec) and passes it env-only.
Offline runs that publish will **overwrite real markdown with fixture
content** — the wrapper warns; re-run `--real` or `git checkout` to
restore.

The long way (what the wrapper does), for reference — everything runs
from the **architecture-context repo root** (work items' `repoDir`
values are repo-root-relative):

```bash
cd <repo-root>   # e.g. .../2026_10_12_pi_arch_context/checkouts/architecture-context
```

### 1. Offline (no credentials, no inference)

One run of the workflow with scripted children:

```bash
rm -rf /tmp/run && mkdir -p /tmp/run/home /tmp/run/session
env HOME=/tmp/run/home \
  WORKFLOW_COMMAND=run-arch-context \
  WORKFLOW_INPUT='{"platform":"breadboard","stages":["analyze","generate","collect","platform"],"concurrency":2}' \
  WORKFLOW_INPUT_FILE="$PWD/architecture/breadboard/components.json" \
  pi --print --mode json --no-approve --no-extensions --no-prompt-templates --no-themes \
     --session-dir /tmp/run/session \
     -e "$PWD/.fullsend/plugins/workflow-engine" \
     --model workflow-engine/v1 --tools workflow \
     "Run the architecture context workflow"
```

The full rung-1 check suite (3× determinism + negatives + recovery):

```bash
python3 .fullsend/plugins/workflow-engine/check-archctx.py --runs 3 --out /tmp/check
```

### 2. Real inference (children on a real model)

Children are hermetic (own HOME, no `PI_*`), so they need a provider
config. The workflow that authored this port used the EnMaaS GLM
gateway — same provider as the dev sessions:

```bash
# Derived child models.json: shared config + $ENV-interpolated apiKey
# (no secret on disk). One-time setup:
python3 - << 'EOF'
import json, os
src = json.load(open(os.path.expanduser('~/.pi/agent/models.json')))
for prov in src['providers'].values():
    prov['apiKey'] = '$ENMAAS_API_KEY'
json.dump(src, open('/tmp/archctx-models.json', 'w'), indent=1)
EOF

rm -rf /tmp/real && mkdir -p /tmp/real/home /tmp/real/session
ENMAAS_KEY=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.pi/agent/auth.json')))['enmaas-glm-5-3']['key'])") \
env HOME=/tmp/real/home \
  WORKFLOW_COMMAND=run-arch-context \
  WORKFLOW_INPUT='{"platform":"breadboard","concurrency":2,"timeoutMs":600000}' \
  WORKFLOW_INPUT_FILE="$PWD/architecture/breadboard/components.json" \
  WORKFLOW_CHILD_MODEL='enmaas-glm-5-3/rits/zai-org/glm-5-3' \
  WORKFLOW_CHILD_MODELS_JSON=/tmp/archctx-models.json \
  WORKFLOW_CHILD_ENV="ENMAAS_API_KEY=$ENMAAS_KEY" \
  pi --print --mode json --no-approve --no-extensions --no-prompt-templates --no-themes \
     --session-dir /tmp/real/session \
     -e "$PWD/.fullsend/plugins/workflow-engine" \
     --model workflow-engine/v1 --tools workflow \
     "Run the architecture context workflow"
```

The key is passed env-only (extracted from auth.json into a shell
variable); it never lands in a file. Swap in any provider by changing
`WORKFLOW_CHILD_MODEL` + the models.json.

### 3. Where everything lands

| Artifact | Path |
|----|----|
| Published component docs | `architecture/breadboard/<component>.md` + `PLATFORM.md` |
| Machine-readable results | `workflow-runs/<runId>/results/<component>.json` |
| Aggregate artifact | `workflow-runs/<runId>/artifact.json` (incl. `platformSummary`, `inventory`, `notes`) |
| Usage records | `workflow-runs/<runId>/usage.jsonl` (one per child, item order; fullsend contract shape) |
| Child sessions | `workflow-runs/<runId>/child-sessions/` (post-mortem: `type: message` events) |
| Journal | `workflow-runs/<runId>/journal.jsonl` (content-addressed, per-run) |

`runId` = `sha256(command + input).slice(0,8)` — same input reuses (and
wipes) the same run dir. Generated `.md` under
`architecture/breadboard/` is gitignored; commit real-model output
deliberately.

### 4. Knobs (CLI parity)

All through `WORKFLOW_INPUT`:

```json
{
  "platform": "breadboard",
  "stages": ["analyze", "generate", "collect", "platform"],
  "concurrency": 2,
  "timeoutMs": 600000,
  "components": ["jira-emulator", "entra-id-emulator"],
  "architectureDir": "architecture"
}
```

`fetch`/`parse` are host-side (P0: `main.py fetch` /
`main.py static-analysis`); `diagrams` is a non-goal; `collect`/
`platform` without `generate` fails loudly (results must be in memory).

**Durable resume (P5)**: set `WORKFLOW_KEEP_RUNS=1` — an interrupted
run's journal (content-addressed, per runDir) then replays completed
children on re-run, so only uncompleted children re-execute and
re-spend. Verified with real GLM children: kill after 2 of 3 journaled,
resume re-spawned only the in-flight child + platform synthesis.

## Verified (2026-10-21)

- Offline rung 1: 3/3 contract runs, byte-identical normalized event
  streams (settled scope), byte-identical published artifacts, 4/4
  negatives (stage gating, unknown component, malformed output,
  wrong-key output), flaky-child retry recovery — `RUNG1-CHECK: PASS`
  on pi 1.3.0.
- Real inference (enmaas-glm-5-3/rits/zai-org/glm-5-3): full
  5-component platform — 7 usage records (one corrective retry),
  182.5k input / 20k output tokens, schema-conformant results,
  published docs are template-shaped and source-accurate.
- Portability (plan req 9): `org-scan.mjs` and `arch-context.mjs`
  compose the same five primitives.
- Rung 2 (OpenShell + podman) and rung 3 (fullsend run): exit 0, full
  event contract, usage folded into metrics.json with oracle
  cross-check (see scripts/rung2-openshell.sh, scripts/rung3-fullsend.sh).
- Durable resume: `resume durable-kill-replay` case in check-archctx.py
  (offline) + the real-children demo above.

## Findings recorded during implementation

- Models fence their JSON and under-escape long outputs; the
  `fanout` retry (error context + full contract per attempt) is the
  structural fix. When a model fails identically across retries,
  suspect the schema, not the model.
- Determinism scope: `tool_execution_update` progress events are
  arrival-ordered under concurrency and excluded from the comparison;
  the settled stream is byte-identical.
- Machine-extracted facts (analyzer inventory, service wiring) are
  rendered deterministically — never left to model discretion.
