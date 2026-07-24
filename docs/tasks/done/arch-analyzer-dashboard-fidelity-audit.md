# Task: Audit Dashboard Structured Fidelity Gaps

## Goal

Determine why the analyzer-first dashboard document misses 24 of 165 structured
fixture identities and resolve the confirmed analyzer, normalization, rendering,
comparison, or bounded-agent defects.

## Context

The analyzer-first viability work proved speed, structural validity, and preservation
of analyzer facts. It did not prove replacement-level document fidelity. The current
dashboard result is 141/165 structured identities (85.45%); the agent output retains
the same identities and therefore does not yet fill the remaining gaps.

## Acceptance Criteria

- [x] Produce a durable, row-level disposition for all 24 missing structured
      identities.
- [x] Audit all populated-cell conflicts against source at commit `f1cdd9f22`.
- [x] Separate fixture defects and semantic aliases from actual extraction gaps.
- [x] Implement focused fixes with fixtures and regression tests for confirmed
      defects.
- [x] Regenerate and structurally validate analyzer and agent Markdown.
- [x] Reach the fidelity gates in the parent milestone or record any unresolved gap
      as an explicit bug.
- [x] Run the revised comparison against a second representative repository.
- [x] Record extraction time and bounded agent time independently.

## Files Likely Involved

- `src/arch-analyzer/`
- `scripts/compare_component_architecture.py`
- `.claude/skills/repo-to-architecture-summary/SKILL.md`
- `docs/plans/component-analyzer-migration.md`

## Status

Done

## Related Milestone

- [Analyzer-generated document fidelity](../../milestones/arch-analyzer-generated-document-fidelity.md)

## Notes

The dashboard comparison now reaches 162/166 raw structured identities (97.59%)
and 162/162 after excluding four source-reviewed fixture defects. The generated
document preserves 314/314 current analyzer identities with zero populated-cell
conflicts and passes structural validation.

The `caikit-nlp` partial-path check preserves 20/20 current analyzer identities.
Dashboard extraction took 0.49 seconds, rendering took less than 0.01 seconds, and
the deterministic synthesis rebase took 0.04 seconds. The preserved bounded agent
treatment took 485 seconds; a fresh rerun could not start because the local Claude
CLI had no active credentials. Full dispositions and evidence are recorded in the
[dashboard fidelity audit](../../notes/arch-analyzer-dashboard-fidelity-audit.md).
