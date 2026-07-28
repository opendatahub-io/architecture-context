# Bug: Partial Run Insight Artifacts Fail Validation

## Observed

In the completed 97-component partial run on 2026-07-27, 96 component run
records were classified with `insight_artifact_validation` errors. The errors
include missing platform/version fields, empty claims/reasoning, unsupported
categories, missing applicability/confidence, and absent provenance references.
Only 1/97 component run records was marked successful.

## Impact

Component architecture files were produced, but run success and benchmark
metrics are contaminated. The error is separate from analyzer extraction
quality and must be fixed before treating run records as clean evaluation
evidence.

## Evidence

- `docs/notes/partial-run-log-demand-report.md`
- ignored `tmp/partial-run-demand-inventory.json`
- representative `logs/generate-architecture/*.run.json` records

## Resolution

Fixed in the analyzer-assisted generation path:

- The component prompt now supplies explicit platform and version values.
- The repo-to-architecture-summary skill now links to an exact insight-artifact
  contract and distinguishes insight categories from analyzer coverage-gap
  categories.
- Missing or malformed insight artifacts are preserved as ignored diagnostic
  files and replaced in the run report with a valid empty artifact. They no
  longer mark an otherwise successful architecture generation as failed.
- Focused tests cover valid, empty, missing, and malformed artifacts.

The validator remains strict for artifacts that claim to contain insights;
the fallback prevents optional insight formatting from contaminating component
architecture success metrics.

## Status

Fixed — moved from `open/` to `fixed/` on 2026-07-28 during bug-ledger
reconciliation.
