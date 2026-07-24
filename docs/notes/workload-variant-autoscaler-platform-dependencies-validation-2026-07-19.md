# Workload Variant Autoscaler Platform Dependencies Validation, 2026-07-19

## Decision

Approve `workload-variant-autoscaler` for analyzer-only component generation. The
analyzer now derives its five previously missing platform dependencies from runtime
source: Prometheus, KEDA, LeaderWorkerSet, Gateway API Inference Extension, and
Prometheus Operator.

The accepted-production fixture used Go import aliases for five controller watches.
The analyzer replaces those aliases with canonical Kubernetes GVKs such as
`keda.sh/v1alpha1/ScaledObject` and
`inference.networking.k8s.io/v1/InferencePool`. This is an intentional source-backed
correction, not lost behavior. The analyzer also preserves the source- and
manifest-proven `:8081` listener on health and readiness checks.

## Generic Extraction

- Go package paths for KEDA, LeaderWorkerSet, Prometheus Operator, and both Gateway
  API Inference Extension packages normalize to canonical API groups.
- Controller registrations guarded by CRD detection retain conditional semantics.
- A Prometheus dependency requires construction of the Prometheus client and API
  wrapper followed by runtime use in the same function; imports and disconnected
  construction are negative controls.
- A repository's owned API group is excluded from its own platform dependencies,
  while consumers of the same API remain eligible.
- CI and end-to-end shell paths are support-only; production deployment,
  entrypoint, hook, and operator scripts remain visible dependency surfaces.
- Controller-runtime health listener defaults resolve through repository-wide
  Viper getter, backing-field, default, and flag bindings.
- Manifest probe ports are resolved, and an identical source-backed probe fact
  suppresses the weaker manifest duplicate.

The probe improvement exposed an obsolete path-only MaaS correction. Its selected
Deployment fixes the endpoint at `:8080/health`, so the historical `/health` key is
source-adjudicated rather than weakening endpoint matching.

## Full Static Replay

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-wva-dependencies-static-20260719T134420Z`

| Measure | Result |
|---------|-------:|
| Components analyzed | 90 |
| Static-analysis failures | 0 |
| Static-analysis wall time | 12.26s |
| Analyzer-sufficient components | 63 |
| Approved analyzer-only components | 28 |
| Newly approved components | 1 |
| False nominations | 0 |
| Target corrections resolved or adjudicated | 8/8 |
| Analyzer identities retained | 8,362/8,367 (99.94%) |
| Accepted analyzer conflicts | 16 |
| Accepted analyzer row corrections | 5 |
| Unexplained analyzer conflicts | 0 |
| Unexplained missing analyzer rows | 0 |
| Structurally valid documents | 90/90 |
| Synthesis/structure quality | 90/90 |
| Required gates | PASS |

The accepted-production fixture retains 9,094/9,157 structured identities (99.31%).
Workload Variant Autoscaler retains 88/93 (94.62%); its only five missing fixture
keys are the corrected import-alias watch identities described above.

The approved set projects 28 avoided agent invocations, $13.1531 in historical
cost, 2,662.35 summed agent seconds, 108 reads, 52 source files, and 123,393 output
tokens.

## Production-Path Matrix

Artifacts:
`tmp/architecture-corpus-runs/rhoai-next-wva-dependencies-matrix-20260719T140520Z`

| Measure | Result |
|---------|-------:|
| Components | 1 |
| Analyzer-only routes | 1 |
| Agent invocations | 0 |
| Analyzer identities retained | 98/98 |
| Historical structured recall | 88/93 (94.62%) |
| Structural validation | 1/1 |
| Synthesis/structure quality | 1/1 |
| Required gates | PASS |
| Workflow wall time | 2.77s |

## Verification

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`: pass.
- `.venv/bin/ruff check .`: pass.
- `.venv/bin/pytest -q --ignore=tests/test_strace_agent.py`: pass.
- `git diff --check`: pass.
