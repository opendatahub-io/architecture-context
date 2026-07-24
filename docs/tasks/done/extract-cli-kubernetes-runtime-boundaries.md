# Task: Extract CLI Kubernetes Runtime Boundaries

## Goal

Extract the source-backed `odh-cli` relationships to Operator Lifecycle Manager and
the Kubernetes API credential/RBAC preflight path, then prove that the component is
safe for analyzer-only routing.

## Context

The accepted reference contains three structured additions: the
`opendatahub-operator` library dependency, the OLM runtime dependency, and Kubernetes
API Authentication. The CLI constructs Kubernetes and OLM clientsets from one
`rest.Config`, reads Subscriptions and ClusterServiceVersions, and creates
`SelfSubjectAccessReview` objects before privileged operations.

## Acceptance Criteria

- [x] Correlate a runtime `rest.Config` with concrete Kubernetes and OLM clientset
  construction in one reachable CLI lifecycle.
- [x] Emit `Operator Lifecycle Manager (OLM)` only when the constructed OLM client is
  used for runtime Subscription or ClusterServiceVersion reads.
- [x] Emit Kubernetes API Authentication only when the same runtime configuration
  supplies a Kubernetes client and a reachable `SelfSubjectAccessReview` creation
  performs RBAC preflight checks.
- [x] Describe kubeconfig/client-go credential-chain behavior without claiming that
  source selects one specific credential mechanism.
- [x] Derive relationship identities from imported APIs and executed operations,
  without component-name exceptions.
- [x] Reject module-only, import-only, interface-only, test/fake, disconnected,
  read-without-construction, and review-object-without-create cases.
- [x] Add focused positive and negative Go tests.
- [x] Pass `go test ./...`, `go vet ./...`, Ruff, and the Python test suite.
- [x] Resolve all 3/3 accepted `odh-cli` structured corrections.
- [x] Run a fresh 90-component replay with zero false nominations and all
  preservation, structural, and synthesis gates passing.
- [x] Add explicit analyzer-only approval after the replay gates pass.
- [x] Run a bounded production-path matrix with zero agent invocations.
- [x] Record validation and reconcile the goal, plan, and residual register.

## Implemented Files

- `src/arch-analyzer/internal/gosource/cli_kubernetes_runtime.go`
- `src/arch-analyzer/internal/gosource/cli_kubernetes_runtime_test.go`
- `src/arch-analyzer/internal/gosource/runtime_graph.go`
- `src/arch-analyzer/internal/gosource/gosource.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `lib/analyzer_only_approvals.json`

The extractor adds generic declared-constructor return inference and bounded
reachability through concrete `Register` and `MustRegister` callbacks. It emits:

| Category | Identity | Source |
|----------|----------|--------|
| Internal dependency | `Operator Lifecycle Manager (OLM)` | `pkg/util/client/client.go:87` |
| Runtime client | `Kubernetes API` | `pkg/util/client/client.go:97` |
| Authentication | `Kubernetes API (6443/TCP)` | `pkg/util/kube/rbac/check.go:60` |

The existing runtime-module contract also retains the accepted
`opendatahub-operator` library dependency, bringing the final correction result to
3/3.

## Validation

- Static replay:
  `tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z`
- Production matrix:
  `tmp/architecture-corpus-runs/rhoai-next-odh-cli-matrix-20260719T182500Z`
- Replay result: 90/90 analyzer snapshots, 34 approved nominations, zero false
  nominations, 3/3 target corrections resolved, and required gates passed.
- Matrix result: zero agents, 60/60 analyzer identities retained, 58/58 fixture
  structured rows retained, and required gates passed in 3.54 seconds.

Validation: [CLI Kubernetes runtime boundaries](../../notes/cli-kubernetes-runtime-boundaries-validation-2026-07-19.md).

## Status

Done.
