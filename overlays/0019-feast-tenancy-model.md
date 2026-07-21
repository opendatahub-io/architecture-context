---
id: "0019"
title: Feast Feature Store multi-tenancy model
status: active
created: 2026-07-17
affects:
  - feast
release:
  - "next"
provenance:
  - https://redhat.atlassian.net/browse/RHOAIENG-76625
  - https://github.com/opendatahub-io/feast
author: Gerard Ryan
superseded_by: null
---

## Fact

The generated architecture doc for Feast documents component structure, APIs, and deployment but does not describe the multi-tenancy model. This overlay captures how tenant isolation works across infrastructure, data, authentication, authorization, and network layers, and identifies gaps where isolation is incomplete.

### Summary

| Aspect | Implementation |
|--------|----------------|
| **Tenant boundary** | Kubernetes namespace (infrastructure) + `feastProject` string (data) |
| **CRD scope** | Namespace-scoped `FeatureStore` CR |
| **Data isolation** | `feastProject` name embedded in online store keys/table names and registry queries |
| **Authentication** | Three modes: none (default), Kubernetes (TokenReview), OIDC (JWKS) |
| **Authorization** | Feast Permission objects with Role/Group/Namespace-based policies; enforced on Python servers |
| **Network isolation** | ClusterIP services; **no NetworkPolicies created** -- must be managed externally |
| **Resource isolation** | No default resource limits on feature server pods; no ResourceQuota/LimitRange created |
| **Shared services** | Cluster-scoped ClusterRoles for token review/namespace discovery; backing stores (Redis/PostgreSQL) can be shared across CRs with project-level key isolation |

**Key risks:**
- If two FeatureStore CRs use the same `feastProject` name and the same backing store, they share data. No cluster-level uniqueness enforcement exists for project names.
- Elasticsearch and Qdrant online stores do not include `feastProject` in index/collection names -- data collisions occur even with different project names if FeatureView names match.
- The intra-communication token (stored in a ConfigMap, not a Secret) bypasses all Feast Permission checks if compromised.

### Tenant Definition

In Feast, a **tenant** maps to a Kubernetes namespace containing a `FeatureStore` CR. Each CR defines a `feastProject` string (set via `spec.feastProject`) that scopes all feature metadata and online store data. The tenancy model is **hybrid**:

- **Kubernetes namespace** provides the **infrastructure boundary** -- Deployments, Services, ConfigMaps, Secrets, ServiceAccounts, and namespace-scoped RBAC resources are created in the CR's namespace with owner references (garbage-collected on CR deletion). A small number of shared cluster-scoped ClusterRoles and an operator-namespace ConfigMap follow the operator-managed lifecycle (see below).
- **Feast project name** (`feastProject`) provides **application-level data isolation for most backends** -- registry metadata is filtered by `project_id`, and most online store keys/table names are prefixed with the project name. However, some backends (Elasticsearch, Qdrant) do not apply project-level scoping (see Data Isolation below).

Both boundaries must align for complete tenant isolation.

### Infrastructure Isolation (Kubernetes)

Each FeatureStore CR creates a complete set of namespace-scoped resources:

| Resource | Count per CR | Purpose |
|----------|-------------|---------|
| Deployment | 1 | Multi-container pod (online, offline, registry, UI) |
| Services | 1-5 | ClusterIP services for each enabled component |
| ConfigMaps | 2-3 | Client config, intra-comm token, CA bundle |
| ServiceAccount | 1 | Feast pod identity |
| PVCs | 0-3 | Persistent storage for offline/online/registry |
| CronJob | 1 | Materialization scheduling |
| Roles/RoleBindings | 2-3+ | CronJob access, authz, custom auth roles |
| HPA/PDB | 0-1 each | Scaling and disruption budget |
| Route | 0-1 | UI exposure (OpenShift only) |
| ServiceMonitor | 0-1 | Prometheus metrics (when available) |

All namespace-scoped resources listed above carry owner references to the FeatureStore CR and are garbage-collected on CR deletion.

A small number of **cluster-scoped and operator-namespace resources** are shared across FeatureStore instances and follow a separate operator-managed lifecycle (explicitly cleaned up when the last FeatureStore using them is deleted, not via owner references):
- `feast-token-review-cluster-role` -- grants TokenReview/SubjectAccessReview permissions for Kubernetes auth
- `feast-oidc-token-review` -- grants TokenReview permissions for OIDC auth
- `feast-discover-namespaces` -- grants namespace listing for client discovery
- `feast-configs-registry` ConfigMap -- tracks FeatureStore deployments across namespaces for client discovery (contains only ConfigMap name mappings, no credentials)

### Data Isolation (Application-Level)

The `feastProject` string is the primary application-level data isolation mechanism within backing stores. Most backends use it to scope keys or table names, but not all backends implement this consistently:

| Store Type | Isolation Mechanism | Example |
|------------|---------------------|---------|
| SQL Registry | `project_id` column in composite primary key; all queries filter by `WHERE project_id = ?` | `SELECT * FROM feature_views WHERE project_id = 'my_project'` |
| File Registry | Protobuf `spec.project` field filtering | N/A (single blob) |
| Redis (online) | Project name bytes appended to entity key bytes | Key = `{entity_key_bytes}{project_bytes}` |
| PostgreSQL/MySQL/SQLite (online) | Table names prefixed with project | `my_project_driver_stats` |
| DynamoDB (online) | Table names include project | `my_project.driver_stats` |
| MongoDB (online) | Collection names include project | `my_project_latest` |
| Bigtable (online) | Table names include project prefix | Documented in code comments |
| **Elasticsearch (online)** | **No project isolation** -- index names use only `table.name` | Index: `driver_stats` (no project prefix) |
| **Qdrant (online)** | **No project isolation** -- collection names use only `table.name` | Collection: `driver_stats` (no project prefix) |

**Critical considerations:**
- If two FeatureStore CRs use the **same `feastProject` name** and the **same backing store connection**, they will read and write the **same data**. There is no cluster-level enforcement of project name uniqueness.
- **Elasticsearch and Qdrant** do not use the project name at all in index/collection naming. Two projects sharing the same ES/Qdrant backend will have data collisions if they have identically named FeatureViews, **regardless of `feastProject` value**.

### Authentication

Three authentication modes are supported, configured via `spec.authz` on the FeatureStore CR:

| Mode | Token Source | Validation | User Extraction |
|------|-------------|------------|-----------------|
| `no_auth` (default) | None | None | N/A |
| `kubernetes` | K8s ServiceAccount token or user token | K8s TokenReview API | Username, roles (from RoleBindings), groups (from TokenReview), namespaces (from SA or dashboard permissions) |
| `oidc` | OIDC Bearer token (JWT) | JWKS validation via OIDC discovery URL | Username (preferred_username/upn), roles (resource_access claim), groups (groups claim) |

### Authorization (Feast Permission System)

The Feast Permission system provides fine-grained access control on feature store objects:

- **Permission** objects are stored in the Feast registry and define: resource types, name patterns, authorized actions, and a policy.
- **Policies** evaluate user attributes: `RoleBasedPolicy` (K8s roles), `GroupBasedPolicy` (K8s/OIDC groups), `NamespaceBasedPolicy` (K8s namespaces), `CombinedGroupNamespacePolicy` (groups OR namespaces).
- **Actions**: CREATE, DESCRIBE, UPDATE, DELETE, READ_ONLINE, READ_OFFLINE, WRITE_ONLINE, WRITE_OFFLINE.
- **Decision strategy**: AFFIRMATIVE -- a single matching permission grants access. If no permissions are defined at all, access is **denied** (secure default).
- **Enforcement**: `assert_permissions()` on get/update/delete operations; `permitted_resources()` filters list results. Enforced on all Python servers (feature server, registry gRPC, registry REST, offline server).

### Network Isolation

- All Feast services use **ClusterIP** (internal-only) service type.
- TLS is auto-configured on OpenShift via service-serving certificate annotations.
- The UI can be exposed externally via an OpenShift Route with TLS re-encrypt termination.
- **No NetworkPolicy resources are created by the operator.** Network isolation must be managed externally by cluster administrators.

### Known Gaps

| Gap | Impact | Severity |
|-----|--------|----------|
| No NetworkPolicy | Any pod in the cluster can reach Feast services across namespaces | P0 |
| No ResourceQuota/LimitRange | Unbounded resource consumption possible per FeatureStore | P0 |
| INTRA_COMMUNICATION_BASE64 token in ConfigMap | Intra-comm token bypasses all Feast Permission checks; stored in a ConfigMap (not Secret) readable by any user with ConfigMap access in the namespace | P1 |
| Elasticsearch/Qdrant lack project prefix | Index/collection names use only `table.name`; data collisions between projects even with different `feastProject` values | P1 |
| Single-project permission scope | `SecurityManager` loads permissions from one project only; if a registry serves multiple projects, other projects' permissions are not enforced | P1 |
| No `feastProject` uniqueness validation | Duplicate project names with shared backends cause data sharing | P1 |
| No default resource limits on feature server pods | Resource exhaustion risk in shared clusters | P1 |
| No ValidatingWebhookConfiguration | Webhook infrastructure scaffolded but disabled; invalid CRs only caught during reconciliation | P2 |
| Application-level data isolation only | No database-level isolation (separate Redis DB, PostgreSQL schema) for shared backends | P2 |

### Cross-Namespace Registry (FeatureStoreRef)

A FeatureStore CR can reference another CR's registry via `spec.services.registry.remote.feastRef` (`FeatureStoreRef` with `name` and optional `namespace` fields). This allows one CR's online/offline services to use a registry deployed by a different CR, even across namespaces. When `feastRef` is used, the operator resolves the referenced FeatureStore and configures the local services to connect to the remote registry endpoint. This pattern enables hub-and-spoke registry sharing but means tenant boundaries extend across namespaces -- the remote registry's permissions and project scope govern access for all connected FeatureStores.

### Cross-Component Interactions

| RHOAI Component | Integration | Tenancy Implications |
|-----------------|-------------|----------------------|
| Kubeflow Notebooks | Operator watches Notebook CRs and creates ConfigMaps with Feast client config | Notebooks access Feast in the same namespace or via cross-namespace auto-access RBAC; ConfigMap contains endpoints but not credentials |
| ODH Dashboard | Watches FeatureStore CRDs to list feature stores | Dashboard's own RBAC determines which FeatureStores a user can see; `disableFeatureStore` flag controls feature visibility |
| MLflow | Optional SDK integration for tracking feature retrievals and materializations | Shares MLflow tracking server; tenant isolation depends on MLflow's access controls |
| rhods-operator | Deploys feast-operator via Kustomize manifests | Operator is deployed once per cluster with cluster-wide watch scope |

### Comparison with Other RHOAI Components

Feast uses a **hybrid namespace + application-level project** model. Compared to other RHOAI components:

- **vs. Models-as-a-Service**: MaaS has a dedicated `Tenant` CRD with header-based isolation and SHA256-hashed tenant folders. Feast uses application-level project naming instead of a dedicated tenant primitive.
- **vs. Model Registry**: Both use per-namespace CRs managed by an operator. Model Registry supports multi-tenant (many CRs, many namespaces) and singleton catalog patterns. Feast adds the project-level data scoping layer.
- **vs. ModelMesh Serving**: ModelMesh creates NetworkPolicies for network isolation. Feast does not.
- **vs. MLflow Operator**: MLflow uses a workspace-aware model mapping 1:1 to K8s namespaces via `kubernetes-workspace-provider`. Feast's project concept is similar but does not enforce 1:1 namespace mapping.

## Impact on Strategies

- Multi-tenant Feast deployments **require externally managed NetworkPolicies** -- the operator does not create any. Strategies involving shared clusters must account for this.
- **Elasticsearch and Qdrant backends are unsuitable** when multiple projects share a backend instance, as they do not include `feastProject` in index/collection names.
- `feastProject` names must be **manually coordinated** across namespaces when backing stores are shared; there is no cluster-level uniqueness enforcement.
- `no_auth` is the **default authentication mode** -- production multi-tenant deployments must explicitly enable `kubernetes` or `oidc` auth.
- **ResourceQuota and LimitRange** are admin prerequisites for multi-tenant clusters; the operator does not create them.
- Cross-namespace registry sharing via `FeatureStoreRef` **extends tenant boundaries across namespaces** -- strategies must account for the remote registry's permissions and project scope governing access for all connected FeatureStores.
- The intra-communication token stored in a ConfigMap (not a Secret) **bypasses all Feast Permission checks** -- strategies should treat ConfigMap access in Feast namespaces as security-sensitive.

## Context

The generated architecture doc for Feast (`feast.md`) documents component structure, APIs, CRDs, and deployment topology but does not cover the multi-tenancy model. This overlay captures how tenant isolation works across infrastructure, data, authentication, authorization, and network layers based on analysis of the feast-operator and upstream Feast 0.64.0 codebases, and identifies gaps where isolation is incomplete or absent.
