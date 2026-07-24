# RHOAI Next Corpus Comparison: 2026-07-18

## Purpose

This note preserves the first successful full-corpus measurement of the local
`arch-analyzer`-first component workflow. The run compared newly generated
`rhoai.next` component documents with the existing `architecture/rhoai.next.bak`
fixture and separately checked whether agent output preserved analyzer-provided
facts.

`PLATFORM.md` synthesis and architecture diagrams were not run and remain outside
this measurement.

## Run Provenance

| Field | Value |
|-------|-------|
| Run ID | `rhoai-next-20260718T034628Z` |
| Platform | `rhoai.next` |
| Model | `opus` |
| Agent workers | 10 |
| Baseline | `architecture/rhoai.next.bak` |
| Analyzer inputs | `tmp/architecture-corpus-runs/rhoai-next-20260718T034628Z/analyzer/rhoai.next` |
| Generated candidates | `tmp/architecture-corpus-runs/rhoai-next-20260718T034628Z/architecture/rhoai.next` |
| Machine-readable report | `tmp/architecture-corpus-runs/rhoai-next-20260718T034628Z/reports/comparison.json` |
| Generated Markdown report | `tmp/architecture-corpus-runs/rhoai-next-20260718T034628Z/reports/comparison.md` |

The run captured repository URLs, branches, commit SHAs, dirty-worktree state,
resolved platform configuration, commands, logs, and phase timings in its
`run.json`. Static analysis, all 90 component agents, collection, structural
validation, and comparison completed. The workflow returned a failed quality gate,
not an execution failure.

## Headline Results

| Measure | Result |
|---------|-------:|
| Structured fixture recall | 2,197/6,161 (35.66%) |
| Median component structured recall | 33.67% |
| Fixture populated-cell conflicts | 1,418 |
| Components below 95% fixture threshold | 89/90 |
| Analyzer identities preserved | 5,081/8,192 (62.02%) |
| Analyzer-to-final populated-cell conflicts | 589 |
| Accepted analyzer-to-final conflicts | 0 |
| Structurally valid documents | 90/90 |
| Required gates | **FAIL** |

The only component above the 95% fixture threshold was `odh-dashboard`, at 96.99%.
The next highest results were `MLServer` at 78.43%,
`guardrails-regex-detector` at 75.00%, `llm-d-latency-predictor` at 72.22%, and
`caikit-nlp` at 71.43%.

The lowest structured fixture results were:

| Component | Recall |
|-----------|-------:|
| `kserve-autogluon-server` | 0.00% |
| `odh-cli` | 0.00% |
| `mlflow` | 5.48% |
| `notebooks-downstream` | 6.45% |
| `trustyai-service-operator` | 7.20% |
| `llm-d-kv-cache` | 9.30% |
| `notebooks` | 9.72% |

## Fixture Category Recall

This comparison measures exact structured row identities in the generated document
against the older agent-authored fixture. It does not by itself establish semantic
correctness.

| Category | Matched | Fixture | Recall | Cell conflicts |
|----------|--------:|--------:|-------:|---------------:|
| Architecture components | 180 | 532 | 33.83% | 292 |
| Authentication | 45 | 288 | 15.62% | 18 |
| CRDs | 135 | 189 | 71.43% | 3 |
| Egress | 151 | 444 | 34.01% | 159 |
| External dependencies | 459 | 899 | 51.06% | 168 |
| gRPC services | 33 | 102 | 32.35% | 33 |
| HTTP endpoints | 392 | 561 | 69.88% | 335 |
| Ingress | 24 | 88 | 27.27% | 30 |
| Integration points | 80 | 1,127 | 7.10% | 33 |
| Internal dependencies | 131 | 499 | 26.25% | 62 |
| RBAC cluster roles | 350 | 790 | 44.30% | 10 |
| RBAC role bindings | 48 | 148 | 32.43% | 46 |
| Secrets | 86 | 251 | 34.26% | 15 |
| Services | 83 | 243 | 34.16% | 38 |

Recent changes retained 29/558 fixture identities (5.20%), and source-file inventory
retained 1,909/4,454 (42.86%). Those evidence inventories are reported separately
and excluded from structured architecture recall.

## Analyzer Preservation

The preservation comparison uses the analyzer snapshot from this same run as its
baseline. It therefore avoids fixture age and repository-revision drift, although it
still uses exact identity and populated-cell equality.

| Category | Preserved | Analyzer | Recall | Cell conflicts |
|----------|----------:|---------:|-------:|---------------:|
| Architecture components | 114 | 147 | 77.55% | 122 |
| Authentication | 17 | 31 | 54.84% | 0 |
| CRDs | 105 | 106 | 99.06% | 0 |
| Egress | 58 | 64 | 90.62% | 40 |
| External dependencies | 1,841 | 4,044 | 45.52% | 137 |
| gRPC services | 108 | 135 | 80.00% | 0 |
| HTTP endpoints | 483 | 577 | 83.71% | 140 |
| Ingress | 17 | 37 | 45.95% | 0 |
| Integration points | 606 | 1,021 | 59.35% | 8 |
| Internal dependencies | 41 | 54 | 75.93% | 2 |
| RBAC cluster roles | 1,331 | 1,543 | 86.26% | 10 |
| RBAC role bindings | 165 | 188 | 87.77% | 9 |
| Secrets | 111 | 147 | 75.51% | 8 |
| Services | 84 | 98 | 85.71% | 62 |

The largest conflict groups were HTTP endpoints (140), external dependencies (137),
architecture components (122), services (62), and source-file line references (51).
By column, protocol accounted for 168 conflicts, dependency required-state for 98,
purpose for 79, type for 52, and source lines for 51.

## Document Set And Readiness

The fixture contained 92 documents and the candidate corpus contained 90. The two
fixture-only documents were `llama-stack` and `llama-stack-k8s-operator`. Their
absence reflects corpus selection drift and must be investigated separately from
document fidelity.

Analyzer readiness classified 65 repositories as `sufficient`, 17 as `partial`, and
8 as `insufficient`. The insufficient repositories were `must-gather`,
`odh-deployer`, `odh-gitops`, `ogx-distribution`,
`rhds-llama-stack-distribution`, `vllm`, `vllm-rocm`, and `vllm-spyre`.

Only 17 fixture comparisons were confirmed to use the same source revision. Revision
status was unknown for the other 73, so the fixture result includes an unquantified
amount of legitimate source evolution.

## Timing

| Phase | Wall time | Failures |
|-------|----------:|---------:|
| Static analysis | 9.99s | 0 |
| Component generation | 3,255.00s | 0 |
| Collection | 0.69s | 0 |
| Total workflow | 3,266.06s | 0 execution failures |

Against the 3,600-second reference, the run reduced wall time by only 9.28%. The
analyzer is fast, but the workflow still launched a full agent for every repository.
The current integration therefore does not yet capture the intended speed benefit.

## Interpretation

The run establishes three facts:

1. The analyzer and runner scale across the complete 90-repository corpus and produce
   structurally valid Markdown.
2. The current agent stage neither preserves all analyzer facts nor avoids broad
   repository work, so it is not yet a safe or materially faster replacement.
3. Exact fixture recall is useful for locating differences, but 35.66% must not be
   interpreted as 35.66% semantic correctness. The fixture has source-revision drift,
   and many conflicts are equivalent or enriched wording.

Examples of comparator-visible changes include `HTTP/HTTPS` becoming `HTTP`,
`ServiceAccount` becoming `ServiceAccount token`, reordered RBAC verb sets, and terse
analyzer purposes becoming more detailed descriptions. Some are harmless
normalization or enrichment; others, such as changed RBAC verb membership or a
dependency changing from optional to required, need source-backed adjudication.

External dependency preservation also needs special treatment. The analyzer records
a broad dependency inventory, while agents often retain only dependencies they judge
architecturally relevant. A preservation rule cannot treat that policy difference as
equivalent to silently dropping a service, endpoint, CRD, or integration.

## Follow-Up Decision

Do not select the next extractor from the raw 35.66% score alone. The next work item
should triage the full-corpus gaps by:

1. canonicalizing semantically equivalent protocols, ordered sets, namespaces, and
   source-line representations;
2. separating analyzer false positives and intentionally filtered dependency data
   from true loss of architecture facts;
3. defining fields or identities that agents must preserve verbatim unless they
   record source-backed adjudication; and
4. measuring agent source reads by readiness class so `sufficient` repositories can
   skip discovery and use agents only for bounded synthesis.

That triage will produce defensible fidelity numbers and identify the next analyzer
or workflow change with the largest expected runtime and coverage benefit.
