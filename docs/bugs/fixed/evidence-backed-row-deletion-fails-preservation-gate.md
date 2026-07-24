# Bug: Evidence-Backed Row Deletion Fails Preservation Gate

## Summary

The corpus comparator failed analyzer preservation when the evidence-gated merge
correctly deleted an analyzer row, even when the merge report contained an exact
source-backed delete decision.

## Reproduction

The `rhoai-next-20260718T200215Z` run deleted four gRPC service identities from
`caikit-tgis-backend`. Source inspection established that the repository consumes
the generated RPC stubs as a client and does not expose the service. The merge
accepted all four delete records, but the comparator only loaded accepted cell
updates and treated the missing identities as unexplained losses.

## Expected

An exact applied delete with a component, category, normalized key, reason, and
source evidence is reported as an accepted analyzer row correction. Missing rows
without that adjudication still fail preservation.

## Actual

The run failed at 8,167/8,171 raw analyzer identities despite having complete merge
adjudications for the four corrections.

## Resolution

- Merge reports now expose `accepted_deletions` separately from populated-cell
  conflicts.
- The corpus harness loads the new field and reconstructs it from recorded merge
  decisions for older completed runs.
- Preservation matches each structured missing key to an exact evidence-backed
  deletion and reports accepted corrections and unexplained missing rows separately.
- Non-architecture history/source inventory remains outside the preservation gate.
- Regression tests cover merge serialization, accepted deletion gating, and the
  completed-run replay.

## Status

Fixed on 2026-07-18.

## Related

- [Full-corpus validation](../../notes/rhoai-next-routing-coverage-full-corpus-2026-07-18.md)
- [Routing coverage task](../../tasks/done/improve-readiness-routed-synthesis-coverage.md)
