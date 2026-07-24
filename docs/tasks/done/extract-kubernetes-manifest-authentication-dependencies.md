# Task: Extract Kubernetes Manifest Authentication And Dependencies

## Goal

Resolve or source-adjudicate the 27 accepted corrections for `rhoai-mcp`,
`llm-d-routing-sidecar`, `llm-d-batch-gateway-operator`,
`trustyai-explainability`, and `llm-d-planner` through generic selected-manifest,
runtime-correlation, authentication, and platform-resource contracts.

## Context

These corrections were grouped as Kubernetes-manifest evidence, but their quality
varies substantially. Probe paths, Prometheus annotations, environment endpoints,
RBAC, CRD fields, and selected workload references are useful evidence. Absence of
an auth sidecar, a ServiceAccount name, a secret key, a comment, or a CRD schema by
itself is not enough to prove a runtime relationship. Treat every historical row as
a hypothesis and adjudicate invalid or overstated rows rather than encoding them.

The analyzer already emits unauthenticated probe facts only when an uncredentialed
HTTP probe correlates to an analyzer-discovered handler. Preserve that strong
contract and extend it only where equally concrete runtime evidence exists.

## Source And Evidence

- Accepted baseline:
  `tmp/architecture-corpus-runs/rhoai-next-20260718T215431Z`
- Current approved analyzer-only replay:
  `tmp/architecture-corpus-runs/rhoai-next-mr-kserve-dep-static-20260719T234520Z`
- Fresh correction source:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T011611Z-3540380`
- Exact rows:
  `logs/agents/<component>.merge.json` and `.merge.md` under the fresh correction
  source.

Audit these exact revisions without resetting dirty checkouts:

| Component | Checkout | Revision | Rows |
|-----------|----------|----------|-----:|
| `rhoai-mcp` | `/data/checkouts/red-hat-data-services.next/rhoai-mcp` | `d6b60e02bbabae7a315a57d2b5b6b8f4afcd2e8c` | 1 |
| `llm-d-routing-sidecar` | `/data/checkouts/red-hat-data-services.next/llm-d-routing-sidecar` | `cc502d185a124d82170df5675b7ec9a533acfd4f` | 3 |
| `llm-d-batch-gateway-operator` | `/data/checkouts/red-hat-data-services.next/llm-d-batch-gateway-operator` | `69f2d6b2203bdd5e55a171a8046cd0dd8123c919` | 5 |
| `trustyai-explainability` | `/data/checkouts/red-hat-data-services.next/trustyai-explainability` | `865224735e7faeb4997cf3acede5ab2c1e8b42f9` | 8 |
| `llm-d-planner` | `/data/checkouts/llm-d-incubation.next/llm-d-planner` | `1d351a5a24506d9ed53f3d8c36c8f277c56d0920` | 10 |

## Correction Inventory

| Component | Category and accepted identities | Primary evidence |
|-----------|----------------------------------|------------------|
| `rhoai-mcp` | Authentication: `/health :: GET` | `deploy/kustomize/base/deployment.yaml:56-70` |
| `llm-d-routing-sidecar` | Internal dependency: platform operator; Authentication: port 8080 root and templated OpenShift Route | `deploy/common/patch-statefulset.yaml:16-19`, `deploy/common/patch-service.yaml:8-11`, `deploy/openshift/patch-route.yaml:1-7` |
| `llm-d-batch-gateway-operator` | Internal dependencies: OpenDataHub operator, Gateway API, Prometheus Operator, cert-manager, llm-d inference gateway | `cmd/main.go:17-65,147-159`, CRD schema and aggregate RBAC under `config/` |
| `trustyai-explainability` | Internal dependencies: KServe, Prometheus, `trustyai-config`; Authentication: Route and two health probes; Integrations: KServe ConfigMap injection and Prometheus scraping | `explainability-service/manifests/base/trustyai-deployment.yaml:9-140`, `explainability-service/manifests/base/route.yaml:13-17` |
| `llm-d-planner` | Internal dependencies: service CA, core/v1 Nodes, OpenShift Route; Integrations: Postgres, Ollama, Kubernetes API, Hugging Face, OpenAI-compatible API, Vertex AI, Model Catalog | `deploy/kubernetes/backend.yaml:1-164`, `deploy/kubernetes/gpu-reader-rbac.yaml:9-18` |

## Required Contracts

- Resolve the selected Kustomize/manifest workload graph before using a resource as
  evidence. Keep examples, tests, development overlays, and unselected templates
  out of production facts.
- Preserve the existing probe-authentication rule: an HTTP probe without credential
  headers may prove an unauthenticated surface only when its path and method
  correlate to a reachable server handler. A probe alone is insufficient.
- Collect individual environment literals, `configMapKeyRef`, `secretKeyRef`,
  `envFrom`, volumes, ServiceAccounts, Routes, annotations, and init-container
  behavior with exact source provenance.
- Emit an integration from manifest configuration only when an endpoint or selected
  provider plus runtime source proves client behavior. Record optional providers as
  conditional. A credential variable alone does not prove a client or destination.
- Distinguish configuration resources from platform components. A ConfigMap,
  Secret, PVC, ServiceAccount, or Route is not automatically an Internal Platform
  Dependency.
- Derive platform ownership from a closed evidence chain such as selected workload
  reference plus selected provisioner/controller behavior, or runtime API use plus
  RBAC. Names and comments are discovery leads only.
- Correlate CRD configuration fields and RBAC with controller/runtime consumption
  before emitting Gateway API, Prometheus Operator, cert-manager, or inference
  gateway dependencies. Schema capability alone is insufficient.
- Recognize selected Prometheus scrape annotations and selected init-container
  mutations only when their target and lifecycle are concrete. Do not convert a
  tooling image such as `ose-cli` into a service dependency.
- Keep Route authentication and TLS claims conservative. Missing annotations,
  missing sidecars, `tls: null`, platform defaults, or unresolved template names do
  not prove an authenticated or unauthenticated public surface.
- Implement reusable contracts without component-name exceptions or repository-path
  allowlists.

## Negative Controls

Reject unselected examples, demos, fixtures, tests, documentation, and overlays;
manifest auth claims based only on absence; unresolved template identities;
ServiceAccount ownership inferred from its name; comment-only platform attribution;
secret keys without endpoint and runtime use; optional providers presented as
required; CRD schema fields without controller/runtime consumption; RBAC without a
correlated client or workload; generic ConfigMaps, Secrets, PVCs, and Routes treated
as platform components; init/tool images treated as external services; and one
component's product semantics projected onto another repository.

## Acceptance Criteria

- [ ] Audit all 27 fresh merge rows at the revisions above and record each as
  analyzer-resolved, valid-but-unsupported, or invalid historical evidence.
- [ ] Resolve or adjudicate 27/27 rows without component-specific exceptions.
- [ ] Add positive and negative tests for every new evidence contract, including
  selection, runtime correlation, optional providers, and absence-only rejection.
- [ ] Preserve existing probe-handler correlation and prove no weaker auth facts are
  introduced.
- [ ] Run `go test ./...` and `go vet ./...` in `src/arch-analyzer`.
- [ ] Run Ruff and the Python suite for affected collection, rendering, routing, and
  corpus measurement behavior.
- [ ] Run a fresh 90-component static replay with zero false nominations and all
  preservation, structural, and synthesis gates passing.
- [ ] Source-audit every newly nominated component before changing the approved set.
- [ ] Run a bounded production matrix for newly approved components only when the
  replay changes routing.
- [ ] Write a validation note with per-row dispositions, update the residual
  register and goal, and move this task to `docs/tasks/done/` only after all
  applicable gates pass.

## Likely Files

- `src/arch-analyzer/internal/extractor/collectors.go`
- `src/arch-analyzer/internal/extractor/extractor.go`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts.go`
- `src/arch-analyzer/internal/platformfacts/platformfacts_test.go`
- `src/arch-analyzer/internal/normalize/normalize.go`

## Status

Done. 3/27 resolved by analyzer (infrastructure API group RBAC-to-dependency), 24/27
source-adjudicated. Approved set unchanged at 36. See
[validation note](../../notes/kubernetes-manifest-authentication-dependencies-validation-2026-07-20.md).
