# Data Science Pipelines -- Multi-Tenancy Model

**Audit Ticket:** [RHOAIENG-76629](https://redhat.atlassian.net/browse/RHOAIENG-76629)
**Date:** 2026-07-20
**Auditor:** Jeff Young

## Tenant Definition

In Data Science Pipelines, a **tenant** is a namespace containing a `DataSciencePipelinesApplication` (DSPA) CR. Each DSPA deploys a fully independent pipeline stack: API server, Argo Workflow Controller, Persistence Agent, Scheduled Workflow controller, MLMD gRPC/Envoy, MariaDB (or external DB), and MinIO/S3 (or external storage). There is no shared data plane between DSPAs.

Multiple DSPAs can coexist in one namespace. Each gets separate databases, object stores, ServiceAccounts, Roles, and NetworkPolicies. The typical pattern is one DSPA per namespace.

## Isolation Mechanisms

### Infrastructure Isolation (Kubernetes)

Each DSPA creates namespace-scoped resources:

| Resource | Count per DSPA | Purpose |
|----------|---------------|---------|
| Deployments | 5-7 | API server, Argo controller, persistence agent, scheduled workflow, MLMD gRPC, MLMD Envoy, MariaDB (optional) |
| Services | 5-7 | ClusterIP for each component |
| ServiceAccounts | 6-8 | Per-component SAs (`ds-pipeline-{name}`, `pipeline-runner-{name}`, `mariadb-{name}`, etc.) |
| Roles/RoleBindings | 6+ | Per-component namespace-scoped roles |
| NetworkPolicies | 3-4 | API server, MariaDB, MLMD gRPC, MLMD Envoy |
| Secrets | 3+ | DB credentials, S3 credentials, TLS certs (service-ca) |
| ConfigMaps | 3+ | `kfp-launcher`, Argo controller config, UI config |
| PVCs | 1-2 | MariaDB storage, MinIO storage (when managed) |
| Routes | 1-2 | API server, MinIO (when managed) |

All namespace-scoped resources carry owner references and are garbage-collected on DSPA deletion.

Cluster-scoped resources (cleaned up by finalizer):
- `ds-pipeline-ui-auth-delegator-{namespace}-{name}` ClusterRoleBinding (binds `ds-pipeline-{name}` and `ds-pipeline-metadata-envoy-{name}` SAs to `system:auth-delegator`)

### Data Isolation

Each DSPA gets its own database and object storage:

| Data Type | Isolation | Mechanism |
|-----------|-----------|-----------|
| Pipeline definitions, run history, experiments | Per-DSPA MariaDB instance (or external DB) | Separate database, separate credentials (`ds-pipeline-db-{name}`) |
| Pipeline artifacts (inputs/outputs, logs) | Per-DSPA MinIO instance (or external S3) | Separate object store, separate credentials (`ds-pipeline-s3-{name}`) |
| ML Metadata (executions, artifacts, lineage) | Per-DSPA MLMD gRPC server | Connects to the per-DSPA MariaDB |
| Pipeline cache | Per-DSPA database | V2 cache in MLMD, V1 cache in SQL table |

When using `externalStorage`, the `BasePath` field provides per-DSPA subpath isolation within a shared S3 bucket. This is application-enforced, not IAM-enforced.

### Authentication & Authorization

External access to the API server goes through a kube-rbac-proxy sidecar:
- Port 8443 (TLS, reencrypt termination via OpenShift Route)
- SubjectAccessReview on `datasciencepipelinesapplications/api` subresource, scoped to the specific DSPA name and namespace
- Users must have explicit RBAC grants on this subresource

Aggregate ClusterRoles control user access:
- `aggregate-dspa-admin-edit` (aggregates into `admin`/`edit`) — full CRUD on DSPA, Pipeline, PipelineVersion CRDs
- `aggregate-dspa-admin-view` (aggregates into `view`) — read-only access

Inter-service auth uses projected ServiceAccount tokens with audience `pipelines.kubeflow.org` and 1-hour expiry.

### Network Isolation

Per-DSPA NetworkPolicies restrict ingress to internal ports:

| Policy Target | Allowed Sources | Ports |
|--------------|----------------|-------|
| API Server (8888, 8887) | Same-DSPA component pods, monitoring namespaces, pipeline executor pods, workbench pods | 8888, 8887 |
| MariaDB (3306) | DSPO operator pod, this DSPA's API server pod, this DSPA's MLMD gRPC pod only | 3306 |
| MLMD gRPC (8080) | Same-DSPA component pods, pipeline executor pods | 8080 |

NetworkPolicies use per-DSPA label selectors — MariaDB for DSPA-A is only reachable by DSPA-A's API server, not DSPA-B's, even within the same namespace.

Port 8443 (kube-rbac-proxy) is not restricted by NetworkPolicy — it handles authentication.

**No egress NetworkPolicies** are created. Pipeline step pods can make outbound connections to any destination.

Pod-to-pod TLS is enabled by default (`PodToPodTLS: true`) via OpenShift service-ca certificates.

## Known Gaps

| Gap | Impact | Severity |
|-----|--------|----------|
| No egress NetworkPolicy | Pipeline step pods run arbitrary user code with unrestricted egress. No data exfiltration prevention. | P0 |
| `pipeline-runner` Role over-permissioned (cluster-verified) | The `pipeline-runner-{name}` Role grants `get`/`list` on all secrets in the namespace, `*` on pods/exec, `*` on deployments, `*` on all `kubeflow.org` resources. Cluster-verified on RHOAI 3.5 EA2: a pod running as `pipeline-runner` read the MariaDB password, S3 credentials, and listed all 8 secrets. The Role is namespace-scoped (no cross-tenant boundary violation). | P1 |
| No ResourceQuota / LimitRange | DSPO does not create quotas. Unbounded pipeline runs can consume all cluster resources. | P1 |
| DB and S3 credentials not auto-rotated | `ds-pipeline-db-{name}` and `ds-pipeline-s3-{name}` secrets are generated at DSPA creation and never rotated. | P1 |
| `verify=False` SSL fallback in pipelines-components | Some pipeline components fall back to disabling certificate verification on SSL errors. | P1 |
| External storage `BasePath` isolation is application-enforced | When multiple DSPAs share an external S3 endpoint, `BasePath` subpath isolation is not IAM-enforced. | P2 |

## Cross-Component Interactions

| RHOAI Component | Integration | Tenancy Implications |
|-----------------|-------------|----------------------|
| ODH Dashboard | Lists/creates/manages DSPA CRs and pipeline runs via user impersonation. Binds `ds-pipeline-user-access-{name}` Role for per-DSPA access. | RBAC-consistent. Dashboard is responsible for creating the user-access RoleBinding. |
| Workbenches (Elyra) | `ds-pipeline-config` secret mounted in notebook pods; KFP SDK submits pipelines | DSPA credentials are namespace-scoped. All workbenches in the namespace connect to the same DSPA. |
| KServe | Pipeline steps can create InferenceServices via `pipeline-runner` SA | `pipeline-runner` has `create`/`get`/`list`/`patch`/`delete` on `inferenceservices.serving.kserve.io` in the namespace |
| Model Registry | Pipeline components register models over HTTP | Model Registry's own access controls apply. Plaintext HTTP, no auth by default. |
| MLflow | Pipeline steps can log experiments/runs via `pipeline-runner` SA (when MLflow RBAC is granted) | `pipeline-runner` Role conditionally includes `mlflow.kubeflow.org` experiment/run permissions |
