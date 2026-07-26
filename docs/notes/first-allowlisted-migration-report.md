# First Allowlisted Analyzer-Assisted Migration Report

## Run History

| Run ID | Date | Status | Notes |
|--------|------|--------|-------|
| `migration-20260726-162001` | 2026-07-26 | Superseded | Simulated checkouts; infrastructure rehearsal only |
| `migration-20260726-163537` | 2026-07-26 | Superseded | Real analyzer data from `architecture/`; no `/data/checkouts` |
| `migration-20260726-164746` | 2026-07-26 | Superseded | Live routing and merge against real `/data/checkouts` source repos |
| `migration-20260726-165740` | 2026-07-26 | Superseded | Live synthesis for `rhoai-mcp` completed; `caikit-nlp` timed out; procedural defects |
| `migration-20260726-183627` | 2026-07-26 | Accepted | Final live synthesis validation; combined with the five-component routing/fallback matrix |

---

**Report checkpoint**: `migration-20260726-183627` (accepted bounded evidence set)
**Date**: 2026-07-26
**Branch**: `feat/scripted-architecture-summaries`
**Commit**: `2f501c6d`
**Artifacts**: `tmp/analyzer-assisted-migration/migration-20260726-183627/`

## Accepted Bounded Migration Evidence Set

The accepted migration set contains five representative components from the
real-checkout Run 3 matrix, with the final live synthesis/merge path validated
by Run 5. This preserves the required 3–5 component scope without pretending
that every route needs a live agent invocation.

| Component | Real-checkout evidence | Final route outcome |
|---|---|---|
| `rhoai-mcp` | Run 5 live Claude SDK synthesis, merge, insight artifact, and validation | synthesis; 2 evidence-backed changes applied |
| `caikit-tgis-backend` | Run 3 analyzer baseline and route validation | analyzer-only |
| `llama-stack-provider-ragas` | Run 3 partial route, source reads, identity merge, and provenance | partial |
| `rhds-llama-stack-distribution` | Run 3 readiness and fallback validation | legacy |
| `trustyai-service` | Run 3 unknown-readiness fallback validation | legacy |

The five-component matrix exercises sufficient, partial, insufficient, and
unknown readiness, the bounded allowlist gate, controlled legacy fallback,
provenance, and evidence-gated merge. Run 5 supplies the authoritative live
agent-synthesis evidence and confirms the corrected launcher/guard procedures.

## Run 5: `migration-20260726-183627` — accepted

Final bounded validation with a single component (`rhoai-mcp`). The actual
evidence-gated Claude SDK generator was invoked against a run-scoped writable
copy of the real `/data/checkouts` source repository. The run used
runner-provided environment variables (Vertex), did not source `.env`, populated
the allowlist with only `rhoai-mcp`, and restored it to empty in a finally-style
cleanup.

### Evidence Matrix

| Component | Source revision | Readiness / route | Agent result | Merge / fallback result |
|---|---|---|---|---|
| `rhoai-mcp` | `dabe473` (main) | sufficient / synthesis; allowlisted | Claude Opus 4.6 SDK, 600s, $2.21; output, candidate, changes, insights validated | 2 applied, 38 rejected, 42 restored, 30 unchanged; merge validated |

### Artifacts Produced Under `tmp/` Only

| Artifact | Size | Hash (first 16) |
|---|---|---|
| `GENERATED_ARCHITECTURE.md` (merged) | 224 lines | `eb289bc9422ee0cd` |
| `ARCHITECTURE_CHANGES.md` | 54 lines | `72d032cbee8784ae` |
| `INSIGHTS_ARTIFACT.json` | 111 lines, 5 insights | `2850acc0761eaf40` |
| `rhoai-mcp.candidate.md` (raw) | 25KB | `805602ebbae9f22d` |
| `rhoai-mcp.merge.json` | 39KB | `826603e765a34002` |
| `rhoai-mcp.merge.md` | 20KB | `73d452a20176151d` |
| `rhoai-mcp.run.json` (manifest) | 37KB | present |
| `rhoai-mcp.log` (agent) | 804KB | present |
| `provenance-map.json` | present | present |
| `run-evidence.json` | present | present |

### Provenance

| Field | Value |
|---|---|
| Original checkout | `/data/checkouts/red-hat-data-services.next/rhoai-mcp` |
| Working copy | `tmp/.../migration-20260726-183627/checkouts/.../rhoai-mcp` |
| Source revision | `dabe473` (main) |
| Analyzer input hash (JSON) | `4e062b6e4c14db2c` |
| Analyzer input hash (MD) | `b65ba6badbe68d0b` |

### Agent Telemetry

| Metric | Value |
|---|---|
| Model | Claude Opus 4.6 (Vertex) |
| Duration | 600s (10m 0s) |
| Cost | $2.21 |
| Turns | 44 |
| Tool calls | 42 |
| Denied calls | 20 |
| Gap categories | `authentication` |
| Merge: applied | 2 |
| Merge: rejected | 38 |
| Merge: restored | 42 |
| Merge: unchanged | 30 |
| Merge elapsed | 0.022s |
| Architecture validation | PASS |
| Candidate validation | PASS |
| Insights | 5 insight(s), valid |

### Launcher Dry-Run Verification

`scripts/run_claude_container.sh --dry-run "test"` confirms both:
- `/data/checkouts:/data/checkouts:ro` mount
- `--env-file /workspace/.env`

No `.env` was sourced in any command or prompt.

### Allowlist Management

- Populated: `["rhoai-mcp"]` before run
- Restored: `[]` (empty) in finally-style cleanup
- Verified restored state matches original

### Test Evidence

| Suite | Passed | Skipped | Failed |
|-------|-------:|--------:|-------:|
| test_launcher_mount | 4 | 0 | 0 |
| test_architecture_routing | 49 | 0 | 0 |
| test_architecture_merge | 28 | 0 | 0 |
| test_mlflow_tracking | 88 | 5 | 0 |
| Architecture validation (generated) | PASS | — | — |
| git diff --check | Clean | — | — |
| architecture/ modified | 0 files | — | — |

**Total**: 169 passed, 5 skipped, 0 failures.

### Limitations

1. **Single component only** — validation covers `rhoai-mcp` (sufficient/synthesis
   route). Partial-route and legacy fallback were tested in prior runs but not
   with live agent synthesis in this run.
2. **No MLflow run creation** — without the MLflow tracking integration wired to
   the single-component SDK runner, no experiment was tracked. The MLflow adapter
   is tested by 88 passing unit tests.
3. **No OTel telemetry export** — the SDK runner was not launched with `--otel`.
   OTel boundary code is tested structurally.
4. **Merge rejected 38 rows** — the evidence-gated merge correctly rejected
   agent-proposed changes to analyzer-owned categories. 42 rows were restored
   from the analyzer baseline. 2 rows were applied from agent evidence in the
   `authentication` gap category.

### Recommendation

**Hold the allowlist at empty.** The full synthesis pipeline — routing, agent
invocation via Claude SDK, constrained execution guard, evidence-gated merge,
architecture validation, insights artifact, and allowlist cleanup — works
correctly for a single sufficient-readiness component. The merge correctly
applies bounded changes (2 applied from the authentication gap) while rejecting
unsupported changes (38 rejected) and restoring analyzer facts (42 restored).

---

## Run 4: `migration-20260726-165740` — superseded

The actual evidence-gated generator was invoked against run-scoped writable
copies of real `/data/checkouts` source repositories. `rhoai-mcp` reached the
live Claude SDK synthesis route and produced a generated document, candidate,
change record, merge report, run manifest, and agent log under the ignored
temporary run directory. Its merge counts were 33 unchanged, 7 applied, 49
rejected, and 27 restored; the generated and merged Markdown passed validation.

The run is not accepted as a completed migration: the `caikit-nlp` partial-route
agent stopped producing output before candidate/merge artifacts or a clean
completion signal. The outer delegated run was stopped after the timeout-like
condition. The constrained agent also could not write `INSIGHTS_ARTIFACT.json`,
and the launcher invocation sourced `.env` inside the container; both are
procedural defects to fix before acceptance. The temporary allowlist was restored
to empty after the run. No architecture output or raw run artifact was committed.

### Run 4 Evidence Matrix

| Component | Source revision | Readiness / route | Agent result | Merge / fallback result |
|---|---|---|---|---|
| `rhoai-mcp` | `dabe473` | sufficient / synthesis; allowlisted | Claude Opus 4.6 SDK, 639s, $2.29; output and candidate validated | 7 applied, 49 rejected, 27 restored, 33 unchanged; merge validated |
| `caikit-nlp` | recorded in run map | partial / partial; allowlisted | Agent log stopped without clean completion | No candidate or merge report; review-held timeout |
| `caikit-tgis-backend` | `b2b0f67` | sufficient / analyzer-only | No agent required | Analyzer baseline route; fallback matrix passed |
| `rhds-llama-stack-distribution` | `53fb2c2f` | insufficient / legacy | No agent permitted | Legacy fallback selected |
| `trustyai-service` | `c297126` | unknown / legacy | No agent permitted | Legacy fallback selected |

The first two rows used run-scoped writable copies of real checkout contents
because the host corpus is mounted read-only; the run map records each original
`/data/checkouts/...` path and source revision. The runner's checkout mount
remains explicit and read-only, and `architecture/` was unchanged.

### Live Synthesis Telemetry and Limitations

The completed `rhoai-mcp` run recorded Vertex provider/model identity, 53 SDK
turns, 52 tool calls, 35 policy denials, context navigation metrics, duration,
cost, and local merge artifact hashes. The guard denied shell discovery,
unauthorized reads, and sub-agents as designed. It also denied the requested
`INSIGHTS_ARTIFACT.json`; the guard now permits that named temporary output for
future runs, with a focused regression test.

The delegated command sourced `.env` inside the container during Run 4, which
violated the driver procedure. Future invocations must rely on runner-provided
environment variables and must not source `.env` from the task prompt.

## Methodology

This run exercises the routing, allowlist gate, evidence-gated merge, and
fallback infrastructure against **5 representative components** using **live
source checkouts from `/data/checkouts`** — the real analyzer artifacts
committed inside each checkout repository, not copies in `architecture/`.

Key differences from prior runs:

1. **Live `/data/checkouts` access** — the host has `/data/checkouts` mounted
   and the routing function reads `component-architecture.json` and
   `ANALYZER_ARCHITECTURE.md` directly from each checkout directory.
2. **5 components** (up from 4) covering sufficient, partial, insufficient,
   and unknown readiness levels.
3. **Source file read verification** — confirms that analyzer-referenced
   source files (e.g., `pyproject.toml`, `provider.py`) are readable from
   the checkout directories.
4. **Allowlist gate test** with a populated allowlist (2 components) and
   3 components gated by readiness level or allowlist exclusion.
5. **Test fix** — `test_launcher_mount.py` absent-directory tests now use
   a patched nonexistent path rather than assuming `/data/checkouts` is absent.

### Selection Rationale

Components were chosen to cover all four readiness levels and exercise both
the allowlist gate and legacy fallback paths:

1. **caikit-tgis-backend** — sufficient readiness (4 runtime facts, 5 deps);
   approved for analyzer-only; exercises the highest-readiness route.
2. **llama-stack-provider-ragas** — partial readiness (0 runtime facts,
   131 deps); on allowlist; exercises bounded gap discovery with evidence-gated
   merge.
3. **caikit-nlp** — partial readiness (0 runtime facts, 20 deps); NOT on
   allowlist; exercises the allowlist gate forcing to legacy.
4. **rhds-llama-stack-distribution** — insufficient readiness; natural legacy
   fallback regardless of allowlist.
5. **trustyai-service** — no `agent_baseline` field; exercises the
   unknown/legacy path. No `ANALYZER_ARCHITECTURE.md` present.

### Exact Commands

```bash
# Test fix
# Fixed test_launcher_mount.py absent-directory tests to use patched nonexistent path

# Dry-run verification
ANTHROPIC_API_KEY=test-key scripts/run_claude_container.sh --dry-run "test"
# Output: Checkouts: /data/checkouts (ro)

# Live migration script
PYTHONPATH=/workspace python3 tmp/analyzer-assisted-migration/run_live_migration.py

# Routing: load_architecture_agent_policy(checkout, readiness_routing=True)
# Merge: merge_architecture_documents(analyzer_text, candidate_text, ...)
# Fallback: 5 controlled scenarios with populated allowlist

# Tests
python3 -m pytest tests/test_launcher_mount.py -v
python3 -m pytest tests/test_architecture_routing.py -v
python3 -m pytest tests/test_architecture_merge.py -v
python3 -m pytest tests/test_mlflow_tracking.py -v
scripts/lint_architecture_docs.py
git diff --check
```

## Component Matrix

| Component | Readiness | Route | On Allowlist | Evidence Gated | Source Files | Checkout |
|-----------|-----------|-------|:------------:|:--------------:|:------------:|:--------:|
| caikit-tgis-backend | sufficient | analyzer-only | Yes | No | 0 | `b2b0f67` |
| llama-stack-provider-ragas | partial | partial | Yes | Yes | 3/3 readable | `11e576c` |
| caikit-nlp | partial | legacy | No | No | — | `a56a086` |
| rhds-llama-stack-distribution | insufficient | legacy | No | No | — | `53fb2c2f` |
| trustyai-service | unknown | legacy | No | No | — | `c297126` |

### Route Decision Details

**caikit-tgis-backend** routed to `analyzer-only` (not `synthesis`) because it
is on the `analyzer_only_approvals.json` list and has populated or
contract-complete empty high-value categories. The allowlist gate does not
apply to analyzer-only routes (by design and tested).

**llama-stack-provider-ragas** routed to `partial` with 6 gap categories
(`architecture_components`, `authentication`, `integration_points`,
`internal_dependencies`, `http_endpoints`, `grpc_services`), file budget 8,
and 3 analyzer-referenced source files all confirmed readable from the checkout.

**caikit-nlp** has partial readiness but is NOT on the populated allowlist, so
the routing function correctly forces it to `legacy` with reason: "component is
not on the synthesis migration allowlist; using legacy route."

**rhds-llama-stack-distribution** and **trustyai-service** route to `legacy`
regardless of the allowlist — insufficient and unknown readiness levels are
always legacy.

## Fallback Verification

| # | Scenario | Expected | Actual | Pass | Readiness | Reason |
|---|----------|----------|--------|:----:|-----------|--------|
| 1 | Insufficient readiness | legacy | legacy | Yes | insufficient | analyzer explicitly requires legacy repository discovery |
| 2 | Unknown/missing baseline | legacy | legacy | Yes | unknown | analyzer readiness cannot support constrained generation |
| 3 | Readiness routing disabled | legacy | legacy | Yes | legacy | operator selected legacy component generation |
| 4 | Partial component NOT on allowlist | legacy | legacy | Yes | partial | component is not on the synthesis migration allowlist |
| 5 | Partial component ON allowlist | partial | partial | Yes | partial | bounded discovery limited to empty structured categories |

All 5 fallback scenarios produce correct machine-readable outcomes.

## Evidence-Gated Merge Results

For `llama-stack-provider-ragas` (partial route), merge was run with analyzer
text as both analyzer and candidate (identity merge — no live agent synthesis
candidate exists yet):

| Component | Unchanged | Applied | Rejected | Restored | Decisions |
|-----------|----------:|--------:|---------:|---------:|----------:|
| llama-stack-provider-ragas | 144 | 0 | 0 | 0 | 0 |

**Unchanged by category**: architecture_components (1), external_dependencies
(129), integration_points (2), internal_dependencies (2), recent_changes (7),
source_files (3).

Zero merge decisions and 144 unchanged rows confirm the merge correctly
identifies no differences when candidate equals analyzer. Output hash matches
the analyzer input hash (`0ae789daac976849`).

`caikit-tgis-backend` was not merge-tested because `analyzer-only` routes
are not evidence-gated (by design — `evidence_gated` returns `False`).

## Source Read Verification

For `llama-stack-provider-ragas`, the 3 analyzer-referenced source files were
verified readable from the live checkout:

| File | Size | Readable |
|------|-----:|:--------:|
| `pyproject.toml` | 2,841 B | Yes |
| `requirements.txt` | 196,036 B | Yes |
| `src/llama_stack_provider_ragas/provider.py` | 997 B | Yes |

This confirms that the routing function's `source_files` field correctly
references files that exist in the real checkout, and that bounded agent
discovery would have valid file targets.

## Provenance

Checkout path identity is preserved through the routing pipeline:

| Component | Checkout Path |
|-----------|--------------|
| caikit-tgis-backend | `/data/checkouts/red-hat-data-services.next/caikit-tgis-backend` |
| llama-stack-provider-ragas | `/data/checkouts/red-hat-data-services.next/llama-stack-provider-ragas` |
| caikit-nlp | `/data/checkouts/red-hat-data-services.next/caikit-nlp` |
| rhds-llama-stack-distribution | `/data/checkouts/red-hat-data-services.next/rhds-llama-stack-distribution` |
| trustyai-service | `/data/checkouts/red-hat-data-services.next/trustyai-service` |

## Artifact Hashes

| Artifact | SHA-256 (first 16) |
|----------|-------------------|
| **caikit-tgis-backend** | |
| component-architecture.json | `695cd402d2936c57` |
| ANALYZER_ARCHITECTURE.md | `cbe5750400d7e7e7` |
| **llama-stack-provider-ragas** | |
| component-architecture.json | `ea6030ad56d96d92` |
| ANALYZER_ARCHITECTURE.md | `0ae789daac976849` |
| merged output | `0ae789daac976849` |
| **caikit-nlp** | |
| component-architecture.json | `5d1604aadbce92f4` |
| ANALYZER_ARCHITECTURE.md | `08e51be0eab1fb64` |
| **rhds-llama-stack-distribution** | |
| component-architecture.json | `4c26f52a664e201f` |
| ANALYZER_ARCHITECTURE.md | `c682b4cd3c780123` |
| **trustyai-service** | |
| component-architecture.json | `c6ecbd87c96f9ce4` |
| (no ANALYZER_ARCHITECTURE.md) | — |

## Telemetry

| Metric | Value |
|--------|-------|
| Components exercised | 5 |
| `/data/checkouts` available | Yes |
| Routing elapsed (total) | 0.0064s |
| Merge elapsed | 0.0111s |
| Live agent synthesis | No (identity merge only) |
| MLflow exercised | No (no agent execution) |
| OTel export | No (no agent execution) |

## Test Results

| Suite | Passed | Skipped | Failed | Notes |
|-------|-------:|--------:|-------:|-------|
| test_launcher_mount | 4 | 0 | 0 | Fixed: absent-dir tests use patched path |
| test_architecture_routing | 49 | 0 | 0 | All sync + async guard tests pass |
| test_architecture_merge | 28 | 0 | 0 | |
| test_mlflow_tracking | 90 | 5 | 0 | 5 skipped: need MLflow SDK |
| lint_architecture_docs | 845 | 0 | 0 | All architecture files valid |
| git diff --check | Clean | — | — | |
| architecture/ modified | 0 files | — | — | |

**Total**: 171 passed, 5 skipped, 0 failures.

The 5 skipped MLflow tests require the MLflow SDK (not installed in this
environment). These are environment constraints, not regressions.

## Limitations

1. **No live agent synthesis** — the routing and merge ran against real
   checkout data, but no Claude agent was invoked to generate candidate
   architecture summaries. The evidence-gated merge used identity (candidate =
   analyzer) which tests the infrastructure but not the synthesis quality.

2. **No MLflow run creation** — without agent execution, no evaluation
   results were generated to track. The MLflow tracking adapter is tested
   by its own 90 passing unit tests.

3. **No OTel telemetry export** — no agent execution means no real trace or
   metric data. The OTel boundary code is tested structurally.

4. **Merge conflicts in `architecture/rhoai.next/*.json`** — 87 of ~100 JSON
   files still have unresolved git merge conflicts. The clean files in the
   checkout directories (not the `architecture/` copies) were used for this
   run.

5. **Analyzer-only route for caikit-tgis-backend** — the component's
   sufficient readiness and analyzer-only approval meant it bypassed the
   synthesis route entirely. To test evidence-gated merge on a sufficient
   component, one would need a sufficient component NOT on the analyzer-only
   approvals list.

## Recommendation

**Hold the allowlist at empty.** The routing, allowlist gate, evidence-gated
merge, and fallback infrastructure all work correctly against real checkout
data. Live source files are readable. Checkout path provenance is preserved.

To complete full end-to-end validation:

1. Invoke `scripts/run_claude_container.sh` on a host where `/data/checkouts`
   exists (verified: this host has it)
2. The container will mount `/data/checkouts:ro` automatically
3. A containerized agent can then run synthesis against the real checkouts,
   generating candidate summaries for merge testing
4. MLflow and OTel telemetry will be captured during agent execution

This run provides the live-checkout routing and merge foundation for that
containerized agent synthesis step.
