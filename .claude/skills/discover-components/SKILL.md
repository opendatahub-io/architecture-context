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
  - `must-gather`, `additional-images`
  - Build/release infrastructure repos (`RHOAI-Build-Config`, `konflux-central`)

**Do NOT exclude** `odh-cli` -- it is a shipped component starting with RHOAI 3.3+.

Create an initial list of candidate repos.

### Step 2a: Classify Components by Tier (DSC-based)

ODH and RHOAI use a **DataScienceCluster (DSC) CR** to manage platform components. The operator's DSC spec defines which components are user-togglable (can be set to `Managed` or `Removed`). This is the authoritative source for tier classification.

**Step 1: Parse the DSC spec to find managed components.**

Look in the operator repo for the DataScienceCluster types:
```bash
grep "json:" {operator_repo}/api/datasciencecluster/v2/datasciencecluster_types.go | grep -v "//"
```

This lists all component fields in the `Components` struct. Each field corresponds to a sub-operator or controller that the user can toggle. These are the `optional_platform` components.

**Step 2: Map DSC field names to repos.** The DSC field names (e.g., `dashboard`, `kserve`, `ray`) map to component controller directories:
```bash
ls {operator_repo}/internal/controller/components/
```

Each directory name maps to a DSC field. Cross-reference with the RELATED_IMAGE mappings (Step 5.1a) and operator bundle to determine which repo each controller deploys.

**Step 3: Apply tier classification.**

| Tier | Criteria | Examples |
|------|----------|---------|
| `core_platform` | The meta-operator itself AND components that are always deployed (not togglable via DSC) | `rhods-operator`, `opendatahub-operator`, `odh-dashboard`, `notebooks`, `odh-model-controller` |
| `optional_platform` | Components with a DSC field -- user can set `managementState: Managed/Removed` | `kserve`, `data-science-pipelines-operator`, `codeflare-operator`, `kuberay`, `kueue`, `trustyai-service-operator`, `model-registry-operator`, `modelmesh-serving`, `trainer`, `training-operator`, `spark-operator`, `feast`, `llama-stack-k8s-operator`, `mlflow-operator`, `models-as-a-service`, `workload-variant-autoscaler` |
| `payload_component` | Shipped containers/libraries deployed BY core or optional components -- not independently togglable | `vllm`, `data-science-pipelines`, `model-registry`, `codeflare-sdk`, `modelmesh`, `rest-proxy` |

**Key distinction:** `optional_platform` components are the ones a cluster admin toggles on/off. `payload_component` repos provide the container images or libraries that optional_platform operators deploy -- they don't have their own DSC toggle.

**Dashboard, notebooks, and odh-model-controller** are `core_platform` even though they appear as DSC fields -- they are always-on components required for the platform to function. The DSC fields for these exist for configuration, not for enable/disable.

Set `discovery_method: "breadcrumb"` in metadata.

**Record the tier for each repo.** This tiering drives the rest of the discovery process:
- `core_platform` + `optional_platform` → full breadcrumb exploration in Steps 3-5
- `payload_component` → include as component, lighter exploration
- `ecosystem` → skip breadcrumb exploration, go directly to excluded (can be pulled back in by dependency analysis in Step 5a/5b)

### Step 3: Find Entry Points

Limit candidate repos to those in the `core_platform`, `optional_platform`, and `payload_component` tiers. Do NOT treat every operator-shaped repo as an entry point.

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

After tier classification (Step 2a) and entry point exploration (Steps 3-4), discover additional components via operand mappings and dependency analysis.

**5.1a: Discover operands via RELATED_IMAGE mappings.** The operator deploys sub-components via `RELATED_IMAGE_*` environment variable mappings defined in `*_support.go` files.

Run the helper script to parse these mappings and match them to repos:

```bash
python ${CLAUDE_SKILL_DIR}/scripts/parse_related_images.py {operator_repo} {checkouts_dir1} {checkouts_dir2} ...
```

The script scans `internal/controller/components/*/*_support.go` for `imageParamMap` entries, normalizes the image keys, and matches them against repos in the checkouts directories. Output is JSON with `repos` (matched) and `unmatched` sections.

For each matched repo in the output, if not already in the component list, add as `discovered_via: "operator_operand"`, `referenced_by: ["{operator-name}"]`. Use the tier already assigned in Step 2a if the repo was classified there; otherwise default to `tier: "payload_component"`.

**Binding rule:** Any repo matched by `parse_related_images.py` MUST be included as a component. Do NOT override these matches by reclassifying the repo as excluded. The script identifies operands that the operator ships -- if the operator references a container image built from a repo, that repo is a shipped component regardless of whether it looks like "infrastructure" or a "utility." The only exception is build infrastructure repos like `RHOAI-Build-Config` itself.

**5.1b: Discover operands via OLM catalog relatedImages (RHOAI).** RHOAI has a build config repo (`RHOAI-Build-Config`) containing OLM catalog YAML with `relatedImages` sections -- the authoritative list of every container image shipped in each version.

Run the helper script to parse the catalog and match images to repos:

```bash
python ${CLAUDE_SKILL_DIR}/scripts/parse_catalog_images.py --find-catalog {checkouts_dir1} {checkouts_dir2} ...
```

Or to target a specific version:

```bash
python ${CLAUDE_SKILL_DIR}/scripts/parse_catalog_images.py --find-catalog --version rhoai-3.4 {checkouts_dir1} {checkouts_dir2} ...
```

The script auto-finds the best `RHOAI-Build-Config/catalog/` directory, extracts unique images from `relatedImages` sections, and matches them to repos using multi-step normalization (strip `odh-` prefix, `-rhel[0-9]` suffix, hardware variant suffixes) plus known name mappings (e.g., `ml-pipelines-*` → `data-science-pipelines`, `dashboard` → `odh-dashboard`).

The catalog directories are versioned by RHOAI release, not by checkout branch -- `RHOAI-Build-Config` is typically checked out at `head` but contains catalogs for all historical versions. If no catalog directory exactly matches the target platform version, the script uses the **latest available version** as the best approximation.

Output is JSON with:
- `repos`: matched repos with image names and match method
- `unmatched`: images with no repo match (third-party base images, internal tools)
- `variant_groups`: images that are build variants of the same component

For each matched repo, if not already in the component list, add as `discovered_via: "container_image"`, `referenced_by: ["rhods-operator"]`. Use the tier already assigned in Step 2a if the repo was classified there; otherwise default to `tier: "payload_component"`. Do NOT add `RHOAI-Build-Config` itself as a component -- it is build infrastructure, not a shipped component. Unmatched images that are clearly third-party (`ubi-*`, `ose-*`, `postgresql-*`, `etcd`) should be ignored. Other unmatched images may represent components without source repos in the checkouts -- note them but don't block on them.

**Binding rule:** Any repo matched by `parse_catalog_images.py` MUST be included as a component. Do NOT override these matches by reclassifying the repo as excluded. The OLM catalog's `relatedImages` is the authoritative list of container images shipped in the product -- if a repo's image is in the catalog, the repo is a shipped component regardless of whether it looks like "infrastructure," a "utility," or "covered by" another component. The only exception is build infrastructure repos like `RHOAI-Build-Config` itself.

**5.1c: Discover components shipped as Python dependencies in container images.** Some components ship as pip packages baked into container images (e.g. notebook workbenches) rather than as standalone Kubernetes workloads. These have no DSC field, no RELATED_IMAGE mapping, and no OLM catalog entry -- but they are shipped components.

For each `core_platform` or `optional_platform` component that builds container images with Python dependencies (primarily `notebooks`), run the helper script:

```bash
python ${CLAUDE_SKILL_DIR}/scripts/parse_image_dependencies.py {image_repo_checkout} {checkouts_dir1} {checkouts_dir2} ...
```

The script scans `pyproject.toml` and `requirements*.txt` files in the image repo, extracts Python package names, and matches them against repos in the checkouts directories. Output is JSON with `repos` (matched) and `unmatched` sections.

For each matched repo in the output, if not already in the component list, add as `discovered_via: "image_dependency"`, `referenced_by: ["{image-repo-name}"]`. Use the tier already assigned in Step 2a if the repo was classified there; otherwise default to `tier: "payload_component"`.

**Binding rule:** Any repo matched by `parse_image_dependencies.py` MUST be included as a component. A repo whose package is pip-installed into a shipped container image is a shipped component -- it runs inside the product regardless of whether it has its own Kubernetes workload.

**5.2: Scan `go.mod` for shared libraries.** Scan `go.mod` (or equivalent) of each discovered `core_platform` and `optional_platform` component. Look for first-party dependencies (same GitHub org) that match repos in the checkouts directory. This is how shared libraries like `library-go`, `api`, `client-go` get discovered.

As you discover references:
1. Check if referenced repo exists in checkouts directory
2. If yes, add to component list with `discovered_via` and `referenced_by`
3. Track what type of reference (deployed_component vs. dependency vs. operand)
4. Mark as `shipped: true` if deployed directly
5. **Always populate the `dependency_graph`** -- even in signal mode, record which components depend on which

Track the dependency graph:
```
{
  "kserve": ["kubeflow", "gateway-api-inference-extension"],
  "data-science-pipelines-operator": ["data-science-pipelines", "ml-metadata", "argo-workflows"],
  "training-operator": ["kubeflow"],
  ...
}
```

### Steps 5a-5c: Classification

See [classification heuristics](references/classification-heuristics.md) for:
- **Step 5a**: Identify shared libraries (reverse dependency graph, detection criteria)
- **Step 5b**: Identify architecturally significant external APIs (tool vs. contract distinction)
- **Step 5c**: Classify component type (operator, controller, service, ui, installer, asset, shared_library, api_specification)

### Step 6: Classify Remaining Repos

Repos not discovered via DSC spec, RELATED_IMAGE mappings, OLM catalog, or dependency analysis are `ecosystem` tier and should be excluded unless they were pulled in as a shared library (Step 5a) or API specification (Step 5b).

**Definitely not shipped** (exclude):
- Documentation only (no code)
- CI/CD tooling repos (`konflux-central`, `RHOAI-Build-Config`)
- Test utilities
- Development helpers
- Archived/stale (no commits in 12+ months)
- Diagnostic/support tools (`must-gather`, `rhoai-additional-images`)

### Step 6a: Multi-Reviewer Consensus for Low-Confidence Repos

See [consensus review procedure](references/consensus-review.md) for the full multi-reviewer consensus process -- when to trigger it, the 3 reviewer prompts (structural, relational, functional), vote aggregation rules, and how to record consensus results in the component map.

### Step 7: Check for Existing Architectures

For each discovered component, check if `GENERATED_ARCHITECTURE.md` exists:

```bash
ls {checkouts_dir}/{repo_name}/GENERATED_ARCHITECTURE.md
```

Set `has_architecture: true/false` accordingly.

### Step 8: Build Output JSON

See [output schema](references/output-schema.md) for the full component-map.json schema including metadata, component fields, dependency_graph, and excluded sections.

**Important structural requirements:**
- `components` must be a **dict** keyed by component key, not a list
- `excluded` must be a **dict** keyed by repo name, not a list
- Each component's `key` field must match its dict key

### Step 9: Write Output

Write to `architecture/{platform}/component-map.json`.

**Always overwrite** the existing file if one is present -- the user is re-running discovery to get updated results. Do NOT skip writing because the file already exists.

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
