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

Search for and analyze:

**CRDs**: `**/*_crd.yaml`, `config/crd/`, `api/*/groupversion_info.go`
- Extract: API group, version, kind, scope

**Controllers**: `controllers/`, `pkg/controller/`, `*_controller.go`
- Extract: Watched CRDs, reconciliation logic

**APIs**: Route definitions, OpenAPI specs, `.proto` files
- Extract: Endpoints, methods, ports, authentication

**Network Services**: Service manifests
- Extract: Names, types, ports, protocols, selectors

**RBAC**: ClusterRole, Role, RoleBinding, ClusterRoleBinding
- Extract: API groups, resources, verbs

**Secrets/ConfigMaps**: Secret references (NOT values)
- Extract: Names, types, purposes

**Network Policies**: NetworkPolicy manifests
- Extract: Selectors, ingress/egress rules, ports

**Service Mesh**: Istio PeerAuthentication, AuthorizationPolicy
- Extract: mTLS settings, authorization rules

### Step 5: Extract Recent Changes

```bash
git log --since="3 months ago" --pretty=format:"%h %s" --no-merges | head -20
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

## Purpose
**Short**: [One sentence]

**Detailed**: [2-3 paragraphs explaining what this component does]

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| [name] | [type] | [purpose] |

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
