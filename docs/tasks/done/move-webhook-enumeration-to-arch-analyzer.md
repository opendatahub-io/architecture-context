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

## Execution record — 2026-07-27

- `arch-analyzer` now discovers literal `+kubebuilder:webhook:` markers and
  CRD `spec.conversion.strategy: Webhook` declarations, including rules,
  paths, operations, and source file/line evidence. It records an explicit
  partial coverage note for unresolved dynamic registration.
- Existing manifest webhook extraction remains the first inventory source;
  source discoveries are merged by name/path while preserving provenance.
- `lib/phases/webhooks.py` now consumes analyzer JSON and no longer invokes
  duplicate Go-marker or conversion scans. The old duplicate helpers were
  removed from `lib/webhook_analyzer.py`.
- Added Go extractor coverage for marker/conversion enumeration and Python
  coverage for analyzer-inventory consumption, cross-cutting maps, and null
  webhook fields.
- Validation passed: `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...`, Python
  compilation, and focused Python regression checks. No generated architecture
  output, raw telemetry, API/OTel dump, secret, or unrelated file was staged.

## Driver review

Accepted pending checkpoint commit. The analyzer is now the deterministic
webhook inventory producer; the phase retains overlays, handler semantics,
cross-component maps, agent enrichment, and output writing.
