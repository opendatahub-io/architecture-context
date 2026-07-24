# Bounded Synthesis Insights Contract

The analyzer-assisted synthesis boundary now has a versioned, non-authoritative
`InsightArtifact` contract in `lib/insights.py`. Insights are separate from
analyzer facts and reviewed overlays and carry category, provenance, reasoning,
applicability, confidence, unknowns/counterevidence, validation status, and a
suggested validation action.

The validator enforces explicit provenance kinds, deterministic semantic
ordering, a maximum of 25 insights, claim/reasoning bounds, and optional token
budget/count metadata with a 200,000-token ceiling. `unknown` and
`not-extracted` are explicit validation states. JSON Schema and raw-dictionary
validation are covered by valid and invalid fixtures.

`lib/architecture_merge.py` drops candidate `Insights`, `Agent Insights`, and
`Synthesis Insights` sections before merging, so agent analysis cannot be
promoted into authoritative tables, dependencies, security, or acceptance
criteria.

Validation: 84 focused tests passed; ruff and `git diff --check` passed.
