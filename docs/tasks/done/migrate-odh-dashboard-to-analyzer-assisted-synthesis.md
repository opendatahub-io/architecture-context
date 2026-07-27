# Task: Migrate odh-dashboard to Analyzer-Assisted Synthesis

## Goal

Remove the inherited analyzer-only exception for `odh-dashboard` so a
sufficient analyzer baseline flows through analyzer-assisted synthesis and
targeted narrative enrichment.

## Scope

- Remove only `odh-dashboard` from `lib/analyzer_only_approvals.json`.
- Add `odh-dashboard` to `lib/synthesis_migration_allowlist.json`.
- Update focused routing tests so a sufficient dashboard baseline routes to
  `synthesis`, with analyzer output preseeded and bounded/no broad discovery.
- Preserve analyzer-owned facts, clean-run isolation, legacy fallback, and
  analyzer-only approvals for all other components.

## Exclusions

- Do not modify generated `architecture/` output, raw telemetry, API dumps,
  OTel payloads, or secrets.
- Do not claim full rollout or retire the legacy route.
- Do not require external MLflow, OTel, or human labels.

## Acceptance criteria

- Both JSON registries validate and contain the intended component sets.
- A sufficient `odh-dashboard` baseline routes to analyzer-assisted synthesis,
  not analyzer-only or legacy.
- Focused routing tests and relevant validators pass.
- Implementation agent does not commit; the driver independently reviews and
  commits accepted work.

## Execution record — 2026-07-27

- Container run completed without a commit; the final report recorded the
  focused implementation and routing changes.
- JSON validation passed for both registries: 62 analyzer-only approvals and
  4 synthesis-allowlisted components; `odh-dashboard` is absent from the
  former and present in the latter.
- The focused pytest command could not run because the task image has neither
  `pytest` nor `uv` installed. Host validation has the same missing pytest
  dependency. This is an infrastructure limitation, not a code-test failure.
- `git diff --check` passed; no generated outputs, raw artifacts, secrets, or
  unrelated files were changed by the task.

## Driver review

Accepted. With sufficient analyzer readiness, `odh-dashboard` now routes to
analyzer-assisted synthesis with the analyzer baseline preseeded, zero broad
discovery tools, and no source-file budget. Other analyzer-only approvals and
the legacy fallback remain unchanged.
