# Webhook Inventory

Webhook data is produced by `arch-analyzer` (deterministic static analysis per
component) and synthesized by `repo-to-architecture-summary` (per-component) and
`aggregate-platform-architecture` (platform-wide).

The dedicated Python webhook inventory phase (`main.py webhook-inventory`) was
removed on 2026-07-27 — see [ADR-0013](../decisions/ADR-0013-webhook-inventory-phase.md)
for the supersession rationale.

## What is available

**Per-component JSON** (`{component}.json`):
- `webhooks` array — discovered by `arch-analyzer` from kubebuilder markers, CRD
  conversion patches, and webhook manifests
- Each entry contains: name, type, path, port, failure_policy, side_effects,
  service_ref, rules, sources

**Querying with arch-query**:

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

# JSON output (full structured data)
arch-query webhooks kserve --version rhoai-3.4 --output json
```

## Explicit unknowns

The following enrichment data was previously populated by the removed webhook
inventory phase and is no longer automatically generated:

| Field | What it provided | Current status |
|-------|------------------|----------------|
| `overlays` | Kustomize overlay membership per webhook | Not populated |
| `enable_condition` | Go-level enable/disable conditions | Not populated |
| `data_read` | Kubernetes resources read by handler code | Not populated |
| `cross_cutting_concerns` | Shared-path groupings across components | Not populated |
| `platform_webhooks` | Cross-component refs from operator webhooks | Not populated |
| `external_webhooks` | Cross-component refs from peer webhooks | Not populated |
| `webhooks.json` | Platform-wide aggregated webhook inventory | Not generated |

These enrichments can be reintroduced as `arch-analyzer` capabilities if needed.

Semantic analysis (webhook purpose, handler behavior) is produced by:
- **Per-component**: `repo-to-architecture-summary` using `references/webhook-analysis.md`
- **Platform-wide**: `aggregate-platform-architecture` using `references/webhook-analysis.md`

## Webhook entry schema

Each webhook entry in the component JSON (as produced by arch-analyzer):

```json
{
  "name": "connection-isvc.opendatahub.io",
  "type": "mutating",
  "path": "/platform-connection-isvc",
  "port": 9443,
  "failure_policy": "fail",
  "rules": [{"apiGroups": ["serving.kserve.io"], "resources": ["inferenceservices"], "operations": ["CREATE", "UPDATE"]}],
  "sources": [
    {"type": "kubebuilder_marker", "file": "internal/webhook/serving/mutating_isvc.go", "repo": "rhods-operator", "line": 40}
  ]
}
```

Source types: `webhook_manifest`, `kubebuilder_marker`, `crd_conversion_patch`.
