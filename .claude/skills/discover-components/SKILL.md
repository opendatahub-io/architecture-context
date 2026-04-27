---
name: discover-components
description: Discover platform components by exploring breadcrumbs (installers, operators, dependencies) in checkouts directory. Outputs component-map.json for platforms without manifest scripts.
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, Bash(ls *), Bash(find *), Bash(cat *), Bash(grep *), Bash(python *)
---

# Discover Components

Discover which repositories in a checkouts directory are actual platform components (shipped in the product) vs. side projects, tools, or helpers.

This is used for platforms that don't have a central manifest script (like ODH/RHOAI's `get_all_manifests.sh`). Instead, we explore "breadcrumbs" to build a component map:

## Breadcrumb Types

1. **Operators** - Kubernetes operators with OLM bundles
2. **Container Images** - Referenced in manifests, Dockerfiles, CI configs
3. **Dependencies** - Listed in requirements files, go.mod, package.json
4. **Installers** - Ansible playbooks, Helm charts, deployment scripts
5. **Build Artifacts** - What gets built in CI/CD pipelines

## Arguments

Required:
- `--platform=<name>` - Platform identifier (e.g., "aap", "ansible")
- `--checkouts-dir=<path>` - Directory containing cloned repos

Optional:
- `--entry-repo=<name>` - Starting point repo (e.g., "installer", "operator")
- `--architecture-dir=<path>` - Output directory (default: architecture)
- `--exclude=<pattern>` - Additional repos to exclude (comma-separated)

## Instructions

### Step 1: Scan Checkouts Directory

List all subdirectories in the checkouts directory:

```bash
ls -1 {checkouts_dir}/
```

This gives you the universe of possible components.

### Step 2: Initial Filtering

Exclude obvious non-components:
- Directories starting with `.` (hidden)
- Common patterns:
  - `*-docs`, `*-documentation`
  - `*-ci`, `*-tools`, `*-testing`, `*-test`
  - `must-gather`, `cli`, `additional-images`
  - Build/release infrastructure repos

Create an initial list of candidate repos.

### Step 2a: Probe for Release Payload Signals

Before breadcrumb exploration, check whether the platform has **formal release inclusion signals** — annotations, manifests, or metadata that explicitly declare which repos ship in the product. Large platforms (OpenShift, OKD, etc.) often have these; small platforms typically don't.

**Why this matters:** Without payload signals, the skill must infer "is this shipped?" from heuristics (has Dockerfile? has operator structure?). On a platform with 800+ repos where 179 are operators, heuristics produce a useless component map. Payload signals give a definitive answer.

**Probe procedure — sample 5-10 repos** (prefer repos named `cluster-*-operator` or `*-controller`) and scan their manifest directories for known signal patterns.

**IMPORTANT: Path rules for signal scanning:**
- Scan BOTH `manifests/` AND `install/` directories (some components use one or the other)
- ALWAYS exclude `vendor/`, `testdata/`, `pkg/*/testdata/`, and `test/` paths — these contain vendored copies of other components' manifests and test fixtures that will produce false positives
- Example: CVO's `vendor/` contains 97 YAML files with release annotations from OTHER operators

```bash
# Correct: exclude vendor and testdata
grep -r --exclude-dir=vendor --exclude-dir=testdata "include.release.openshift.io" {sample_repo}/manifests/ {sample_repo}/install/ 2>/dev/null
# WRONG: scanning all YAML will hit vendor/ and testdata/
grep -r "include.release.openshift.io" {sample_repo}/ 2>/dev/null
```

#### Signal 1: Release Inclusion Annotations
```bash
grep -r --exclude-dir=vendor --exclude-dir=testdata "include.release.openshift.io\|release.openshift.io\|operator.openshift.io/managed" {sample_repo}/manifests/ {sample_repo}/install/ 2>/dev/null
```
These annotations declare that a component ships in a specific release profile (self-managed, single-node, hypershift, etc.).

#### Signal 2: Capability/Optional Annotations
```bash
grep -r --exclude-dir=vendor --exclude-dir=testdata "capability.openshift.io/name\|operator.openshift.io/capability" {sample_repo}/manifests/ {sample_repo}/install/ 2>/dev/null
```
These mark a payload component as **optional** — it ships by default but can be disabled. Components WITHOUT this annotation (but WITH release inclusion) are **core**.

**CRITICAL: Check the Deployment, not just any manifest.** A capability annotation on a sub-resource (dashboard, credential request, operator group) means "this sub-resource is conditional on that capability" — it does NOT mean the operator itself is optional. To determine if the operator is truly optional, check specifically whether the operator's **Deployment manifest** (`kind: Deployment`) has the capability annotation:

```bash
# Find the operator's Deployment manifest and check for capability annotation
grep -l "kind: Deployment" {repo}/manifests/ {repo}/install/ 2>/dev/null | xargs grep -l "capability.openshift.io/name" 2>/dev/null
```

- If the **Deployment** has `capability.openshift.io/name: X` → the operator is `optional_platform` with `capability: "X"`
- If only non-Deployment resources have capability annotations → the operator is `core_platform` (with some conditional sub-resources)

**Extract the actual capability name** from the annotation value (e.g., `capability.openshift.io/name: openshift-samples` → `"capability": "openshift-samples"`). Do NOT use a generic placeholder like `"optional-component"`.

#### Signal 3: Image Reference Manifests
```bash
ls {sample_repo}/manifests/image-references {sample_repo}/install/image-references 2>/dev/null
```
A structured file listing container images the repo contributes to the release payload.

#### Signal 4: OLM Catalog Membership
```bash
ls {sample_repo}/bundle/manifests/*.clusterserviceversion.yaml 2>/dev/null
```
If a central catalog repo exists (e.g., `certified-operators`, `redhat-operators`), check whether this repo's CSV is listed there.

#### Signal 5: Helm Chart Index / Kustomize Catalog
```bash
ls {sample_repo}/charts/ {sample_repo}/Chart.yaml 2>/dev/null
```
For Helm-based platforms, check if a central chart index references this repo.

**If signals are found in 3+ sampled repos**, this platform has formal payload signals. Set `discovery_method: "release_payload_signals"` and proceed with a **full signal scan**:

#### Full Signal Scan

Scan ALL repos in the checkouts directory for the detected signal type(s). Apply the path rules above (scan `manifests/` + `install/`, exclude `vendor/` + `testdata/`). Classify each repo into a tier:

| Tier | Criteria | Example |
|------|----------|---------|
| `core_platform` | Has release inclusion annotations and NO capability annotation **on its Deployment** | `cluster-etcd-operator`, `cluster-kube-apiserver-operator` |
| `optional_platform` | Has release inclusion annotations AND capability annotation **on its Deployment** | `cluster-samples-operator` (capability: openshift-samples) |
| `payload_component` | Has `image-references` but no release/capability annotations | Supporting images shipped in payload |
| `ecosystem` | No release signals at all | `aws-account-operator` |

**Important subtlety:** A repo like `cluster-kube-apiserver-operator` may have `capability.openshift.io/name: Console` on dashboard manifests — this means "only create this dashboard if Console capability is enabled," NOT "this operator is optional." Only the Deployment-level annotation determines the operator's tier.

#### Bootstrap / Self-Referential Components

Some components exist **before** the release payload mechanism and naturally won't annotate themselves:

- **Cluster Version Operator (CVO)** — the component that reads `include.release.openshift.io` annotations and reconciles all other operators. It doesn't annotate itself because it IS the reconciler. If a repo contains CVO logic (look for `ClusterVersion` controller code, or repo name matches `*-version-operator`), classify as `core_platform` automatically.
- **Installer** — bootstraps the cluster before CVO takes over. If a repo is named `installer` or contains cluster bootstrapping logic (terraform, ignition configs), include it as `core_platform` with `type: "installer"`.
- **Bootstrap components** — repos that run during cluster bootstrap (e.g., `cluster-bootstrap`) may use `install/` instead of `manifests/`. Check both.

General rule: if a component is part of the **bootstrap chain** that brings the platform into existence before the normal operator lifecycle starts, it's `core_platform` even without release annotations.

**Record the tier for each repo.** This tiering drives the rest of the discovery process:
- `core_platform` + `optional_platform` → full breadcrumb exploration in Steps 3-5
- `payload_component` → include as component, lighter exploration
- `ecosystem` → skip breadcrumb exploration, go directly to excluded (can be pulled back in by dependency analysis in Step 5a/5b)

**If signals are NOT found** (fewer than 3 sampled repos match), this platform doesn't have formal payload signals. Set `discovery_method: "breadcrumb"` and proceed to Step 3 with the full candidate list as before.

### Step 3: Find Entry Points

**If release payload signals were found (Step 2a):** Limit candidate repos to those in the `core_platform`, `optional_platform`, and `payload_component` tiers. Do NOT treat every operator-shaped repo as an entry point — only those with release signals.

If `--entry-repo` specified, start there. Otherwise, search for common entry points:

**Operator repos** (high-value entry points):
- Directories containing `bundle/`, `config/manager/`, `operator.yaml`
- Typically named: `*-operator`, `operator`

**Installer repos**:
- Directories containing: `install.yml`, `site.yml`, `playbooks/`
- Typically named: `installer`, `*-installer`, `deployment`

**Platform repos**:
- Directories with platform-wide configs
- Names like: `platform`, `automation-platform`, `*-platform`

List discovered entry points and pick the best one (or use all).

### Step 4: Explore Breadcrumbs from Entry Points

For each entry point, look for references to other repos:

#### 4a. Kubernetes Manifests
Search for container image references:

```bash
grep -r "image:" {entry_repo}/config/ {entry_repo}/manifests/ {entry_repo}/bundle/
```

Extract repo names from image paths like:
- `quay.io/ansible/awx-operator:latest` → `awx-operator`
- `registry.redhat.io/ansible/eda-server:1.0` → `eda-server`

#### 4b. Ansible Playbooks
Search for role/collection references:

```bash
grep -r "role:" {entry_repo}/
grep -r "collection:" {entry_repo}/
```

#### 4c. Dependency Files

**Python** (`requirements.txt`, `pyproject.toml`):
```bash
find {entry_repo} -name "requirements*.txt" -o -name "pyproject.toml"
cat {found_files}
```

Look for patterns like:
- `django-ansible-base>=1.0.0` - First-party package (matches repo name)
- `-e git+https://github.com/ansible/django-ansible-base.git` - Editable install from git
- `file:///path/to/local/repo` - Local dependency

**Go** (`go.mod`):
```bash
find {entry_repo} -name "go.mod"
cat {found_files}
```

Look for:
- `github.com/ansible/common-lib v1.0.0` - First-party module
- `replace github.com/ansible/foo => ../foo` - Local replacement

**Key insight:** If a dependency name matches a repo in the checkouts directory, it's likely a first-party shared library!

#### 4d. Git Submodules
```bash
cat {entry_repo}/.gitmodules
```

#### 4e. CI/CD Pipelines
```bash
find {entry_repo} -path "*/.github/workflows/*.yml" -o -path "*/.gitlab-ci.yml"
cat {found_files}
```

Look for:
- Build jobs
- Image build steps
- Deployment steps
- References to other repos

### Step 5: Build Component Graph

**This step runs in BOTH breadcrumb and release_payload_signals modes.** Even when payload signals identified the components, you still need dependency analysis to discover shared libraries (Step 5a) and populate the dependency graph.

**In release_payload_signals mode**, two additional scans are required:

**5.1: Discover operand repos via `image-references`.** Operators often deploy separate repos as operands (the workload the operator manages). These operand repos typically have NO release annotations of their own — the operator carries the annotations and the operand is just a container image the operator deploys.

Scan the `image-references` file (in `manifests/` or `install/`) of each discovered operator. For each image name listed:
1. Check if a repo with that name exists in the checkouts directory
2. If yes and it's not already in the component list, add it as `tier: "payload_component"`, `discovered_via: "operator_operand"`, `referenced_by: ["{operator-name}"]`
3. Mark as `shipped: true` (it's deployed by the operator)

```bash
# Example: console-operator's image-references lists "console" as an operand
cat {operator_repo}/manifests/image-references
# - name: console-operator    ← the operator itself
# - name: console             ← the operand (separate repo!)
```

Common operator→operand pairs:
- `console-operator` → `console` (web UI)
- `cluster-ingress-operator` → router/haproxy-router
- `cluster-image-registry-operator` → `image-registry`
- `cluster-dns-operator` → coredns

**5.2: Scan `go.mod` for shared libraries.** Scan `go.mod` (or equivalent) of each discovered `core_platform` and `optional_platform` component. Look for first-party dependencies (same GitHub org) that match repos in the checkouts directory. This is how shared libraries like `library-go`, `api`, `client-go` get discovered.

As you discover references:
1. Check if referenced repo exists in checkouts directory
2. If yes, add to component list with `discovered_via` and `referenced_by`
3. Track what type of reference (deployed_component vs. dependency vs. operand)
4. Mark as `shipped: true` if deployed directly
5. **Always populate the `dependency_graph`** — even in signal mode, record which components depend on which

Track the dependency graph:
```
{
  "cluster-etcd-operator": ["api", "library-go", "client-go"],
  "cluster-kube-apiserver-operator": ["api", "library-go", "client-go", "apiserver-library-go"],
  "cluster-network-operator": ["api", "library-go", "client-go"],
  ...
}
```

### Steps 5a-5c: Classification

See [classification heuristics](references/classification-heuristics.md) for:
- **Step 5a**: Identify shared libraries (reverse dependency graph, detection criteria)
- **Step 5b**: Identify architecturally significant external APIs (tool vs. contract distinction)
- **Step 5c**: Classify component type (operator, controller, service, ui, installer, asset, shared_library, api_specification)

### Step 6: Classify Remaining Repos

**If release payload signals were found (Step 2a):** The default is inverted. Repos without release signals are `ecosystem` tier and should be excluded unless they were pulled in as a shared library (Step 5a) or API specification (Step 5b). Do NOT apply the "possible shipped components" heuristics below to ecosystem-tier repos — the release signals are the authoritative source.

**If NO release payload signals were found:** Use the heuristics below for repos not discovered via breadcrumbs:

**Possible shipped components** (include with lower confidence):
- Has `Dockerfile` or `Containerfile`
- Has Kubernetes manifests (`config/`, `manifests/`)
- Has operator structure (`bundle/`, `config/manager/`)
- Has recent git activity (within last 6 months)
- Has releases/tags

**Definitely not shipped** (exclude):
- Documentation only (no code)
- CI/CD tooling repos
- Test utilities
- Development helpers
- Archived/stale (no commits in 12+ months)

### Step 6a: Multi-Reviewer Consensus for Low-Confidence Repos

See [consensus review procedure](references/consensus-review.md) for the full multi-reviewer consensus process — when to trigger it, the 3 reviewer prompts (structural, relational, functional), vote aggregation rules, and how to record consensus results in the component map.

### Step 7: Check for Existing Architectures

For each discovered component, check if `GENERATED_ARCHITECTURE.md` exists:

```bash
ls {checkouts_dir}/{repo_name}/GENERATED_ARCHITECTURE.md
```

Set `has_architecture: true/false` accordingly.

### Step 8: Build Output JSON

See [output schema](references/output-schema.md) for the full component-map.json schema including metadata, component fields, dependency_graph, and excluded sections.

### Step 9: Write Output

Write to `architecture/{platform}/component-map.json`.

**Always overwrite** the existing file if one is present — the user is re-running discovery to get updated results. Do NOT skip writing because the file already exists.

### Step 9a: Validate Output

After writing, run the validation script to catch schema errors before reporting success:

```bash
python ${CLAUDE_SKILL_DIR}/scripts/validate_component_map.py architecture/{platform}/component-map.json
```

If validation fails, read the errors, fix the JSON, re-write the file, and re-validate. Do not proceed to Step 10 until validation passes.

### Step 10: Report Summary

See [output schema](references/output-schema.md) for the full report summary template. Output includes platform info, discovery method, component counts, tiered component lists, consensus-reviewed repos, and next steps.

## Heuristics for Component Classification

See [classification heuristics](references/classification-heuristics.md) for full include/exclude criteria, confidence levels, shared library detection methods, and special cases.

## Error Handling

- If no entry point found, use operator detection heuristics
- If checkouts directory doesn't exist, error and exit
- If no components discovered, warn but output empty map
- If breadcrumb parsing fails, continue with next repo

## Notes

- This is heuristic-based, not perfect
- User can manually edit `component-map.json` after generation
- Designed for platforms without central manifest scripts
- Outputs same format as manifest parser for pipeline compatibility

### Critical: Don't Exclude Shared Libraries or API Contracts!

See [common mistakes](references/common-mistakes.md) for the 5 most frequent classification errors and how to avoid them.
