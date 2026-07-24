# Analyzer-Only Full-Corpus Production Validation: 2026-07-18

## Purpose

This note records the 90-component production validation of conservative
analyzer-only routing. It compares the treatment run with the accepted Opus run used
to derive the eligibility policy. `PLATFORM.md` synthesis and diagrams remain out of
scope.

## Provenance

| Field | Reference | Treatment |
|-------|-----------|-----------|
| Run ID | `rhoai-next-20260718T200215Z` | `rhoai-next-20260718T215431Z` |
| Model | `opus` | `opus` |
| Workers | 10 | 10 |
| Components | 90 | 90 |
| Agent invocations | 90 | 75 |
| Analyzer-only documents | 0 | 15 |

All 90 repository commit SHAs are identical between the two run manifests. The
treatment artifacts and primary comparison are stored under
`tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z`. A second comparison
against the accepted Opus component documents is stored in that run's
`reports/accepted-opus-comparison.json` and `.md` files.

## Routing Result

The policy selected the same 15 components nominated by the reference classifier:

`agents-operator`, `codeflare-operator`, `data-science-pipelines`,
`fms-guardrails-orchestrator`, `kserve`, `kserve-autogluon-server`,
`kube-rbac-proxy`, `kubeflow`, `kueue`, `model-registry-operator`,
`modelmesh-serving`, `odh-dashboard`, `odh-model-controller`, `ogx-k8s-operator`,
and `training-operator`.

The other 75 components retained their prior route class: 67 used evidence-gated
agents and eight used the legacy insufficient-coverage route. All 90 generation
results succeeded.

## Quality And Preservation

| Gate or comparison | Result |
|--------------------|-------:|
| Analyzer identities retained raw | 8,166/8,171 (99.94%) |
| Accepted populated-cell corrections | 16 |
| Accepted row deletions | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required corpus gates | **PASS** |

The five accepted deletions comprise the four previously adjudicated client-only
gRPC service declarations in `caikit-tgis-backend` and one generic architecture
component in `models-perf-benchmark-data` replaced by two source-backed specific
components.

The direct accepted-Opus comparison is exact for the analyzer-only treatment set:

| Measure | Result |
|---------|-------:|
| Accepted structured rows | 2,460 |
| Rows retained | 2,460 (100%) |
| Missing rows | 0 |
| Additional rows | 0 |
| Populated-cell conflicts | 0 |

Analyzer-only synthesis contains 284 to 369 words per document, with a mean of
328.27, and every document exceeds the 200-word route-specific threshold.

Across all 90 documents, the accepted-Opus comparison retains 8,513/9,239 structured
rows (92.14%). Changes in aggregate generated-table counts belong entirely to the 75
fresh agent outputs: the 15 analyzer-only documents are structurally exact against
their accepted counterparts. The whole-corpus figure therefore measures normal
agent-output variability as well as routing and must not be attributed to the
analyzer-only route.

## Execution Comparison

| Measure | Reference | Treatment | Change |
|---------|----------:|----------:|-------:|
| Agent invocations | 90 | 75 | -15 (-16.67%) |
| Cost | $101.1090 | $89.0946 | -$12.0144 (-11.88%) |
| Tool calls | 2,019 | 1,757 | -262 (-12.98%) |
| Read calls | 921 | 792 | -129 (-14.01%) |
| Source files read | 563 | 488 | -75 (-13.32%) |
| Input tokens | 376,209 | 322,872 | -53,337 (-14.18%) |
| Cache-creation tokens | 5,522,558 | 4,747,609 | -774,949 (-14.03%) |
| Cache-read tokens | 83,987,315 | 72,590,002 | -11,397,313 (-13.57%) |
| Output tokens | 906,673 | 858,803 | -47,870 (-5.28%) |
| Summed generation time | 18,975.77s | 17,639.92s | -1,335.85s (-7.04%) |

## Wall Time

| Phase | Reference | Treatment | Change |
|-------|----------:|----------:|-------:|
| Static analysis | 13.74s | 10.75s | -2.99s (-21.76%) |
| Component generation | 1,971.84s | 1,891.99s | -79.85s (-4.05%) |
| Collection | 0.74s | 0.74s | unchanged |
| Workflow | 1,986.70s | 1,903.90s | -82.80s (-4.17%) |

The direct wall-time delta is smaller than the 214.94-second reference projection
because the 75 remaining agent calls accumulated approximately 699 seconds more
runtime than the corresponding calls in the reference run. This is unrelated to the
15 skipped jobs.

A FIFO 10-worker counterfactual using the treatment run's 75 observed durations and
the reference durations for the 15 omitted jobs estimates 2,087.16 seconds without
analyzer-only routing and 1,887.73 seconds with it. On that controlled schedule, the
route avoids 199.43 seconds (9.56%), close to the original 214.94-second (10.93%)
projection. The measured workflow remains 47.11% faster than the original 3,600
second project reference.

## Decision

The full-corpus production validation passes. The analyzer-only policy selected the
expected conservative set, skipped 15 agents, preserved every accepted structured
row for those components, passed all existing gates, and materially reduced cost and
repository-reading work. No bug or rollback task is required for this rollout.

Future optimization should be tracked as a separate task that deliberately broadens
analyzer-only eligibility by closing specific static coverage or deterministic
synthesis gaps. It should not weaken the validated policy boundary.
