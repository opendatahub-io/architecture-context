# Task: Run Next Optimized Analyzer-Assisted Migration

## Goal

Exercise the optimized analyzer-sufficient synthesis route on one bounded,
allowlisted component and compare its evidence, output validation, and route
telemetry with the prior migration without changing committed architecture
output or expanding the allowlist automatically.

## Scope

- Use the existing analyzer-assisted migration harness and the optimized
  `repo-to-architecture-summary` route contract.
- Run one representative sufficient-readiness component in temporary ignored
  output only.
- Capture route, pre-seeding, source-read, discovery/denial, duration, model,
  cost, merge, insight, and validation evidence.
- Produce or update a human-readable report with observations, conclusions,
  limitations, and a recommendation about whether to expand the allowlist.

## Explicit exclusions

- Do not modify committed `architecture/` output.
- Do not add raw logs, API dumps, OTel payloads, or secrets to Git.
- Do not run a full-corpus or paid benchmark.
- Do not expand the allowlist or retire the legacy route in this task.

## Acceptance criteria

- The run uses the optimized `synthesis` route with analyzer evidence
  pre-seeded and no broad source discovery.
- Temporary output, candidate, merge, insight, provenance, and validation
  artifacts are complete and schema-valid.
- Telemetry is compared with the prior migration without claiming a causal
  performance improvement from a single run.
- A human-readable report records exact commands, inputs, outputs, duration,
  cost, route/read/denial counts, limitations, and recommendation.
- Focused tests and validators pass; raw temporary artifacts remain ignored.
- The task remains review-held until the driver independently accepts the
  generated output and evidence.
