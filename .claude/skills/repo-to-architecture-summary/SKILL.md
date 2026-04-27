---
name: repo-to-architecture-summary
description: Analyze a component repository and generate comprehensive architecture summary with structured markdown tables. Use when analyzing ODH/RHOAI components, documenting architecture, or creating security diagrams.
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git *), Bash(ls *), Bash(find *), Bash(python *), Write
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

## Output File

**The output file MUST be named exactly `GENERATED_ARCHITECTURE.md`** — not `ARCHITECTURE_SUMMARY.md`, not `architecture.md`, not any other name. The filename is required by downstream tooling (collect, validate, platform aggregation). Write to `GENERATED_ARCHITECTURE.md` in the repository root.

## Instructions

Generate a comprehensive architecture summary following these steps:

**IMPORTANT - TOOL USAGE**:
- Do NOT call `ToolSearch`. You already have access to: Bash, Read, Write, Glob, Grep.
- When reading multiple files, use **parallel tool calls** — issue multiple Read/Glob/Grep calls in a single turn rather than one at a time. This dramatically reduces execution time.
- Prefer Grep with `--include` patterns over Bash `grep` commands.

**CRITICAL - SOURCE REFERENCE TRACKING**:
You MUST maintain a running log of EVERY file you read or grep during analysis. For each file, record:
- The **relative file path** from the repository root
- The **specific line numbers** referenced (e.g., lines 15-42, or line 88)
- Which **output section(s)** the information informed (e.g., "CRDs", "Network Architecture", "RBAC")

Track this from the very first file you open. This data is written into the final `## Source References` section of the output. Every claim in the architecture document must be traceable to a specific file and line range. This is non-negotiable — the source references are as important as the architecture content itself.

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
- **READ EVERY `.go` FILE** in controller directories — not just files matching known patterns. Controller logic is often split across helper files, action files, and feature-specific files (e.g., `dashboard_redirects.go`, `ocp_routes.go`, `gateway_support.go`). Skipping any `.go` file risks missing dynamically-created resources.
- **READ EVERY TEMPLATE FILE** in `resources/` subdirectories under controller directories (e.g., `*.tmpl.yaml`, `*.yaml`). These templates define the exact Kubernetes resources the controller creates at runtime. List the directory first, then read each template file.
- Look for gateway/ingress controllers that manage Gateway API, HTTPRoute, Istio Gateway, Routes, etc.
- Example: `internal/controller/services/gateway/` indicates operator manages ingress infrastructure
- Document controller-managed ingress/egress in Network Architecture section

**RHOAI 3.x Migration Patterns** (CRITICAL TO UNDERSTAND):
Controllers in RHOAI 3.x create different resources than 2.x. Read controller code to identify current behavior:

**Primary ingress pattern (RHOAI 3.x)**:
- Creates `HTTPRoute` CRs (Gateway API) for main service traffic
- Uses `kube-rbac-proxy` sidecars for authentication
- Look for: `gateway.networking.k8s.io/v1beta1` or `v1`, `HTTPRoute`, `kube-rbac-proxy` container

**Legacy pattern (RHOAI 2.x, being phased out)**:
- Creates OpenShift `Route` CRs for main service traffic
- Uses `oauth-proxy` sidecars for authentication
- Look for: `routev1.Route`, `oauth-proxy` container

**IMPORTANT — Routes still appear in 3.x code**:
RHOAI 3.x controllers may ALSO create OpenShift Route CRs intentionally for:
- **Redirect routes**: Routes pointing at nginx/redirect services to redirect old URLs to new Gateway API URLs (e.g., `dashboard_redirects.go` creates Route CRs for legacy dashboard and gateway hostnames that 301-redirect to the new hostname)
- **OAuth callback routes**: Routes needed for OAuth flows that must use the legacy Route mechanism
- **OcpRoute ingress mode**: An alternative ingress mode using Routes instead of Gateway API
- Do NOT skip or dismiss Route-creating code just because it's in a 3.x controller. Document ALL resources the controller creates, regardless of whether they use "old" or "new" patterns. The distinction is what traffic the resource handles, not whether it's legacy.

**How to identify in controller code**:
```go
// Search for ALL of these patterns across ALL .go files in controller directories:
HTTPRoute                    // Creating Gateway API HTTPRoutes
gateway.networking.k8s.io    // Gateway API imports
kube-rbac-proxy             // Auth sidecar (3.x primary)
routev1.Route               // OpenShift Routes (may be redirects, OAuth callbacks, or OcpRoute mode)
oauth-proxy                 // OAuth proxy (2.x pattern)
Route                       // Any Route creation (check purpose: redirect vs primary ingress)
```

**Examples**:
- `kubeflow/components/odh-notebook-controller/controllers/`: Creates HTTPRoutes + kube-rbac-proxy sidecars per notebook
- `rhods-operator/internal/controller/services/gateway/`: Deploys platform Gateway for HTTPRoutes to reference
- `rhods-operator/internal/controller/services/gateway/dashboard_redirects.go`: Creates nginx Deployment + Service + OpenShift Route CRs that redirect legacy dashboard/gateway URLs to the new Gateway API hostname
- Document ALL resources the controller creates — both HTTPRoutes AND Routes, noting the purpose of each

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

### Step 5: Git Information

Git metadata (version, branch, remote URL, recent commits) is **pre-gathered by the orchestrator** and included at the top of this prompt under "Pre-gathered Git Metadata". Use that data directly — do NOT run git commands to re-collect it.

If the pre-gathered metadata section is missing (e.g., when running this skill manually), fall back to:
```bash
git describe --tags --always 2>/dev/null; git branch --show-current; git remote get-url origin 2>/dev/null; git log --oneline --no-merges -20
```

### Step 6: Generate GENERATED_ARCHITECTURE.md

Follow the template exactly as defined in [architecture template](references/architecture-template.md). Read that file before writing.

**Structural rules:**
- Use exactly the section headings and table column headers from the template — do not rename, reorder, or add sections
- If a section has no data (e.g., no gRPC services), keep the heading and empty table header row, omit data rows
- Component-specific details (deployment modes, configuration, troubleshooting) go in the relevant existing sections (Architecture Components, Purpose/Detailed), not as new H2 sections
- Document current behavior based on code analysis, not assumptions

**IMPORTANT**: For RHOAI ingress architecture:
- Document controller-managed ingress even if not in static manifests
- RHOAI 3.x pattern: HTTPRoute + kube-rbac-proxy (document in Ingress table with type "HTTPRoute (Gateway API)")
- RHOAI 2.x pattern: Route + oauth-proxy (document with type "Route (OpenShift)")
- Read controller code to confirm which pattern is actually implemented

**Precision requirements for table values:**

- **Port numbers**: `8443/TCP`, `9090/TCP` (not "HTTPS port")
- **Protocols**: `HTTP`, `HTTPS`, `gRPC`, `gRPC/HTTP2` (not "network")
- **Encryption**: `TLS 1.3`, `TLS 1.2+`, `mTLS`, `plaintext` (not "encrypted")
- **Authentication**: `Bearer Token (JWT)`, `mTLS client certs`, `AWS IAM credentials` (not "authenticated")
- **RBAC**: Exact API groups: `""` for core, `apps`, `serving.kserve.io` (not "Kubernetes API")

### Step 7: Write File

Create `GENERATED_ARCHITECTURE.md` in the repository root.

**Important**: Populate the "Generated By" field in the Metadata section:
- Use the current date in YYYY-MM-DD format (use `date +%Y-%m-%d` command if needed)
- Include your model name (e.g., "Claude Sonnet 4.5", "Claude Opus 4.6", "Claude Haiku 3.5")
- Example: `**Generated By**: Claude Sonnet 4.5 on 2026-03-13`

**CRITICAL**: The `## Source References` section MUST be populated from your tracking log before writing.
- Every file you read during Steps 1-5 must appear in the "Files Analyzed" table
- Every grep/search you ran must appear in the "Grep/Search Results Used" table
- Line numbers must be specific ranges (e.g., `12-45`), not vague (e.g., "various")
- The "Sections Informed" column must map to actual section headings in the document
- If a section has no source file backing it (e.g., inferred from naming conventions), note it in the Coverage summary as "inferred"
- Do NOT fabricate file paths or line numbers — only include files you actually read

### Step 7a: Validate Output

After writing, run the validation script to catch template conformance errors:

```bash
python ${CLAUDE_SKILL_DIR}/scripts/validate_architecture.py GENERATED_ARCHITECTURE.md
```

If validation fails, read the errors, fix the markdown, re-write the file, and re-validate. Do not proceed to Step 8 until validation passes. Warnings (e.g., extra sections) are informational — fix if straightforward, otherwise note in the report.

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

Source References:
- [N] files analyzed
- [N] total lines referenced
- [N] grep/search patterns used
- [List any sections marked as "inferred" with no direct file backing]

Next steps:
1. Review GENERATED_ARCHITECTURE.md for accuracy (especially network/security tables)
2. Audit Source References section — verify file:line mappings are correct
3. Edit markdown if corrections needed (it's human-editable!)
4. Commit: git add GENERATED_ARCHITECTURE.md && git commit -m "Add architecture summary"
5. Use /aggregate-platform-architecture to combine with other components
```

## Notes

- Document what exists (if no CRDs/network policies found, that's okay)
- Search deployment manifests and source code thoroughly for network details
- Precision in security configuration is critical (RBAC, secrets, TLS, auth)
- Markdown tables are machine-parseable by LLMs for diagram generation
- Accuracy > speed - this is a source of truth document
- **Source References are mandatory** — every architecture claim must trace back to file:line
- The Source References section enables auditing, accuracy validation, and iterative improvement
- If you cannot find a source file for a claim, mark it as "inferred" in the Coverage summary rather than omitting it
- Source references also serve as a reading guide for reviewers who want to verify specific claims
