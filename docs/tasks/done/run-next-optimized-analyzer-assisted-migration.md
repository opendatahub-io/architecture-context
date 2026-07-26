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

## Execution record

### Retry run: `migration-20260726-optimized-retry`

- **Component**: `rhoai-mcp`
- **Source revision**: `dabe473`
- **Route**: `synthesis` / `sufficient`
- **Temporary allowlist**: `rhoai-mcp` only; restored to the empty tracked
  allowlist after execution
- **Agent evidence**: 3 navigation reads, 0 source reads, 0 Bash/Glob/Grep/
  Task calls; 65 turns; 408.5 seconds; reported cost $4.83
- **Artifacts**: all generated output, candidate, merge, and insights under
  `tmp/analyzer-assisted-migration/migration-20260726-optimized-retry/`
- **Merge**: 0 applied, 2 rejected, 7 restored, 50 unchanged
- **Validation**: architecture validator PASS; insight validator PASS with 3
  insights; container-reported focused tests 76 passed and broader related
  tests 185 passed
- **Report**: `docs/notes/next-optimized-analyzer-assisted-migration-report.md`

The first host SDK attempt (`migration-20260726-optimized`) failed during
Claude initialization after 100.3 seconds because the control request timed
out. It produced no source reads or candidate; the container retry is the
accepted migration result.

### Review

The container agent also made route-contract refinements to the skill and
added focused tests for the newly observed synthesis boundaries. These are
included in the reviewed task diff because they make synthesis skip
orchestrator-owned validation and scope operator/source instructions to the
routes that may actually read source. No committed architecture output or raw
task-run data was added. The host virtual environment was recreated by UV
after the container run; a subsequent offline host test rerun was blocked by
an uncached `claude-agent-sdk` wheel and unavailable DNS, so the container test
results and system-level artifact validators are the authoritative evidence for
this execution.
