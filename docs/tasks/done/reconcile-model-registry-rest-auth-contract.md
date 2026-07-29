# Task: Reconcile Model Registry REST Auth Contract

## Goal

Resolve the `FACT-005` mismatch between the consumer-v1 expected answer and
the generated `model-registry.md` authentication evidence.

## Context

The `20260729T165013Z` rerun flagged `FACT-005`. Tree B reads
`model-registry.md` and answers from the generated BFF/SAR/controller-token
evidence, while the corpus expects Istio `AuthorizationPolicy`,
ingressgateway ServiceAccount, internal JWT, and `kubeflow-userid` spoofing
protection.

Tracking bug:
`docs/bugs/fixed/model-registry-rest-auth-contract-drift.md`.

## Plan

1. Check current model-registry source manifests and code for the expected
   Istio `AuthorizationPolicy` and JWT/header-spoofing controls.
2. Decide whether the generated architecture document or the corpus expected
   answer is stale.
3. Update analyzer extraction/rendering, synthesis guidance, or corpus source
   lines accordingly.
4. Rerun `FACT-005` or the focused consumer-v1 slice.

## Acceptance Criteria

- `model-registry.md` and `FACT-005` agree on the current REST API
  authentication contract.
- The source line for `FACT-005` points at evidence that still exists in the
  evaluation tree.
- A focused rerun no longer flags `FACT-005` for source-citation or semantic
  drift.

## Status

Done. Analyzer extraction/rendering is implemented, `model-registry.md` has
been regenerated, deterministic validation passes, and the completed
`consumer-v1` run at `20260729T215258Z` no longer flags `FACT-005`.

Implemented changes:

- `arch-analyzer` extracts Istio `AuthorizationPolicy` manifests into
  `access_policies`.
- `arch-analyzer` extracts Istio `VirtualService` routes into
  `ingress_routing`.
- A bounded supplemental scan loads canonical Istio option kustomizations such
  as `manifests/kustomize/options/istio` and
  `manifests/kustomize/options/ui/overlays/istio`, while excluding
  scripts/tests/examples/samples.
- Platform facts now render Istio authorization policies as
  `Authentication & Authorization` rows and correlate policies to matching
  `VirtualService` backends.

Real-source validation against `red-hat-data-services/model-registry` on `main`
at commit `d707343fcff1c1e2040993b58ca6231ac0383a40` rendered the expected
`model-registry.md` authentication row for `/api/model_registry/*` with:

- Istio sidecar proxy `AuthorizationPolicy` enforcement.
- ingressgateway ServiceAccount principal allow rule.
- Kubeflow namespace internal request path with Kubernetes JWT.
- `request.headers[kubeflow-userid]` blocking for internal JWT requests.
- controller metrics RBAC via controller-runtime authn/authz filter.

Regeneration result, 2026-07-29:

- Ran static analysis for `rhoai.next` `model-registry`.
- Regenerated `architecture/rhoai.next/model-registry.md`.
- The promoted document contains the relevant authentication evidence at
  lines `277-280`: `:8443/metrics`, `/api/model_registry/*`, and `/api/v1/*`.
- Updated `benchmark/consumer-v1/corpus.json` `FACT-005` `source_line` from
  `303-306` to `277-280`.
- `uv run python3 benchmark/consumer-v1/validate.py` passed.
- `uv run python scripts/lint_architecture_docs.py architecture/rhoai.next/model-registry.md`
  passed.
- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...` passed from
  `src/arch-analyzer`.

Focused rerun attempts, 2026-07-29:

- `tmp/evaluations/consumer-v1-rhoai-next-20260729T205600Z` using Opus was
  interrupted after the evaluator wrote only the `FACT-005_tree_a.log` header
  and made no further progress.
- `tmp/evaluations/consumer-v1-rhoai-next-20260729T210900Z` using Opus was
  interrupted for the same reason.
- `tmp/evaluations/consumer-v1-rhoai-next-20260729T211300Z-sonnet` using
  Sonnet was interrupted for the same reason.

The evaluator hang is tracked separately in
`docs/bugs/fixed/consumer-v1-focused-eval-agent-start-hangs.md`.

Completion evidence, 2026-07-29:

- User-run full `consumer-v1` rerun completed at
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T215258Z/report.md`.
- Tree B overall score is `0.5292`, slightly above Tree A `0.5250`.
- `FACT-005` scored Tree A `50%`, Tree B `50%`; Tree B passed source citation
  and gap acknowledgment and was not flagged as a regression.
- Remaining flagged regressions at the time were `INV-003`, `FACT-008`, and
  `NAV-010`; `NAV-010` was later resolved by
  `docs/tasks/done/reconcile-llama-stack-platform-name.md`.
