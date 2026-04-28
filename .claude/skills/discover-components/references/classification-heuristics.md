# Classification Heuristics

## Step 5a: Identify Shared Libraries

After building the dependency graph, analyze it to find shared libraries:

**Reverse the dependency graph** to count consumers:
```
{
  "awx-operator": ["installer"],                          # 1 consumer
  "eda-operator": ["installer"],                          # 1 consumer
  "awx-api": ["awx-operator"],                           # 1 consumer
  "django-ansible-base": ["awx-operator", "eda-operator", "automation-hub-operator"]  # 3 consumers!
}
```

**Shared library detection criteria:**
1. Is a dependency (not deployed standalone)
2. Used by 2+ platform components
3. In the same organization (first-party, not third-party)
4. Contains actual code (not just config/docs)

**For detected shared libraries:**
- Mark as `type: "shared_library"`
- Set `shipped: false` (not deployed directly)
- Set `architecturally_significant: true`
- Add `consumer_count` and `consumers: [...]`
- Include in component map (don't exclude!)

**Examples:**
- ✅ `django-ansible-base` - Shared Django utilities used by AWX, EDA, Hub
- ✅ `ansible-common-auth` - Shared authentication library
- ✅ `platform-sdk` - SDK used by multiple operators
- ❌ `django` - Third-party (not in platform org)
- ❌ `postgres` - Third-party infrastructure
- ❌ `one-off-util` - Only used by one component

## Step 5b: Identify Architecturally Significant External APIs

Some third-party repos aren't utilities you *use* — they're contracts you *implement*. These define the CRDs, APIs, or interface specifications that shape your platform's architecture. Excluding them loses critical architectural context.

**After shared library detection, scan excluded third-party repos for API contract significance:**

1. Repo exists in the checkouts directory (the platform team chose to mirror/fork it)
2. Primarily defines APIs, CRDs, or interface contracts — look for:
   - `apis/`, `config/crd/`, protobuf definitions (`.proto` files)
   - Module is mostly types/interfaces (Go: types, structs, interfaces; Python: abstract base classes, schemas)
   - Kubernetes API machinery (`GroupVersionResource`, `runtime.Object` implementations)
3. Platform components import its types as **direct** (not indirect/transitive) dependencies
4. High reference count in core control-plane or reconciliation code — the platform's controllers are **structured around** these types, not just calling utility functions

**How to measure architectural impact:**
```bash
# Count references to the repo's types in core platform code
grep -r "Gateway\|HTTPRoute\|GRPCRoute" {platform_repo}/pilot/ | wc -l
# If this is in the hundreds across core packages, it's architectural
```

**The key distinction: tool vs. contract**
- `django` is a **tool** — you call its functions, but your architecture doesn't revolve around Django types
- `gateway-api` is a **contract** — your controllers exist to reconcile its CRDs, your entire ingress model is defined by its types

**For detected API specifications:**
- Mark as `type: "api_specification"`
- Set `shipped: false` (not your code)
- Set `architecturally_significant: true`
- Add `upstream_org` field to clarify ownership (e.g., `"kubernetes-sigs"`)
- Add `consumer_count` and `consumers: [...]`
- Include in component map (don't exclude!)
- Add a note clarifying it is upstream-owned but architecturally foundational

**Examples:**
- ✅ `gateway-api` - Kubernetes Gateway API (defines CRDs that Istio's control plane reconciles)
- ✅ `operator-framework/api` - OLM API types (if platform operators are built around them)
- ✅ `open-cluster-management/api` - OCM API types (if platform implements OCM contracts)
- ❌ `envoy` - Upstream runtime dependency (you embed it, but don't implement its API spec)
- ❌ `go-control-plane` - Utility library (you call it, architecture doesn't revolve around its types)
- ❌ `client-go` - Kubernetes client library (tool, not contract)

## Step 5c: Classify Component Type

For each discovered component, determine its `type`. Do NOT default everything to `"operator"` just because it has manifests. Check what the repo actually contains:

**`operator`** — Has a Deployment running a controller/reconciler binary AND owns its own operator lifecycle:
- Contains `main.go` or equivalent entrypoint with controller-runtime/operator-sdk imports
- Has `config/manager/` or operator bundle structure (OLM bundle, CSV)
- Reconciles CRDs or cluster resources
- Has its own OLM lifecycle (or is the top-level meta-operator)
- Key distinction from `controller`: operators manage their own installation/upgrade lifecycle via OLM or equivalent

**`controller`** — Runs a reconciliation loop but does NOT own its own operator lifecycle:
- Uses controller-runtime/kubebuilder but is deployed as a sub-component of a parent operator
- May define or watch CRDs, but doesn't have its own OLM bundle or CSV
- Examples: notebook-controller (deployed by rhods-operator), odh-model-controller (deployed by rhods-operator)
- Key distinction from `operator`: controllers are deployed by operators, not independently installable

**`service`** — Runs as a workload but is not a controller/operator:
- Serves API endpoints, processes data, runs as a daemon
- Examples: API servers, model servers, proxies, pipeline servers

**`ui`** — A user-facing web application (frontend, dashboard):
- Contains frontend code (React, Angular, Vue, etc.) and optionally a backend-for-frontend
- Serves a web UI that users interact with directly
- Examples: odh-dashboard (React + Node.js), console (OpenShift web console)
- Key distinction from `service`: the primary purpose is user-facing UI, not a headless API

**`installer`** — Bootstraps the cluster or platform:
- Contains terraform, ignition configs, installer logic
- Examples: `installer`, `assisted-installer`

**`asset`** — Ships static content, not running code:
- GPG keys, branding assets, base images, OS definitions
- Examples: `cluster-update-keys` (signing keys), `origin-branding` (UI branding), `okd-machine-os` (OS image definition), `driver-toolkit` (base container image)

**`shared_library`** — Code imported by other components (detected in Step 5a)

**`api_specification`** — Defines API contracts the platform implements (detected in Step 5b)

**Quick heuristic:** If the repo has no `main.go`/`cmd/` and no Deployment that runs a binary it builds, it's not an operator.

**`architecturally_significant` is independent of `type`.** Do NOT set `architecturally_significant: false` just because something is an `asset` or `service` instead of an `operator`. A component is architecturally significant if:
- Other components depend on it or build on top of it (e.g., base container images)
- It defines security boundaries (e.g., signing keys, certificates)
- It's part of the bootstrap/install chain
- It appears in the dependency graph with 2+ consumers
- Removing or changing it would affect the architecture of the platform

Default to `architecturally_significant: true` for all `core_platform` and `optional_platform` components regardless of type. Only set it to `false` for `payload_component` tier repos that are clearly peripheral (e.g., a deprecated shim that's still shipped but unused).

## Heuristics for Component Classification

### Include: Deployed Components (shipped: true)

**Definitive (DSC spec — Step 2a):**
- Has a field in the DataScienceCluster Components struct → `tier: optional_platform` (user-togglable via managementState)
- Is the meta-operator itself (rhods-operator, opendatahub-operator) → `tier: core_platform`
- Is an always-on component (odh-dashboard, notebooks, odh-model-controller) → `tier: core_platform`
- Found in OLM catalog relatedImages → `shipped: true`
- Found in RELATED_IMAGE mappings → `shipped: true`, `tier: payload_component` (unless classified higher by DSC spec)

The DSC spec is the authoritative source for tier classification. It overrides all heuristic confidence levels below.

**High confidence (definitely deployed):**
- Referenced in operator manifests
- Referenced in installer playbooks
- Container image built in CI and pushed to registry
- Listed in OLM bundle
- Has operator structure (bundle/, config/manager/)

**Medium confidence (probably deployed):**
- Has Kubernetes manifests
- Has recent releases
- Referenced by other high-confidence components

**Low confidence (maybe deployed):**
- Has Dockerfile
- Active development
- Matches naming pattern

### Include: Shared Libraries (shipped: false, architecturally_significant: true)

**Critical shared libraries:**
- First-party code (same GitHub org)
- Used by 2+ platform components
- Contains actual code (not just config/docs)
- Examples: django-ansible-base, shared authentication libraries, common SDKs

**Detection method:**
1. Found in requirements.txt, pyproject.toml, go.mod of multiple repos
2. Reverse dependency count ≥ 2
3. Repo exists in checkouts directory (first-party)
4. Has source code (not a meta-repo)

**Why include them:**
- Critical for understanding platform architecture
- Needed for security reviews (shared code paths)
- Dependency impact analysis (if library has vulnerability, which components affected?)
- Architecture dependencies (components share behavior through these)

### Exclude: Non-Components

**Always exclude:**
- Third-party utility dependencies (django, flask, postgres, redis)
- Docs/wiki repos (no code, just markdown)
- CI/CD tooling repos
- Test frameworks and utilities
- Development helpers
- Archived/stale repos (no commits in 12+ months)

**Exception — do NOT exclude external API specifications:**
- If a third-party repo defines CRDs/APIs that your platform *implements* (not just *uses*), include it as `type: "api_specification"` per Step 5b
- The test: do your controllers/reconcilers exist to serve this repo's types? If yes, it's a contract, not a utility

**How to distinguish first-party from third-party:**
- First-party: In the same GitHub org as platform
- Third-party: External dependencies (PyPI, npm, Go modules)
- Third-party API spec: External org, but defines contracts your platform implements (see Step 5b)

**Special cases:**
- One-off dependencies (only used by 1 component): Exclude unless deployed
- Internal tools (used by developers, not shipped): Exclude
- Vendored third-party code: Exclude (treat as third-party)
- Mirrored/forked API spec repos: Include if they meet Step 5b criteria
