# Task: Extend Analyzer Runtime and API Inventory from Demand Evidence

## Goal

Use the completed partial-run demand inventory to reduce recurring agent work by
making `arch-analyzer` extract and render more deterministic runtime-component,
API/service, integration, dependency, and authentication evidence.

## Evidence

See `docs/notes/partial-run-log-demand-report.md` and the ignored
`tmp/partial-run-demand-inventory.json`. The highest-frequency declared gaps
were `architecture_components` (96), `authentication` (81),
`integration_points` (81), `internal_dependencies` (81), `grpc_services` (80),
`services` (80), and `http_endpoints` (77). Common source hotspots included
`go.mod`, `pyproject.toml`, and `cmd/main.go`.

## Scope

- Inspect the existing arch-analyzer extract schema and renderers.
- Add source-backed deterministic mappings for executable entrypoints,
  Dockerfiles/images, workloads, routes/handlers, services/transports,
  dependency roles, literal auth/TLS/RBAC/secret boundaries, and integration
  identities where the evidence is unambiguous.
- Render concise source-linked factual prose for high-value narrative sections.
- Preserve explicit unknown/not-extracted values and never infer security or
  business semantics from structural presence alone.
- Add sanitized fixtures, schema/render tests, and replay comparisons for at
  least one Go operator, Python service, gRPC service, and multi-runtime repo.

## Exclusions

- Do not use prior architecture documents as synthesis inputs.
- Do not commit raw logs, transcripts, API/OTel payloads, secrets, or generated
  architecture outputs.
- Do not move ambiguous workflow interpretation, trade-offs, or higher-level
  architectural judgment into deterministic extraction.

## Acceptance Criteria

- [ ] Each new field has a schema contract, source provenance, and explicit
      unknown behavior.
- [ ] Representative replay cases show fewer declared gaps/source reads or
      fewer synthesis edits without loss of analyzer fact preservation.
- [ ] Existing analyzer and architecture validation suites pass.
- [ ] A human-readable before/after report records reads, edits, duration,
      output quality, and limitations.
