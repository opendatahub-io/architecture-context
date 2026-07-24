# Task: Extract Operator Authentication Controls

## Goal

Replace the accepted `data-science-pipelines-operator` and `trainer-operator`
Authentication corrections with deterministic, repository-independent extraction,
then safely promote both components to analyzer-only generation.

## Context

Both components are analyzer-sufficient and have exactly one empty high-value
category. Their accepted agents added three Authentication rows each:

- controller-runtime liveness and readiness probes that are unauthenticated by
  design;
- a metrics endpoint whose controller-runtime `SecureServing` option is explicitly
  `false`;
- Kubernetes RBAC aggregation labels that extend built-in roles; and
- a Kubernetes RBAC rule whose `resourceNames` field restricts Secret access.

The current corpus classifier also treats every historical structured correction as
permanently unresolved. It must distinguish accepted correction identities that a
fresh analyzer document now supplies from corrections that remain agent-owned.

## Acceptance Criteria

- [x] Go source extraction emits Authentication facts for registered
  controller-runtime health/readiness probes.
- [x] Go source extraction emits an unauthenticated metrics fact only when
  `metricsserver.Options.SecureServing` is statically and explicitly `false`.
- [x] Manifest extraction retains ClusterRole aggregation labels and RBAC
  `resourceNames` restrictions.
- [x] Semantic normalization emits stable Authentication rows for aggregate Argo
  Workflow access and named-secret restrictions without component-name exceptions.
- [x] The analyzer reproduces all accepted Authentication row identities for
  `data-science-pipelines-operator` and `trainer-operator`.
- [x] The eligibility classifier reports total, resolved, and unresolved historical
  architectural corrections and uses unresolved corrections for false nominations.
- [x] Production analyzer-only routing requires an explicit corpus-validated rollout
  approval; newly populated partial categories cannot bypass an agent automatically.
- [x] Unit tests include negative controls for secure metrics, unrelated RBAC labels,
  unrestricted Secret rules, and non-controller health-like routes.
- [x] The 90-component static replay produces exactly two justified new
  analyzer-only nominations and zero false nominations.
- [x] Analyzer preservation, structural validation, and synthesis-quality gates pass.
- [x] A bounded paid validation is run only if replay changes production routing as
  expected.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/extractor/collectors.go`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/`
- `scripts/analyze_analyzer_only_eligibility.py`
- `tests/test_architecture_corpus.py`

## Status

Done

## Baseline Evidence

- Production fixture:
  `tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z`
- Fresh static replay:
  `tmp/architecture-corpus-runs/rhoai-next-category-completeness-final-20260719T005100Z`
- `data-science-pipelines-operator`: 3 accepted Authentication additions,
  200.10 agent seconds, $1.0688.
- `trainer-operator`: 3 accepted Authentication additions, 180.93 agent seconds,
  $0.8641.

## Notes

Historical agent output is the regression target for row identity and a discovery
aid. Source evidence remains authoritative when the baseline is incomplete or wrong.

Validation is recorded in
`docs/notes/operator-authentication-extraction-validation-2026-07-19.md`.
