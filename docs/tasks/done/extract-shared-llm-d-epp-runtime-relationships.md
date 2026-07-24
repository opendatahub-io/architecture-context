# Task: Extract Shared llm-d EPP Runtime Relationships

## Goal

Convert the remaining reusable EPP runtime components and dependencies shared by
`llm-d-inference-scheduler` and `llm-d-router` into generic analyzer facts, then
determine independently whether either component is safe for analyzer-only routing.

## Context

The two product repositories contain the same `cmd/epp/runner/runner.go` at different
revisions. The registered-gRPC tranche already extracts the canonical Endpoint Picker
component, ExternalProcessor and health services, and optional TLS without relying on
either repository name.

Accepted agent output still uses alternate identities and adds relationships not yet
represented by analyzer facts: Gateway API InferencePool, Envoy ExtProc, vLLM model
server metric endpoints, and llm-d KV cache. `llm-d-router` also adds standalone
health and metrics runtime components. Historical ExtProc Authentication rows use
different punctuation and method labels from the canonical registered-service fact.

Together these two agent passes cost $2.4939 and 440.62 summed agent seconds, with 16
reads, 8 source files, and 19,539 output tokens in the accepted production run.

## Acceptance Criteria

- [x] Normalize equivalent Endpoint Picker and ExtProc structured identities from
  their protocol and runtime evidence; do not use component-name-specific aliases.
- [x] Emit an Envoy proxy internal relationship only when a runtime-reachable
  ExternalProcessor service registration and Envoy ExtProc protocol implementation
  converge. Imports and protobuf types alone are negative controls.
- [x] Represent an InferencePool controller watch with a stable resource identity
  while preserving the provider/API-project relationship needed by existing
  consumers such as Workload Variant Autoscaler.
- [x] Emit a model-serving metrics relationship only when model-server endpoint
  discovery, configured metrics transport, and a runtime metrics request converge.
  Port fields, flag declarations, and test clients alone are negative controls.
- [x] Emit an internal Go-module relationship only when a direct project module is
  imported by non-test runtime source; `go.mod` presence or test-only imports are
  insufficient. Apply the rule generically to project-owned module namespaces.
- [x] Extract standalone health or metrics runtime components only when listener
  construction, service/handler registration, and `Serve`, `Start`, or manager
  registration converge. Endpoint declarations alone must not create components.
- [x] Keep optional TLS, plaintext health, and Kubernetes-authenticated metrics facts
  source-backed and avoid duplicate Authentication rows caused only by spelling or
  method-label differences.
- [x] Resolve or source-adjudicate all remaining accepted corrections for each
  component before approving its route; approval of one component must not imply
  approval of the other.
- [x] A fresh 90-component replay has zero false approved nominations and passes all
  preservation, structural, and synthesis gates.
- [x] Run a bounded production-path matrix only for components whose routing changes.

## Files Likely Involved

- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/normalize/normalize.go`
- `scripts/analyze_analyzer_only_eligibility.py`
- `lib/analyzer_only_approvals.json`

## Status

Done

## Baseline Evidence

- Latest replay:
  `tmp/architecture-corpus-runs/rhoai-next-gie-epp-static-20260719T143319Z`
- `llm-d-inference-scheduler` checkout:
  `1f40050f38ff3f03a317abf875a6eb167fe2dac7`; 1/6 corrections resolved.
- `llm-d-router` checkout:
  `829fd28a806ebd160ce60404db8b707ec3a3cd9a`; 3/9 corrections resolved.
- Both checkouts have byte-identical `cmd/epp/runner/runner.go` files at the audited
  revisions.

## Progress

- A source-backed, runtime-reachable ExternalProcessor registration now emits the
  `Envoy proxy` ExtProc relationship in both repositories. Disconnected registrations
  remain rejected by the registered-gRPC extractor.
- Direct modules under project namespaces become internal Go-library relationships
  only after a non-test runtime import is found. Both repositories prove
  `llm-d-kv-cache` use at
  `pkg/epp/framework/interface/requesthandling/types.go:27`; declaration-only and
  test-only dependencies remain negative controls.
- Model-server endpoint discovery, the registered metrics data-source factory,
  `MetricsHost` URL construction, and an executed HTTP GET must all converge before
  emitting `Model-serving endpoints` with `HTTP metrics scrape`. Both repositories
  prove the request at
  `pkg/epp/framework/plugins/datalayer/source/http/client.go:72`; focused mutations
  independently reject missing discovery, construction, URL binding, execution, or
  runtime registration.
- A registered `grpc.health.v1` service becomes `Health Server` only when its gRPC
  server also reaches `Serve`, `Start`, or a concrete manager `GRPCServer` runnable.
  A `/metrics` handler becomes `Metrics Server` only when a Prometheus handler,
  `http.Server`, and `ListenAndServe` converge in runtime-reachable source. Both
  shared checkouts prove these lifecycles at `runner.go:728` and `runner.go:1035`;
  isolated construction, registration, lifecycle, and reachability mutations are
  rejected.
- Persisted agent correction keys are re-normalized with current canonical aliases:
  EPP process labels resolve to `Endpoint Picker (EPP)`, InferencePool labels retain
  the canonical `gateway-api-inference-extension` provider while the controller
  watch keeps the exact GVK, vLLM endpoint labels resolve to `Model-serving
  endpoints`, and ExtProc spelling/method variants resolve to the registered
  ExternalProcessor service.
- Source correlation selects the dedicated plaintext Health registration before
  gRPC service deduplication instead of merging it with the conditional Health
  registration on the optional-TLS ExtProc server. The existing reviewed metrics
  adjudication remains conservative: a source-visible Kubernetes filter without
  secure serving and deployed review RBAC does not become an authentication fact.
- Against the accepted merge reports and focused fresh documents, scheduler
  corrections resolve 6/6 and router corrections resolve 9/9. Full-corpus replay is
  still required before routing approval.
- The final 90-component replay extracted 90/90 repositories in 12.10 seconds,
  retained 8,452/8,457 analyzer identities with only five accepted corrections,
  passed structural and synthesis checks for 90/90 documents, and reported zero
  false nominations. Both target components are now explicitly approved.
- The two-component production-path matrix invoked zero agents, retained 154/154
  analyzer identities, passed both quality gates, and completed in 4.03 seconds.
- Focused Go extraction and platform semantic tests pass; the corpus replay and
  bounded matrix approved both affected routes with zero agent invocations.
