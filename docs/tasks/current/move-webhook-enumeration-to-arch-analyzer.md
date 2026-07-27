# Task: Move Webhook Enumeration into arch-analyzer

## Goal

Make `arch-analyzer` the single deterministic producer of webhook inventory
data, so downstream webhook processing consumes analyzer output instead of
re-enumerating repository source independently.

## Scope

- Extend `src/arch-analyzer` extraction to enumerate webhook identities,
  types, paths, rules, API groups/resources, conversion webhooks, source
  locations, and explicit coverage limitations from supported manifests and
  Go markers.
- Preserve source evidence and stable JSON schema/provenance for each emitted
  webhook; represent unresolved/dynamic cases as partial or not-extracted.
- Update `lib/phases/webhooks.py` and `lib/webhook_analyzer.py` to consume the
  analyzer webhook inventory and stop duplicating deterministic Go-marker and
  conversion enumeration.
- Retain webhook-phase responsibilities for overlay resolution, handler
  semantic analysis, cross-component reference maps, agent-derived purpose or
  data dependencies, and Markdown/JSON enrichment.
- Preserve null-safe handling, clean-run isolation, prior-architecture
  exclusion, legacy fallback, and compatibility with existing webhook JSON.
- Add focused analyzer fixtures, schema/contract tests, and an end-to-end
  migration comparison showing no avoidable inventory loss.

## Exclusions

- Do not move agent semantic analysis into the deterministic analyzer.
- Do not use prior generated `architecture/` documents as analyzer or synthesis
  inputs.
- Do not commit generated architecture output, raw telemetry, API/OTel dumps,
  secrets, or unrelated worktree changes.
- Do not require external MLflow, OTel, or human labels.

## Acceptance criteria

- A fresh analyzer run produces the canonical webhook inventory consumed by
  the webhook phase without duplicate source enumeration.
- Manifest, Go-marker, and conversion webhook coverage is preserved or every
  difference is explicitly classified with evidence.
- Webhook provenance includes source paths and line ranges where available.
- Cross-cutting maps, platform/external reference maps, and enrichment still
  work from analyzer output and remain null-safe.
- Focused analyzer/webhook tests, schema validation, and relevant Go/Python
  checks pass; implementation agent does not commit.
