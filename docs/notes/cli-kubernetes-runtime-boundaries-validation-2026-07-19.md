# CLI Kubernetes Runtime Boundaries Validation, 2026-07-19

## Decision

Approve `odh-cli` for analyzer-only component generation. The fresh analyzer resolves
all 3/3 accepted structured additions and the bounded production path invokes no
component agent.

## Extraction Contract

- A shipped Go entrypoint must reach a `ConfigFlags.ToRESTConfig` result returned
  through a runtime configuration provider.
- The same configuration must reach concrete Kubernetes and OLM typed-client
  construction in a returned client wrapper.
- OLM is emitted only when the reachable lifecycle executes Subscription or
  ClusterServiceVersion reads.
- Kubernetes API Authentication is emitted only when the reachable lifecycle
  creates a `SelfSubjectAccessReview` for RBAC preflight.
- Concrete callbacks registered by reachable `Register` or `MustRegister` calls are
  included in the bounded lifecycle.
- Module-only, import-only, interface-only, test/fake, disconnected,
  construction-without-operation, and review-without-create evidence is rejected.

## Target Result

At `bcefde42f7a60f02b585e4fefcf7b8a78e08d053`, the analyzer emits:

| Category | Identity | Source |
|----------|----------|--------|
| Internal dependency | `opendatahub-operator` | existing runtime module/library evidence |
| Internal dependency | `Operator Lifecycle Manager (OLM)` | `pkg/util/client/client.go:87` |
| Authentication | `Kubernetes API (6443/TCP)` | `pkg/util/kube/rbac/check.go:60` |

The accepted change file contains three additions, not two. Earlier planning counted
only the two rows introduced by the new CLI-specific extractor and omitted the
already analyzer-owned `opendatahub-operator` row. Fresh eligibility correctly
reports 3/3 resolved.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z`

| Measure | Result |
|---------|-------:|
| Components analyzed and snapshotted | 90/90 |
| Static-analysis failures | 0 |
| Fresh analyzer-sufficient components | 64 |
| Approved analyzer-only components | 34 |
| False nominations | 0 |
| Target accepted corrections | 3/3 resolved |
| Accepted-corpus structured identities | 9,089/9,157 (99.26%) |
| Analyzer identities retained | 8,499/8,504 (99.94%) |
| Unexplained analyzer conflicts or missing rows | 0 |
| Structural validation | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The replay adds `odh-cli` to `lib/analyzer_only_approvals.json`. Eligibility projects
34 avoided agent invocations, $20.2380 historical cost avoided, 4,182.33 seconds of
summed historical agent time avoided, and 199,136 output tokens avoided.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-odh-cli-matrix-20260719T182500Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Static-analysis failures | 0 |
| Agent invocations | 0 |
| Analyzer-only documents | 1 |
| Fixture structured recall | 58/58 (100.00%) |
| Analyzer identities retained | 60/60 (100.00%) |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Workflow wall time | 3.54s |

The one fixture populated-cell conflict is a wording normalization for the
`opendatahub-operator` interaction type: accepted `Go module import
(pkg/clusterhealth)` versus analyzer `Go library`. The identity is retained, there
are zero analyzer-to-final conflicts, and the required gates accept the source-backed
normalization.

## Verification

- `go test ./...`: pass before replay.
- `go vet ./...`: pass before replay.
- Ruff: pass before replay.
- Python suite: 126 passed before replay.
- Static replay comparison: pass.
- Bounded production matrix: pass.
