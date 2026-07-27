# Partial-Run Log Demand Report

## Scope and run boundary

This report uses only the completed component-agent run in
`logs/generate-architecture/` as primary evidence. The boundary contains 97
component records and 97 component logs. Component log modification times span
approximately 13:31–14:33 EDT on 2026-07-27. Platform aggregation completed in
`logs/generate-platform-architecture/rhoai.next.log` and platform diagram
generation completed in `logs/generate-diagrams/rhoai.next_platform.log`.

The run used the intended analyzer-assisted routing: 96 components selected
`partial` and one selected `legacy` because its analyzer-backed route was not
usable. Readiness counts were 74 `sufficient`, 13 `partial`, 9
`insufficient`, and 1 `unknown`. Representative run records report an 8-file
partial budget and `Glob`/`Grep` as the discovery tools.

The machine-readable, redacted inventory is generated at
`tmp/partial-run-demand-inventory.json` by
[`scripts/mine_partial_run_logs.py`](../../scripts/mine_partial_run_logs.py).
The `tmp/` path is ignored and the inventory contains no transcript text or
source content.

## Demand summary

| Signal | Observed value |
|---|---:|
| Component records parsed | 97/97 |
| Partial routes | 96 |
| Legacy routes | 1 |
| Run records marked successful | 1/97 |
| Average recorded agent duration | 590.7 s |
| Maximum recorded agent duration | 1,217.9 s |
| Average source paths read | 7.45 |
| Average model turns | 40.1 |
| Read tool calls | 1,462 |
| Edit tool calls | 1,676 |
| Write tool calls | 344 |
| Glob/Grep calls | 132/195 |
| Delegated Task calls | 0 |

The partial guard is working: source reads stay within the declared file
budgets and no delegated sub-agents were used. The remaining latency is mostly
serial model interaction and document editing rather than broad repository
enumeration.

The low run-success count is a separate quality issue: 96 records failed
insight-artifact validation even though their component documents were
produced. It must not be interpreted as 96 analyzer extraction failures.

## Recurring analyzer demand

The declared gap categories show what the rendered baseline is still asking
agents to improve:

| Rank | Gap category | Components |
|---:|---|---:|
| 1 | `architecture_components` | 96 |
| 2 | `authentication` | 81 |
| 2 | `integration_points` | 81 |
| 2 | `internal_dependencies` | 81 |
| 5 | `grpc_services` | 80 |
| 5 | `services` | 80 |
| 7 | `http_endpoints` | 77 |
| 8 | `ingress`, `egress`, `secrets` | 7 each |

The most frequently reread source paths were `go.mod` (18 components),
`pyproject.toml` (17), `cmd/main.go` (14), and `README.md` (7). These are
demand indicators, not proof that every occurrence should be extracted; each
candidate still needs a deterministic contract and source provenance.

## Prioritized opportunities

### P0 — Repair insight-artifact generation/validation separately

96 component run records contain an `insight_artifact_validation` error. The
reported failures include invalid or missing schema fields such as platform,
version, claim, reasoning, category, applicability, confidence, and
provenance. This is not an arch-analyzer extraction opportunity, but it makes
the run records unsuccessful and must be fixed before using success/cost data
as a clean benchmark.

### P1 — Runtime component and entrypoint mapping

`architecture_components` is declared for 96 of 96 partial routes. Extend
extraction/rendering to map executable entrypoints, Dockerfiles, workloads, and
runtime roles into a source-backed component table. Candidate deterministic
inputs include `cmd/main.go`, language entrypoints, Dockerfiles, and manifest
container commands. Keep dynamic role interpretation explicit as unknown when
the mapping is ambiguous.

Expected effect: reduce repeated reads and edits in Architecture Components,
Purpose, and Deployment sections.

### P1 — API ownership and transport enrichment

`grpc_services` and `services` appear in 80 components, while
`http_endpoints` appears in 77. The analyzer should associate extracted routes
and services with their registering package, handler/service owner, transport,
port, and source location where deterministically available. It should also
render explicit unknowns for dynamically assembled routes.

Expected effect: reduce targeted reads in API, Network Architecture, and Data
Flows sections without inferring authentication or business semantics.

### P1 — Integration and internal-dependency role classification

`integration_points` and `internal_dependencies` are each declared in 81
components. Extend structured extraction to distinguish package/library
dependencies from runtime calls, Kubernetes resource relationships, and
external services. `go.mod` and `pyproject.toml` are the most common source
hotspots, but dependency purpose should only be populated when supported by
declared metadata or a deterministic import/call relationship.

Expected effect: reduce repeated dependency and integration edits while
preserving a separate agent role for higher-level workflow interpretation.

### P1 — Authentication, TLS, and enforcement-boundary inventory

`authentication` is declared in 81 components. Extract literal middleware,
auth-proxy sidecars, TLS settings, RBAC references, token-review calls, secret
references, and ingress policy links into structured evidence. Do not infer
that an endpoint is secure merely because a proxy or TLS library exists; retain
explicit unknowns and source references.

Expected effect: reduce safety-critical targeted reads while keeping semantic
security conclusions agent-reviewed.

### P2 — Narrative rendering from structured facts

Every component log mentions the high-value narrative sections, and the agents
performed 1,676 edits across the run. Improve `render` so it produces concise,
source-linked factual prose for Purpose, Data Flows, Integration Points, and
Architectural Analysis from extracted relationships. Leave trade-offs,
ambiguity resolution, and cross-file interpretation to the agent.

Expected effect: reduce edit-turn churn more than adding isolated inventory
fields alone.

### P2 — Configuration, probes, and lifecycle relationships

Less frequent but high-value reads include RBAC manifests, metrics services,
webhook patches, configuration files, and runtime entrypoints. Extract literal
environment/config references, health/readiness probes, lifecycle hooks, and
controller watch relationships with provenance. These should be prioritized
after the higher-frequency categories above.

## Deterministic versus agent-owned work

Good analyzer candidates are literal inventories, identity joins, source
locations, and explicit absence/unknown states. The agent should continue to
own ambiguous purpose, cross-file workflow explanation, trade-offs, and
security conclusions that require interpretation beyond extracted facts.

## Replay baseline

The inventory records route, readiness, allowed source files, source paths
read, tool counts, edit/write counts, duration, cost when present, validation
markers, and classified run errors for every component. Representative replay
cases should include a Go operator, a Python service, a gRPC service, and a
multi-runtime component; the current run provides examples such as
`ai-gateway-operator`, `MLServer`, `caikit-tgis-backend`, and `batch-gateway`.

The baseline is currently contaminated by the 96 insight-artifact validation
errors, so those errors must be separated from analyzer-runtime comparisons.
No raw transcript or generated architecture file is used as a golden output.

## Limitations

- The inventory derives tool-call counts from structured log representations;
  counts are demand indicators, not exact token accounting.
- Section mention counts measure observed log references, not semantic edit
  coverage.
- Source-path frequency does not prove that a file was needed; it identifies
  candidates for deterministic extraction review.
- The one legacy record and insight validation failures require separate
  follow-up before claiming uniform run quality.
