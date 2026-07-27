# Platform Webhook Synthesis

Use this reference when producing the "Platform Admission Webhooks" section of
PLATFORM.md.  All inputs are structured data — do not read component source
code, spawn sub-agents, or re-enumerate webhook handlers.

## Inputs

| Source | How to load | What it provides |
|--------|-------------|------------------|
| `webhooks.json` | `arch-query webhooks --version {v} --output json`, or read `{platform_dir}/webhooks.json` directly | Full webhook list, cross-cutting concerns, summary stats |
| Component JSONs | Already loaded in Step 1 (`arch-query platform-summary`) | Per-component `webhooks`, `platform_webhooks`, `external_webhooks` arrays |
| Component map | `component-map.json` in the platform directory | Component names and ownership metadata |

Do not use prior `architecture/**/*.md` files as synthesis inputs.  Do not
inspect component source repositories.  The webhook inventory phase and
per-component synthesis have already extracted all handler semantics; this step
synthesizes their structured outputs at the platform level.

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
entry plus the `platform_webhooks` and `external_webhooks` arrays on
component JSONs.

### Cross-component targets

Identify webhooks whose `rules` target resource types owned by a different
component.  These create runtime coupling: a request for component A's CRD
is intercepted by component B's webhook.

For each cross-component target, record: the source component and webhook
name, the target component, the intercepted resource types, the webhook type
(mutating/validating), and the failure policy.

Use the `platform_webhooks` and `external_webhooks` arrays from component
JSONs, plus the `rules` and `failure_policy` fields on each webhook entry.

### Shared / cross-cutting concerns

The `cross_cutting_concerns` array in `webhooks.json` groups webhooks that
share handler paths or target the same resource types across components.
Synthesize these into a table identifying:

- The concern name and the components involved.
- The affected resource types.
- Whether the concern is a coordination risk (multiple webhooks modifying
  the same type) or an expected design pattern (e.g., operator-level
  defaulting layered on component-level validation).

### Overlay and deployment limitations

From the `overlays` field on each webhook entry, determine which webhooks
are active under which kustomize overlays.  Note:

- Webhooks absent from a given overlay are not deployed in that
  configuration.
- Overlay-specific behavior (e.g., a webhook enabled only in the `rhoai`
  overlay but not `odh`) is a deployment variant, not a code difference.
- Prefetched-manifest webhooks are deployment artifacts attributed to the
  owning component, not the operator that deploys them.

### Security implications

Summarize the platform-wide admission posture:

- Total mutating vs. validating webhooks and their failure policies.
- Webhooks with `Ignore` failure policy (requests proceed if the webhook is
  unavailable).
- Webhooks that read secrets, configmaps, or cluster-scoped resources
  (from `data_read` fields).
- Any gaps: resources with no admission webhook coverage, or webhook
  registrations with unknown handler behavior.

### Provenance

Record the data lineage:

- `webhooks.json` metadata: `generated_at`, `platform_version`,
  `overlays_analyzed`.
- Webhook sources: each entry's `sources` array identifies the evidence
  type (`webhook_manifest`, `kubebuilder_marker`, `go_handler`,
  `crd_conversion_patch`) and the originating file.
- The deterministic inventory is produced by `arch-analyzer`; semantic
  enrichment (purpose, data_read) is produced by per-component synthesis.
  Platform-level synthesis (this step) aggregates those outputs.
