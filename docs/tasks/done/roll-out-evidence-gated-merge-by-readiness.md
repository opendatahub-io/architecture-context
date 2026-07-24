# Task: Roll Out Evidence-Gated Merge By Analyzer Readiness

## Goal

Validate the Markdown change-record contract in live bounded agent runs, then select
production component-generation behavior by analyzer readiness so quality enforcement
also reduces source discovery and wall time.

## Context

The [evidence-gated merge pilot](../../notes/evidence-gated-merge-pilot-2026-07-18.md)
proved deterministic replay on `MLServer` and `notebooks`: 100% analyzer preservation,
zero analyzer conflicts, unchanged raw-candidate fixture recall, and approximately
0.1-second merge time. The replay used source-reviewed change records because the raw
agents predated the new skill contract.

## Acceptance Criteria

- [x] Run the updated skill and `--evidence-gated-merge` live on at least one
      `sufficient`, one `partial`, and one `insufficient` repository.
- [x] Verify live agents create parseable Markdown change records for every intended
      structured addition, correction, or deletion.
- [x] Require 100% analyzer identity preservation and zero unexplained populated-cell
      conflicts for `sufficient` and `partial` outputs.
- [x] Compare raw and merged fixture recall and source-review any regression.
- [x] Record tool calls, file reads, output tokens, cost, agent time, and merge time.
- [x] Make `sufficient` agents synthesis-first and prohibit broad discovery in code,
      not only through prompt instructions.
- [x] Give `partial` agents an explicit category and file budget derived from analyzer
      coverage.
- [x] Retain the legacy full-document fallback for `insufficient` repositories.
- [x] Aggregate per-component merge adjudications into the corpus preservation report.
- [x] Enable production routing only after the small live matrix passes its quality
      and runtime gates.

## Status

Completed on 2026-07-18.

## Results

The live matrix used `odh-dashboard` (sufficient), `caikit-tgis-backend` (partial),
and `must-gather` (insufficient). The final corpus gate preserved 323/323 analyzer
structured identities, reported zero analyzer-to-final conflicts, and validated all
three documents. The sufficient preseed optimization reduced dashboard agent time
from 339.79 seconds to 146.24 seconds and output tokens from 19,804 to 5,965.

Production generation now defaults to readiness routing and evidence-gated merge.
`--no-evidence-gated-merge` retains an explicit operator escape hatch, while analyzer
`insufficient` still selects legacy discovery automatically.

Full measurements, fixture comparisons, source review, defects found, and artifact
locations are recorded in the
[readiness-routed evidence merge pilot](../../notes/readiness-routed-evidence-merge-pilot-2026-07-18.md).

Validation completed with 83 Python tests, both Go project test suites, Ruff,
golangci-lint, `go vet`, 20 overlay checks, 15 platform checks, and 769 component
architecture document checks.

## Dependencies

- [Evidence-gated analyzer document merge](../done/evidence-gated-analyzer-document-merge.md)
