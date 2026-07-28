# arch-analyzer Optimization Follow-up

## Objective

Use the completed 97-component analyzer-assisted run to make deterministic
analyzer artifacts more synthesis-complete, reducing agent rediscovery,
source reads, edit turns, and runtime without moving ambiguous architectural
judgment into static analysis.

The current run is the primary demand evidence. Prior architecture documents
remain comparison-only and must not become synthesis inputs.

## Evidence baseline

- 97 components completed the generation run.
- The median component made no source-file reads; the remaining cost is mostly
  context navigation, reasoning, and reconstruction of missing relationships.
- Agents repeatedly reconstructed endpoint purpose/owner/port/auth/TLS and
  service, authentication, gRPC, integration, and dependency relationships.
- Merge reports contained many rejected or restored candidate rows in
  `integration_points`, `internal_dependencies`, `authentication`, and
  `http_endpoints`.
- Nine insight artifacts fell back because `cross-component implication` is
  not accepted by the current applicability schema. This is a separate
  synthesis-contract task, not an analyzer extraction task.

## Implementation sequence

### 1. Cross-reference enrichment

Implement deterministic maps connecting services, endpoints, ports,
transport/TLS, authentication/RBAC, webhooks, controller watches, and
component references. Every relationship must retain source provenance and
explicitly distinguish observed facts from unresolved relationships.

### 2. Complete coverage and absence findings

For categories with reliable coverage, emit explicit complete-empty findings,
such as no gRPC services, no ingress, or no CRDs. Incomplete categories must
remain `unknown` or `not-extracted`; absence must never be inferred from a
partial scan.

### 3. Compact synthesis evidence bundles

Render section-oriented, bounded evidence slices for endpoints, services,
authentication, dependencies, integrations, and runtime/build metadata. Keep
the full JSON authoritative, but give the synthesis agent the smallest useful
source-linked context so it does not repeatedly navigate large artifacts.

### 4. Insight contract correction

Normalize or formally support the emitted `cross-component implication`
applicability value. Preserve the distinction between component-local and
cross-component analysis, and ensure invalid insight artifacts do not silently
fall back.

### 5. Replay and measure

Replay representative Go operators, Python services, gRPC services, webhook-
heavy components, and multi-runtime repositories. Compare source reads,
discovery calls, edit/merge decisions, duration, fallback rate, fact
preservation, and validation outcomes with the completed-run baseline.

## Boundaries

- Do not use prior generated architecture documents as synthesis context.
- Do not commit raw logs, transcripts, API/OTel dumps, credentials, or
  generated platform outputs.
- Keep semantic trade-offs, cross-component reasoning, and recommendations in
  the agent insight route unless a deterministic source-backed contract is
  established.

## Success criteria

- Repeated endpoint/service/dependency reconstruction declines in replay.
- Complete-empty findings reduce unnecessary source inspection without false
  absence claims.
- Evidence bundles reduce context/tool activity while preserving provenance.
- Insight fallback count reaches zero for schema-valid artifacts.
- No regression in analyzer fact preservation or architecture validation.

## Current evidence

The implementation and sanitized fixture replay are recorded in
`docs/notes/analyzer-optimization-replay-report.md`. A full runtime comparison
is intentionally not claimed until the component checkouts are available for a
fresh platform run.

## Follow-up execution: route and context efficiency

The next two implementation tasks address subsequent full-run findings:

1. [Allow bounded source reads on the partial route](../tasks/done/allow-bounded-source-reads-on-partial-route.md)
   removes the readiness-based denial from partial execution while retaining
   the file budget and synthesis restrictions.
2. [Add a compact analyzer context file](../tasks/done/add-compact-analyzer-context-file.md)
   gives agents a bounded projection before the potentially very large JSON.

Implementation evidence is recorded in
`docs/notes/route-and-context-efficiency-replay.md`. A fresh full run is still
required to measure runtime and denial-rate changes.
