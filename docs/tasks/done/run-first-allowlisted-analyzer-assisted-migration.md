# Task: Run the First Allowlisted Analyzer-Assisted Migration

## Goal

Run and validate the first real provisional analyzer-assisted summary migration
for a small representative component set, then checkpoint the accepted
migration evidence without retiring the legacy route.

## Fixed boundaries

- Select a small, representative set of 3–5 components from the available
  architecture corpus; record the exact components and selection rationale.
- Populate or override the operator allowlist only for this bounded run; do not
  silently broaden it.
- Use the existing synthesis/partial routing, evidence-gated merge, analyzer
  baseline, and legacy fallback behavior.
- Write generated summaries, merge reports, route reports, telemetry, and logs
  only under an ignored temporary run directory such as
  `tmp/analyzer-assisted-migration/<run-id>/`.
- Use local context telemetry and local file-backed MLflow where tracking is
  exercised; do not create external tracking or collector state.
- The task container must expose the host checkout corpus at the same absolute
  path (`/data/checkouts`) when that directory exists. The launcher must make
  this mount explicit and preserve the checkout path identities in provenance.

## Acceptance criteria

- The task records the selected components, source/analyzer revisions, model,
  allowlist contents, exact commands, run duration, and local artifact paths.
- Every selected component has a route decision, generated output status,
  provenance, merge/validation result, telemetry, and explicit fallback result
  if applicable.
- Analyzer-owned facts, reviewed overlays, explicit unknowns, and evidence
  boundaries are preserved; agent insights remain non-authoritative.
- Temporary outputs pass the architecture, merge, schema, and relevant route
  validators. Compare each migrated summary with its analyzer baseline and
  record any accepted evidence-backed changes.
- Exercise at least one controlled fallback scenario and verify its
  machine-readable outcome (`legacy` or `analyzer-baseline` as appropriate).
- Produce a committed human-readable Markdown migration report covering
  methodology, component matrix, route outcomes, summary/merge findings,
  telemetry, limitations, and recommendation to expand or hold the allowlist.
- Run focused tests and `git diff --check`; do not modify committed
  `architecture/` output, run a full-corpus/paid benchmark, fill human labels,
  retire legacy code, or commit raw results/dumps.

## Review boundary

This task is evidence for provisional expansion only. It does not establish
semantic quality, human approval, production rollout, or legacy retirement.

## Execution Record

### Run 3: `migration-20260726-164746` (current)

- **Run ID**: `migration-20260726-164746`
- **Commit**: `2f501c6d` (feat/scripted-architecture-summaries)
- **Date**: 2026-07-26
- **Run artifacts**: `tmp/analyzer-assisted-migration/migration-20260726-164746/`
- **Migration report**: `docs/notes/first-allowlisted-migration-report.md`

#### Test Fix

Fixed `tests/test_launcher_mount.py` absent-directory tests to use
`_run_patched_script("/tmp/.nonexistent-checkouts-path-for-test")` instead of
`_dry_run_output()`, so tests no longer assume `/data/checkouts` is absent on
the host.

#### Dry-Run Verification

`scripts/run_claude_container.sh --dry-run` confirms:
```
Checkouts: /data/checkouts (ro)
--volume /data/checkouts:/data/checkouts:ro
```

#### Selected Components

| Component | Readiness | Route | On Allowlist | Rationale |
|-----------|-----------|-------|:------------:|-----------|
| caikit-tgis-backend | sufficient | analyzer-only | Yes | 4 runtime facts; approved analyzer-only; tests highest-readiness route |
| llama-stack-provider-ragas | partial | partial | Yes | 131 deps; bounded gap discovery with evidence-gated merge |
| caikit-nlp | partial | legacy | No | Partial but off allowlist; tests allowlist gate |
| rhds-llama-stack-distribution | insufficient | legacy | No | Natural fallback; analyzer self-declares insufficient |
| trustyai-service | unknown | legacy | No | No agent_baseline; exercises unknown path |

#### Data Sources

Used real analyzer JSON and ANALYZER_ARCHITECTURE.md from live
`/data/checkouts/red-hat-data-services.next/` checkouts — the actual
committed repository artifacts, not copies from `architecture/`.

#### What Was Exercised

- Routing logic against 5 components with real checkout-resident analyzer data
- Allowlist gate (populated with 2 components, 3 excluded)
- Evidence-gated merge on llama-stack-provider-ragas (identity merge: 144 unchanged rows, 0 decisions)
- Source file read verification (3/3 files readable from checkout)
- 5 controlled fallback scenarios (all pass)
- 171 focused tests (launcher, routing, merge, MLflow)
- Architecture document validator (845 files pass)
- `git diff --check` (clean)
- `architecture/` directory unmodified
- Checkout path provenance preserved for all 5 components
- Merge output hash matches analyzer input hash (identity merge verified)

#### What Could Not Be Exercised

`/data/checkouts` exists and is readable, but no agent container was invoked:

- Live agent synthesis (requires containerized Claude execution)
- New candidate generation (requires agent synthesis)
- MLflow run creation (requires agent evaluation results)
- OTel telemetry export (requires agent execution traces)

The merge ran as identity (candidate = analyzer) which validates the merge
infrastructure but does not test synthesis quality.

#### Test Evidence

| Suite | Passed | Skipped | Failed |
|-------|-------:|--------:|-------:|
| test_launcher_mount | 4 | 0 | 0 |
| test_architecture_routing | 49 | 0 | 0 |
| test_architecture_merge | 28 | 0 | 0 |
| test_mlflow_tracking | 90 | 5 | 0 |
| lint_architecture_docs | 845 | 0 | 0 |
| git diff --check | Clean | — | — |

5 MLflow SDK tests skipped (need mlflow SDK — environment constraint, not regression).

#### Recommendation

**Hold the allowlist at empty.** Routing, merge, and fallback work correctly
against real checkouts. Live agent synthesis requires invoking
`scripts/run_claude_container.sh` to run a containerized agent that generates
candidate summaries for merge testing.

---

### Run 2: `migration-20260726-163537` (superseded by Run 3)

- **Run ID**: `migration-20260726-163537`
- **Commit**: `2f501c6d` (feat/scripted-architecture-summaries)
- **Date**: 2026-07-26
- **Run artifacts**: `tmp/analyzer-assisted-migration/migration-20260726-163537/`
- **Migration report**: `docs/notes/first-allowlisted-migration-report.md`

#### Infrastructure Fix

Added conditional `/data/checkouts:/data/checkouts:ro` mount to
`scripts/run_claude_container.sh`. The mount activates when the host directory
exists and is read-only. Startup summary now reports mount status. 4 passing
tests verify mount behavior; 1 passing test verifies routing preserves
checkout path identity in provenance.

#### Selected Components

| Component | Readiness | Route | On Allowlist | Rationale |
|-----------|-----------|-------|:------------:|-----------|
| llama-stack-provider-ragas | partial | partial | Yes | Has category_coverage metadata; bounded gap discovery |
| models-perf-benchmark-data | partial | partial | Yes | Minimal dependency footprint (3 deps); small corpus |
| rhds-llama-stack-distribution | insufficient | legacy | No | Natural fallback; analyzer self-declares insufficient |
| trustyai-service | unknown | legacy | No | No agent_baseline field; exercises unknown path |

#### Data Sources

Used real analyzer JSON and markdown from `architecture/rhoai.next/` (canonical
repository artifacts), not simulated checkout copies. The routing function reads
`data_coverage.agent_baseline`, `category_coverage`, and markdown table
structure — all present in the canonical files.

#### What Was Exercised

- Routing logic with real analyzer data from 4 components
- Allowlist gate (populated with 2 components)
- Evidence-gated merge (2 partial-route components)
- 5 controlled fallback scenarios (all pass)
- 146 focused tests (launcher, routing, merge, MLflow)
- Architecture document validator (845 files pass)
- `git diff --check` (clean)
- `architecture/` directory unmodified

#### What Could Not Be Exercised

`/data/checkouts` does not exist in this container environment:

- Live agent synthesis against source repositories
- New candidate generation
- MLflow run creation
- OTel telemetry export
- Full fetch→analyze→route→synthesize→merge pipeline

The launcher mount fix removes the infrastructure blocker. When run on a host
with `/data/checkouts`, the mount activates automatically.

#### Additional Finding

87 of ~100 `architecture/rhoai.next/*.json` files have unresolved git merge
conflicts. Only 13 are clean, and only 3 of those have explicit `agent_baseline`
readiness levels. This limits the candidate pool for migration testing.

#### Test Evidence

| Suite | Passed | Deselected | Failed |
|-------|-------:|----------:|---------:|
| test_launcher_mount | 4 | 0 | 0 |
| test_architecture_routing (sync) | 39 | 6 | 0 |
| test_architecture_merge | 28 | 0 | 0 |
| test_mlflow_tracking | 75 | 20 | 0 |
| lint_architecture_docs | 845 | 0 | 0 |
| git diff --check | Clean | — | — |

6 async routing guard tests and 20 MLflow SDK tests deselected (need
pytest-asyncio and mlflow SDK respectively — environment constraints, not
regressions).

#### Recommendation

**Hold the allowlist at empty.** Infrastructure is fixed and tested. Live
agent synthesis requires running the launcher on a host with `/data/checkouts`.

---

### Run 1: `migration-20260726-162001` (superseded)

- **Run ID**: `migration-20260726-162001`
- **Commit**: `2f501c6d` (feat/scripted-architecture-summaries)
- **Date**: 2026-07-26
- **Run artifacts**: `tmp/analyzer-assisted-migration/migration-20260726-162001/`
- **Status**: Superseded by Run 2

#### Driver review — not accepted

The execution was a valid routing/merge infrastructure rehearsal, but not
the requested first real migration. The host has `/data/checkouts`, while
`scripts/run_claude_container.sh` mounted only the repository and ADC file, so
the delegated container could not see the absolute checkout paths from
`architecture/rhoai.next/component-map.json`.

The agent therefore used simulated checkouts assembled from corpus and prior
pilot artifacts. No live agent synthesis, source-repository reads, MLflow run,
or Claude OTel execution occurred. The report and raw run artifacts are
provisional and cannot satisfy this task's completion criteria.

#### Selected Components (Run 1)

| Component | Readiness | Route | Rationale |
|-----------|-----------|-------|-----------|
| llama-stack-provider-ragas | partial | partial | Has category_coverage metadata |
| models-perf-benchmark-data | partial | partial | Minimal dependency footprint |
| rhds-llama-stack-distribution | insufficient | legacy | Natural fallback test case |
| trustyai-service | unknown | legacy | Exercises unknown path |
| caikit-tgis-backend | partial | partial | Prior pilot candidate data available |

#### Key Results (Run 1)

- Routing correctly dispatches: partial→partial (3), insufficient→legacy (1), unknown→legacy (1)
- Empty allowlist = gate open (design intent verified)
- Evidence-gated merge: 18 unchanged, 7 applied, 8 rejected, 0 restored
- All 4 fallback scenarios produce machine-readable legacy outcomes
- `git diff --check` clean; `architecture/` unmodified
- 193 focused tests pass (5 skipped for MLflow SDK); 2 pre-existing failures unrelated

## Status: accepted — five-component bounded evidence set completed

The accepted evidence set combines the five-component real-checkout routing,
merge, provenance, and fallback matrix from Run 3 with Run 5's actual
evidence-gated Claude SDK synthesis for `rhoai-mcp`. This satisfies the bounded
3–5 component migration scope while keeping the live agent invocation limited
to the explicitly selected synthesis route. All procedural defects from Run 4
were resolved: no `.env` sourcing, `INSIGHTS_ARTIFACT.json` is permitted, and
the allowlist was managed with finally-style cleanup.

### Run 5: `migration-20260726-183627` (accepted)

- **Run ID**: `migration-20260726-183627`
- **Commit**: `2f501c6d` (feat/scripted-architecture-summaries)
- **Date**: 2026-07-26
- **Run artifacts**: `tmp/analyzer-assisted-migration/migration-20260726-183627/`
- **Migration report**: `docs/notes/first-allowlisted-migration-report.md`

#### Selected Component

| Component | Readiness | Route | On Allowlist | Rationale |
|-----------|-----------|-------|:------------:|-----------|
| rhoai-mcp | sufficient | synthesis | Yes | Single-component bounded validation; tests full SDK synthesis + merge pipeline |

The complete five-component evidence matrix is recorded in the migration report:
`rhoai-mcp`, `caikit-tgis-backend`, `llama-stack-provider-ragas`,
`rhds-llama-stack-distribution`, and `trustyai-service`.

#### What Was Exercised

- Launcher dry-run confirms `/data/checkouts:ro` mount and `--env-file`
- Run-scoped writable copy with provenance map (original path + source revision)
- Temporary allowlist populated with only `rhoai-mcp`, restored to empty in finally block
- Real Claude SDK agent synthesis (Opus 4.6, Vertex, 44 turns, 42 tool calls, 20 denied)
- Constrained execution guard: denied shell discovery, unauthorized reads, sub-agents
- Evidence-gated merge: 2 applied (authentication gap), 38 rejected, 42 restored, 30 unchanged
- Architecture validation: PASS for both candidate and merged document
- INSIGHTS_ARTIFACT.json: 5 insights, valid
- ARCHITECTURE_CHANGES.md: present and archived
- All outputs under ignored `tmp/` directory only; `architecture/` unmodified
- Runner-provided environment variables (Vertex); `.env` not sourced
- 169 focused tests pass (5 skipped for MLflow SDK)
- `git diff --check`: clean

#### Agent Telemetry

| Metric | Value |
|---|---|
| Duration | 600s ($2.21) |
| Model | Claude Opus 4.6 (Vertex) |
| Tool calls / denied | 42 / 20 |
| Gap categories | authentication |
| Merge counts | 2 applied, 38 rejected, 42 restored, 30 unchanged |

#### What Could Not Be Exercised

- Partial-route and legacy fallback with live agent synthesis (only synthesis
  route exercised; fallback tested in prior runs without live agent)
- MLflow run creation (not wired to single-component SDK runner)
- OTel telemetry export (SDK runner not launched with `--otel`)

#### Recommendation

**Hold the allowlist at empty.** The full synthesis pipeline works correctly for
a single sufficient-readiness component. The merge correctly applies bounded
changes from the authentication gap while rejecting unsupported changes and
restoring analyzer facts.

---

### Run 4 Evidence Detail (superseded by Run 5)

- `rhoai-mcp` ran the actual Claude SDK synthesis route from the real checkout
  contents at source revision `dabe473`; its 639-second, $2.29 Claude Opus 4.6
  run produced validated generated Markdown, candidate, change, merge, run,
  and telemetry artifacts under the ignored Run 4 directory.
- Its evidence-gated merge reported 33 unchanged, 7 applied, 49 rejected, and
  27 restored rows. Analyzer facts remained authoritative.
- `caikit-nlp` was a bounded partial-route attempt, but stopped without a clean
  completion signal or candidate/merge artifacts. This is a timeout evidence
  result, not a successful migration.
- `INSIGHTS_ARTIFACT.json` is now an allowed constrained-agent output and has a
  focused regression test. The allowlist was restored to empty after Run 4.
- Do not source `.env` inside delegated prompts or task commands; use only the
  environment variables passed by the launcher.
