# Kustomize Manifest Analysis

Analyze the kustomize manifest structure that defines how a component is deployed. Almost all ODH/RHOAI component repos ship deployment manifests that the platform operator (`rhods-operator` or `opendatahub-operator`) consumes via `get_all_manifests.sh` at pinned commits.

## When to use

The repo has a `manifests/` or `config/` directory containing `kustomization.yaml` files. Use this reference doc as a supplement alongside the primary language-specific doc (controller-analysis, python-service-analysis, etc.).

## Sub-agent threshold

Manifest directories are small (typically 20-50 YAML files). Read them directly — no sub-agents needed. Focus on `kustomization.yaml` files first (they define the composition), then read the resources they reference.

## Step 1: Find the manifest directory

Repos use one of two conventions:

```bash
# Pattern A: manifests/ directory (odh-dashboard, training-operator, model-registry, notebooks)
find manifests/ -name "kustomization.yaml" -o -name "kustomization.yml" 2>/dev/null | sort

# Pattern B: config/ directory (kserve, data-science-pipelines-operator, spark-operator)
find config/ -name "kustomization.yaml" -o -name "kustomization.yml" 2>/dev/null | sort
```

Also check for component metadata:
```bash
find . -maxdepth 3 -name "component_metadata.yaml" 2>/dev/null
```

## Step 2: Read kustomization.yaml files

Start with the root or base kustomization, then follow references outward. For each `kustomization.yaml`, extract:

| Field | What to look for |
|-------|-----------------|
| **resources:** | List of YAML files and subdirectories composed into this layer |
| **bases:** | Referenced base kustomizations (older syntax, equivalent to resources pointing to dirs) |
| **components:** | Optional kustomize components that add feature-specific resources |
| **configMapGenerator:** | ConfigMaps generated from `params.env` or literal values — these are the parameterization mechanism |
| **vars:** / **replacements:** | Dynamic field substitution — how image refs and config values get injected into resource fields |
| **namePrefix:** / **nameSuffix:** | Resource name transformations — affects service discovery and RBAC |
| **namespace:** | Default namespace for all resources in this layer |
| **patches:** / **patchesStrategicMerge:** | Modifications applied to base resources (env-specific overrides) |
| **generatorOptions:** | `disableNameSuffixHash: true` means stable ConfigMap names |

## Step 3: Analyze base resources

Read the YAML files referenced by the base kustomization. Categorize each:

| Resource type | Template section it informs |
|---------------|----------------------------|
| Deployment, StatefulSet, DaemonSet | Architecture Components, Deployment Manifests |
| Service | Network Architecture → Services |
| ServiceAccount | Security |
| ClusterRole, Role, ClusterRoleBinding, RoleBinding | Security → RBAC |
| NetworkPolicy | Network Architecture → Network Policies |
| HTTPRoute, Route, Ingress | Network Architecture → Ingress |
| CRD definitions | APIs Exposed → CRDs |
| ConfigMap, Secret | Dependencies or Security → Secrets |
| PeerAuthentication, AuthorizationPolicy | Security (Istio/service mesh) |

## Step 4: Analyze parameterization

Read `params.env` files and trace how values flow:

```bash
# Find params.env files
find manifests/ config/ -name "params.env" 2>/dev/null

# Find configMapGenerator usage
grep -r "configMapGenerator" manifests/ config/ 2>/dev/null
```

The parameterization chain:
1. `params.env` defines key=value pairs (typically container image references)
2. `configMapGenerator` creates a ConfigMap from params.env
3. `vars:` or `replacements:` inject those values into Deployment container image fields

Document each parameter in the Parameterization table:
- What the parameter controls (image, replica count, config)
- Where the default value comes from (params.env)
- What resource fields it targets (Deployment.spec.template.spec.containers[].image)

## Step 5: Analyze distribution variants

Look for platform-specific overlays:

```bash
# Common patterns
ls -d manifests/odh/ manifests/rhoai/ 2>/dev/null
ls -d manifests/rhoai/addon/ manifests/rhoai/onprem/ manifests/rhoai/shared/ 2>/dev/null
ls -d config/overlays/ 2>/dev/null
```

For each variant, compare against the base:
- What resources are added (RHOAI-only monitoring, addon-specific config)?
- What patches are applied (different image sources, namespace changes)?
- What resources are removed or replaced?

Document differences in the Distribution Variants table.

## Key kustomize patterns to recognize

| Pattern | What it means | Example |
|---------|---------------|---------|
| `configMapGenerator` + `params.env` | Image versions injected at deploy time by the operator | `odh-dashboard-image=quay.io/...` |
| `vars:` / `replacements:` | Dynamic field substitution targeting specific resource fields | Image ref → Deployment container |
| `namePrefix:` | All resources get a common prefix | `data-science-pipelines-operator-` |
| `namespace:` in kustomization | Default namespace for all resources | `opendatahub` |
| `disableNameSuffixHash: true` | Stable ConfigMap names (no random hash) | Referenced by name in code |
| `components:` | Optional feature sets composed in | CRD variants (minimal vs full) |
| Separate `odh/` vs `rhoai/` dirs | Distribution-specific deployment | Different monitoring stacks |
| `patchesStrategicMerge:` | Overlay-specific resource modifications | Add sidecar containers in RHOAI |
| `commonLabels:` / `commonAnnotations:` | Labels applied to all resources | Platform ownership labels |

## Aggregation into template

Findings map to these architecture template sections:

- **Deployment Manifests → Kustomize Structure**: Base/overlay directory tree and what each layer provides
- **Deployment Manifests → Parameterization**: Every configMapGenerator param, its source, default, and purpose
- **Deployment Manifests → Distribution Variants**: ODH vs RHOAI differences, addon vs onprem variants
- **Network Architecture**: Services, Ingress (HTTPRoute/Route), NetworkPolicies from manifest YAML
- **Security → RBAC**: ClusterRoles, Roles, Bindings from manifest YAML
- **Security → Secrets**: Secret definitions and their provisioning source (annotation-based, manual, cert-manager)
- **APIs Exposed → CRDs**: CRD definitions from `config/crd/` or `manifests/common/crd/`
- **Architectural Analysis**: Observations about deployment complexity, parameterization patterns, ODH/RHOAI divergence, or unusual kustomize usage
