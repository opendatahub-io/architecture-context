# Task: Fix Partial Route Change Record Contract

## Goal

Ensure evidence-gated partial-route agents emit mergeable structured change
records for source-backed architecture facts.

## Context

The full run at
`tmp/architecture-corpus-runs/rhoai.next-20260730T194519Z-863253/` completed
all 97 agents successfully, but `odh-gitops` failed the quality gate. Its
candidate had 31 source-backed additions, while `ARCHITECTURE_CHANGES.md`
contained prose only. The merge parser therefore restored the sparse analyzer
baseline.

## Plan

1. Document the exact structured change table contract in the summary skill.
2. Add regression coverage for the skill contract.
3. Replay `odh-gitops` with `custom-test.sh` and verify candidate rows apply.

`custom-test.sh` is scoped to `odh-gitops` for this task and runs static
analysis followed by component generation with one agent slot.

## Acceptance Criteria

- The skill specifies the exact eight change-table headers.
- Add/delete rows specify `<empty>` values and `Column` `*`.
- Every changed row requires numeric repository-relative evidence.
- A targeted `odh-gitops` replay passes synthesis quality without weakening
  evidence-gated merge validation.

## Status

Accepted 2026-07-30 after the targeted replay at
`logs/pipeline/odh-gitops-change-record-replay-20260730T213608Z/generate-architecture/`.

## Replay Result: 20260730T204314Z

The agent emitted the required eight-column table, but merge parsed zero valid
records. It reported 37 parse errors: two unsupported `metadata` rows, add
rows with non-empty value cells, and missing compound key cells for
`authentication` and `integration_points`. The candidate itself contained the
expected source-backed architecture tables, so the remaining defect is still
change-record contract compliance.

## Replay Result: 20260730T205437Z

The tightened category and key guidance improved the result: 18 records were
applied and 16 were rejected. All remaining rejections were caused by bare
file-path evidence without numeric line numbers. The skill now explicitly
forbids bare paths and requires a line or line range on every evidence item.

## Replay Result: 20260730T212249Z

The agent produced 28 records with valid keys, empty add-row values, and
numeric evidence, but omitted the optional outer Markdown table pipes. The
merge parser therefore reported a missing change table and applied zero rows.
The parser now accepts both outer-piped and valid pipe-separated Markdown table
forms, while the skill explicitly requires canonical outer pipes for new
artifacts.

## Replay Result: 20260730T213608Z

The replay applied all 21 change records with zero rejected records and zero
parse errors. The candidate architecture rows survived the evidence-gated
merge. Source-read justification coverage was complete at 12/12 with no
warnings or repairs. One oversized-source-read denial remains unrelated to
this change-record contract.

The acceptance criteria are met.
