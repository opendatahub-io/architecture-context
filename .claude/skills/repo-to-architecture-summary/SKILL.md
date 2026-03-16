---
name: repo-to-architecture-summary
description: Analyze a component repository and generate comprehensive architecture summary with structured markdown tables. Use when analyzing ODH/RHOAI components, documenting architecture, or creating security diagrams.
allowed-tools: Read, Glob, Grep, Bash(git *), Bash(ls *), Bash(find *), Write
---

# Repo to Architecture Summary

Analyze a component repository (for Open Data Hub or Red Hat OpenShift AI) and generate a `GENERATED_ARCHITECTURE.md` file with detailed architecture information.

## Arguments

Positional argument:
- `[directory]` - Path to repository directory (default: current directory)

Optional flags:
- `--distribution=odh|rhoai|both` (default: both)
- `--version=X.Y` (default: auto-detect)

Examples:
```bash
/repo-to-architecture-summary                                    # analyze current directory
/repo-to-architecture-summary checkouts/opendatahub-io/kserve   # analyze specific directory
/repo-to-architecture-summary ./kserve --distribution=rhoai --version=3.3
```

## Instructions

Generate a comprehensive architecture summary following these steps:

**IMPORTANT FOR OPERATORS**: Don't just read manifests - read the controller code!
- Operators deploy infrastructure dynamically through controller reconcile logic
- Check `internal/controller/`, `controllers/`, `pkg/controller/` directories
- Gateway/ingress controllers are especially critical - they define how components expose services
- Example: `internal/controller/services/gateway/` managing Gateway API is ingress architecture

### Step 0: Parse Arguments and Navigate to Repository

Parse the arguments string:
1. Extract first non-flag argument as directory path (if provided)
2. If directory path is provided, change to that directory:
   ```bash
   cd [directory-path]
   ```
3. Extract flag arguments (--distribution, --version) for later use

### Step 1: Prepare Repository (Special Cases)

**For opendatahub-operator repository specifically**:
```bash
make get-manifests
```
- This clones kustomize manifests into `./opt/` directory
- These manifests are used at deployment time when components are enabled
- Critical for analyzing actual deployment configuration (not just operator code)
- Without this step, you'll miss component deployment details

**For rhods-operator repository (RHOAI 3.x+)**:
- Check `internal/controller/services/gateway/` for gateway controller code
- This operator deploys critical platform ingress infrastructure:
  - Gateway API (gateway.networking.k8s.io)
  - EnvoyFilter for traffic management
  - kube-rbac-proxy for authentication
  - Components create HTTPRoute CRs that reference the data-science-gateway
- Document this in the Ingress section even though it's not in static manifests
- This is THE platform ingress mechanism - not optional to document

**For other repositories**: Skip to discovery below.

### Step 3: Discover Repository Structure

Identify:
1. Repository name and purpose
2. Languages and frameworks:
   - Go operators: look for `main.go`, `controllers/`, `api/`
   - Python services: `setup.py`, `requirements.txt`, `pyproject.toml`
   - React/TypeScript: `package.json`, `src/`
   - Containers: **PRIORITIZE `Dockerfile.konflux` or `Containerfile.konflux`** if they exist
     - RHOAI is completely built by Konflux; ODH is transitioning to Konflux
     - Regular `Dockerfile`/`Containerfile` may be outdated/unused - verify they're actually used in builds
     - If both exist, prefer Konflux files for analysis
3. Deployment artifacts:
   - Helm charts: `Chart.yaml`
   - Kustomize: `kustomization.yaml`
   - Manifests: `*.yaml` in `manifests/`, `config/`, `deploy/`
   - **For opendatahub-operator**: Check `./opt/` directory for component manifests (populated by `make get-manifests`)

### Step 4: Analyze Code Artifacts

**First: Detect Controller Type and Capabilities**

For Go operators, run recursive greps to understand operator capabilities before detailed analysis:

```bash
# Controller-runtime based operator detection
grep -r "sigs.k8s.io/controller-runtime" --include="*.go" . | head -20

# OpenShift API usage
grep -r "github.com/openshift/api" --include="*.go" . | head -20

# Gateway API usage (RHOAI 3.x ingress pattern)
grep -r "gateway.networking.k8s.io" --include="*.go" . | head -20

# OLM/Operator SDK patterns
grep -r "github.com/operator-framework" --include="*.go" . | head -20

# Service Mesh / Istio usage
grep -r "istio.io/api" --include="*.go" . | head -20
```

**Interpret results**:
- `controller-runtime/pkg/client`: Kubernetes operator using controller-runtime
- `controller-runtime/pkg/reconcile`: Has reconcile loops managing resources
- `openshift/api/route/v1`: Manages OpenShift Routes (RHOAI 2.x pattern)
- `openshift/api/config/v1`: Accesses OpenShift cluster configuration
- `gateway.networking.k8s.io`: Manages Gateway API resources (RHOAI 3.x pattern)
- `operator-framework/api`: OLM-based operator with CRDs
- `istio.io/api`: Integrates with Istio service mesh

**Document findings** in Architecture Components table:
- Example: "Go Operator | controller-runtime based | Manages Gateway API (HTTPRoute), OpenShift Routes (legacy), Istio VirtualService"

This reconnaissance helps identify what the operator manages before reading controller code.

---

Search for and analyze:

**CRDs**: `**/*_crd.yaml`, `config/crd/`, `api/*/groupversion_info.go`
- Extract: API group, version, kind, scope

**Controllers**: `controllers/`, `pkg/controller/`, `internal/controller/`, `*_controller.go`
- Extract: Watched CRDs, reconciliation logic
- **CRITICAL**: Read controller code to see what resources are created dynamically (not just manifests!)
- Check `internal/controller/`, `controllers/`, `components/*/controllers/` for all controller code
- Look for gateway/ingress controllers that manage Gateway API, HTTPRoute, Istio Gateway, Routes, etc.
- Example: `internal/controller/services/gateway/` indicates operator manages ingress infrastructure
- Document controller-managed ingress/egress in Network Architecture section

**RHOAI 3.x Migration Patterns** (CRITICAL TO UNDERSTAND):
Controllers in RHOAI 3.x create different resources than 2.x. Read controller code to identify current behavior:

**OLD Pattern (RHOAI 2.x, being phased out)**:
- Creates OpenShift `Route` CRs
- Uses `oauth-proxy` sidecars for authentication
- Look for: `routev1.Route`, `oauth-proxy` container

**NEW Pattern (RHOAI 3.x, current)**:
- Creates `HTTPRoute` CRs (Gateway API)
- Uses `kube-rbac-proxy` sidecars for authentication
- Look for: `gateway.networking.k8s.io/v1beta1` or `v1`, `HTTPRoute`, `kube-rbac-proxy` container

**How to identify in controller code**:
```go
// Search for these patterns in *_controller.go files:
HTTPRoute                    // Creating Gateway API HTTPRoutes
gateway.networking.k8s.io    // Gateway API imports
kube-rbac-proxy             // New auth sidecar
routev1.Route               // OLD: OpenShift Routes (legacy)
oauth-proxy                 // OLD: OAuth proxy (legacy)
```

**Examples**:
- `kubeflow/components/odh-notebook-controller/controllers/`: Creates HTTPRoutes + kube-rbac-proxy sidecars per notebook
- `rhods-operator/internal/controller/services/gateway/`: Deploys platform Gateway for HTTPRoutes to reference
- Document what controller CREATES (HTTPRoute), not legacy patterns (Route)

**Gateway API / Ingress Controllers**:
- Search for: `gateway.networking.k8s.io`, `Gateway`, `HTTPRoute`, `GRPCRoute`, `TLSRoute`
- Check controller code to understand what ingress infrastructure is deployed
- Common patterns in RHOAI 3.x:
  - Platform operator deploys Gateway API + EnvoyFilter + auth infrastructure
  - Component controllers create HTTPRoute CRs that reference a parent Gateway (e.g., "data-science-gateway")
  - Component controllers inject kube-rbac-proxy sidecars for auth
  - This is **critical ingress architecture** - must be documented even if not in manifests
- Read controller reconcile logic to understand what gets deployed at runtime

**APIs**: Route definitions, OpenAPI specs, `.proto` files
- Extract: Endpoints, methods, ports, authentication

**Network Services**: Service manifests
- Extract: Names, types, ports, protocols, selectors
- Check controller code for services created dynamically (not just static manifests)

**Sidecar Containers** (injected by controllers):
- Search controller code for sidecar injection patterns
- Look for: `Container{}` structs being added to Pod specs in reconcile loops
- RHOAI 3.x pattern: `kube-rbac-proxy` sidecars for authentication
  - Typically on port 8443/TCP
  - Fronts main application container
  - Enforces RBAC before proxying to application
- Document in Network Architecture → Services section
- Example: "kube-rbac-proxy sidecar (8443/TCP) → application container (8080/TCP)"

**RBAC**: ClusterRole, Role, RoleBinding, ClusterRoleBinding
- Extract: API groups, resources, verbs

**Secrets/ConfigMaps**: Secret references (NOT values)
- Extract: Names, types, purposes

**Network Policies**: NetworkPolicy manifests
- Extract: Selectors, ingress/egress rules, ports

**Service Mesh**: Istio PeerAuthentication, AuthorizationPolicy
- Extract: mTLS settings, authorization rules

### Step 5: Extract Git Information

Use the Python script to get all git information in one call (version, branch, remote URL, and recent commits):

```bash
python scripts/get_git_changes.py . --format=metadata --since="3 months ago" --limit=20
```

This single command provides:
- **Version**: From `git describe --tags --always` (use this if --version not specified)
- **Branch**: Current git branch
- **Remote URL**: Repository URL
- **Recent commits**: Last 20 commits for Recent Changes section

**Example output**:
```
Repository: .
Version: v0.15.2-45-ga1b2c3d
Branch: main
Remote: https://github.com/opendatahub-io/kserve.git

Recent commits (20):
  a1b2c3d Add new inference runtime
  e4f5g6h Fix scaling issue
  ...
```

### Step 6: Generate GENERATED_ARCHITECTURE.md

Create a file with this structure (use **precise technical details** in tables):

```markdown
# Component: [Name]

## Metadata
- **Repository**: [GitHub URL]
- **Version**: [Version]
- **Distribution**: ODH, RHOAI, or both
- **Languages**: [Languages]
- **Deployment Type**: [Operator/Service/Frontend/etc]

**IMPORTANT**: Document current behavior based on code analysis, not assumptions:
- For RHOAI 3.x: HTTPRoute + kube-rbac-proxy (NEW pattern)
- For RHOAI 2.x: Route + oauth-proxy (LEGACY pattern)
- Read controller code to confirm which pattern is actually implemented

## Purpose
**Short**: [One sentence]

**Detailed**: [2-3 paragraphs explaining what this component does]

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| [name] | [type] | [purpose] |

**For controllers**: Document what they create dynamically:
- Example: "Notebook Controller | Go Operator | Creates HTTPRoute CRs and kube-rbac-proxy sidecars per notebook"
- Example: "Gateway Controller | Go Operator | Deploys Gateway API infrastructure (Gateway, EnvoyFilter, auth proxies)"
- Include the resources managed (CRDs, HTTPRoutes, Services, sidecars, etc.)

## APIs Exposed

### Custom Resource Definitions (CRDs)

| Group | Version | Kind | Scope | Purpose |
|-------|---------|------|-------|---------|
| [group] | [version] | [kind] | [Namespaced/Cluster] | [purpose] |

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| [path] | [method] | [8080/TCP] | [HTTP/HTTPS] | [TLS 1.3/None] | [Bearer/mTLS/None] | [purpose] |

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| [service] | [9090/TCP] | [gRPC] | [mTLS] | [cert] | [purpose] |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| [name] | [version] | [Yes/No] | [purpose] |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| [name] | [API/CRD/etc] | [purpose] |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| [name] | [ClusterIP/LoadBalancer] | [8080/TCP] | [8080] | [HTTP/HTTPS] | [TLS 1.3] | [mTLS] | [Internal/External] |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| [name] | [Istio Gateway] | [hosts] | [443/TCP] | [HTTPS] | [TLS 1.3] | [SIMPLE/MUTUAL] | [External] |

**CRITICAL**: Document controller-managed ingress even if not in static manifests!
- For operators: Check `internal/controller/services/` and `internal/controller/gateway/` for gateway controllers
- For components: Check `controllers/`, `components/*/controllers/` for what gets created dynamically
- Gateway API pattern (RHOAI 3.x): Controllers create HTTPRoute CRs + kube-rbac-proxy sidecars
  - Operator deploys Gateway infrastructure (Gateway API + EnvoyFilter)
  - Component controllers create HTTPRoute CRs referencing parent Gateway (e.g., "data-science-gateway")
  - Component controllers inject kube-rbac-proxy sidecars for authentication
- Document type as "HTTPRoute (Gateway API)" for RHOAI 3.x, not "Route (OpenShift)"
- Include auth components: "kube-rbac-proxy" for 3.x (NOT "oauth-proxy" which is legacy 2.x)
- Example for notebook controller: "Creates HTTPRoute CRs per notebook with kube-rbac-proxy sidecar authentication"
- If operator watches HTTPRoute CRs, mention it provides platform ingress for components

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| [dest] | [443/TCP] | [HTTPS] | [TLS 1.2+] | [AWS IAM] | [purpose] |

## Security

### RBAC - Cluster Roles

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| [role] | [group, ""] | [resources] | [get, list, watch] |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| [binding] | [ns] | [role] | [sa] |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| [name] | [kubernetes.io/tls] | [purpose] | [cert-manager] | [Yes/No] |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| [endpoint] | [methods] | [Bearer/mTLS/etc] | [Istio/etc] | [policy] |

## Data Flows

### Flow 1: [Flow Name]

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | [source] | [dest] | [443/TCP] | [HTTPS] | [TLS 1.3] | [Bearer Token] |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| [component] | [gRPC/API] | [9090/TCP] | [gRPC] | [mTLS] | [purpose] |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| [version] | [date] | - Change 1<br>- Change 2 |
```

### Critical Requirements - Security Diagram Precision

When filling tables, be **extremely precise**:

✅ **Port numbers**: `8443/TCP`, `9090/TCP` (not "HTTPS port")
✅ **Protocols**: `HTTP`, `HTTPS`, `gRPC`, `gRPC/HTTP2` (not "network")
✅ **Encryption**: `TLS 1.3`, `TLS 1.2+`, `mTLS`, `plaintext` (not "encrypted")
✅ **Authentication**: `Bearer Token (JWT)`, `mTLS client certs`, `AWS IAM credentials` (not "authenticated")
✅ **RBAC**: Exact API groups: `""` for core, `apps`, `serving.kserve.io` (not "Kubernetes API")

### Step 7: Write File

Create `GENERATED_ARCHITECTURE.md` in the repository root.

### Step 8: Report Results

After creating the file, output:

```
✅ Architecture summary generated!

File created: GENERATED_ARCHITECTURE.md

Component: [Name]
Distribution: [ODH/RHOAI/Both]
Version: [X.Y]

Summary:
- [N] CRDs found
- [N] Services analyzed
- [N] RBAC rules documented
- [N] Data flows mapped

Next steps:
1. Review GENERATED_ARCHITECTURE.md for accuracy (especially network/security tables)
2. Edit markdown if corrections needed (it's human-editable!)
3. Commit: git add GENERATED_ARCHITECTURE.md && git commit -m "Add architecture summary"
4. Use /aggregate-platform-architecture to combine with other components
```

## Notes

- Document what exists (if no CRDs/network policies found, that's okay)
- Search deployment manifests and source code thoroughly for network details
- Precision in security configuration is critical (RBAC, secrets, TLS, auth)
- Markdown tables are machine-parseable by LLMs for diagram generation
- Accuracy > speed - this is a source of truth document
