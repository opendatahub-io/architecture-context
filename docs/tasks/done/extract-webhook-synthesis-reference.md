# Task: Extract Webhook Synthesis Reference

## Goal

Move webhook-specific synthesis guidance out of the core
`repo-to-architecture-summary` skill and duplicated controller instructions
into a single progressive-disclosure reference file.

## Scope

- Add `references/webhook-analysis.md` covering analyzer-first inputs, route
  permissions, bounded semantic inspection, output requirements, provenance,
  and aggregation.
- Keep `SKILL.md` as the navigation point for webhook synthesis.
- Remove duplicated webhook instructions from `references/controller-analysis.md`
  and direct webhook-focused agents to the new reference.
- Preserve the distinction between analyzer-owned deterministic enumeration and
  source-based semantic enrichment.

## Acceptance criteria

- The new reference is directly linked from `SKILL.md`.
- `SKILL.md` and `controller-analysis.md` contain no conflicting webhook
  synthesis rules.
- The reference prohibits duplicate deterministic source enumeration and prior
  architecture input while allowing route-authorized semantic inspection.
- Required webhook table, provenance, unknown handling, and aggregation rules
  remain documented.
- Skill validation and Markdown checks pass.

## Execution record

- Added `references/webhook-analysis.md` with analyzer-first route rules,
  semantic questions, output mapping, provenance, unknown handling, ownership
  enrichment, and delegated-finding aggregation.
- Linked the reference from `SKILL.md` and removed duplicated webhook
  instructions from `references/controller-analysis.md`.
- Removed unsupported `user-invocable` frontmatter from `SKILL.md` so the
  repository skill validator accepts the existing skill metadata.
- Validation: `quick_validate.py` passed; scoped Markdown diff checks passed.

## Status

Completed 2026-07-27.
