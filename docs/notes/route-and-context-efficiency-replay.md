# Route and Analyzer Context Efficiency Replay

## Demand evidence

The in-progress 2026-07-27 generation run produced 60 component logs when
audited. Forty-five agents had completed successfully. Among the completed and
active logs, the source guard emitted at least 280 readiness-based denials, and
22 components attempted analyzer JSON reads over the 25,000-token tool limit.
Completed-agent median runtime was approximately 337 seconds.

The denials occurred even though prompts explicitly used
`--analysis-route=partial`; the guard checked `readiness=sufficient` instead of
the route. The large-read failures occurred because the skill required reading
the full JSON before using the bounded projections.

## Changes

- Partial route source reads now use the declared file budget regardless of
  readiness. Synthesis remains restricted to analyzer-referenced files.
- `arch-analyzer render` now emits `analyzer_synthesis_context.md` beside the
  baseline and JSON. It contains only coverage findings, cross-references, and
  bounded source-linked evidence claims.
- The skill now reads the compact context first and uses bounded offset/limit
  reads of the full JSON only for facts not present in the projection.

## Validation

- `GOCACHE=/tmp/arch-analyzer-go-cache go test ./...` — passed.
- Focused Python regression suites — 103 passed.
- Real fixture extract/render — passed; projection size was 1,903 bytes.
- Raw logs and generated outputs remain untracked/ignored.

Runtime improvement must be measured on the next full run; this change does
not claim a speedup from regression tests alone.
