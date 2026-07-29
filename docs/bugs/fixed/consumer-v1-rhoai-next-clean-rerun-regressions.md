# Bug: Consumer V1 rhoai.next Clean Rerun Flags Mixed Regressions

## Summary

The clean `consumer-v1` rerun for `rhoai.next` at
`20260729T120959Z` improved Tree B's primary architecture-only composite score
but still flagged four regression rows across `INV-003`, `INV-009`,
`FACT-007`, and `NAV-008`.

## Evidence

- Report:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T120959Z/report.md`
- Raw results:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T120959Z/raw-results.json`
- Scored results:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T120959Z/scored-results.json`

Run summary:

| Metric | Tree A | Tree B | Delta |
|---|---:|---:|---:|
| Composite | 46.7% | 49.6% | +2.9pp |
| Architecture-only composite | 47.3% | 50.4% | +3.1pp |
| Exact match | 22.5% | 17.5% | -5.0pp |
| Source citation | 70.0% | 80.0% | +10.0pp |

Flagged regression rows:

| ID | Regression | Triage |
|---|---|---|
| `INV-003` | exact match and source citation | Tree B correctly answers that InstructLab has no standalone document, but misses the corpus phrase "standalone RHOAI component" and does not cite `training-hub.md`; this overlaps the open exact-match-variant bug. |
| `INV-009` | source citation | Tree B reads `modelmesh-serving.md` and `modelmesh-runtime-adapter.md` but answers "No" because the generated `modelmesh-serving.md` exposes the ServingRuntime CRDs without clearly listing Triton as a default ModelMesh runtime. |
| `FACT-007` | exact match | Tree B answers 16 Kueue CRDs from the generated `kueue.md`; the corpus expects 11 core Kueue CRDs and excludes configuration/visibility API entries. |
| `NAV-008` | source citation | Both materialized eval trees contain 98 top-level Markdown files, while the corpus expects 94. Tree B also dropped `README.md` and added/renamed several component docs, making the question brittle for the rolling target. |

## Impact

MEDIUM — the overall clean comparison is positive for Tree B, but the
regression report combines actionable architecture-generation issues with
known deterministic-scoring and rolling-inventory artifacts.

## Recommendation

1. Expand or semantically score `INV-003` under the existing exact-match
   variant bug.
2. Improve ModelMesh Serving generated output so default runtime definitions
   explicitly name Triton, MLServer, OVMS, and TorchServe when present.
3. Teach the Kueue CRD rendering/answer contract to distinguish core owned
   CRDs from configuration and aggregated visibility APIs, or update the
   corpus expected answer if the broader CRD definition is intended.
4. Retire or retarget `NAV-008` for rolling `rhoai.next`; static file counts
   are not stable enough for the current benchmark unless pinned to an
   immutable artifact.

## Follow-up Bugs

- `docs/bugs/fixed/modelmesh-serving-missing-default-triton-runtime.md`
- `docs/bugs/open/kueue-crd-count-scope-drift.md`
- `docs/bugs/open/consumer-v1-rolling-file-count-question-brittle.md`
- `docs/bugs/open/corpus-v1-exact-match-variants-too-strict.md`

## Status

Closed as decomposed — 2026-07-29. The mixed regression bucket is no longer the
unit of work; the remaining issues are tracked by focused open bugs.
