# RHOAI Next Routing Coverage Full-Corpus Validation: 2026-07-18

## Purpose

This note records the 90-component production validation of the readiness-routing
coverage fix. It covers per-component analyzer extraction, bounded agent synthesis,
evidence-gated merge, and corpus comparison. `PLATFORM.md` synthesis and diagrams
remain out of scope.

## Run Provenance

| Field | Value |
|-------|-------|
| Run ID | `rhoai-next-20260718T200215Z` |
| Platform | `rhoai.next` |
| Model | `opus` |
| Components | 90 |
| Workers | 10 |
| Baseline fixture | `architecture/rhoai.next.bak` |
| Previous routed run | `rhoai-next-20260718T173838Z` |
| Run manifest | `tmp/architecture-corpus-runs/rhoai-next-20260718T200215Z/run.json` |
| Machine report | `tmp/architecture-corpus-runs/rhoai-next-20260718T200215Z/reports/comparison.json` |
| Markdown report | `tmp/architecture-corpus-runs/rhoai-next-20260718T200215Z/reports/comparison.md` |

All 90 analyzer snapshots use the same repository commits as the previous routed
run. The structured-coverage comparison below is therefore not affected by source
revision drift.

## Coverage Result

The four high-value agent-owned categories gained 325 valid rows, an 18.81% increase
over the previous routed run.

| Category | Previous rows | Current rows | Change |
|----------|--------------:|-------------:|-------:|
| Architecture components | 233 | 265 | +32 |
| Authentication | 73 | 194 | +121 |
| Integration points | 1,257 | 1,321 | +64 |
| Internal dependencies | 165 | 273 | +108 |
| **Total** | **1,728** | **2,053** | **+325** |

This confirms the matrix result at platform scale: sparse sufficient and partial
repositories can recover source-backed structure without repository-wide discovery.
The older fixture remains diagnostic rather than authoritative. Exact structured
fixture recall rose from 24.82% to 25.70%, but identity wording and valid additions
continue to make raw fixture equality an unsuitable quality gate.

## Analyzer Correction

The initial comparison reported 8,167/8,171 raw analyzer identities retained. All
four removed rows were `fmaas.GenerationService` RPCs in
`caikit-tgis-backend`. The analyzer interpreted a checked-in proto definition as an
API exposed by the repository. Bounded source inspection showed that the component
loads `GenerationServiceStub` as a gRPC client and does not implement the generated
servicer.

The agent supplied exact delete records with numeric evidence from
`tgis_backend.py`, `tgis_connection.py`, and `generation_pb2_grpc.py`; the merge
accepted those corrections. The corpus comparator initially failed because it could
adjudicate evidence-backed cell changes but not evidence-backed row deletions. It now
records accepted row corrections separately and continues to reject every missing
structured row without an exact reason and source evidence.

## Required Gates

| Gate | Result |
|------|-------:|
| Raw analyzer identities retained | 8,167/8,171 (99.95%) |
| Accepted analyzer row corrections | 4 |
| Unexplained missing analyzer rows | 0 |
| Accepted populated-cell corrections | 13 |
| Unexplained populated-cell conflicts | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Successful agents | 90/90 |
| Required gates | **PASS** |

## Execution Comparison

| Measure | Previous routed run | Current run | Change |
|---------|--------------------:|------------:|-------:|
| Workflow wall time | 1,810.29s | 1,986.70s | +9.75% |
| Cost | $93.7342 | $101.1090 | +7.87% |
| Tool calls | 1,929 | 2,019 | +4.67% |
| Read calls | 904 | 921 | +1.88% |
| Distinct source files | 548 | 563 | +2.74% |
| Output tokens | 768,391 | 906,673 | +18.00% |

The current workflow completed in 33.11 minutes, 44.81% below the one-hour
reference. Static analysis took 13.74 seconds and collection took 0.74 seconds. The
coverage gain is materially larger than the cost and source-read increases, although
the agent synthesis pass remains the dominant runtime and cost.

## Decision

The readiness-routing coverage change is accepted for the full corpus. It restores
high-value structured coverage at bounded cost, preserves or explicitly corrects
every analyzer identity, and passes all structural and synthesis-quality gates.

The next migration work should reduce the remaining agent synthesis burden rather
than broaden discovery. The full run establishes a stable production benchmark for
moving more high-value fact extraction and Markdown adaptation into
`src/arch-analyzer` while retaining the evidence-gated correction path.

This follow-up is tracked in
[Eliminate redundant sufficient-route agent passes](../tasks/done/eliminate-redundant-sufficient-agent-passes.md).
