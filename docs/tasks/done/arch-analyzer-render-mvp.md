# Task: Build arch-analyzer Render MVP

## Goal

Create the project-owned Go module and prove that stored architecture JSON can be
normalized into the canonical component Markdown contract and evaluated against
`rhoai.next` fixtures.

## Acceptance Criteria

- [x] Standalone `src/arch-analyzer` Go module builds.
- [x] Compatibility JSON loads into project-owned types.
- [x] Renderer emits all required Markdown sections and tables.
- [x] Generated documents pass the existing structural validator.
- [x] Tests cover compatibility decoding, normalization, rendering, and escaping.
- [x] Four representative fixtures produce comparison reports.
- [x] Repository build and CI targets include the new module.
- [x] Production extraction remains unchanged.

## Evidence

- Four documents rendered in approximately 0.03 seconds total.
- Focused rendering benchmark: approximately 48 microseconds per document.
- Kueue retained 10 of 121 measured baseline rows with no conflicts.
- Model Registry Operator retained 30 of 121 rows with 3 reviewable conflicts.
- ODH Dashboard retained 35 of 292 rows with 7 reviewable conflicts.
- FMS Guardrails Orchestrator retained 2 of 116 rows with no conflicts.
- Go tests, Go formatting, `go vet`, Python tests, Ruff, validator, and
  `git diff --check` pass.

## Status

Done

## Next

Implement source repository extraction, beginning with Kubernetes YAML and kustomize
resources, without changing the production analyzer selection yet.
