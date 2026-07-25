# Integrate Synthesis Insight Artifacts

Connected the bounded `InsightArtifact` contract to the component synthesis
execution path. Synthesis and partial jobs now receive an explicit
`INSIGHTS_ARTIFACT.json` output path; the skill documents the required schema,
evidence citations, explicit unknowns, and valid empty artifacts. The phase
validates and archives the artifact beside the run report and exposes its
path/count/validation metadata without merging it into analyzer-owned
Markdown. Legacy and analyzer-only routes remain unchanged.

Validation: 156 focused host tests passed across architecture phase, insights,
routing, and merge suites; Ruff and `git diff --check` passed. No production
agents or evaluations were launched.
