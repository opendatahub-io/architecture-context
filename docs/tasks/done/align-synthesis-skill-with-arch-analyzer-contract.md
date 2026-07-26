# Align Synthesis Skill With arch-analyzer Contract

Date: 2026-07-26

## Result

Updated `.claude/skills/repo-to-architecture-summary/SKILL.md` to explicitly
document the analyzer-assisted handoff:

- `src/arch-analyzer extract` produces `component-architecture.json`.
- `arch-analyzer render` produces `ANALYZER_ARCHITECTURE.md`.
- The orchestrator places both files at the component checkout/output root,
  derives readiness from `data_coverage.agent_baseline`, and pre-seeds the
  rendered baseline before restricted-route invocation.
- The JSON contract is the machine-readable, source-backed authority;
  analyzer-owned Markdown tables and provenance are preserved by merge.
- Agents must not rerun the analyzer or regenerate these inputs; absent inputs
  disqualify constrained routes and leave routing to the legacy/fallback path.

The route-specific source-read restrictions and analyzer provenance rules are
unchanged, but their dependency on the concrete analyzer outputs is now
explicit and auditable.

## Validation

The skill contains the route contract, output filenames, CLI handoff, readiness
field, and fallback condition. Existing routing, merge, and architecture
validation checks remain applicable. No generated architecture output or raw
temporary artifact was changed.
