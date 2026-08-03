# Insight Artifact Contract

When `--insights-output=FILENAME` is present, write exactly one JSON object to
that path. This artifact is supplementary and non-authoritative; it records
architectural observations, not analyzer coverage gaps.

## Required envelope

```json
{
  "schema_version": 1,
  "component": "component-name",
  "platform": "rhoai",
  "version": "rhoai.next",
  "insights": []
}
```

`schema_version` must be the JSON number `1`, not the string `"1"`. The
`component`, `platform`, and `version` values must be non-empty strings. An
empty `insights` array is valid and is preferred when the available evidence
does not support a meaningful observation.

## Insight shape

Every item in `insights` must contain all of these fields:

```json
{
  "id": "component-pattern-001",
  "claim": "A short, evidence-backed architectural claim.",
  "category": "pattern",
  "provenance": [
    {
      "kind": "analyzer-fact",
      "location": "component-architecture.json#/runtime"
    }
  ],
  "reasoning": "Explain how the cited evidence supports the claim.",
  "applicability": "component",
  "confidence": "medium"
}
```

Allowed values are:

- `category`: `pattern`, `trade-off`, `risk`, or `cross-component implication`
- `applicability`: `component`, `cross-component`, `cross-platform`, or `platform`
- `confidence`: `high`, `medium`, or `low`
- provenance `kind`: `analyzer-fact`, `query-result`, `overlay`, or
  `source-excerpt`

`architecture_components`, `authentication`, `integration_points`,
`internal_dependencies`, `http_endpoints`, and `grpc_services` are analyzer
coverage-gap categories. They must not be used as insight categories. Use the
analyzer facts to support a real claim, or leave `insights` empty.

Use exactly one of the listed enum values for `applicability`. Do not append
descriptive suffixes (e.g. `cross-component implication` is invalid; use
`cross-component` and explain the implication in `reasoning`).

Do not invent provenance, copy whole source files, include secret values, or
promote an insight into the architecture Markdown. The orchestrator validates
this file independently.
