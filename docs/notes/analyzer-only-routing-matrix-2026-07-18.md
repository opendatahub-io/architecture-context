# Analyzer-Only Routing Matrix: 2026-07-18

## Purpose

This note records the classification, implementation, and same-revision treatment
matrix for eliminating redundant component-agent passes. It covers per-component
Markdown only; `PLATFORM.md` synthesis and diagrams remain unchanged.

## Reference Classification

The reproducible classifier evaluated the accepted full run
`rhoai-next-20260718T200215Z`:

| Measure | Result |
|---------|-------:|
| Sufficient components | 63 |
| Components with zero accepted structured mutations | 18 |
| Analyzer-only nominations | 15 |
| False nominations | 0 |
| Recall of zero-mutation components | 83.33% |
| Historical agent invocations nominated for removal | 15 |
| Historical cost represented | $13.0212 |
| Historical summed agent time represented | 2,034.82s |
| Historical reads represented | 119 |
| Historical source files represented | 60 |
| Historical output tokens represented | 87,810 |

The machine and Markdown reports are stored at:

- `tmp/architecture-corpus-runs/rhoai-next-20260718T200215Z/reports/analyzer-only-eligibility.json`
- `tmp/architecture-corpus-runs/rhoai-next-20260718T200215Z/reports/analyzer-only-eligibility.md`

The 10-worker FIFO projection closely reproduces the observed full-run agent phase:
1,966.91 projected seconds versus 1,971.84 observed seconds. Removing the 15
nominated jobs projects 1,751.96 seconds, a reduction of 214.94 seconds or 10.93%.
This is a scheduling projection; the treatment matrix below supplies observed route
behavior.

## Eligibility Policy

A component is analyzer-only eligible only when all of the following are true from
its fresh analyzer output:

1. `agent_baseline` readiness is `sufficient`.
2. Architecture Components, Authentication, Integration Points, and Internal
   Platform Dependencies are all populated.
3. Partial coverage and document shape nominate no bounded high-value correction
   category.

The policy does not contain component names and does not consult prior agent output.
An empty high-value category retains the existing constrained agent even when its
coverage surface is marked complete. Partial and insufficient routes are unchanged.

## Implementation

The Go renderer now creates deterministic Purpose, Data Flows, and Architectural
Analysis sections from typed facts. It summarizes component topology, interfaces,
integrations, security and network evidence, and explicit partial-coverage limits.
It does not infer request ordering or behavior absent from structured evidence.

The generation phase validates and copies eligible analyzer Markdown directly to
`GENERATED_ARCHITECTURE.md`, writes a normal run report with the
`analyzer-only` route, and never submits that component to Claude. Corpus telemetry
separates processed components, actual agent invocations, and analyzer-only outputs.

Analyzer-only quality gates require at least 200 synthesis words and reject pending
synthesis placeholders. Existing structural, analyzer-preservation, sparse-structure,
and evidence gates remain active.

## Matrix Provenance

| Field | Value |
|-------|-------|
| Run ID | `rhoai-next-analyzer-only-matrix-20260718T214500Z` |
| Model for controls | `opus` |
| Workers | 4 |
| Components | `odh-dashboard`, `kueue`, `eval-hub`, `batch-gateway` |
| Run manifest | `tmp/architecture-corpus-runs/rhoai-next-analyzer-only-matrix-20260718T214500Z/run.json` |
| Corpus report | `tmp/architecture-corpus-runs/rhoai-next-analyzer-only-matrix-20260718T214500Z/reports/comparison.json` |
| Accepted-Opus comparison | `tmp/architecture-corpus-runs/rhoai-next-analyzer-only-matrix-20260718T214500Z/reports/accepted-opus-comparison.json` |

All four repositories match the accepted full-run commits: `batch-gateway` at
`fac0c8d8c693`, `eval-hub` at `50ffb64af836`, `kueue` at `02d90493a211`, and
`odh-dashboard` at `f1cdd9f22ebd`.

| Component | Readiness | Route | Agent | Reads | Source files |
|-----------|-----------|-------|------:|------:|-------------:|
| `odh-dashboard` | sufficient | analyzer-only | no | 0 | 0 |
| `kueue` | sufficient | analyzer-only | no | 0 | 0 |
| `eval-hub` | sufficient with gaps | evidence-gated | yes | 7 | 4 |
| `batch-gateway` | partial | evidence-gated | yes | 12 | 8 |

The matrix routed all four roles as intended. A post-run deterministic re-render
applied wording and pluralization polish to the two analyzer-only artifacts; no agent
output or structured fact changed. Both corpus comparisons were replayed afterward.

## Quality And Preservation

| Gate | Result |
|------|-------:|
| Analyzer identities retained | 652/652 (100%) |
| Unexplained missing rows | 0 |
| Unexplained populated-cell conflicts | 0 |
| Structurally valid documents | 4/4 |
| Synthesis/structure quality | 4/4 |
| Analyzer-only placeholders | 0 |
| Successful generation results | 4/4 |
| Required gates | **PASS** |

Compared directly with accepted Opus documents at the same commits, the matrix
retains 661/677 structured rows (97.64%). The analyzer-only treatment accounts for
577/577 exact rows with zero conflicts: `kueue` is 262/262 and `odh-dashboard` is
315/315. All 16 unmatched rows and eight populated-cell conflicts belong to the two
fresh agent controls, not the analyzer-only route.

## Synthesis Review

| Component | Accepted Opus words | Deterministic words | Structured fidelity |
|-----------|--------------------:|--------------------:|--------------------:|
| `kueue` | 921 | 316 | 262/262 |
| `odh-dashboard` | 1,118 | 369 | 315/315 |

Both deterministic documents provide a short and detailed purpose, entry/service
surface, runtime inventory, downstream interaction summary, security context,
deployment and control-plane analysis, and explicit evidence boundaries. Their
statements are traceable to the adjacent tables and avoid turning empty or Unknown
cells into claims.

The tradeoff is intentional: the deterministic prose does not reproduce Opus's
domain-specific narratives, such as Kueue admission sequencing or dashboard proxy
call chains, when those sequences are not represented as typed relationships. The
structured tables carrying CRDs, endpoints, RBAC, authentication, integrations, and
dependencies remain exact and are the primary downstream-agent input. The concise
synthesis is accepted for this conservative route because it is complete,
source-bounded, explicit about uncertainty, and protected by a route-specific quality
gate. Components with any high-value gap retain an agent for richer source-backed
correction and synthesis.

## Execution Comparison

The historical comparison uses the same four components from the accepted full run.

| Measure | Accepted Opus passes | Treatment matrix | Change |
|---------|---------------------:|-----------------:|-------:|
| Agent invocations | 4 | 2 | -50.00% |
| Cost | $4.3228 | $2.5778 | -40.37% |
| Summed generation time | 758.07s | 482.62s | -36.34% |
| Tool calls | 85 | 51 | -40.00% |
| Read calls | 38 | 19 | -50.00% |
| Source files | 20 | 12 | -40.00% |
| Output tokens | 35,542 | 23,635 | -33.50% |

Observed matrix workflow wall time was 301.52 seconds. It is dominated by the
298.19-second `batch-gateway` control, so skipping the two shorter agents does not
materially shorten this particular four-way critical path. The full-corpus schedule
projection is the relevant wall-time estimate and predicts a 10.93% agent-phase
reduction with 10 workers.

## Decision

The analyzer-only route is accepted for the conservative eligibility boundary. The
classification has zero observed false nominations, the treatment preserves all
analyzer and accepted Opus structured facts for eligible components, deterministic
synthesis passes explicit quality gates, and the matrix materially reduces agent
work and cost.

The subsequent [90-component production validation](analyzer-only-full-corpus-production-validation-2026-07-18.md)
selected all 15 expected analyzer-only components, preserved 2,460/2,460 accepted
structured rows for that treatment set, passed every required gate, and reduced
agent invocations by 16.67% and cost by 11.88%. A controlled 10-worker schedule
estimates 199.43 seconds (9.56%) avoided, close to the 214.94-second projection.
