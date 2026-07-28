# Task: Fix Duplicate Security Evidence Rendering

## Goal

Make the agents-operator security evidence bug non-regressing: generic
`crypto/tls` import evidence must not render as repeated literal TLS controls.

## Bug

- `docs/bugs/fixed/arch-analyzer-duplicate-security-evidence.md`

## Scope

- Preserve stable deduplication of repeated Go security import evidence.
- Verify repeated `crypto/tls` imports produce one `tls-config` row with
  retained source provenance.
- Render the evidence value as a signal type rather than a misleading runtime
  status.
- Add regression coverage for the agents-operator-style repeated TLS import
  shape.

## Execution record

- Added Go extractor regression coverage for four files importing
  `crypto/tls`; the result must contain exactly one `tls-config` /
  `crypto/tls` row, with `dependency-signal` and all source files retained in
  `Sources`.
- Updated Markdown rendering for Security Evidence to use the column
  `Signal Type` instead of `Status`.
- Added Markdown regression coverage proving the rendered table has one
  dependency-signal row and does not render a generic TLS import as `literal`.

## Validation

```bash
GOCACHE=/tmp/arch-analyzer-go-cache go test ./internal/gosource ./internal/renderer
GOCACHE=/tmp/arch-analyzer-go-cache go test ./...
```

Results: full `src/arch-analyzer` Go suite passed.

## Status

Completed 2026-07-28.
