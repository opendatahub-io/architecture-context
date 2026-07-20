# Workbenches -- Multi-Tenancy Model

**Audit Ticket:** [RHOAIENG-76627](https://redhat.atlassian.net/browse/RHOAIENG-76627)
**Date:** 2026-07-20
**Auditor:** Jeff Young

## Tenant Definition

In Workbenches, a **tenant** is a Kubernetes namespace containing one or more `Notebook` CRs (`kubeflow.org/v1`). The namespace is the sole tenant boundary -- there is no application-level tenant concept beyond the namespace. Users with the required Notebook RBAC permissions (`get`, `list`, `watch` on `notebooks.kubeflow.org`) in a namespace can see notebooks in it.

Workbench images (JupyterLab, Code-Server) have **zero application-level authentication or authorization** (`--ServerApp.token=''`, `--auth none`). For external access (via Gateway/HTTPRoute), auth/authz is delegated to the kube-rbac-proxy sidecar injected by the odh-notebook-controller. Port 8888 (Jupyter API) is unauthenticated but restricted by NetworkPolicy to the `redhat-ods-applications` namespace only (see Network Isolation). A compromised pod in that namespace could access kernel activity (`/api/kernels`) and file listings (`/api/contents`) without authentication.

## Isolation Mechanisms

### Infrastructure Isolation (Kubernetes)

Each Notebook CR creates namespace-scoped resources:

| Resource | Count per CR | Purpose |
|----------|-------------|---------|
| StatefulSet | 1 | Workbench pod (notebook container + kube-rbac-proxy sidecar) |
| Service | 1 | ClusterIP service on port 80 |
| PVC | 1 | User data storage |
| ServiceAccount | 1 | Notebook pod identity |
| Secret | 1-2 | kube-rbac-proxy TLS cert (service-ca auto-rotated), DSPA config |
| NetworkPolicy | 2 | `{name}-ctrl-np` (port 8888 ingress), `{name}-kube-rbac-proxy-np` (port 8443 ingress) |

All namespace-scoped resources carry owner references and are garbage-collected on CR deletion.

Cluster-scoped resources (managed via labels + finalizers):
- **ClusterRoleBinding** `{name}-rbac-{namespace}-auth-delegator` (binds notebook SA to `system:auth-delegator`)

Resources in other namespaces (managed via labels + finalizers):
- **HTTPRoute** in the central controller namespace (references user-namespace Service via ReferenceGrant)
- **ReferenceGrant** shared per user namespace in the gateway namespace

### Authentication & Authorization

The full auth chain for a notebook request:

1. Browser -> HTTPS to Gateway (TLS termination)
2. Gateway -> kube-rbac-proxy sidecar (TLS, port 8443)
3. kube-rbac-proxy -> TokenReview to K8s API (validates bearer token)
4. kube-rbac-proxy -> SubjectAccessReview to K8s API (checks `get notebooks.kubeflow.org` in namespace)
5. kube-rbac-proxy -> notebook container (plaintext HTTP, localhost, port 8888)

Aggregate ClusterRoles (`kubeflow-notebooks-edit`, `notebooks-edit`) auto-merge into K8s `admin`/`edit` roles, granting users with those roles in a namespace the ability to access notebooks.

### Network Isolation

**Cluster-verified on RHOAI 3.5 EA2:**

| NetworkPolicy | Port | Allowed Sources | Blocked |
|--------------|------|-----------------|---------|
| `{name}-ctrl-np` | 8888 (Jupyter API, unauthenticated) | Pods in `redhat-ods-applications` namespace only (idle culling controller) | Cross-namespace access, same-namespace access from non-controller pods |
| `{name}-kube-rbac-proxy-np` | 8443 (authenticated proxy) | Any pod (auth enforced by kube-rbac-proxy SAR) | N/A -- open by design |

Test results: a pod in `tenant-b` cannot reach `tenant-a`'s port 8888 (connection timeout). A pod in `redhat-ods-applications` gets HTTP 200 on port 8888 with access to `/api/kernels` (kernel activity) and `/api/contents` (file listing).

**No Workbench-created egress NetworkPolicies.** Cluster-wide policies, SDN rules, or firewalls may apply independently.

### Data Isolation

- **User data**: per-pod PVC (namespace-scoped). No shared filesystem between notebooks or namespaces.
- **Configuration**: per-notebook ConfigMaps (Elyra runtime, CA bundles) in the user namespace.
- **Credentials**: per-notebook Secrets (TLS cert auto-rotated, DSPA config) in the user namespace. DSPA credentials are namespace-scoped, not per-user.

## Known Gaps

| Gap | Impact | Severity |
|-----|--------|----------|
| No Workbench-created egress NetworkPolicy | Workbench components do not create egress restrictions. Without cluster-wide policies, workbench pods can reach any in-cluster service or internet endpoint. | P0 |
| No ResourceQuota / LimitRange | Workbench components do not create quotas. A user can launch unlimited notebooks. Platform admins must set quotas externally. | P1 |
| Controller ClusterRole breadth | `odh-notebook-controller-manager-role` has broad cross-namespace permissions: `create/delete/get/list/patch/update/watch` on ClusterRoleBindings and HTTPRoutes; `create/get/list/patch/update/watch` (no delete) on Secrets and NetworkPolicies. | P1 |
| NetworkPolicy rules undocumented | The per-notebook NetworkPolicy rules are not documented in architecture-context. They are correct (cluster-verified) but require source code reading or cluster testing to understand. | P1 |
| kf-notebook-controller metrics: no TLS | Metrics on port 8080 have no TLS (the odh-notebook-controller uses TLS 1.2+). | P2 |
| Workbenches-operator has no NetworkPolicy | Explicitly noted as a TODO with CWE-284 reference in the kustomization.yaml. | P2 |

## Cross-Component Interactions

| RHOAI Component | Integration | Tenancy Implications |
|-----------------|-------------|----------------------|
| ODH Dashboard | Lists/creates/deletes Notebook CRs via user impersonation | RBAC-consistent: user only sees notebooks in namespaces they have access to |
| Data Science Pipelines | DSPA connection secret mounted per notebook; Elyra submits pipelines via KFP SDK | DSPA credentials are namespace-scoped, not per-user. All notebooks in a namespace share the same DSPA. |
| Feature Store (Feast) | Python SDK embedded in workbench images | Cross-namespace Feast access via `FeatureStoreRef` is possible if the user configures it |
| MLflow | Python SDK embedded in workbench images | Workspace isolation depends on MLflow's `kubernetes-auth` plugin and SSAR enforcement |
