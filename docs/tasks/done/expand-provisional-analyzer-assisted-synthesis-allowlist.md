# Expand Provisional Analyzer-Assisted Synthesis Allowlist

Date: 2026-07-26

## Objective

Enable the smallest reviewed provisional allowlist supported by the accepted
three-route migration matrix. This is a bounded operating decision, not full
rollout authorization.

## Decision

`lib/synthesis_migration_allowlist.json` now lists:

- `rhoai-mcp` — synthesis route; three navigation reads and zero source or
  discovery reads; architecture, merge, and insight artifacts validated.
- `caikit-nlp` — partial route; five bounded Python source reads; architecture,
  merge, and insight artifacts validated. One Bash `ls` preference violation
  was recorded without broadening the read set.

`trustyai-service` remains off the allowlist and correctly exercises legacy
  routing. Unknown, insufficient, and failed restricted-route cases retain
  legacy or analyzer-baseline fallback as already implemented.

## Evidence and safeguards

- The three-component matrix independently validated all architecture outputs.
- Restricted-route insight artifacts loaded with zero errors.
- Evidence-gated merge and provenance protections remain in force.
- No generated architecture output, raw result, API dump, OTel payload, or
  secret was added to the repository.
- External MLflow registration, external-fetch OTel producer evidence, human
  root-cause adjudication, and human semantic calibration remain unresolved.
- This decision does not authorize legacy-route retirement, authoritative
  agent insights, or a full-rollout claim.

## Validation

Evidence: `docs/notes/bounded-multi-component-optimized-migration-report.md`

The report records the route/read matrix, independent architecture and insight
validation, merge counts, limitations, and ignored raw-artifact location.

## Status

Accepted as a provisional operator-controlled configuration change. The next
work remains the external-gate audit/resolution task and continued provisional
evaluation with the legacy route preserved.
