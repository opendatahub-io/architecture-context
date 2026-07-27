# Analyzer-Assisted Agent Architecture

**Status**: Local implementation complete; real analyzer-assisted synthesis
validated for `rhods-operator` and `odh-dashboard`; `rhods-operator` is
provisionally allowlisted; promotion remains pending external gates

## Context

The pipeline currently has two ways to produce architecture documents:

1. **Analyzer-only**: the Go analyzer extracts structured facts and renders
   them into Markdown. This is accurate for the categories it covers, but the
   result is often an inventory rather than an explanation. (At design time it
   served 63/90 components; the architecture tree has since grown — see
   Baseline provenance below.)
2. **Evidence-gated / legacy**: an agent reads source files to fill analyzer
   gaps and write synthesis prose; the merge layer preserves analyzer facts
   and accepts only evidence-backed changes.

The desired outcome is an agent-assisted document for every component, while
preserving deterministic facts and making uncertainty visible. External
historical feedback reports a 94-question retrieval baseline of 84% (79/94),
with the weakest categories being CRD/API surface (50%), deployment model
(60%), and team ownership (62.5%). Review corrections also repeatedly
identify stale versions, missing scope limitations, missing
upstream/dependency status, absent test matrices, missing failure modes, and
invented or vague performance thresholds.

Therefore, a query server alone is insufficient: it can expose facts that
exist, but cannot answer questions for which the context has no fact. This
design combines deterministic extraction, structured context enrichment,
bounded agent synthesis, and a measurable feedback loop.

### Baseline provenance

Every numeric baseline in this plan has a classification below. Evaluation
targets and success criteria reference these identities; no score may be
claimed without a verifiable artifact.

| Claim | Source | Status |
|---|---|---|
| 94-question / 84% (79/94) retrieval baseline | External historical feedback | **Unverified** — no 94-question corpus, result set, or evaluation log exists in the repository (searched `git log`, `grep`, and `benchmark/`); preserved in `corpus_manifest.json` as `plan_claim_94q` with `verification_status: "unverified"` |
| Category scores: CRD/API 50%, deployment 60%, ownership 62.5% | Same external historical feedback | **Unverified** — same provenance as the 94-question claim; no per-category result artifact exists |
| 63/90 analyzer component coverage | Design-time observation | **Stale** — the architecture tree now contains 27 versions and 100+ unique components; the original 63/90 ratio described a single-version snapshot at plan authoring time |
| 40 active / 0 retired / 40 total corpus questions | `benchmark/analyzer-assisted-v1/corpus_manifest.json` (v1.1.0) | **Verified** — 40 active questions in `consumer-v1/corpus.json` (Tier 1: 10, Tier 2: 10, Tier 3: 10, Tier 4: 10); 0 retired; contract target met per `schema.json` `minItems` |
| v1-ab evaluation: 40 questions evaluated | `benchmark/consumer-v1/results/v1-ab/scored-results.json` | **Verified** — durable artifact; all 40 questions now active; 11 re-authored with corrected expected answers (v1-ab scores reflect original ground-truth) |
| Consumer-v1 corpus: 40 questions | `benchmark/consumer-v1/corpus.json` | **Verified** — authoritative on-disk corpus |
| 40-question contract target | `benchmark/consumer-v1/schema.json` (`minItems: 40`) | **Verified** — schema and `validate.py` enforce this; contract target met (all 40 questions authored with verified evidence) |

## Goals and non-goals

### Goals

- Give every component a useful narrative without weakening analyzer-owned
  facts.
- Make provenance, freshness, maturity, confidence, and known limitations
  visible to both agents and human readers.
- Improve feasibility and testability decisions, not only architecture prose.
- Reduce source scanning and redundant architecture-context retrieval.
- Discover and report architectural insights that static analysis alone
  cannot produce — patterns, trade-offs, cross-component implications, and
  risks.
- Turn staff corrections into reviewable context overlays.

### Non-goals

- Claim that query results eliminate hallucinations; they reduce avoidable
  searching and must still be evidence-gated.
- Infer roadmap commitments, ownership, performance targets, or upstream
  behavior from source structure alone.
- Remove the legacy route before the retrieval experiment and rollout gates
  demonstrate that it is safe to do so.

## Design

### Phase 1: Deterministic baseline

`arch-analyzer extract` and `arch-analyzer render` continue to produce
`component-architecture.json` and `analyzer_architecture.md`. Analyzer-owned
tables remain authoritative, but each fact should carry (where available):

- source/provenance and the extraction timestamp;
- release or version applicability;
- confidence and validation state (`confirmed`, `needs-validation`, or
  `unknown`);
- lifecycle/maturity (`GA`, `TP`, `DP`, `planned`, or `deprecated`);
- scope limitations and deployment topology;
- dependency status (`exists`, `needed`, `open`, or `blocked`) and upstream
  provenance.

The baseline should add behavioral context where evidence exists, rather than
inventing it:

- integration constraints and known failure modes;
- configuration and RBAC/deployment ordering;
- test topology, architecture/provider matrices, and observable outcomes;
- measured performance/resource baselines and image/build status;
- delivery-independence and primary-versus-peripheral component hints.

Unknown values are explicit. A missing threshold must remain missing; the
agent may recommend that a threshold be defined, but must not manufacture one.

### Phase 2: Context index, overlays, and correction feedback

Add a generated index that maps common questions to component sections and
provides aliases for renamed components. Keep human-reviewed corrections in a
separate overlay layer so regeneration does not erase them. Overlays must
include provenance, author/source, applicability, and last-verified date.

The correction harvester should extract candidates from Staff Engineer / SME
Input sections, especially scope, architecture constraints, ownership,
maturity, and upstream corrections. Candidates require review before becoming
authoritative overlays. Track correction frequency by component to prioritize
regeneration and manual review.

### Phase 3: Query interface

Introduce `arch-analyzer query`, initially as a one-shot CLI (one process per
query; no server lifecycle). Queries should return a bounded, machine-readable
answer with source locations, applicable version, freshness, and an explicit
`unknown`/`not-extracted` result when the analyzer cannot answer.

Initial queries:

| Query | Purpose |
|---|---|
| `callers-of --function X --package Y` | Direct callers with source locations |
| `consumers-of --type X` | Files/functions that reference a type |
| `config-sources --component X` | Environment, ConfigMap, and CLI configuration |
| `crds --component X` | CRDs, scope, versions, controllers, and watch relationships |
| `dependency-status --component X --release R` | Dependency state, provenance, and release applicability |
| `diff --from R1 --to R2 --component X` | Added, removed, or changed facts between snapshots |

Add `auth-chain`, `deployment-order`, and deeper call/dependency traversal
only after measuring demand. Query output is evidence, not an authority
override: the merge layer applies the same ownership and evidence rules as
document edits.

### Phase 4: Bounded synthesis agent

Every component receives a synthesis pass. The agent reads the analyzer
baseline, index, applicable overlays, and query results, then writes only
designated narrative sections such as Purpose, Data Flows, Architectural
Analysis, trade-offs, platform context, feasibility caveats, and testability
guidance. A full run treats the target architecture output directory as empty:
prior generated documents are comparison/evaluation inputs only and must not
influence synthesis.

The synthesis contract requires the agent to:

- cite the fact or query result supporting each structural claim;
- distinguish confirmed facts, assumptions, recommendations, and unknowns;
- preserve scope exclusions, component aliases, and version applicability;
- use observable outcomes and existing measurements when stating test criteria;
- include relevant failure modes and test-matrix dimensions when the context
  provides them;
- escalate to bounded source inspection only for declared gaps.

Beyond narrating known facts, the agent should discover and report insights
that pure static analysis cannot produce:

- **Architectural patterns and anti-patterns**: identify design idioms (e.g.
  sidecar delegation, fan-out provisioning, shared-nothing scaling) and flag
  structural concerns (e.g. circular dependencies, single points of failure,
  inconsistent auth postures across related components).
- **Cross-component implications**: reason about how a component's design
  choices affect its neighbors — upgrade ordering, failure blast radius,
  API contract coupling, shared-state assumptions.
- **Design trade-off analysis**: explain *why* the architecture is shaped the
  way it is — what documented constraints drove the design, what alternatives
  are explicitly discussed, and what flexibility was preserved or sacrificed.
  If the source does not document the rationale, the agent may offer a
  clearly labeled hypothesis, never present an inferred alternative as an
  architectural decision.
- **Risk and gap identification**: surface things the analyzer found but
  cannot evaluate — e.g. an endpoint with no auth middleware (fact) that
  serves user-facing data and may need protection (insight), or a dependency
  on an upstream project with no stable release (fact) that creates a
  feasibility risk (insight). An absence can only be treated as a fact when
  analyzer coverage for that category is complete; otherwise the result must
  say “not verified.” Security concerns are findings for review, not fixes or
  vulnerability claims.
- **Emergent complexity**: identify cases where individually simple components
  interact in ways that create operational complexity — cascading failures,
  ordering constraints, configuration coupling, or hidden assumptions about
  shared infrastructure.

These insights must be clearly labeled as agent analysis, not analyzer facts,
and must be emitted in a separate, non-authoritative `insights` section. Each
insight should contain:

- a concise claim and category (`pattern`, `trade-off`, `risk`, or
  `cross-component implication`);
- the exact facts, queries, overlays, or source excerpts used as inputs;
- the reasoning step that connects those inputs to the claim;
- applicability, confidence, and unresolved alternatives or counterevidence;
- a suggested validation action when the claim is consequential.

The agent must not silently promote an insight into an analyzer fact, table
row, dependency status, security finding, roadmap commitment, or acceptance
criterion. It must not create a risk merely because a relationship was not
found in an incomplete extraction. Limit insight count and token budget per
component so the agent cannot fill the document with speculative commentary.

#### Published output and retained artifacts

The published architecture tree should contain the final human-facing
`<component>.md` documents and a deterministic `INDEX.md` for each platform or
version. The pipeline must also preserve the machine-readable and intermediate
artifacts used to produce those documents rather than discarding them. Store
them in a clearly separated, non-agent-facing artifact namespace, for example:

```text
architecture/<platform>/
  INDEX.md
  <component>.md
  _artifacts/<component>/
    component-architecture.json
    analyzer_architecture.md
    INSIGHTS_ARTIFACT.json
```

`component-architecture.json` remains the structured analyzer-fact record and
`analyzer_architecture.md` remains the analyzer baseline. The final component
document may incorporate their validated facts and approved narrative merge,
but must not treat the retained artifacts as interchangeable sources. An
`INSIGHTS_ARTIFACT.json` contains separate, non-authoritative agent analysis;
it may be surfaced through review and reports, but must never silently promote
its claims into analyzer facts or authoritative tables. Every retained
artifact must carry or inherit source revision, applicable version, format
version, and generation provenance.

Analyzer-sufficient means “sufficient for the requested claim categories,” not
“the component has no missing information.” The agent must not read source
files in that mode. Analyzer-partial permits limited, category-specific
source reads and records the gap and evidence used. A legacy fallback remains
available for unresolved high-value gaps until rollout gates are met.

### Merge and retrieval boundaries

The merge layer must preserve analyzer-owned rows and reviewed overlays. Agent
changes to structured facts remain rejected unless they include acceptable
evidence. Narrative sections are agent-owned, but their claims must retain
fact/query provenance where possible.

Fetch architecture-context once per CI run and share the immutable snapshot
across sessions. Instrument reads and queries with OTel spans so evaluation
can distinguish navigation, useful reads, query use, missing context, stale
context, and unsupported inference.

## Routing and rollout

Use three routes during migration:

| Route | Condition | Agent access |
|---|---|---|
| **synthesis** | Required categories have adequate fresh evidence | Analyzer baseline, index, overlays, queries; no prior generated summaries or source files |
| **partial** | Some required categories are missing or stale | Above plus bounded reads for declared gaps |
| **legacy** | High-value gaps cannot be resolved safely | Analyzer-first fallback; targeted evidence-gated exploration, expanding to full discovery only when required evidence is absent or unresolved |

Retire legacy only after a canary shows no regression in analyzer-fact
accuracy, improves retrieval on the question corpus, and does not degrade
human review outcomes. Route selection must consider category coverage,
freshness, and confidence—not just whether a component has an analyzer JSON.

## Implementation sequence

### Step 1: Establish the evaluation and instrumentation baseline

- Use the canonical corpus (40 active questions; contract target met —
  see Baseline provenance). The plan's original 94-question target is
  external historical feedback with no repository artifact; evaluation must
  use the verified corpus until additional questions are authored against
  on-disk evidence. Stratify by category and difficulty; reserve a stable
  evaluation subset.
- Record the verified v1-ab baseline (40 questions evaluated; all 40 now
  active; 11 re-authored with corrected expected answers). The 84% (79/94) figure is unverified external
  feedback and cannot serve as a reproducible baseline — see Baseline
  provenance.
- Create the four-condition experiment: baseline, `INDEX.md`, `arch-query`,
  and combined index plus query. *(Implemented — experiment manifest v1.3.0,
  all four conditions available.)*
- Add OTel spans for context fetches/reads and configure experiment tracking.
  *(Local implementation complete for the repository-owned layers — context
  telemetry collector, streaming Claude OTel/API capture with pre-persistence
  redaction, local OTel JSONL export, MLflow adapter, and canary readiness
  validator are in place. Local file-backed MLflow tracking validated
  end-to-end with `MLFLOW_RUNS_DIR`; the full 320-session provisional corpus
  evaluation completed with 0 failures and 320 local MLflow runs with
  read-back verification. External-fetch OTel producer and external MLflow
  server registration remain external gates. See
  `docs/tasks/done/add-local-claude-otel-api-capture.md` and the committed
  provisional results report.)*
- Classify incorrect answers as stale context, missing context, retrieval
  failure, or unsupported inference. *(Failure-classification proposal
  pipeline implemented; 35-proposal adjudication template prepared at
  `benchmark/consumer-v1/adjudication_template.json` v0.1.0 with all
  `human_category: null`; human adjudication required before promotion to
  authoritative classifications.)*
- Define an LLM-as-judge semantic-equivalence scoring dimension with a
  human-labeled calibration set. *(Contract/protocol implemented — schema
  v0.1.0, validator, 65 tests, rationale required non-empty; 24-question
  stratified calibration template prepared at
  `benchmark/consumer-v1/calibration_template.json` v0.1.0 with all
  `human_label: null`; judge execution blocked on human labeling and user
  authorization.)*

### Step 2: Improve the context contract

Add schemas and renderer support for provenance, freshness, maturity,
dependency/upstream status, scope/interaction constraints, deployment
topology, test topology, performance/build evidence, and explicit unknowns.
Add the generated index and version diff capability. Do not populate fields
from guesses.

*(Implemented — 19/19 sub-requirements verified. Context contract schema,
model, renderer, and normalizer cover provenance, freshness, maturity,
dependency/upstream status, scope/deployment topology, confidence/validation
state, explicit unknowns, generated index, and version diff. Behavioral
evidence fields — image/build status, configuration/RBAC, architecture/
provider matrices, observable outcomes, and delivery-independence/component
classification — added in commit `9f931a8b` as optional fields with schema,
renderer, and test coverage; unsupported values remain unpopulated/
not-extracted. See audit at
`docs/tasks/done/audit-local-plan-implementation-gaps.md`.)*

### Step 3: Add reviewed overlays and the correction loop

Implement correction harvesting, reviewable overlay proposals, last-verified
metadata, and component correction-frequency reports. Add regression
assertions for known corrections and confirmed-correct patterns from the
feedback corpus.

*(Implemented — 7/7 sub-requirements verified. Correction harvesting
(`arch-analyzer harvest-proposals`), reviewable overlay proposals
(`arch-query proposals validate/generate`), last-verified metadata with
date validation, component correction-frequency reports
(`arch-query proposals report`), regression assertions for known corrections
(18 tests in `test_correction_adjudication_regression.py`), overlay
preservation across regeneration (`architecture_merge.py`
`NON_AUTHORITATIVE_SECTIONS`), and source-audited empty categories
(`architecture_routing.py`). See audit at
`docs/tasks/done/audit-local-plan-implementation-gaps.md`.)*

### Step 4: Implement query and synthesis modes

Key areas:

- `src/arch-analyzer/cmd/root.go` and `internal/query/` for the CLI;
- `internal/gosource/` and `internal/pythonsource/` for extractors;
- `.claude/skills/repo-to-architecture-summary/SKILL.md` for synthesis;
- `lib/architecture_routing.py`, `lib/phases/architecture.py`, and
  `lib/agent_runner.py` for routing and tool permissions;
- `lib/architecture_merge.py` for ownership/provenance enforcement.

*(Partially implemented — 24/28 sub-requirements verified. Query CLI
(`arch-query query` with `crds`, `dependency-status`, `diff`; `callers-of`,
`consumers-of`, `config-sources` return explicit not-extracted), synthesis
routing (three analyzer-assisted routes), source-read prohibition and bounded
partial reads, insights contract with non-authoritative isolation,
`gosource`/`pythonsource` extractors, synthesis skill, context telemetry,
agent runner tool guard, deterministic synthesis renderer, merge-layer
ownership enforcement, and evidence-backed change records. Three
sub-requirements remain promotion-gated: external-fetch OTel producer
(external script), optional external MLflow registration, and human
labels/adjudication (calibration and adjudication templates prepared, all
human fields null). These do not block local analyzer-assisted implementation
or the provisional track. The user-authorization gate for
the provisional full-corpus evaluation is resolved by the completed
320-session run recorded in
`docs/tasks/done/run-full-provisional-corpus-evaluation.md`. These remaining
external inputs correspond to the Step 5 gates. See audit at
`docs/tasks/done/audit-local-plan-implementation-gaps.md`.)*

### Step 5: Canary, benchmark, and expand

Run synthesis on a representative subset, compare against the baseline and
legacy route, then expand only if the gates below pass. Include the canonical
corpus (40 active questions; contract target met), regression assertions,
human review scores, token/time cost, and source-read volume.

Every benchmark run must also produce a committed, human-readable Markdown
results-and-conclusions report (for example,
`docs/notes/analyzer-assisted-provisional-results.md`) alongside its raw,
scored, telemetry, and tracking artifacts. The report must describe the
evaluation matrix and methodology, summarize results by condition, tree, tier,
and scoring dimension, record cost/time/token/context metrics, distinguish
observations from conclusions, and state the provisional limitations and
remaining rollout gates. Machine-readable artifacts alone are insufficient;
the report must not present provisional exact-match evidence as human semantic
review or full rollout approval.

The provisional analyzer-assisted migration may now proceed for an explicit,
reviewable component allowlist using the existing synthesis/partial routes and
evidence-gated merge. The allowlist, route decisions, fallback behavior, and
telemetry must be recorded for each run. This is an implementation and
provisional migration step, not authorization to retire the legacy route or
promote agent-authored insights to authoritative facts.

The first migration gate is implemented and validated in
`docs/tasks/done/implement-provisional-analyzer-assisted-summary-migration.md`:
the operator allowlist gates synthesis/partial routing, non-allowlisted
components retain the legacy route, and restricted-route merge/validation
failures are reported as the distinct `analyzer-baseline` fallback.

The next milestone is the first real allowlisted migration. It must use a
small representative component set, write only temporary output, and produce
reviewable summary, merge, route, fallback, provenance, and telemetry evidence
before the allowlist is expanded. This milestone does not retire the legacy
route or satisfy the human-data and external-observability rollout gates.

*(Completed — the accepted five-component evidence set and the live `rhoai-mcp`
synthesis/merge run are recorded in
`docs/tasks/done/run-first-allowlisted-analyzer-assisted-migration.md` and
`docs/notes/first-allowlisted-migration-report.md`. The run took approximately
600 seconds for agent generation; the allowlist remains empty and no committed
architecture output was changed.)*

The next implementation task optimizes the analyzer-sufficient synthesis
route. The generic `repo-to-architecture-summary` skill must consume analyzer
output before inspecting repository source, using pre-seeded analyzer evidence
and declared context inputs. It has no broad source discovery in `synthesis`,
category-specific bounded reads only in `partial`, and analyzer-first fallback
exploration in `legacy`, expanding to full discovery only when the analyzer is
absent or leaves required high-value evidence unresolved. The task must retain
source-reference and provenance requirements and record route-specific
read/tool telemetry.

*(Completed — `repo-to-architecture-summary/SKILL.md` now has explicit
analyzer-first route contracts: synthesis skips discovery and source reads,
partial permits only declared bounded reads, and legacy starts from analyzer
coverage before expanding exploration for unresolved or safety-critical gaps.
Focused routing and phase tests pass; the architecture validator passes
against the latest temporary output. See
`docs/tasks/done/optimize-analyzer-sufficient-synthesis-discovery.md`.)*

The next execution task is to rerun one bounded migration with the optimized
synthesis route, compare its route/read/denial telemetry with the prior
`rhoai-mcp` run, and review the generated output before any allowlist expansion.

*(Completed — the optimized `rhoai-mcp` retry produced valid output with zero
source reads and zero discovery calls. The tracked allowlist remains empty;
the host SDK initialization failure, container retry, merge evidence, and
limitations are recorded in
`docs/notes/next-optimized-analyzer-assisted-migration-report.md`.)*

The next provisional execution should exercise a small multi-component matrix
covering sufficient synthesis, partial bounded reads, and legacy/analyzer
fallback outcomes. It must remain temporary and reviewable; it does not
authorize tracked allowlist expansion or legacy-route retirement.

*(Completed — the three-component matrix exercised sufficient synthesis,
partial bounded reads, and unknown/legacy fallback. All three architecture
documents passed validation; restricted-route insights passed validation. The
tracked allowlist remains empty. See
`docs/notes/bounded-multi-component-optimized-migration-report.md`.)*

The clean-run enrichment boundary exposed by the operator/dashboard comparison
is now verified: generation stages analyzer JSON and
`analyzer_architecture.md` as synthesis context, while existing committed
architecture documents remain comparison/evaluation inputs only and are not
staged as synthesis context or fallback input. Focused tests also verify the
restricted read/write and Bash guards. See
`docs/tasks/done/verify-clean-run-analyzer-assisted-synthesis.md` and commit
`6e04522a`. The merge layer continues to protect analyzer-owned facts,
overlays, provenance, and explicit unknowns.

The local provisional migration evidence is now sufficient to proceed with
reviewed, bounded expansion decisions, but the full plan remains gated on
external MLflow/OTel integration and human adjudication/calibration. The
reviewed provisional allowlist now enables `rhoai-mcp` on the synthesis route
and `caikit-nlp` on the partial route. Components that are unknown,
insufficient, or not listed retain the existing legacy/fallback behavior. No
legacy-route retirement or full-rollout claim is authorized by this matrix.

**External-input gates for Step 5 execution:**

| Gate | Status | Required input |
|---|---|---|
| MLflow experiment registration | Local tracking validated; external server registration pending | Local file-backed (`MLFLOW_RUNS_DIR`) and local REST modes validated end-to-end (preflight, dry-run, live tracking with read-back against ephemeral MLflow 2.22.0 server; REST `max_results` bug fixed in commit `4be242c5`; 95 tests pass). Requires `MLFLOW_TRACKING_URI` and a running MLflow server for external registration. |
| Root-cause classification | Adjudication template ready; human adjudication pending | `benchmark/consumer-v1/adjudication_template.json` v0.1.0: 35 proposals, all `human_category: null`, all `proposed_category: "unresolved"`. Validator: `validate_adjudication.py` (44 tests). Requires human adjudication before promotion to authoritative classifications. |
| LLM-as-judge calibration | Calibration template ready; human labeling pending | `benchmark/consumer-v1/calibration_template.json` v0.1.0: 24 questions (6/tier, 4 answerable-as-gap), all `human_label: null`. Validator: `validate_calibration.py` (49 tests). Requires human semantic-match labeling and user authorization for judge execution. |
| External-fetch OTel spans | Local export ready | Requires `fetch-architecture-context.sh` OTel producer (not in this repository) |
| Corpus at contract minimum | 40/40 active questions | **Resolved** — all 40 questions authored with verified evidence |
| User authorization | Bounded pilot and full-corpus provisional evaluation authorized and completed | The 32-session pilot ran at $8.1087 within the $25 / 30-minute guard. The user subsequently authorized the 320-session full-corpus provisional evaluation without a cost ceiling; it completed at $117.13 in 39.0 minutes. |

## Success criteria

- No analyzer-owned fact regressions or loss of reviewed overlays.
- Retrieval improves from the verified v1-ab baseline, with specific
  improvement in CRD surface, deployment model, and ownership categories.
  (The 84% figure is unverified external feedback — see Baseline provenance.
  The reproducible baseline is the v1-ab scored-results artifact against the
  canonical corpus.)
- Fewer stale/wrong-context corrections and fewer invented thresholds.
- Testability output contains concrete observable outcomes, applicable test
  matrices, and explicit unknowns instead of vague “measured by” language.
- Feasibility output identifies dependency status, upstream coordination, and
  critical-path open questions when evidence supports those conclusions.
- Context fetches occur once per CI run; measured navigation/read/query cost
  and agent token/time cost are reported.
- Synthesis output includes architectural insights (patterns, trade-offs,
  cross-component risks) that are clearly labeled as agent analysis and
  include reasoning chains reviewers can validate; unsupported-claim and
  false-positive rates remain below an agreed threshold.
- Human review scores do not regress, and all rollout failures are attributable
  to a recorded root-cause category.

### Provisional track (no new human data)

When additional human adjudication and calibration data is unavailable,
a provisional track enables regression detection and directional signal
without asserting that human-data gates are satisfied. See
`docs/notes/no-human-data-provisional-rollout-track.md` for the full
definition.

Provisional measurements cover: deterministic regression assertions (S1),
exact-match scoring against the canonical 40-question corpus (S2 — exact
match only, not semantic equivalence), automated root-cause signal
generation (S3 — directional, not authoritative), contract-field presence
for testability/feasibility (S4, S5), context telemetry metrics (S6), and
insight artifact structure (S7 — directional only). Human review scores
(S8) are not measurable without human labels.

The provisional track does not satisfy the full rollout gates. The legacy
route must not be retired based on provisional evidence alone. All
`human_label` and `human_category` values remain null. The existing
94-question feedback package provides directional signal only (see
`docs/notes/historical-feedback-provenance.md`).

## Open questions

1. Which fields can be populated deterministically from source, and which
   require owner or SME confirmation?
2. What freshness window makes a version, ownership, maturity, or dependency
   fact stale for routing purposes?
3. Which query output format best supports both CLI use and future MCP/server
   integration?
4. What evidence threshold is required before a synthesis agent may cite a
   performance value or make a feasibility recommendation?
5. Which source categories are safe for bounded reads in analyzer-partial
   mode, and what is the maximum budget per category?
