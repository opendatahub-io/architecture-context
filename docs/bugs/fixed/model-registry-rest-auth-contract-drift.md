# Bug: Model Registry REST Auth Contract Drift

## Summary

The `consumer-v1` rerun at `20260729T165013Z` flagged `FACT-005` because Tree B
no longer supports the corpus answer for model-registry REST API
authentication.

## Evidence

- Evaluation report:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T165013Z/report.md`
- Raw results:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T165013Z/raw-results.json`
- Question: `FACT-005`
- Expected answer: `/api/model_registry/*` endpoints use Istio
  `AuthorizationPolicy`; the policy allows the Istio ingressgateway
  ServiceAccount and internal JWT requests, blocks `kubeflow-userid` spoofing,
  uses controller-runtime RBAC for controller metrics, and supports Bearer
  token or internal ServiceAccount authentication for the UI BFF.
- Tree B files read: `model-registry.md`

The generated Tree B document emphasizes BFF Kubernetes identity extraction,
Kubernetes `SubjectAccessReview`, controller bearer-token access to the Model
Registry REST API, controller-runtime metrics auth, and unauthenticated health
probes. It does not clearly document the expected Istio
`AuthorizationPolicy`, ingressgateway ServiceAccount, internal JWT, or
`kubeflow-userid` spoofing protection facts.

The corpus source pointer is also stale against the follow-up eval tree:
`FACT-005` points at `architecture/rhoai.next/model-registry.md` lines
`303-306`, while those lines now begin `Integration Points` and no longer
contain the expected auth policy evidence.

## Impact

MEDIUM — this is a security-review fact. It is unclear whether the generated
architecture document lost important authentication evidence, or whether the
corpus expected answer is pinned to older model-registry content that no
longer represents the current tree.

## Expected

Reconcile the source truth before changing the benchmark:

- If the source still defines the Istio `AuthorizationPolicy` behavior, update
  analyzer extraction/rendering or synthesis guidance so `model-registry.md`
  preserves it.
- If the current component no longer exposes that policy, update the corpus
  expected answer and source line to match the generated architecture evidence.

## Status

Fixed. Analyzer support has been implemented,
`architecture/rhoai.next/model-registry.md` has been regenerated with matching
auth evidence, and the completed `consumer-v1` run at `20260729T215258Z` no
longer flags `FACT-005`.

Implementation note, 2026-07-29: `arch-analyzer` now extracts Istio
`AuthorizationPolicy` and `VirtualService` manifests, supplements selected
manifests from canonical Istio option kustomizations, and renders
route-correlated Istio policies in `Authentication & Authorization`. Real-source
validation against `red-hat-data-services/model-registry` at
`d707343fcff1c1e2040993b58ca6231ac0383a40` rendered `/api/model_registry/*`
with Istio sidecar `AuthorizationPolicy`, ingressgateway ServiceAccount,
Kubeflow namespace JWT, `kubeflow-userid` blocking, and controller metrics RBAC
evidence.

Regeneration note, 2026-07-29: the promoted
`architecture/rhoai.next/model-registry.md` now contains the expected
authentication rows at lines `277-280`, and `FACT-005` now points at that range.
Deterministic corpus validation, architecture linting, and `src/arch-analyzer`
Go tests passed. Focused live reruns could not complete because the evaluator
hung before the first Tree A answer body; tracked separately in
`docs/bugs/fixed/consumer-v1-focused-eval-agent-start-hangs.md`.

Closure note, 2026-07-29: the user-run full evaluation completed successfully
and included all 40 questions. In
`tmp/evaluations/consumer-v1-rhoai-next-20260729T215258Z/report.md`,
`FACT-005` is not a flagged regression. Tree B scored `50%`, passed source
citation, and passed gap acknowledgment for `FACT-005`.
