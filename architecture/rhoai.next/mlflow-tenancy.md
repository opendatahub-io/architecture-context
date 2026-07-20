# MLflow -- Multi-Tenancy Model

**Audit Ticket:** [RHOAIENG-76371](https://redhat.atlassian.net/browse/RHOAIENG-76371)
**Date:** 2026-07-20
**Auditor:** Jeff Young

## Tenant Definition

In MLflow, a **tenant** is a Kubernetes namespace mapped to an MLflow workspace. The `kubernetes://` workspace provider reflects K8s namespaces as MLflow workspaces in a read-only, 1:1 mapping. The workspace is determined per-request from the `X-MLFLOW-WORKSPACE` HTTP header (set by the Python SDK's `kubernetes-namespaced` auth provider, which auto-detects the pod's namespace).

MLflow uses a **single shared server** model — one cluster-scoped singleton `MLflow` CR deploys one tracking server in the platform namespace. All tenants share the same server process and the same database.

## Isolation Mechanisms

### Infrastructure (Shared Server)

The MLflow tracking server is a single Deployment in `redhat-ods-applications`. All tenants share:
- One server process (horizontal scaling via replicas, shared database connection pool)
- One PostgreSQL database (the `MLflow` CR has a single `backendStoreUri` — no per-tenant database mechanism exists)
- One GC CronJob

Per-tenant resources:
- `MLflowConfig` CR (namespace-scoped, name must be `mlflow`) — overrides artifact storage per namespace
- `mlflow-artifact-connection` Secret (namespace-scoped) — per-tenant S3 bucket and credentials
- RoleBindings (per-namespace, via `NamespaceRBACReconciler` when namespaces are labeled `opendatahub.io/global-mlflow-workspace=mlflow`)

### Authentication & Authorization

Every API request carries a Kubernetes ServiceAccount bearer token. The `kubernetes-auth` plugin performs a `SelfSubjectAccessReview` against pseudo-resources in the `mlflow.kubeflow.org` API group, scoped to the target workspace namespace:

| Pseudo-Resource | View Verbs | Edit Verbs |
|-----------------|-----------|------------|
| `experiments` | get, list | create, update, delete |
| `registeredmodels` | get, list | create, update, delete |
| `datasets` | get, list | create, update, delete |
| `gatewayendpoints` | get, list | create, update, delete, `/use` |
| `gatewaysecrets` | get, list | — |
| `gatewaymodeldefinitions` | — | `/use` |

Aggregate ClusterRoles:
- `mlflow-operator-mlflow-view` (aggregates into `view`/`edit`/`admin`) — read access to pseudo-resources
- `mlflow-operator-mlflow-edit` (aggregates into `edit`/`admin`) — write access to pseudo-resources

**Cluster-verified on RHOAI 3.5 EA2:** spoofing the `X-MLFLOW-WORKSPACE` header does not grant cross-workspace access — the server checks the caller's token against the target namespace's RBAC, not just the header value. Tenant-b cannot search, get, or create experiments in tenant-a's workspace (returns `PERMISSION_DENIED` or empty results).

### Data Isolation

Two layers enforce workspace isolation:

1. **K8s SSAR** — blocks cross-workspace API access at the authorization level
2. **`WorkspaceAwareSqlAlchemyStore`** — every SQL query includes `WHERE workspace = ?`. Every entity table (`SqlExperiment`, `SqlRun`, `SqlTraceInfo`, `SqlLoggedModel`, `SqlScorer`, `SqlGatewaySecret`, `SqlGatewayEndpoint`, etc.) has a `workspace` column. Validation methods (`_validate_run_accessible()`, `_validate_trace_accessible()`, `_validate_dataset_accessible()`) confirm ownership before access.

Both layers must fail simultaneously for a cross-tenant data leak.

### Artifact Isolation

| Mode | Isolation | How to Configure |
|------|-----------|-----------------|
| **Default (shared)** | Path-based only (`/workspaces/<workspace_name>/<experiment_id>/`). All tenants share the same S3 bucket and credentials. | No configuration needed — this is the default. |
| **BYO per tenant** | Credential-based. Each tenant has its own S3 bucket, endpoint, and access keys. | Create a `MLflowConfig` CR and `mlflow-artifact-connection` Secret in the tenant namespace with `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_S3_BUCKET`, `AWS_S3_ENDPOINT`. |

BYO database per tenant is not supported — the `MLflow` CR is a cluster-scoped singleton with a single `backendStoreUri`.

### Network Isolation

| Policy | Ingress | Egress |
|--------|---------|--------|
| MLflow server | Port 8443 from any namespace (shared service — auth enforced per request) | DNS (53, 5353), HTTPS (443, 6443, 8443), PostgreSQL (5432), MySQL (3306), S3 (9000, 8333, 8334). Customizable via CR spec. |
| Migration Job | None (ingress blocked) | DNS + database only |

### Compute Isolation

None — all tenants share the same server pod(s). No per-tenant rate limiting, request queuing, or resource partitioning.

## Known Gaps

| Gap | Impact | Severity |
|-----|--------|----------|
| Shared database, no BYO database per tenant | All tenants share one PostgreSQL instance. The `MLflow` CR is a singleton with a single `backendStoreUri`. No database-level Row-Level Security. Isolation depends on SSAR + application SQL filtering. | P0 |
| Server SA can read `mlflow-artifact-connection` secrets cluster-wide | The `mlflow` ClusterRole grants `get/list/watch` on secrets with `resourceNames: ["mlflow-artifact-connection"]` across all namespaces. Pod compromise exposes all tenants' artifact credentials. | P0 |
| Default shared artifact credentials | BYO artifact storage per tenant is supported but opt-in. Without per-namespace `MLflowConfig`, all tenants share the same S3 bucket/credentials with path-based isolation only. | P1 |
| No per-tenant compute isolation | Single shared server. An expensive query from one tenant impacts all others. No rate limiting. | P1 |
| Gateway secrets encrypted with shared KEK | AES-GCM envelope encryption uses a single `MLFLOW_CRYPTO_KEK_PASSPHRASE` for all tenants. | P2 |

## Cross-Component Interactions

| RHOAI Component | Integration | Tenancy Implications |
|-----------------|-------------|----------------------|
| Workbenches | Python SDK with `kubernetes-namespaced` auth provider auto-detects pod namespace and injects `Authorization` + `X-MLFLOW-WORKSPACE` headers | Workspace = pod's namespace (auto-detected) |
| Data Science Pipelines | Python SDK from pipeline step pods. `pipeline-runner` SA token used for auth. | `pipeline-runner` SA needs `mlflow-integration` or aggregate role bindings in the namespace |
| ODH Dashboard | Lists MLflow CRs, reads experiment/model status | Uses `mlflow-view` aggregate role — consistent with standard K8s RBAC |
