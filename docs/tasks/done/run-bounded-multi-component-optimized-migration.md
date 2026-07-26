# Task: Run Bounded Multi-Component Optimized Migration

## Goal

Run a small provisional migration matrix using the optimized analyzer-assisted
route and compare sufficient synthesis, partial bounded-read, and legacy or
analyzer-baseline fallback behavior before expanding the tracked allowlist.

## Scope

- Select 3–5 components with real analyzer evidence and record the rationale.
- Use temporary allowlist entries and run-scoped writable checkout copies.
- Include at least one sufficient synthesis component, one partial component,
  and one excluded/insufficient/unknown fallback case.
- Capture route, source-read, discovery/denial, duration, cost, merge,
  provenance, insight, and validation evidence for every selected component.
- Produce a committed human-readable report with methodology, component
  matrix, observations, conclusions, limitations, and allowlist recommendation.

## Explicit exclusions

- Do not modify committed `architecture/` output.
- Do not add raw logs, API dumps, OTel payloads, or secrets to Git.
- Do not run a full-corpus or paid benchmark.
- Do not make the temporary allowlist permanent.
- Do not retire the legacy route or claim full rollout.

## Acceptance criteria

- Every selected component has a recorded route and complete output/merge/
  validation result, including explicit fallback outcomes where applicable.
- Synthesis components show no source/discovery reads; partial components show
  only declared category-specific bounded reads; legacy behavior remains
  available and unchanged.
- Analyzer-owned facts, overlays, provenance, explicit unknowns, and insight
  non-authority are preserved.
- All temporary outputs pass architecture, merge, insight, and relevant
  schema validators.
- The report compares telemetry with prior runs without overclaiming causal
  performance or quality improvements.
- Focused tests and `git diff --check` pass; the task remains review-held until
  independent driver acceptance.

## Execution record

### Matrix run: `migration-20260726-matrix`

- **Components**: `rhoai-mcp` (synthesis), `caikit-nlp` (partial),
  `trustyai-service` (legacy/unknown)
- **Aggregate agent duration**: approximately 788 seconds
- **Reported cost**: $5.98
- **Artifacts**: ignored temporary output under
  `tmp/analyzer-assisted-migration/migration-20260726-matrix/`
- **Validation**: all three architecture documents passed; `rhoai-mcp` and
  `caikit-nlp` insight artifacts passed with 3 and 2 insights respectively
- **Merge counts**:
  - `rhoai-mcp`: 94 applied, 84 rejected, 48 restored, 14 unchanged
  - `caikit-nlp`: 59 applied, 45 rejected, 32 restored, 20 unchanged
- **Report**: `docs/notes/bounded-multi-component-optimized-migration-report.md`

The matrix exercised all required routes. The partial agent made one Bash
`ls` call outside the preferred Glob-only discovery pattern; this was logged,
did not expand its five-file Python read set, and did not alter the route
contract. The tracked allowlist remains empty and no committed architecture
output changed.
