# Task: Build RHOAI Next Corpus Measurement Harness

## Goal

Run the complete analyzer-first component workflow for `rhoai.next` and compare its
outputs with `architecture/rhoai.next.bak` using reproducible corpus-level quality,
preservation, failure, and timing measurements.

## Context

The dashboard milestone established replacement-level fidelity for one large
`sufficient` repository, and `caikit-nlp` exercised the bounded `partial` path. A
full component run is now needed to measure production wall time and identify
repository-specific regressions. `PLATFORM.md` synthesis and diagrams remain out of
scope.

The backup directory is a regression fixture, not unquestioned ground truth. Source
revision drift and source-reviewed fixture defects must remain distinguishable from
analyzer or agent regressions.

## Acceptance Criteria

- [x] Add a shell entry point that runs forced static analysis, component generation
      with ten workers, and collection for `rhoai.next` without running platform
      synthesis or diagrams.
- [x] Write collected results to a fresh output tree and leave
      `architecture/rhoai.next.bak` unchanged.
- [x] Refuse configurations where the baseline and candidate directories overlap.
- [x] Record the platform configuration, repository revisions, model, worker count,
      phase start/end times, wall times, failures, and logs needed to reproduce the
      run.
- [x] Compare every matching component with the structured Markdown comparator and
      emit aggregate machine-readable and Markdown reports.
- [x] Report total and per-component structured recall, median recall, components
      below 95%, populated-cell conflicts, missing documents, extra documents, and
      readiness classifications.
- [x] Report recent history and source-file inventory separately from structured
      architecture fidelity.
- [x] Compare each final generated document with its analyzer input and require 100%
      structured identity preservation with no unexplained populated-cell changes.
- [x] Structurally validate every generated component document.
- [x] Record static-analysis and bounded-agent time independently and summarize the
      end-to-end wall-time change from the prior approximately one-hour run.
- [x] Add focused tests for corpus aggregation, missing files, mismatched component
      sets, threshold reporting, and preservation failures.
- [x] Document the exact command and expected output artifacts.

## Files Likely Involved

- `scripts/run_rhoai_next_architecture.sh`
- `scripts/compare_architecture_corpus.py`
- `lib/architecture_baseline.py`
- `tests/`

## Dependencies

- [Normalize platform distribution parsing](../done/normalize-platform-distribution-parsing.md)

## Status

Done on 2026-07-17.

## Completion Evidence

`scripts/run_rhoai_next_architecture.sh` initializes a fresh run tree, captures the
resolved platform configuration and repository revisions, runs only the three
component phases, snapshots analyzer inputs before agent edits, records each phase
with GNU `time`, and invokes the corpus comparator. It defaults to ten workers and
the 3,600-second prior reference.

The comparator emits JSON and Markdown reports covering fixture fidelity,
analyzer-to-final preservation, readiness, revision drift, document-set drift,
structural validation, and timing. Fixture differences are informational. Missing
analyzer facts, unexplained populated-cell changes, and structural failures are hard
gates. Evidence-backed agent refinements can be recorded exactly in the generated
`preservation-adjudications.json` file.

A real dry run captured all 90 available configured repositories and printed the
forced static-analysis, ten-worker agent, collection, snapshot, and comparison
commands. A second preflight using overlapping `/tmp` baseline and candidate paths
was rejected before output creation. The paid full agent run was intentionally not
started as part of harness implementation; its actual measurements will populate
the same run manifest and reports when the documented command is executed.

Verification passed with 41 Python tests, both Go project test suites, Ruff, all
configuration and architecture-document linters, shell syntax validation, and
`git diff --check`.

## First Full-Run Attempt

The first execution at `rhoai-next-20260718T033804Z` completed static analysis for
90/90 repositories in 15.63 seconds and captured 90/90 analyzer inputs. Component
generation then exposed a shared-console backpressure bug and exited after the first
ten workers, before collection or comparison. The runner fix and regression evidence
are recorded in the [fixed nonblocking-output bug](../../bugs/fixed/concurrent-agent-nonblocking-output.md).

## First Successful Full-Corpus Run

The rerun at `rhoai-next-20260718T034628Z` completed static analysis, 90/90
component agents, collection, structural validation, and corpus comparison. The
workflow produced 90/90 structurally valid documents but failed the analyzer
preservation quality gate. The measurements, limitations, interpretation, and
follow-up decision are preserved in the
[dated corpus comparison report](../../notes/rhoai-next-corpus-comparison-2026-07-18.md).

## Related Work

- [Analyzer-generated document fidelity](../../milestones/arch-analyzer-generated-document-fidelity.md)
- [Analyzer-first platform viability](../done/arch-analyzer-platform-ab.md)
- [Dashboard fidelity audit](../done/arch-analyzer-dashboard-fidelity-audit.md)
