# Multi-Tenancy Analysis

Analyze how a component implements multi-tenancy -- tenant isolation, data separation, resource scoping, and the Kubernetes primitives used to enforce boundaries. This is a supplementary analysis used alongside the primary language-specific reference doc (controller-analysis, go-service-analysis, python-service-analysis, etc.).

## When to use

Every component should be evaluated for multi-tenancy. The depth of analysis depends on what the component does:

- **Platform operators** (rhods-operator, opendatahub-operator): These define the tenancy model for the entire platform. Deep analysis required.
- **Component operators** (kserve, kueue, training-operator): These enforce tenancy within their domain. Medium analysis.
- **Services and frontends** (dashboard, model registry API): These interact with tenant-scoped data. Check API scoping and data isolation.
- **Libraries and SDKs**: Usually inherit tenancy from the consuming service. Brief analysis -- note what tenancy assumptions the library makes.

## Guiding Questions

Answer these questions by reading source code, manifests, CRDs, RBAC definitions, and controller logic. Not every question applies to every component -- skip questions that are genuinely not applicable and note why.

**Handling large grep output**: The grep commands below run without `head` limits so that no matches are silently dropped. If a grep returns more output than fits in your context, first run it with `wc -l` to count matches, then use `sort -u` or tighter `--include` patterns to reduce noise before reviewing. Do not cap with `head` -- a truncated result set can miss the file that defines the actual tenancy boundary.

### 1. Tenant Definition

What does "tenant" mean in this component?

- Is tenancy per cluster, per namespace, per tenant CR, per customer, per user, or some other model?
- Is the tenant boundary explicit (a CRD field, a namespace label) or implicit (assumed from request context)?
- Does the component use a single-tenant or multi-tenant deployment model?

Search for:
```bash
# Tenant-related types, fields, and constants
grep -rn "tenant\|Tenant\|TENANT\|multi.tenant\|namespace\|Namespace" --include="*.go" --include="*.py" --include="*.ts" . | grep -v vendor | grep -v node_modules | grep -v _test
# CRD fields that scope to a tenant
grep -rn "namespace\|project\|workspace\|team\|org\|owner" --include="*.go" . | grep -i "spec\.\|field\|scope" | grep -v vendor | grep -v _test
# Namespace-scoped vs cluster-scoped resources
grep -rn "Namespaced\|ClusterScoped\|scope" --include="*.go" . | grep -v vendor | grep -v _test```

### 2. Isolation Mechanisms

How are tenants isolated across each dimension?

#### Authentication and Authorization
- Does the component enforce per-tenant auth, or does it rely on the platform (kube-rbac-proxy, OAuth proxy, Istio)?
- Are there per-tenant service accounts, roles, or role bindings?
- Can one tenant's credentials access another tenant's resources?

```bash
# Auth enforcement patterns
grep -rn "rbac\|RBAC\|authorize\|Authorize\|authenticate\|SubjectAccessReview\|TokenReview" --include="*.go" --include="*.py" . | grep -v vendor | grep -v _test
# Per-tenant RBAC generation
grep -rn "RoleBinding\|ClusterRoleBinding\|Role{" --include="*.go" . | grep -v vendor | grep -v _test```

#### Data Storage
- Is data stored per-namespace, per-database, per-table with tenant column, or in a shared store?
- Are there separate PVCs, S3 buckets, or database schemas per tenant?
- Can one tenant read or write another tenant's data?

```bash
# Storage patterns
grep -rn "PersistentVolumeClaim\|StorageClass\|bucket\|database\|schema\|tableName" --include="*.go" --include="*.py" . | grep -v vendor | grep -v _test
# Data scoping patterns
grep -rn "ByNamespace\|InNamespace\|namespace.*filter\|tenant.*id\|owner.*ref" --include="*.go" --include="*.py" . | grep -v vendor | grep -v _test```

#### Network Traffic
- Are there per-tenant NetworkPolicies, AuthorizationPolicies, or PeerAuthentications?
- Does the component create network boundaries between tenants?
- Is inter-tenant traffic blocked by default or allowed?

```bash
# Network isolation
grep -rn "NetworkPolicy\|AuthorizationPolicy\|PeerAuthentication\|network.*policy" --include="*.go" --include="*.yaml" --include="*.tmpl.yaml" . | grep -v vendor | grep -v _test```

#### Compute and Resource Usage
- Are there per-tenant ResourceQuotas, LimitRanges, or priority classes?
- Can one tenant starve another of resources?
- Does the component enforce compute isolation (separate pods, node affinity, taints)?

```bash
# Resource isolation
grep -rn "ResourceQuota\|LimitRange\|PriorityClass\|nodeSelector\|toleration\|affinity\|taint" --include="*.go" --include="*.yaml" . | grep -v vendor | grep -v _test```

#### Configuration and Secrets
- Are Secrets and ConfigMaps scoped per tenant (per namespace) or shared?
- Can one tenant read another tenant's configuration?
- Are there shared credentials that cross tenant boundaries?

```bash
# Config scoping
grep -rn "Secret\|ConfigMap\|secretName\|configMapRef" --include="*.go" . | grep -v vendor | grep -v _test```

#### API Access and Object Scoping
- Are API endpoints scoped to a namespace or tenant context?
- Do list/watch operations filter by tenant, or return all objects?
- Can a user in one tenant see or modify objects belonging to another?

```bash
# API scoping
grep -rn "InNamespace\|ListOptions\|FieldSelector\|LabelSelector\|ByNamespace\|\.Namespace" --include="*.go" . | grep -v vendor | grep -v _test
# Watch scoping
grep -rn "Watch\|Informer\|cache\.NewInformer\|cache\.NewSharedInformer" --include="*.go" . | grep -v vendor | grep -v _test```

### 3. Kubernetes Primitives

Which Kubernetes primitives enforce the tenancy model?

- Namespaces as tenant boundaries
- RBAC (Roles, ClusterRoles, RoleBindings)
- NetworkPolicies
- ResourceQuotas and LimitRanges
- Custom Resources (tenant CRDs, workspace CRDs)
- Admission webhooks (validating or mutating for tenant isolation)
- Separate control planes or virtual clusters

```bash
# Admission control for tenancy
grep -rn "ValidatingWebhook\|MutatingWebhook\|admission\|Validate\|Mutate" --include="*.go" . | grep -v vendor | grep -v _test```

### 4. Kubernetes vs Application Enforcement

Which parts of the tenancy model are enforced by Kubernetes (RBAC, NetworkPolicy, namespace isolation) versus by application code (custom authorization logic, query filters, tenant ID propagation)?

Application-enforced tenancy is higher risk -- a bug in application code can leak data across tenants, while Kubernetes-enforced tenancy is harder to bypass.

### 5. Shared Services and Data Planes

- Are there shared services (databases, caches, message queues) that serve multiple tenants?
- If so, how are tenant boundaries preserved within the shared service?
- Are there shared data plane components (Envoy, inference servers) that handle traffic from multiple tenants?

### 6. Risks and Gaps

Based on the analysis above, identify:
- Missing isolation at any layer (auth, data, network, compute, config, API)
- Shared resources without tenant boundary enforcement
- Cluster-scoped resources that should be namespace-scoped
- Application-enforced isolation where Kubernetes enforcement would be stronger
- Default-allow postures where default-deny would be safer

## Output Format

Write findings into the `## Multi-Tenancy` section of the architecture document using the tables defined in the template.

When analyzing as a sub-agent, write findings to `/tmp/arch-analysis-{component}-multi-tenancy.md` using the same table format, then return a short confirmation. The main agent will aggregate.
