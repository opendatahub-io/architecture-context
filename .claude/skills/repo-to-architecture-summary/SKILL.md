---
name: repo-to-architecture-summary
description: Analyze a component repository and generate comprehensive architecture summary with structured markdown tables. Use when analyzing ODH/RHOAI components, documenting architecture, or creating security diagrams.
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git *), Bash(ls *), Bash(find *), Bash(python *), Write, Task
---

# Repo to Architecture Summary

Analyze a component repository (for Open Data Hub or Red Hat OpenShift AI) and generate a `GENERATED_ARCHITECTURE.md` file with detailed architecture information.

## Arguments

Positional argument:
- `[directory]` - Path to repository directory (default: current directory)

Optional flags:
- `--distribution=odh|rhoai|both` (default: both)
- `--version=X.Y` (default: auto-detect)
- `--output=FILENAME` (default: `GENERATED_ARCHITECTURE.md`)
- `--generated-by=STRING` (default: auto-detect from model name + current date)

Examples:
```bash
/repo-to-architecture-summary                                    # analyze current directory
/repo-to-architecture-summary checkouts/opendatahub-io/kserve   # analyze specific directory
/repo-to-architecture-summary ./kserve --distribution=rhoai --output=GENERATED_ARCHITECTURE.md
/repo-to-architecture-summary . --distribution=rhoai --generated-by="Claude Opus 4.6"
```

## Instructions

Generate a comprehensive architecture summary following these steps:

**IMPORTANT - TOOL USAGE**:
- Do NOT call `ToolSearch`. You already have access to: Bash, Read, Write, Glob, Grep, Task.
- When reading multiple files, use **parallel tool calls** — issue multiple Read/Glob/Grep calls in a single turn rather than one at a time. This dramatically reduces execution time.
- Prefer Grep with `--include` patterns over Bash `grep` commands.
- For large repositories, use the **Task tool to spawn sub-agents** that read files in parallel — see Step 3b (strategy selection) and Step 4a (sub-agent dispatch).

**NEVER read `*_test.go` files.** They consume context without informing architecture. Exclude them from all find commands and never open them.

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
3. Extract flag arguments (--distribution, --version, --output) for later use
4. The `--output` flag sets the output filename (default: `GENERATED_ARCHITECTURE.md`). Use this exact filename when writing the final file — do not invent a different name.

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

This operator deploys the platform's entire ingress infrastructure. You MUST thoroughly analyze it:

1. **List ALL controller directories** — run `find internal/controller -type d` and `find controllers -type d 2>/dev/null`
2. **For EVERY controller directory found**, run `ls -la` to see all files, then **read every `.go` file and every template file** (`*.tmpl.yaml`, `*.yaml`, `*.tmpl`) in that directory and its `resources/` subdirectory
3. Pay special attention to these directories (non-exhaustive — read ALL directories, not just these):
   - `internal/controller/services/gateway/` — Gateway API, Envoy, EnvoyFilter, kube-rbac-proxy
   - `internal/controller/services/gateway/resources/` — YAML/template files for Gateway, EnvoyFilter, Deployments
   - Any directory matching `*dashboard*`, `*route*`, `*redirect*`, `*ingress*`, `*auth*`

The ingress stack this operator deploys includes ALL of:
- **Gateway API** (`gateway.networking.k8s.io`): Gateway CR defining the platform ingress entry point
- **Envoy proxy**: The data plane that serves Gateway API traffic (deployed as a pod)
- **EnvoyFilter CRs** (`networking.istio.io/v1alpha3`): Traffic shaping, header manipulation, auth integration
- **kube-rbac-proxy**: Authentication/authorization sidecar injected into component pods
- **OpenShift Routes**: Redirect routes for legacy URLs, OAuth callback routes
- **nginx redirect services**: Deployment + Service + Route for 301 redirects from old hostnames
- **HTTPRoute CRs**: Per-component routing rules referencing the parent Gateway

Missing ANY of these produces an incomplete ingress architecture. Document every resource the controllers create.

**For other repositories**: Skip to discovery below.

### Step 3: Discover Repository Structure

Identify:
1. Repository name and purpose
2. Languages and frameworks:
   - Go operators: look for `main.go`, `controllers/`, `api/`
   - Python services: `setup.py`, `requirements.txt`, `pyproject.toml`
   - React/TypeScript: `package.json`, `src/`
   - Rust services: `Cargo.toml`, `src/main.rs`
   - Containers: **PRIORITIZE `Dockerfile.konflux` or `Containerfile.konflux`** if they exist
     - RHOAI is completely built by Konflux; ODH is transitioning to Konflux
     - Regular `Dockerfile`/`Containerfile` may be outdated/unused - verify they're actually used in builds
     - If both exist, prefer Konflux files for analysis
3. Deployment artifacts:
   - Helm charts: `Chart.yaml`
   - Kustomize: `kustomization.yaml`
   - Manifests: `*.yaml` in `manifests/`, `config/`, `deploy/`
   - **For opendatahub-operator**: Check `./opt/` directory for component manifests (populated by `make get-manifests`)

### Step 3a: Konflux Component Discovery

Identify every shippable container image by parsing Konflux Dockerfiles. Each `Dockerfile*konflux*` maps to one deployable component.

```bash
find . -maxdepth 3 \( -name "*Dockerfile*konflux*" -o -name "*Containerfile*konflux*" \) -print | sort
```

Read each Konflux Dockerfile and extract: component name (from filename suffix), base image, build stages, COPY source paths, exposed ports, and entry command. This creates a component inventory that drives all subsequent analysis.

For each Dockerfile, also determine the component's **intent** — its architectural role:
- **Primary service**: The main binary/server the repo exists to produce
- **Sidecar module**: Runs alongside primary in the same pod (BFF modules, kube-rbac-proxy)
- **Build variant**: Same component with instrumentation or different config (e.g., sealights)
- **Utility image**: CLI tool, migration runner, init container
- **Optional module**: Only deployed when a feature is enabled

The intent drives the Sub-Component Details section in the output.

See [Konflux Component Discovery](references/konflux-component-discovery.md) for the full procedure.

### Step 3b: Select Analysis Strategy

Based on what you found in Steps 3 and 3a, select which reference doc(s) to use for deep code analysis in Step 4a:

| Repo indicators | Reference doc | Sub-agent threshold |
|-----------------|---------------|---------------------|
| `go.mod` + `controllers/` or `internal/controller/` or `PROJECT` file | [Controller Analysis](references/controller-analysis.md) | 20+ Go files |
| `package.json` + `frontend/` + `packages/*/bff/` | [Frontend + BFF Analysis](references/frontend-bff-analysis.md) | 200+ TS/Go files |
| `pyproject.toml` or `setup.py` + Python source dirs | [Python Service Analysis](references/python-service-analysis.md) | 100+ Python files |
| `go.mod` + `cmd/*/main.go` (no controller dirs) | [Go Service Analysis](references/go-service-analysis.md) | 50+ Go files |
| `Cargo.toml` + `src/main.rs` | [Rust Service Analysis](references/rust-service-analysis.md) | 80+ Rust files |
| Only Dockerfiles, no significant source code | [Container Image Analysis](references/container-image-analysis.md) | Never (read directly) |
| `manifests/` or `config/` with `kustomization.yaml` | [Kustomize Manifest Analysis](references/kustomize-manifest-analysis.md) | Never (read directly) |

**Multi-language repos** (e.g., kserve with Go operators + Python SDK, model-registry with Go + Python + UI) should use multiple reference docs — one per language layer.

**Kustomize manifests** are a supplementary analysis — use the kustomize reference doc alongside the primary language-specific doc. Almost all component repos have `manifests/` or `config/` directories that define deployment resources, parameterization, and distribution variants.

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

# Envoy / EnvoyFilter (RHOAI ingress data plane)
grep -r "EnvoyFilter\|envoy" --include="*.go" . | head -20
grep -r "EnvoyFilter\|envoy" --include="*.yaml" --include="*.tmpl.yaml" --include="*.tmpl" . | head -20

# kube-rbac-proxy (RHOAI auth sidecar)
grep -r "kube-rbac-proxy" --include="*.go" --include="*.yaml" --include="*.tmpl.yaml" . | head -20

# OLM/Operator SDK patterns
grep -r "github.com/operator-framework" --include="*.go" . | head -20

# Service Mesh / Istio usage
grep -r "istio.io/api\|networking.istio.io" --include="*.go" . | head -20

# FIPS compliance (build flags, crypto, OLM annotations)
grep -r "GOEXPERIMENT\|strictfipsruntime\|CGO_ENABLED" --include="Dockerfile*" --include="Containerfile*" --include="Makefile*" --include="*.sh" . | head -20
grep -r "fips-compliant\|fips\.enabled\|FIPS" --include="*.yaml" --include="*.json" . | head -20
grep -r "boring\|boringcrypto\|openssl\|crypto/tls" --include="*.go" . | head -20
```

**Interpret results**:
- `controller-runtime/pkg/client`: Kubernetes operator using controller-runtime
- `controller-runtime/pkg/reconcile`: Has reconcile loops managing resources
- `openshift/api/route/v1`: Manages OpenShift Routes (RHOAI 2.x pattern)
- `openshift/api/config/v1`: Accesses OpenShift cluster configuration
- `gateway.networking.k8s.io`: Manages Gateway API resources (RHOAI 3.x pattern)
- `EnvoyFilter` / `networking.istio.io`: Creates Envoy filters for traffic shaping (RHOAI ingress)
- `kube-rbac-proxy`: Injects auth sidecar containers (RHOAI 3.x auth pattern)
- `operator-framework/api`: OLM-based operator with CRDs
- `istio.io/api`: Integrates with Istio service mesh
- `GOEXPERIMENT=strictfipsruntime`: Go binary compiled with FIPS-compliant crypto
- `CGO_ENABLED=1` (with strictfipsruntime): Required for Go FIPS — dynamically links against OpenSSL
- `-tags strictfipsruntime`: Build tag enabling FIPS crypto at compile time
- `fips-compliant: "true"` in CSV: OLM feature annotation declaring FIPS compliance
- `boringcrypto` / `boring` in imports: Using BoringCrypto backend for FIPS
- `crypto/tls`: Go TLS configuration — check for custom cipher suite restrictions or non-FIPS defaults
- **No FIPS signals**: Also significant — document the absence in the Security → FIPS Compliance section

**FIPS analysis has two layers — document both**:

**Layer 1: Build-time (check-payload gate)**:
Konflux validates images via [check-payload](https://github.com/openshift/check-payload) which enforces: Go binaries must be dynamically linked (CGO_ENABLED=1), OpenSSL must be installed in the image, no statically linked Go crypto. The `Dockerfile.konflux*` files are where these build flags live. If Konflux discovery (Step 3a) found FIPS flags, carry them into Security → FIPS Compliance. If NOT found, also check:
- CSV manifests (`bundle/manifests/*.clusterserviceversion.yaml`) for `features.operators.openshift.io/fips-compliant` annotation
- Go build commands in Makefiles for `-tags strictfipsruntime` or `GOEXPERIMENT` env vars

**Layer 2: Application-level crypto correctness**:
check-payload is the bare minimum — it validates build artifacts but not runtime crypto behavior. A binary can pass check-payload while still using non-FIPS cipher suites. Search the source code for:
```bash
# Go: TLS config, cipher suites, custom crypto
grep -r "tls\.Config\|CipherSuites\|MinVersion\|InsecureSkipVerify" --include="*.go" . | head -20
grep -r "crypto/md5\|crypto/rc4\|crypto/des" --include="*.go" . | head -10

# Python: non-FIPS crypto libraries
grep -r "pycryptodome\|pycrypto\|hashlib\.md5\|Crypto\." --include="*.py" . | head -10
grep -r "cryptography\|pyOpenSSL" --include="*.txt" --include="*.toml" --include="*.cfg" . | head -10

# Rust: crypto crate choices
grep -r "ring\|rustls\|openssl" --include="*.toml" . | head -10

# Java: BouncyCastle, custom crypto providers
grep -r "BouncyCastle\|Security\.addProvider\|Cipher\.getInstance" --include="*.java" . | head -10
```
Document findings in both the Build-Time and Application-Level tables under Security → FIPS Compliance. A component that passes check-payload but uses `crypto/md5` or `InsecureSkipVerify` has a FIPS gap worth noting.

**Build hermeticity — check lock files at every layer**:
Hermetic builds require all dependencies to be pre-resolved and locked. Check for lock files at three layers:

```bash
# RPM-level locks (from rpm-lockfile-prototype — often only on downstream release branches)
find . -maxdepth 3 -name "rpms.lock.yaml" | head -10

# Language-level locks
find . -maxdepth 3 \( -name "go.sum" -o -name "uv.lock" -o -name "poetry.lock" -o -name "Pipfile.lock" -o -name "package-lock.json" -o -name "yarn.lock" -o -name "Cargo.lock" -o -name "pixi.lock" \) | head -20

# Artifact locks (Hermeto — locks non-package artifacts like ML models)
find . -maxdepth 3 -name "artifacts.lock.yaml" | head -10

# Hermeto (formerly cachi2) prefetch integration in Dockerfiles
grep -r "cachi2\|hermeto\|REMOTE_SOURCES" --include="Dockerfile*" --include="Containerfile*" . | head -10
```

**Important**: Lock files often exist only on downstream release branches (`rhoai-3.4`, `rhoai-3.3`) and not on upstream/main branches. This is expected — Konflux adds lock files during release hardening. Document what is present on the branch being analyzed and note if the branch is upstream vs downstream.

Document findings in the **Security → Build Hermeticity** table. Gaps at any layer (e.g., `go.sum` present but no `rpms.lock.yaml`) are supply chain risks worth noting.

**Document findings** in Architecture Components table:
- Example: "Go Operator | controller-runtime based | Manages Gateway API (HTTPRoute), OpenShift Routes (legacy), Istio VirtualService"

This reconnaissance helps identify what the operator manages before reading controller code.

---

Search for and analyze:

**CRDs**: `**/*_crd.yaml`, `config/crd/`, `api/*/groupversion_info.go`
- Extract: API group, version, kind, scope

**Controllers and Webhooks**: `controllers/`, `pkg/controller/`, `internal/controller/`, `internal/webhook/`

- Extract: Watched CRDs, reconciliation logic, dynamically-created resources, integration points
- **CRITICAL**: Read controller code to see what resources are created dynamically (not just manifests!)
- **CRITICAL**: Identify every external system the controller talks to (API calls, CRD watches, webhook calls, metrics endpoints, auth providers)

**Use the sub-agent dispatch procedure in Step 4a below** for all controller and webhook analysis. Do NOT attempt to read all controller/webhook files yourself — large operators have 100+ files that exceed a single context window. Step 4a spawns sub-agents via the Task tool to read files in parallel and return structured findings.

- Document controller-managed ingress/egress in Network Architecture section
- Document every integration point in the Integration Points section
- Document webhook behavior in the Security section (what gets validated/mutated at admission time)

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
Gateway                      // Gateway CR (the ingress entry point itself)
EnvoyFilter                  // Istio EnvoyFilter CRs (traffic shaping, header manipulation)
networking.istio.io          // Istio API imports (for EnvoyFilter, VirtualService)
envoy                        // Envoy proxy configuration or deployment
kube-rbac-proxy             // Auth sidecar (3.x primary)
routev1.Route               // OpenShift Routes (may be redirects, OAuth callbacks, or OcpRoute mode)
oauth-proxy                 // OAuth proxy (2.x pattern)
Route                       // Any Route creation (check purpose: redirect vs primary ingress)
nginx                       // Redirect services (301 redirects from legacy URLs)
```

**Examples**:
- `kubeflow/components/odh-notebook-controller/controllers/`: Creates HTTPRoutes + kube-rbac-proxy sidecars per notebook
- `rhods-operator/internal/controller/services/gateway/`: Deploys platform Gateway for HTTPRoutes to reference
- `rhods-operator/internal/controller/services/gateway/dashboard_redirects.go`: Creates nginx Deployment + Service + OpenShift Route CRs that redirect legacy dashboard/gateway URLs to the new Gateway API hostname
- Document ALL resources the controller creates — both HTTPRoutes AND Routes, noting the purpose of each

**Gateway API / Ingress Controllers**:
- Search for: `gateway.networking.k8s.io`, `Gateway`, `HTTPRoute`, `GRPCRoute`, `TLSRoute`
- Search for: `EnvoyFilter`, `networking.istio.io`, `envoy` (Envoy data plane)
- Search for: `kube-rbac-proxy`, `oauth-proxy` (auth sidecars)
- Check controller code to understand what ingress infrastructure is deployed
- RHOAI 3.x deploys a full ingress stack — ALL of these must be documented:
  1. **Gateway CR** (`gateway.networking.k8s.io`): Defines the platform ingress entry point (e.g., "data-science-gateway")
  2. **Envoy proxy**: The data plane pod that serves Gateway API traffic
  3. **EnvoyFilter CRs** (`networking.istio.io/v1alpha3`): Traffic shaping, header manipulation, CORS, auth enforcement
  4. **HTTPRoute CRs**: Per-component routing rules referencing the parent Gateway
  5. **kube-rbac-proxy sidecars**: Auth enforcement per component pod
  6. **OpenShift Routes**: Redirect routes (legacy URL → new Gateway URL), OAuth callbacks
  7. **nginx redirect Deployments**: 301 redirect services for legacy hostnames
- This is **critical ingress architecture** — must be documented even if not in static manifests
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

**Kustomize structure analysis**: When `manifests/` or `config/` directories contain `kustomization.yaml` files, analyze the full kustomize composition — not just individual YAML files. See [Kustomize Manifest Analysis](references/kustomize-manifest-analysis.md). Document the base/overlay structure, parameterization (`configMapGenerator`, `vars`, `replacements`, `params.env`), and distribution variants (ODH vs RHOAI) in the **Deployment Manifests** section. These manifests are consumed by the platform operator (`rhods-operator`/`opendatahub-operator`) via `get_all_manifests.sh` and define how the component is actually deployed on clusters.

### Step 4a: Sub-Agent Deep Analysis

When the repository has more source files than you can read in one context window, use the sub-agent dispatch pattern: enumerate files, group them by functional area, spawn sub-agents via the Task tool to read all files in parallel, then aggregate their structured findings.

**Use the reference doc selected in Step 3b.** Each reference doc contains the complete procedure — enumeration commands, grouping heuristics, sub-agent prompt template, and aggregation instructions:

| Repo type | Reference doc | Sub-agent prompt extracts |
|-----------|---------------|--------------------------|
| Go operator | [Controller Analysis](references/controller-analysis.md) | Resources Created/Watched, Webhooks, Integration Points, Network Exposure, RBAC |
| Frontend + BFF monorepo | [Frontend + BFF Analysis](references/frontend-bff-analysis.md) | API Surface, Module Federation, Routes, BFF Handlers, Upstream Calls, Config |
| Python ML service | [Python Service Analysis](references/python-service-analysis.md) | API Endpoints, Proto/gRPC, Config, Health, Dependencies, Model Architecture |
| Go service | [Go Service Analysis](references/go-service-analysis.md) | Entry Points, HTTP Handlers, gRPC, Upstream Calls, Auth, Health |
| Rust service | [Rust Service Analysis](references/rust-service-analysis.md) | HTTP Routes, gRPC, Downstream Calls, Config, TLS/mTLS, Health |
| Container image | [Container Image Analysis](references/container-image-analysis.md) | Base images, installed packages, ports, entry points (no sub-agents needed) |

**General sub-agent rules** (apply to all reference docs):
- Use the Task tool with `subagent_type=Explore` (read-only analysis)
- Launch up to **3 sub-agents in parallel** per batch
- Each sub-agent must read EVERY file in its assigned group — no skipping
- **File-based output**: Each sub-agent writes its findings to a temp file (e.g., `/tmp/arch-analysis-{component}-group-{N}.md`) using the Write tool, then responds with only a short confirmation message. This keeps sub-agent responses small and avoids context bloat.
- After all sub-agents complete, the main agent **reads each output file** using the Read tool, then aggregates findings into the architecture template

**Multi-language repos**: Run sub-agents from multiple reference docs. For example, kserve needs both controller-analysis.md (Go operator) and python-service-analysis.md (Python SDK).

### Step 5: Git Information

Git metadata (version, branch, remote URL, recent commits) is **pre-gathered by the orchestrator** and included at the top of this prompt under "Pre-gathered Git Metadata". Use that data directly — do NOT run git commands to re-collect it.

If the pre-gathered metadata section is missing (e.g., when running this skill manually), fall back to:
```bash
git describe --tags --always 2>/dev/null; git branch --show-current; git remote get-url origin 2>/dev/null; git log --oneline --no-merges -20
```

### Step 6: Generate GENERATED_ARCHITECTURE.md

Follow the template exactly as defined in [architecture template](references/architecture-template.md). Read that file before writing.

**Structural rules:**
- Use exactly the section headings and table column headers from the template — do not rename, reorder, or add sections (except Sub-Component Details, which is conditional)
- If a section has no data (e.g., no gRPC services), keep the heading and empty table header row, omit data rows
- Document current behavior based on code analysis, not assumptions

**Sub-Component Details** (multi-component repos only):
When the component inventory from Step 3a contains multiple Konflux Dockerfiles, add a **Sub-Component Details** section after Architecture Components. Each Dockerfile-derived component gets its own `###` subsection with: intent (1-2 sentences on why it exists and when it's deployed), API routes, upstream dependencies, and configuration tables. For single-Dockerfile repos, skip this section — the Purpose section covers intent. Every sub-component MUST be analyzed — do not sample or skip any.

When writing the intent for init containers and utility images: the Dockerfile `CMD` is the image default for standalone use. In Kubernetes, the consuming deployment typically overrides it via `command:`/`args:`. Describe the deployed behavior (what the pod actually runs), not just the image default. If the runtime command is specified in a deployment manifest within the repo (or a sibling checkout), use that. If it cannot be determined, note the Dockerfile CMD as the default and that the runtime command is set by the consuming deployment.

**Architectural Analysis** (all repos):
After completing all structured sections, write an **Architectural Analysis** section with free-form observations about the component's architecture. This is where you synthesize patterns, design decisions, risks, or noteworthy findings that don't fit the tables. Examples: "The BFF modules share a common Go framework but each implements auth differently", "The cache server webhook has no TLS — it relies on the namespace network policy for isolation", "The driver/launcher split mirrors a sidecar pattern but runs as sequential Argo steps". Write 2-5 paragraphs. Be specific and cite files or patterns you observed.

**IMPORTANT — Operators that manage infrastructure require expanded output**:

If the component is an operator that creates Kubernetes resources dynamically (Deployments, Services, Routes, HTTPRoutes, EnvoyFilters, NetworkPolicies, etc.), the output MUST go beyond the flat tables in the template. Specifically:

1. **Network Architecture section**: Every resource the controller creates at runtime must appear in the Services, Ingress, or Egress tables. Include resources from Go code AND from `.tmpl.yaml` template files in `resources/` directories. If the operator manages a multi-layer ingress stack (Gateway → Envoy → auth proxy → application), document the full chain with traffic flow.

2. **Integration Points section**: Must list every component this operator interacts with. For platform operators (rhods-operator, opendatahub-operator), this means every component CR it creates, every external CRD it watches, every webhook it calls, every shared Secret/ConfigMap it reads or writes.

3. **Key Controllers section** (under Architecture Components or as subsections): Each controller that manages significant infrastructure deserves a dedicated subsection describing:
   - What CRs/resources it watches
   - What resources it creates/manages (list every resource type with its purpose)
   - What external systems it integrates with
   - The reconciliation flow (what happens when the CR changes)

4. **For RHOAI ingress specifically**: The Gateway controller deploys a full stack — Gateway CR, Envoy proxy, EnvoyFilter CRs, kube-auth-proxy (OAuth and OIDC deployments), HTTPRoutes, DestinationRules, NetworkPolicies, OpenShift Routes (redirects), nginx redirect Deployments. Every one of these must appear in the output with its purpose, ports, TLS configuration, and how it connects to the next layer. A bullet-point summary is NOT sufficient — use the Ingress table AND a traffic flow description.

5. **RHOAI ingress patterns**:
   - RHOAI 3.x pattern: HTTPRoute + kube-rbac-proxy (document in Ingress table with type "HTTPRoute (Gateway API)")
   - RHOAI 2.x pattern: Route + oauth-proxy (document with type "Route (OpenShift)")
   - Read controller code to confirm which pattern is actually implemented
   - Document ALL resources even if they mix patterns (e.g., 3.x controllers that also create Routes for redirects)

**Precision requirements for table values:**

- **Port numbers**: `8443/TCP`, `9090/TCP` (not "HTTPS port")
- **Protocols**: `HTTP`, `HTTPS`, `gRPC`, `gRPC/HTTP2` (not "network")
- **Encryption**: `TLS 1.3`, `TLS 1.2+`, `mTLS`, `plaintext` (not "encrypted")
- **Authentication**: `Bearer Token (JWT)`, `mTLS client certs`, `AWS IAM credentials` (not "authenticated")
- **RBAC**: Exact API groups: `""` for core, `apps`, `serving.kserve.io` (not "Kubernetes API")

### Step 7: Write File

Write the output file using the filename from the `--output` flag (default: `GENERATED_ARCHITECTURE.md`). The file goes in the repository root.

**Important**: Populate the "Generated By" field in the Metadata section:
- If `--generated-by` was provided, use that exact string
- Otherwise, use your model name (e.g., "Claude Sonnet 4.5", "Claude Opus 4.6", "Claude Haiku 3.5")
- Append the current date in YYYY-MM-DD format (use `date +%Y-%m-%d` command if needed)
- Example: `**Generated By**: Claude Opus 4.6 on 2026-03-13`

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

### Depth expectations by component type

- **Platform operators** (rhods-operator, opendatahub-operator): These are the most complex components. They manage dozens of sub-components, create hundreds of Kubernetes resources dynamically, and define the platform's entire networking, security, and deployment architecture. The output should be 500+ lines with detailed controller descriptions, complete resource inventories, full ingress/egress chains, and comprehensive integration points. A shallow 200-line summary is a failure.
- **Component operators** (kserve, kueue, training-operator, etc.): Medium complexity. Focus on CRDs, controller logic, network exposure, and integration with the platform operator. 200-400 lines typical.
- **Services and frontends** (dashboard, model registry API, etc.): Lower complexity. Focus on API surface, deployment topology, and security. 150-300 lines typical.

### Integration points are critical

The Integration Points section is one of the most valuable parts of the output — it tells architects and agents how components connect. For every component, ask:
- What CRDs does it watch that belong to other components?
- What Services/endpoints does it call?
- What Secrets/ConfigMaps does it read that are created by other components?
- What webhooks does it register that intercept other components' resources?
- What labels/annotations does it set that other components select on?

A platform operator should have 15-30+ integration point rows. A simple service might have 3-5. An empty Integration Points table is almost always wrong.
