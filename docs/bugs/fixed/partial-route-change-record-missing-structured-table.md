# Bug: Partial Route Change Record Missing Structured Table

## Summary

An evidence-gated partial-route agent can produce a prose
`ARCHITECTURE_CHANGES.md` summary instead of the structured change table
required by the merge parser. Candidate rows are then rejected as lacking
exact evidence records and the analyzer baseline is restored.

## Evidence

Run:
`tmp/architecture-corpus-runs/rhoai.next-20260730T194519Z-863253/`

For `odh-gitops`, the candidate contained 31 useful rows across four gap
categories, but the change sidecar contained only prose headings. The merge
report recorded:

- missing change table with the required headers;
- 31 rejected candidate-only rows;
- final synthesis quality `96/97`, with `odh-gitops` as the only failure.

## Impact

High for components whose analyzer baseline is sparse. Agent synthesis can
correctly discover and write evidence-backed rows, but the final architecture
document silently restores the empty analyzer tables when the sidecar contract
is not followed.

## Fix Direction

Make the repo-to-architecture-summary skill state the exact change-table
headers, `<empty>` conventions for add/delete rows, and numeric source evidence
requirements. Preserve the strict merge behavior so unsupported or
unsubstantiated rows remain rejected.

## Status

Initial fix implemented in skill guidance with a regression assertion. The
`20260730T204314Z` replay produced the required table but still violated the
contract with unsupported `metadata` rows, populated add-row values, and
incomplete compound keys. Guidance was tightened with explicit category/key
rules and a valid add-row example; another targeted replay is pending.

The `20260730T205437Z` replay applied 18 records successfully. The remaining
16 rejected records used bare file paths without numeric line evidence, so the
contract was tightened again to require `path:number` or `path:start-end` for
every evidence item.

The `20260730T212249Z` replay had numeric evidence and produced 28 records, but
omitted optional outer Markdown table pipes. The parser did not recognize the
table, so zero records applied. The parser now accepts both canonical tables
with outer pipes and valid Markdown tables without them; the skill still asks
agents to emit canonical outer pipes.

The `20260730T213608Z` replay applied all 21 change records with zero rejected
records and zero parse errors. Candidate rows survived the evidence-gated
merge, so this bug is resolved. One oversized source-read denial remains a
separate partial-route runtime concern.

## Resolution

Resolved 2026-07-30 by tightening the skill contract and making Markdown table
parsing tolerant of optional outer pipes. The future JSON patch migration is
tracked separately in
`docs/tasks/pending/replace-markdown-change-record-with-json-patch.md`.
