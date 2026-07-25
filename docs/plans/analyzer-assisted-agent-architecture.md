# Analyzer-Assisted Agent Architecture

**Status**: Design

## Context

The pipeline currently has two ways to produce architecture documents:

1. **Analyzer-only**: the Go analyzer extracts structured facts and renders
   them into Markdown. This is accurate for the categories it covers, but the
   result is often an inventory rather than an explanation. It currently
   serves 63/90 components.
2. **Evidence-gated / legacy**: an agent reads source files to fill analyzer
   gaps and write synthesis prose; the merge layer preserves analyzer facts
   and accepts only evidence-backed changes.

The desired outcome is an agent-assisted document for every component, while
preserving deterministic facts and making uncertainty visible. The feedback
corpus shows that narrative quality is only part of the problem. The current
94-question retrieval baseline is 84% (79/94), with the weakest categories
being CRD/API surface (50%), deployment model (60%), and team ownership
(62.5%). Review corrections also repeatedly identify stale versions, missing
scope limitations, missing upstream/dependency status, absent test matrices,
missing failure modes, and invented or vague performance thresholds.

Therefore, a query server alone is insufficient: it can expose facts that
exist, but cannot answer questions for which the context has no fact. This
design combines deterministic extraction, structured context enrichment,
bounded agent synthesis, and a measurable feedback loop.

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
`component-architecture.json` and `ANALYZER_ARCHITECTURE.md`. Analyzer-owned
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

Every component receives a synthesis pass. The agent reads the baseline,
index, applicable overlays, and query results, then writes only designated
narrative sections such as Purpose, Data Flows, Architectural Analysis,
trade-offs, platform context, feasibility caveats, and testability guidance.

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
    ANALYZER_ARCHITECTURE.md
    INSIGHTS_ARTIFACT.json
```

`component-architecture.json` remains the structured analyzer-fact record and
`ANALYZER_ARCHITECTURE.md` remains the analyzer baseline. The final component
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
| **synthesis** | Required categories have adequate fresh evidence | Baseline, index, overlays, queries; no source files |
| **partial** | Some required categories are missing or stale | Above plus bounded reads for declared gaps |
| **legacy** | High-value gaps cannot be resolved safely | Existing full evidence-gated exploration |

Retire legacy only after a canary shows no regression in analyzer-fact
accuracy, improves retrieval on the question corpus, and does not degrade
human review outcomes. Route selection must consider category coverage,
freshness, and confidence—not just whether a component has an analyzer JSON.

## Implementation sequence

### Step 1: Establish the evaluation and instrumentation baseline

- Use the 94-question corpus and stratify by category and difficulty; reserve
  a stable evaluation subset of 50–100 questions.
- Record the existing 84% baseline and category scores.
- Create the four-condition experiment: baseline, `INDEX.md`, `arch-query`,
  and combined index plus query.
- Add OTel spans for context fetches/reads and configure experiment tracking.
- Classify incorrect answers as stale context, missing context, retrieval
  failure, or unsupported inference.

### Step 2: Improve the context contract

Add schemas and renderer support for provenance, freshness, maturity,
dependency/upstream status, scope/interaction constraints, deployment
topology, test topology, performance/build evidence, and explicit unknowns.
Add the generated index and version diff capability. Do not populate fields
from guesses.

### Step 3: Add reviewed overlays and the correction loop

Implement correction harvesting, reviewable overlay proposals, last-verified
metadata, and component correction-frequency reports. Add regression
assertions for known corrections and confirmed-correct patterns from the
feedback corpus.

### Step 4: Implement query and synthesis modes

Key areas:

- `src/arch-analyzer/cmd/root.go` and `internal/query/` for the CLI;
- `internal/gosource/` and `internal/pythonsource/` for extractors;
- `.claude/skills/repo-to-architecture-summary/SKILL.md` for synthesis;
- `lib/architecture_routing.py`, `lib/phases/architecture.py`, and
  `lib/agent_runner.py` for routing and tool permissions;
- `lib/architecture_merge.py` for ownership/provenance enforcement.

### Step 5: Canary, benchmark, and expand

Run synthesis on a representative subset, compare against the baseline and
legacy route, then expand only if the gates below pass. Include the 94
question corpus, 29-question consumer benchmark, regression assertions,
human review scores, token/time cost, and source-read volume.

## Success criteria

- No analyzer-owned fact regressions or loss of reviewed overlays.
- Retrieval improves from the 84% baseline, with specific improvement in CRD
  surface, deployment model, and ownership categories.
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
