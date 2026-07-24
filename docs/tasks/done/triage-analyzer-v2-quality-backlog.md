# Task: Triage Analyzer V2 Quality Backlog

## Goal

Turn the consumer A/B results into a bounded, evidence-ranked v2 backlog without
folding unrelated downstream infrastructure work back into the analyzer.

## Prerequisite

[Run Analyzer V1 Consumer A/B Evaluation](run-analyzer-v1-consumer-ab-evaluation.md)
must be complete.

## Work

- Classify each material failure as extraction, normalization, component synthesis,
  `PLATFORM.md` synthesis, inventory/navigation, freshness, overlay handling,
  downstream prompting/access, benchmark defect, or accepted limitation.
- Group reusable fixes and rank them by severity, consumer frequency, expected
  quality gain, implementation cost, and false-positive risk.
- Create focused task or bug files with examples, negative controls, tests, and
  acceptance gates for work selected for v2.
- Keep `arch-query`, fetch-script consolidation, and consumer-skill changes in their
  own workstream unless evidence proves they are required for document evaluation.
- Record explicit no-action decisions for stylistic differences and unsupported
  behavior that do not impair downstream use.

## Acceptance Criteria

- [ ] Every material A/B regression has one disposition and supporting evidence.
- [ ] Selected work is decomposed into independently claimable task or bug files.
- [ ] The ranked backlog distinguishes analyzer quality from delivery and consumer
  adoption concerns.
- [ ] A new v2 goal is created only when the evidence supports concrete work.
- [ ] The post-migration evaluation plan is marked complete and this task is moved
  to `docs/tasks/done/`.

## Status

Done. 2026-07-20.

See: docs/notes/v1-ab-triage-quality-backlog-2026-07-20.md

