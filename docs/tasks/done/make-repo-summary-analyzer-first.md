# Make repo-to-architecture-summary Analyzer-First

Date: 2026-07-26

## Objective

Use as much of the `arch-analyzer` output as possible before the skill reads
component source, reducing redundant file inspection while preserving source
verification for unresolved, stale, contradictory, or safety-critical facts.

## Changes

Updated `.claude/skills/repo-to-architecture-summary/SKILL.md` so that:

- every route reads `component-architecture.json` and
  `ANALYZER_ARCHITECTURE.md` first when present;
- `data_coverage`, `category_coverage`, provenance, explicit gaps, and output
  requirements determine the inspection list;
- analyzer-covered facts are not reread from source merely to restate them;
- source reads require a declared gap, stale/contradictory fact, missing
  analyzer category, or safety-critical dynamic behavior;
- legacy is an analyzer-first fallback, expanding to broad discovery only when
  required evidence is absent or unresolved;
- dynamic-resource safety requirements remain in force, including exhaustive
  inspection where the analyzer does not establish controller behavior.

Updated the architecture plan to match this behavior. Synthesis remains
source-free, partial remains bounded and gap-specific, and legacy fallback is
preserved.

## Validation

The skill contract was inspected for the analyzer-first policy and route hard
limits. Existing routing/phase tests and architecture validation remain the
runtime evidence for enforcement. No generated architecture output, raw
temporary artifact, or secret was changed.
