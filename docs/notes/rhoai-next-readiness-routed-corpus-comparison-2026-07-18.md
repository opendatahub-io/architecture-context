# RHOAI Next Readiness-Routed Corpus Comparison: 2026-07-18

## Purpose

This note preserves the first full `rhoai.next` corpus run after readiness routing
and evidence-gated analyzer merge became the default component-generation path. It
compares the result with both `architecture/rhoai.next.bak` and the analyzer snapshot
captured during the same run.

`PLATFORM.md` synthesis and architecture diagrams were not run and remain outside
this measurement.

## Run Provenance

| Field | Value |
|-------|-------|
| Run ID | `rhoai-next-20260718T173838Z` |
| Platform | `rhoai.next` |
| Model | `opus` |
| Agent workers | 10 |
| Baseline | `architecture/rhoai.next.bak` |
| Run manifest | `tmp/architecture-corpus-runs/rhoai-next-20260718T173838Z/run.json` |
| Machine-readable report | `tmp/architecture-corpus-runs/rhoai-next-20260718T173838Z/reports/comparison.json` |
| Generated Markdown report | `tmp/architecture-corpus-runs/rhoai-next-20260718T173838Z/reports/comparison.md` |

The run completed static analysis, all 90 component agents, collection, structural
validation, and comparison without an execution failure. The required preservation
and structural gates passed.

## Headline Results

| Measure | Result |
|---------|-------:|
| Structured fixture recall | 1,529/6,161 (24.82%) |
| Median component structured recall | 22.50% |
| Fixture populated-cell conflicts | 681 |
| Analyzer identities preserved | 8,192/8,192 (100.00%) |
| Analyzer-to-final conflicts | 12 |
| Accepted source-backed conflicts | 12 |
| Unexplained analyzer-to-final conflicts | 0 |
| Structurally valid documents | 90/90 |
| Successful component agents | 90/90 |
| Required gates | **PASS** |

The 12 accepted analyzer corrections cover `ai4rag`, `caikit-nlp`,
`caikit-tgis-backend`, `fms-hf-tuning`, `pipelines-components`, `training-hub`,
`vllm-gaudi`, and `vllm-orchestrator-gateway`. Each correction has a source path,
line range, and reason in the run's merge adjudications.

## Change From The First Full Run

The comparison run `rhoai-next-20260718T034628Z` used full agents for all components
and failed analyzer preservation. The new run uses the production readiness routes.

| Measure | First full run | Readiness-routed run | Change |
|---------|---------------:|---------------------:|-------:|
| Workflow wall time | 3,266.06s | 1,810.29s | -44.57% |
| Component-generation wall time | 3,255.00s | 1,794.30s | -44.87% |
| Structured fixture recall | 35.66% | 24.82% | -10.84 points |
| Matched structured fixture rows | 2,197 | 1,529 | -668 |
| Median component recall | 33.67% | 22.50% | -11.17 points |
| Analyzer identity preservation | 62.02% | 100.00% | +37.98 points |
| Analyzer conflicts | 589 | 12 accepted | 0 unexplained |
| Required gate | Fail | Pass | corrected |

Against the original 3,600-second reference, the complete new workflow is 49.71%
faster. Static analysis itself took 14.62 seconds.

The production run consumed 1,929 tool calls, including 904 reads of 548 distinct
source files. It emitted 768,391 output tokens and recorded $93.73 in model cost.
The 65 denied calls were enforcement events, not execution errors: all were attempts
to use tools outside the bounded route, primarily `TodoWrite`, and all component
agents still succeeded.

## Readiness Routes

| Readiness | Components | Matched | Fixture | Weighted recall |
|-----------|-----------:|--------:|--------:|----------------:|
| Sufficient | 63 | 1,142 | 4,721 | 24.19% |
| Partial | 19 | 183 | 889 | 20.58% |
| Insufficient legacy fallback | 8 | 204 | 551 | 37.02% |

The lower fixture recall is not isolated to one readiness class. The legacy result
also varies because agent output is stochastic, but the largest absolute losses are
in the new bounded sufficient and partial routes.

## Category Diagnosis

| Category | Candidate rows | Matched fixture rows | Fixture rows | Recall |
|----------|---------------:|---------------------:|-------------:|-------:|
| Architecture components | 233 | 90 | 532 | 16.92% |
| Authentication | 73 | 17 | 288 | 5.90% |
| CRDs | 106 | 91 | 189 | 48.15% |
| Egress | 188 | 74 | 444 | 16.67% |
| External dependencies | 4,091 | 381 | 899 | 42.38% |
| HTTP endpoints | 642 | 230 | 561 | 41.00% |
| Integration points | 1,257 | 47 | 1,127 | 4.17% |
| Internal dependencies | 165 | 59 | 499 | 11.82% |
| RBAC cluster roles | 1,500 | 375 | 790 | 47.47% |
| Services | 113 | 57 | 243 | 23.46% |

The integration score is primarily an identity and abstraction mismatch, not an
empty-output problem: the new corpus has more integration rows than the fixture and
preserves all 1,021 analyzer integration identities. Authentication, internal
dependencies, architecture components, egress, and services have substantially
fewer candidate rows than the fixture and require source review for true omissions.

The clearest routing failure is `batch-gateway`. Its partial route allocated the six
available gap categories to services, ingress, egress, RBAC, and secrets. The agent
used its eight-file budget effectively and produced source-backed network facts and
synthesis prose, but left architecture components, authentication, internal
dependencies, and integration points empty. Its exact fixture result fell from
27/51 in the first run to 1/51 in this run. This is a policy-selection defect, not a
merge failure: the merge correctly preserved every analyzer fact and applied all 20
valid additions.

Other large losses that warrant targeted source review include
`model-metadata-collection`, `trustyai-explainability`, `openvino_model_server`,
`caikit-nlp`, `models-as-a-service`, `guardrails-detectors`, and `eval-hub`.

`rhods-operator` also exposed a deterministic analyzer defect. The repository does
not commit generated CRD bases, so the analyzer missed its Kubebuilder Go API types
and mistook two CA-injection patches for complete CRDs. It emitted a blank CRD row,
the merge removed that invalid row, and the final document retained 0/27 fixture CRD
identities. This demonstrated that 100% analyzer preservation is a loss-prevention
gate, not a completeness guarantee.

The subsequent Kubebuilder extraction fix recovered 30 versioned identities and
rendered 27 canonical CRD rows. The corrected output exactly matches 26/27 fixture
identities; the remaining difference adds the source-backed `v1alpha1`
`HardwareProfile` version alongside `v1`.

## Interpretation

This run proves the two properties the production routing was designed to enforce:

1. analyzer facts survive the agent stage unless a source-backed adjudication
   explicitly corrects them; and
2. bounded routing cuts full-platform wall time by almost half.

It does not prove corpus-wide replacement quality. The exact fixture score is still
a diagnostic rather than a semantic accuracy score because only 17 components have
machine-comparable baseline revisions and many generated identities use a different
abstraction than the older agent-authored fixture. Even with that limitation, the
row-count and representative-document review reveal a real coverage regression in
agent-owned structured categories.

Deterministic Kubebuilder CRD recovery and partial-category selection are now fixed.
The subsequent three-component source-reviewed matrix recovered valid facts in all
four target categories across sufficient and partial routes while maintaining 100%
analyzer preservation and bounded source access. Its
[permanent report](readiness-routing-coverage-matrix-2026-07-18.md) supports another
full corpus run after review, with an expected increase in agent cost.
