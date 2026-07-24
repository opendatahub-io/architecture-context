# Analyzer Context Contract

The analyzer context contract is an optional, versioned `context_contract`
envelope in `component-architecture.json`. Version 1 carries provenance,
applicability and freshness, confidence, maturity, scope and deployment
topology, dependency/upstream status, and behavioral evidence.

Contract fields use explicit validation states: `confirmed`,
`needs-validation`, `unknown`, and `not-extracted`. An absent optional field
means that metadata was not provided; it is not equivalent to a confirmed
negative. The renderer labels explicit unknown and not-extracted values and
does not infer or populate contract values.

Applicability accepts date-only or RFC3339 boundaries. The Go model rejects an
`applicable_from` value after `applicable_until` and exposes a deterministic
staleness check against a caller-supplied reference date. Cross-field date
constraints remain model validation because they cannot be expressed by the
JSON Schema dialect used here.

The contract is a carrier and compatibility boundary only. Query, overlay,
synthesis, and broad generated-output changes remain separate plan tasks.
