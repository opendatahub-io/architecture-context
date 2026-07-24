# Dashboard Analyzer Fidelity Audit

## Scope

This audit compares `architecture/rhoai.next/odh-dashboard.md` with a fresh
analyzer document generated from dashboard commit
`f1cdd9f22ebd3b320de9cf45e9ba3fdb6a93e335`. Source paths below are relative to
that checkout. The existing Markdown is treated as a regression fixture, not as
unquestioned ground truth.

The comparison excludes recent Git history and the files-read inventory from the
architecture-fidelity denominator. Those are evidence inventories rather than
architecture identities.

## Result

| Measure | Before | After |
|---------|-------:|------:|
| Structured identity recall | 141/165 (85.45%) | 162/166 (97.59%) |
| Adjudicated structured recall | Not measured | 162/162 (100%) |
| Whole-document row recall | 170/292 (58.22%) | 192/293 (65.53%) |
| Populated-cell conflicts | 47 | 28 |
| Extraction | about 0.50s | 0.49s |
| Rendering | less than 0.01s | less than 0.01s |
| Structural validation | Passed | Passed |

The structured denominator increased by one because role binding identity now
includes the referenced role. This preserves the fixture's separate `Role` and
`ClusterRole` bindings that previously collapsed under the same binding name.

All four remaining raw misses are fixture defects or out-of-scope facts and are
removed from the adjudicated denominator. No source-backed fixture identity remains
unexplained.

## Original Missing Identities

Every one of the original 24 missing structured identities has the following
row-level disposition.

| Category | Baseline identity | Disposition | Evidence or fix |
|----------|-------------------|-------------|-----------------|
| Internal dependency | `Perses` | Analyzer defect, fixed | Federation config declares the Perses proxy at `manifests/modular-architecture/federation-configmap.yaml:181`. |
| Internal dependency | `rhods-operator / opendatahub-operator` | Analyzer defect, fixed | Managed-by label at `dashboard-operator/charts/dashboard/values.yaml:14`. |
| Egress | `External (HTTP/S)` | Fixture scope defect, excluded | The cited behavior is browser navigation and documentation links, for example `frontend/src/components/ExternalLink.tsx:18`; it is not dashboard server/pod egress. |
| Cluster RBAC | `dashboard-operator-role`; core resources | Comparator defect, fixed | Core API group blanks and unordered resource lists are now canonicalized. Source: `dashboard-operator/config/rbac/role.yaml:34`. |
| Cluster RBAC | `dashboard-operator-role`; `networking.k8s.io` | Comparator defect, fixed | Resource-list order is non-semantic. |
| Cluster RBAC | `dashboard-operator-role`; `rbac.authorization.k8s.io` | Comparator defect, fixed | Resource-list order is non-semantic. |
| Cluster RBAC | `odh-dashboard`; core ConfigMaps/PVCs/Secrets | Comparator defect, fixed | Empty and quoted-empty core API groups are equivalent. Source: `manifests/core-bases/base/sa-rbac/cluster-role.yaml:55`. |
| Cluster RBAC | `odh-dashboard`; core namespaces | Comparator defect, fixed | Empty and quoted-empty core API groups are equivalent. Source: `manifests/core-bases/base/sa-rbac/cluster-role.yaml:128`. |
| Cluster RBAC | `odh-dashboard`; core nodes | Comparator defect, fixed | Empty and quoted-empty core API groups are equivalent. Source: `manifests/core-bases/base/sa-rbac/cluster-role.yaml:13`. |
| Cluster RBAC | `odh-dashboard`; core Pods/SAs/Services | Comparator defect, fixed | Empty and quoted-empty core API groups are equivalent. Source: `manifests/core-bases/base/sa-rbac/cluster-role.yaml:118`. |
| Cluster RBAC | `odh-dashboard`; MachineAutoscalers/MachineSets | Fixture incomplete, excluded | The source rule includes both `machine.openshift.io` and `autoscaling.openshift.io`; the fixture records only one. Source: `manifests/core-bases/base/sa-rbac/cluster-role.yaml:20`. |
| Cluster RBAC | `odh-dashboard`; RBAC resources | Comparator defect, fixed | Resource-list order is non-semantic. |
| Cluster RBAC | `odh-dashboard`; TrustyAI resources | Comparator defect, fixed | Resource-list order is non-semantic. |
| Cluster RBAC | `odh-dashboard`; users/groups | Normalization defect, fixed | Equal role/group/verb rules are merged before rendering. Source: `manifests/core-bases/base/sa-rbac/cluster-role.yaml:102`. |
| Role binding | `odh-dashboard-image-puller` | Fixture incorrect, excluded | Source name is `cluster-image-pullers` and subject is group `system:serviceaccounts`, not dashboard SA. Source: `manifests/core-bases/base/sa-rbac/image-puller.clusterrolebinding.yaml:1`. |
| Integration | `AcceleratorProfile CR` | Analyzer defect, fixed | Exact API group/resource extraction from `manifests/core-bases/base/sa-rbac/role.yaml:12`. |
| Integration | `cert-manager` | Analyzer defect, fixed | Certificate manifests at `dashboard-operator/config/webhook/manifests.yaml:42`. |
| Integration | `DataScience Pipelines` | Semantic-alias defect, fixed | `DataScience Pipelines API` is the same REST-proxy target. Source: `backend/src/routes/api/service/pipelines/index.ts`. |
| Integration | `MaaS BFF (inter-BFF)` | Analyzer defect, fixed | GenAI BFF service configuration at `manifests/modular-architecture/modules/gen-ai/deployment.yaml:152`. |
| Integration | `MCP Servers` / `Stdio/HTTP` | Fixture stale, excluded | Current source supports SSE and streamable HTTP, not stdio. Sources: `packages/gen-ai/bff/internal/constants/mcp.go:11` and `packages/gen-ai/bff/internal/models/aaa_mcp.go:56`. |
| Integration | `NIM Account CR` | Analyzer defect, fixed | Exact API group/resource extraction from `manifests/common/rbac/all-users/fetch-nim-account.rbac.yaml:6`. |
| Integration | `Perses` | Semantic-alias defect, fixed | `Perses Service` is the same REST-proxy target. Source: `manifests/modular-architecture/federation-configmap.yaml:181`. |
| Integration | `rhods-operator / opendatahub-operator` | Analyzer defect, fixed | Managed-by evidence at `dashboard-operator/charts/dashboard/values.yaml:14`. |
| Integration | `ServingRuntime CR` | Analyzer defect, fixed | Exact API group/resource extraction from `manifests/core-bases/base/sa-rbac/role.yaml:127`. |

## Conflict Audit

### Component Purpose Prose

The 16 component-purpose conflicts are semantic-compatible wording differences.
The analyzer emits a concise role description while the fixture contains agent
synthesis. Identity, component type, and source evidence are retained. These rows
remain legitimate synthesis opportunities and are not extractor defects.

| Component identity | Analyzer evidence |
|--------------------|-------------------|
| `agent-ops BFF` | `packages/agent-ops/bff/go.mod:1` |
| `app-config` | `packages/app-config/package.json:3` |
| `automl BFF` | `packages/automl/bff/go.mod:1` |
| `autorag BFF` | `packages/autorag/bff/go.mod:1` |
| `backend` | `backend/package.json:2` |
| `core-bff` | `distributions/core-bff/bff/go.mod:1` |
| `dashboard-operator` | `dashboard-operator/go.mod:1` |
| `eval-hub BFF` | `packages/eval-hub/bff/go.mod:1` |
| `frontend (host app)` | `frontend/package.json:2` |
| `gen-ai BFF` | `packages/gen-ai/bff/go.mod:1` |
| `k8s-core` | `packages/k8s-core/package.json:3` |
| `kube-rbac-proxy` | `manifests/rhoai/base/deployment.yaml` |
| `maas BFF` | `packages/maas/bff/go.mod:1` |
| `mlflow BFF` | `packages/mlflow/bff/go.mod:1` |
| `model-registry BFF` | `packages/model-registry/upstream/bff/go.mod:1` |
| `plugin-core` | `packages/plugin-core/package.json:3` |

### Technical Cells

| Category and identity | Difference | Disposition | Evidence |
|-----------------------|------------|-------------|----------|
| Egress `Kubernetes API` protocol | Fixture `HTTPS`; analyzer `HTTPS/WSS` | Fixture incomplete; analyzer retains both REST and watch transports. | `backend/src/routes/wss/k8s/index.ts:77` and `backend/src/plugins/kube.ts`. |
| Egress `Prometheus/Thanos` port | Fixture `9091`; analyzer `9092` | Fixture stale; analyzer correct. | `backend/src/utils/constants.ts:181`. |
| Egress `TrustyAI Service` port | Fixture `varies`; analyzer `443` | Analyzer is a source-backed refinement. | `backend/src/routes/api/service/trustyai/index.ts:12`. |
| Cluster RBAC Dashboard subresources | Fixture appends status/finalizers to Dashboard verbs; analyzer emits separate resources | Fixture conflates three Kubernetes resources; analyzer correct. | `dashboard-operator/config/rbac/role.yaml:7-32`. |
| Auth-delegator binding namespace | Fixture `kube-system`; analyzer `redhat-ods-applications` | Fixture incorrect for the pinned RHOAI overlay. | `manifests/rhoai/base/auth-delegator.clusterrolebinding.yaml:7-9`. |
| `odh-dashboard-modules-token` type | Fixture `Opaque`; analyzer `kubernetes.io/service-account-token` | Fixture incorrect; analyzer correct. | `manifests/modular-architecture/modules-sa-token-secret.yaml:1`. |
| Integration `Llama Stack Server` encryption | Fixture `TLS 1.2+`; analyzer `TLS` | Fixture is more specific than the client source supports and conflicts with its own egress row. | `packages/gen-ai/bff/internal/integrations/llamastack/llamastack_client.go:38`. |
| Integration `ML Metadata (MLMD)` protocol | Fixture `HTTPS`; analyzer `gRPC-web` | Fixture records transport security in the protocol cell; analyzer records the application protocol. | `backend/src/routes/api/service/mlmd/index.ts`. |
| Integration `Prometheus/Thanos` port | Fixture `9091`; analyzer `9092` | Fixture stale; analyzer correct. | `backend/src/utils/constants.ts:181`. |
| Integration `TrustyAI Service` port | Fixture `varies`; analyzer `443` | Analyzer is a source-backed refinement. | `backend/src/routes/api/service/trustyai/index.ts:12`. |
| Source `backend/src/routes/wss/k8s/index.ts` lines | Fixture `1-30`; analyzer `77` | Analyzer points to the exact extracted declaration. | `backend/src/routes/wss/k8s/index.ts:77`. |
| Source GenAI deployment lines | Fixture `1-50`; analyzer `152` | Analyzer points to the exact inter-BFF configuration. | `manifests/modular-architecture/modules/gen-ai/deployment.yaml:152`. |

## Implemented Corrections

- The comparator reports structured recall separately from history and source-file
  inventory and can enforce it with `--min-structured-recall`.
- RBAC core groups and unordered group/resource lists compare semantically.
- Role binding identity retains role kind and supports an omitted kind as a wildcard.
- Equal role/group/verb rules merge their resource lists before rendering.
- Source-backed dashboard operator, Perses, cert-manager, MaaS, MCP, NIM,
  AcceleratorProfile, and ServingRuntime relationships are extracted.
- OpenShift serving-certificate annotations upgrade referenced Secrets to
  `kubernetes.io/tls` with their provisioner.
- Source endpoints win normalization ties over generic workload probes.

## Agent Treatment

The preserved bounded dashboard treatment completed in 485 seconds, used 19 tool
calls, read eight targeted files, and spawned no sub-agents. It retained every
structured identity supplied by its analyzer input. A fresh Claude treatment was
attempted after this audit but the local CLI had no active credentials; it failed
before an API call in 0.79 seconds and did not modify the generated document.

The synthesis-only sections from the preserved treatment are rebased onto the new
analyzer document for final validation. This keeps the newly corrected structured
tables authoritative while avoiding an unmeasured replacement agent run.

The deterministic synthesis rebase completed in 0.04 seconds. The resulting
dashboard document passes structural validation, preserves 314/314 structured
identities from the current analyzer document, and has zero analyzer-to-agent cell
conflicts. Its comparison with the regression fixture remains 162/166 (97.59%), as
expected from the four adjudicated fixture exclusions.

## Second Repository

`caikit-nlp` at commit `a56a086b62d289a9a0d341761207f763f900ed38`
exercises the `partial` path because its API surface is dynamically registered.

| Measure | Result |
|---------|-------:|
| Extraction | 0.09s |
| Rendering | less than 0.01s |
| Analyzer fixture recall | 18/56 structured identities (32.14%) |
| Bounded agent fixture recall | 27/56 structured identities (48.21%) |
| Current analyzer identities retained by agent | 20/20 (100%) |
| Bounded agent time | 239s |
| Structural validation | Passed |

The two analyzer-to-agent cell changes are the `caikit-nlp` component type and
purpose. The bounded treatment expanded `Python gRPC Service` / `Caikit NLP` to a
source-informed runtime and capability description after its targeted Python pass;
it did not remove an analyzer identity. This confirms that the comparison and
preservation gates support both `sufficient` copy-and-synthesize documents and
`partial` documents requiring bounded dynamic-framework investigation.
