# Bug: Valid Empty Analyzer Cells Rejected by Preservation Gate

## Summary

The analyzer-to-generated preservation gate rejected valid merge adjudications
when an evidence-backed update populated a previously empty analyzer cell.
Merge reports represent that cell as `"analyzer": ""`, but the comparator
treated the empty string as a missing required field.

## Evidence

Full run:
`tmp/architecture-corpus-runs/rhoai.next-20260730T215609Z-929041/`

- Component generation: 97 components, 0 failures.
- Analyzer identities retained: 10,703/10,709.
- Conflicts: 10, all source-backed and accepted.
- Unexplained conflicts: 0.
- Invalid adjudications: 26, all caused by empty analyzer cell values.
- Gate failure: `analyzer-to-generated preservation failed`.

## Impact

The full wrapper reported a failed preservation gate despite successful
generation and source-backed merge decisions. The affected updates were
valid additions to analyzer rows whose prior cell was empty.

## Fix

The comparator now validates identity fields, reason, and evidence strictly
while allowing empty strings for analyzer and generated cell values. A
regression test covers an accepted update from an empty analyzer cell.

## Status

Resolved 2026-07-30. The targeted comparator suite passes, and rerunning the
comparison over the completed full-run artifacts clears the gate:

- Invalid adjudications: 0.
- Accepted analyzer-to-final conflicts: 10.
- Analyzer structured recall: 10,703/10,709 (99.94%).
- Required gates: pass.
