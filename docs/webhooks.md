# Webhook Inventory

The webhook inventory phase extracts, enriches, and aggregates admission webhook data across all RHOAI/ODH components.

## What it produces

**Per-component JSON** (`{component}.json`):
- Webhooks discovered from Go kubebuilder markers (fills arch-analyzer gaps)
- Conversion webhooks from CRD patches (`spec.conversion.strategy: Webhook`)
- Each webhook entry enriched with `sources`, `overlays`, `enable_condition`, `purpose`, `data_read`
- `platform_webhooks` — refs to webhooks from the platform operator targeting this component's types
- `external_webhooks` — refs to webhooks from peer components targeting this component's types
- Prefetched-manifest webhooks stripped from operator components (those belong to the owning component)

**Per-component markdown** (`{component}.md`):
- `## Admission Webhooks` section — table of the component's own webhooks with purpose, plus Platform Webhooks and External Webhooks subsections

**Platform-wide** (`webhooks.json`):
- Full webhook list across all components (deduplicated)
- Cross-cutting concern map (webhooks that share handler paths or target the same types across components)
- Summary statistics

## Running

```bash
# Analyze a specific platform version
uv run main.py webhook-inventory --platform=rhoai-3.4

# Force regeneration
uv run main.py webhook-inventory --platform=rhoai-3.4 --force

# Use a different model for agent analysis
uv run main.py webhook-inventory --platform=rhoai-3.4 --model=opus

# Also runs as part of the full pipeline
uv run main.py all --platform=rhoai --branch=rhoai-3.4
```

## Querying with arch-query

```bash
# Compact table: NAME  TYPE  POLICY  TARGETS
arch-query webhooks --version rhoai-3.4

# Single component
arch-query webhooks rhods-operator --version rhoai-3.4

# Wide output: adds PURPOSE column
arch-query webhooks rhods-operator --version rhoai-3.4 --output wide

# Filter by type
arch-query webhooks --type mutating --version rhoai-3.4

# Filter by target resource (kube-style: resource.group, singular OK)
arch-query webhooks --target inferenceservices --version rhoai-3.4
arch-query webhooks --target inferenceservices.serving.kserve.io --version rhoai-3.4
arch-query webhooks --target notebook --version rhoai-3.4

# JSON output (full structured data including platform_webhooks and external_webhooks)
arch-query webhooks kserve --version rhoai-3.4 --output json
```

## Pipeline steps

The webhook inventory runs as Phase 4b (after collect, before platform architecture):

1. **Collect from JSON** — Read existing webhooks from `component-architecture.json` files (prefetched-manifest webhooks filtered out for operator components)
2. **Discover from Go** — Parse `+kubebuilder:webhook:` markers in Go source to find webhooks arch-analyzer missed
3. **Discover conversions** — Find CRD patches with `spec.conversion.strategy: Webhook`
4. **Resolve overlays** — Walk kustomize overlay trees to determine which webhooks are active per overlay
5. **Map Go handlers** — Match webhook paths to handler Go files via kubebuilder markers
6. **Extract Go patterns** — Grep handler files for `client.Get/List`, enable conditions
7. **Agent analysis** — Spawn Claude agents to read each Go handler and extract `purpose` + `data_read`
8. **Build cross-cutting map** — Group webhooks by shared resource types
9. **Build webhook ref maps** — Split into `platform_webhooks` (from operator) and `external_webhooks` (from peers)
10. **Enrich component JSONs** — Write enriched webhooks and refs to each component JSON
11. **Enrich component markdown** — Add Platform Capabilities and Admission Webhooks sections to each component `.md`
12. **Write webhooks.json** — Aggregate platform-wide inventory

## Webhook entry schema

Each webhook entry in the component JSON:

```json
{
  "name": "connection-isvc.opendatahub.io",
  "type": "mutating",
  "path": "/platform-connection-isvc",
  "port": 9443,
  "failure_policy": "fail",
  "rules": [{"apiGroups": ["serving.kserve.io"], "resources": ["inferenceservices"], "operations": ["CREATE", "UPDATE"]}],
  "sources": [
    {"type": "kubebuilder_marker", "file": "internal/webhook/serving/mutating_isvc.go", "repo": "rhods-operator", "line": 40},
    {"type": "go_handler", "file": "internal/webhook/serving/mutating_isvc.go", "repo": "rhods-operator", "line": 54}
  ],
  "overlays": ["default"],
  "enable_condition": "Kserve component enabled",
  "purpose": "Mutates InferenceService resources to inject connection credentials from secrets...",
  "data_read": [{"kind": "Secret", "group": ""}]
}
```

Source types: `webhook_manifest`, `go_handler`, `kubebuilder_marker`, `crd_conversion_patch`.

## Platform and external webhooks

Each component JSON includes two reference arrays for webhooks from other components:

**`platform_webhooks`** — from the platform operator (rhods-operator/opendatahub-operator). These inject platform-level concerns that individual components don't know about:
```json
"platform_webhooks": [
  {"component": "rhods-operator", "webhook": "hardwareprofile-isvc-injector.opendatahub.io"},
  {"component": "rhods-operator", "webhook": "connection-isvc.opendatahub.io"}
]
```

**`external_webhooks`** — from peer components that share types or have cross-component integration:
```json
"external_webhooks": [
  {"component": "odh-model-controller", "webhook": "minferenceservice-v1beta1.odh-model-controller.opendatahub.io"}
]
```

## Operator prefetched-manifest filtering

The `rhods-operator` repo contains prefetched webhook manifests from other components (kserve, spark, training-operator, etc.) in `prefetched-manifests/`. These are deployment artifacts, not ownership signals. The webhook inventory attributes these webhooks to the component that owns the Go handler code, not the operator that deploys them.
