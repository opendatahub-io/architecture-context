# Task: Render Source-Linked Analyzer Narratives

## Goal

Reduce partial-synthesis edit churn by rendering concise, deterministic,
source-linked factual prose for Purpose, Data Flows, Integration Points, and
Architectural Analysis from `arch-analyzer` facts. Leave trade-offs,
ambiguity resolution, and cross-file interpretation to the synthesis agent.

## Implementation

- Added bounded provenance markers to deterministic Purpose, Data Flows, and
  Architectural Analysis prose using the normalized section-to-source index.
- Added an explicit Integration Points narrative above the structured table,
  including interaction type and available role, protocol, port, and purpose
  facts.
- Preserved explicit evidence boundaries and unknowns; no runtime ordering,
  authentication guarantee, or design rationale is inferred.
- Limited each narrative to a small deterministic set of files/relationships;
  the complete source inventory remains in `Source References`.
- Added renderer coverage for source-linked prose and integration narratives.

## Validation

From `src/arch-analyzer`:

```bash
GOCACHE=/tmp/arch-analyzer-go-cache go test ./...
GOCACHE=/tmp/arch-analyzer-go-cache go vet ./...
```

Both commands passed on 2026-07-27. `git diff --check` passed for the task
files. No raw logs, generated architecture outputs, API dumps, OTel payloads,
or secrets were staged.

## Measurement limitation

This checkpoint proves deterministic rendering behavior and provenance
coverage. A post-change agent read/edit/runtime comparison requires a future
run against available component checkouts; the prior partial-run baseline is
documented in `docs/notes/partial-run-log-demand-report.md`.

## Status

Complete.
