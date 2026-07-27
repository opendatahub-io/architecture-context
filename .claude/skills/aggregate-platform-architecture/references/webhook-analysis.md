# Platform Webhook Synthesis

Use this reference when producing the "Platform Admission Webhooks" section of
PLATFORM.md.  All inputs are structured data — do not read component source
code, spawn sub-agents, or re-enumerate webhook handlers.

## Inputs

| Source | How to load | What it provides |
|--------|-------------|------------------|
| Component JSONs | Already loaded in Step 1 (`arch-query platform-summary`) | Per-component `webhooks` arrays (arch-analyzer inventory) |
| `arch-query webhooks` | `arch-query webhooks --version {v} --output json` | Aggregated webhook list across all components |
| Component map | `component-map.json` in the platform directory | Component names and ownership metadata |

Do not use prior `architecture/**/*.md` files as synthesis inputs.  Do not
inspect component source repositories.

## Explicit unknowns

The following fields were previously populated by a dedicated webhook inventory
phase and may be absent from component JSONs:

| Field | What it provided | Status |
|-------|------------------|--------|
| `overlays` | Kustomize overlay membership per webhook | Absent unless resolved externally |
| `enable_condition` | Go-level enable/disable conditions | Absent unless resolved externally |
| `data_read` | Kubernetes resources read by handler code | Absent unless resolved externally |
| `cross_cutting_concerns` | Shared-path groupings across components | Absent; derive from webhook rules at synthesis time |
| `platform_webhooks` | Cross-component refs from operator webhooks | Absent; derive from CRD ownership vs webhook rules |
| `external_webhooks` | Cross-component refs from peer webhooks | Absent; derive from CRD ownership vs webhook rules |

When a field is absent, state the gap explicitly in the synthesis output rather
than fabricating values.

## What to synthesize

### Ownership

Classify every webhook by its owning component and role:

- **Platform webhooks** — defined by the platform operator
  (`rhods-operator` / `opendatahub-operator`).  These inject platform-level
  concerns (hardware profiles, connection credentials, resource limits) into
  resources owned by other components.
- **Component webhooks** — defined and owned by the component that serves
  the webhook handler.  These validate or default the component's own CRDs.
- **External / peer webhooks** — a component's webhook that intercepts
  resource types owned by a different non-operator component.

Populate the ownership table from the `component` field on each webhook
entry.  When `platform_webhooks` / `external_webhooks` arrays are present on
component JSONs, use those directly.  Otherwise, derive cross-component
targeting by cross-referencing each component's CRDs against webhook `rules`.

### Cross-component targets

Identify webhooks whose `rules` target resource types owned by a different
component.  These create runtime coupling: a request for component A's CRD
is intercepted by component B's webhook.

For each cross-component target, record: the source component and webhook
name, the target component, the intercepted resource types, the webhook type
(mutating/validating), and the failure policy.

Derive these by matching each webhook's `rules` (apiGroups + resources) against
the CRDs declared by other components.

### Shared / cross-cutting concerns

When the `cross_cutting_concerns` field is populated in component JSONs, use
it.  Otherwise, identify concerns by grouping webhooks that share handler paths
or target the same resource types across components.  Synthesize into a table:

- The concern name and the components involved.
- The affected resource types.
- Whether the concern is a coordination risk (multiple webhooks modifying
  the same type) or an expected design pattern (e.g., operator-level
  defaulting layered on component-level validation).

### Overlay and deployment limitations

If `overlays` data is present on webhook entries, determine which webhooks
are active under which kustomize overlays.  If absent, state explicitly:
"Overlay membership data is not available for this generation."

### Security implications

Summarize the platform-wide admission posture:

- Total mutating vs. validating webhooks and their failure policies.
- Webhooks with `Ignore` failure policy (requests proceed if the webhook is
  unavailable).
- Webhooks that read secrets, configmaps, or cluster-scoped resources
  (from `data_read` fields when available).
- Any gaps: resources with no admission webhook coverage, or webhook
  registrations with unknown handler behavior.

### Provenance

Record the data lineage:

- Webhook sources: each entry's `sources` array identifies the evidence
  type (`webhook_manifest`, `kubebuilder_marker`, `go_handler`,
  `crd_conversion_patch`) and the originating file.
- The deterministic inventory is produced by `arch-analyzer`; semantic
  enrichment (purpose, data_read) comes from per-component synthesis when
  available.  Platform-level synthesis (this step) aggregates those outputs.
- Overlay membership, enable conditions, and cross-component reference
  arrays are available only when an external enrichment step has run.
