# RHOAI Dashboard -- Multi-Tenancy Model

**Audit Ticket:** [RHOAIENG-76368](https://redhat.atlassian.net/browse/RHOAIENG-76368)
**Date:** 2026-07-20
**Auditor:** Jeff Young

## Tenant Definition

In the RHOAI Dashboard, a **tenant** is a user with RBAC access to one or more Kubernetes namespaces (Data Science Projects). The dashboard scopes resource visibility by forwarding the user's own bearer token (from `x-forwarded-access-token`) to the K8s API — the API server evaluates the user's own RBAC, not the dashboard SA's permissions. Users see only resources in namespaces their RBAC allows.

The dashboard does not deploy per-tenant infrastructure. It runs as a single shared pod in the platform namespace (`redhat-ods-applications`) serving all users.

## Isolation Mechanisms

### Token Forwarding (Core Tenancy Mechanism)

The dashboard uses the **user's forwarded bearer token** for K8s API calls:

1. kube-rbac-proxy (port 8443) authenticates the user (SAR: `list` on `projects`), forwards token via `x-forwarded-access-token`
2. Node.js backend extracts the token and uses it as `Authorization: Bearer <token>` for K8s API calls
3. K8s API server evaluates the user's own RBAC — the dashboard SA's permissions are not used for user requests
4. For service proxies (DSP, Model Registry, MLflow), the user's token is forwarded to the upstream service

This is **direct token forwarding**, not K8s impersonation (no impersonation headers are set).

### SA-Privileged Operations

Some operations use the **dashboard SA token** instead of the user's token, gated by SubjectAccessReview checks:

| Operation | SA Permission Used | SSAR Gate |
|-----------|-------------------|-----------|
| Notebook CR creation | `create` on `notebooks.kubeflow.org` | User can create notebooks in the namespace |
| Per-user RoleBinding creation | `create` on `rolebindings` | User has namespace access |
| Namespace labeling (`opendatahub.io/dashboard=true`) | `patch` on `namespaces` | User can `update` projects |
| Admin cluster settings | Various | User can `patch` the `Auth` singleton CR |

### Authentication

Four-layer chain:
1. **Gateway** — TLS termination
2. **kube-rbac-proxy** — SAR: user can `list` projects in `project.openshift.io`. Sets `X-Auth-Request-User` and `X-Auth-Request-Groups` headers.
3. **Node.js backend** — extracts user token from `x-forwarded-access-token`
4. **BFF sidecars** — receive user token, use for upstream calls

### RBAC

The `rhods-dashboard` ClusterRole grants the dashboard SA:

| Resource | Verbs | Notes |
|----------|-------|-------|
| secrets, configmaps, PVCs | `create/delete/get/list/patch/update/watch` | Full CRUD including delete |
| notebooks (`kubeflow.org`) | `create/delete/get/list/patch/update/watch` | Full CRUD including delete |
| rolebindings, clusterrolebindings, roles | `create/delete/get/list/patch` | No `update` or `watch` |
| namespaces | `patch` only | Namespace labeling |
| storageclasses | `patch/update` only | No create/delete |
| nodes, users, groups | `get/list` (+ `watch` for users/groups) | Read-only |

These permissions are used only for SA-privileged operations, not for user requests (which use the user's own token).

### Network Isolation

- NetworkPolicies for the dashboard pod and per-BFF-module NetworkPolicies
- External access via HTTPRoute on port 8443 through the Gateway
- Pod-internal: kube-rbac-proxy to Node.js backend over HTTP (localhost); Node.js to BFF sidecars over HTTPS with TLS
- No dashboard-created egress NetworkPolicies. The dashboard proxies to many platform services (DSP, Model Registry, MLflow, KServe, Prometheus). Cluster-wide policies may restrict egress independently.

### Token Isolation

- `automountServiceAccountToken: false` on the pod spec
- Separate projected tokens: `dashboard-sa-token` for core containers (Node.js + kube-rbac-proxy), `modules-sa-token` for BFF sidecars
- Limits blast radius if a BFF sidecar is compromised

## Known Gaps

| Gap | Impact | Severity |
|-----|--------|----------|
| Dashboard SA ClusterRole breadth | `rhods-dashboard` ClusterRole grants `create/delete` on secrets, configmaps, PVCs, notebooks, rolebindings, clusterrolebindings, and roles cluster-wide. SA-privileged operations are gated by SSAR checks. A bug in SSAR gating logic would expose these privileges across all namespaces. | P0 |
| No per-tenant dashboard configuration | `OdhDashboardConfig` is a platform-wide singleton. All tenants share the same feature flags, admin groups, and visibility settings. | P1 |
| BFF sidecars share pod network namespace | All BFF sidecars and the Node.js backend share a pod network namespace. A compromised BFF can reach all other sidecars on localhost. Mitigated by token isolation (separate projected tokens). | P1 |
| Dashboard logs may contain cross-tenant information | Pod logs from the shared pod may include request information from all users. No per-tenant log filtering. | P2 |

## Cross-Component Interactions

| RHOAI Component | Integration | Tenancy Implications |
|-----------------|-------------|----------------------|
| Kubeflow Notebooks | Creates Notebook CRs using SA token (gated by SSAR). Creates per-user Role and RoleBinding giving the user `get` access to their specific notebook. | SA-privileged creation. SSAR bypass would allow creating notebooks in any namespace. |
| Data Science Pipelines | Service proxy: forwards user's token to DSPA API. SSAR check verifies user can `GET` the DSPA CR before proxying. | User's token forwarded — DSPA's kube-rbac-proxy handles authorization. |
| MLflow | MLflow BFF proxies user's token to MLflow tracking server. Dashboard manages global MLflow workspace namespace labels (admin-only). | User's token forwarded — MLflow's kubernetes-auth SSAR handles authorization. |
| Model Registry | REST proxy + CRD management with user's token. | User's token forwarded — Model Registry's auth handles authorization. |
| KServe | K8s API pass-through with user's token. | K8s RBAC evaluated on user's identity. |
