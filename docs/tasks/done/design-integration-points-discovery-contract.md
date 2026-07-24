# Task: Implement Integration Points Discovery Contract

## Goal

Implement a conservative `integration-points/v1` category-coverage contract that
distinguishes a legitimately empty Integration Points table from an extraction gap.
Use `guardrails-regex-detector` as the first audited candidate without encoding a
component-specific exception.

## Context

The completeness-only audit manually established that
`guardrails-regex-detector` has no outbound runtime relationships at revision
`5c6116749e66a3496f7a5ac7427219f294df7ec3`. The analyzer cannot use that manual
conclusion because Integration Points has no machine-enforced discovery contract.

The audit result is a target example, not proof that a generic analyzer check is
complete. At least 14 corpus components are blocked by Integration Points, so an
overbroad contract could create many false analyzer-only nominations.

## Authoritative Evidence

- Replay:
  `tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z`
- Audit:
  `docs/notes/completeness-only-candidate-audit-2026-07-19.md`
- Checkout:
  `/data/checkouts/red-hat-data-services.next/guardrails-regex-detector`
- Candidate revision: `5c6116749e66a3496f7a5ac7427219f294df7ec3`
- Fresh analyzer JSON:
  `tmp/architecture-corpus-runs/rhoai-next-cli-kubernetes-static-20260719T180727Z/analyzer/rhoai.next/guardrails-regex-detector.json`

The candidate is a 213-line Rust Axum service with two inbound routes and no
audited outbound HTTP, gRPC, database, storage, queue, streaming, or file-I/O
relationships. Its only network construction is an inbound
`tokio::net::TcpListener::bind`.

## Contract Requirements

Add `integration-points/v1` alongside `authentication/v1` and
`internal-platform-dependencies/v1`. A `complete` result must include nonempty
completed checks and evidence, no limitations, and a fact count matching normalized
Integration Points.

The contract must account for applicable analyzer evidence surfaces:

- Normalized Integration Point facts.
- Outbound HTTP, REST, and gRPC client construction and executed calls.
- Database, object storage, file storage, and cache client construction.
- Message queue and streaming client construction.
- Runtime endpoint references and service bindings from selected manifests and
  configuration.
- Runtime clients, egress identities, and external connections already emitted by
  other extractors.
- Supported-language source coverage and parse failures.

Only languages and constructs covered by explicit checks may contribute to a
complete result. Relevant unsupported source, dynamic endpoint construction,
unresolved dispatch, unreadable files, parser failures, or incomplete selected
manifest resolution must retain `partial` or `unknown`.

## Negative Controls

- Dependency absence in `Cargo.toml`, `go.mod`, or package metadata is not proof of
  no runtime integration.
- Keyword-only scans are not a completeness proof.
- An inbound listener or server route is not an outbound Integration Point.
- A dependency declaration without client construction and use is not a runtime
  relationship.
- Test, example, benchmark, generated, vendored, and support-only surfaces must not
  create facts or satisfy runtime checks.
- Dynamic or interface-dispatched clients that cannot be closed statically must
  keep coverage partial.
- A populated Integration Points table does not automatically prove the category is
  complete; unaccounted relevant surfaces remain limitations.

Add fixtures covering at least: complete-empty standalone service, outbound HTTP,
outbound gRPC, database/storage, message queue, dynamic endpoint/dispatch,
unsupported language, parse failure, unselected manifest, and test-only client.

## Likely Files

- `src/arch-analyzer/internal/extractor/categorycoverage.go`
- `src/arch-analyzer/internal/extractor/categorycoverage_test.go`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/renderer/markdown.go`
- `src/arch-analyzer/internal/renderer/markdown_test.go`
- `lib/architecture_routing.py`
- `tests/test_arch_analyzer_category_coverage.py`
- `tests/test_architecture_routing.py`
- `tests/test_analyzer_only_eligibility.py`

Prefer existing structured extractor outputs over a second ad hoc repository scan.
Add new source scanning only when existing facts and coverage metadata cannot
account for a required surface.

## Acceptance Criteria

- [ ] `integration-points/v1` is emitted with deterministic status, fact count,
  completed checks, limitations, and evidence.
- [ ] Complete-empty requires every applicable bounded check to succeed.
- [ ] All negative controls remain partial, unknown, or populated as appropriate.
- [ ] Old analyzer JSON without Integration Points coverage remains compatible and
  cannot gain eligibility.
- [ ] Python routing recognizes only the exact `integration-points/v1` contract with
  zero facts, nonempty checks/evidence, and no limitations.
- [ ] No component-name or repository-path exceptions are introduced.
- [ ] `go test ./...` and `go vet ./...` pass in `src/arch-analyzer`.
- [ ] Ruff and the affected Python test suite pass.
- [ ] A fresh 90-component replay has zero false nominations, no unexplained
  analyzer conflicts or missing rows, and 90/90 structural and synthesis gates.
- [ ] Every newly nominated component is source-audited before approval; do not
  infer safety from the contract result alone.
- [ ] A bounded production matrix passes for each newly approved component.
- [ ] A validation note records routing, preservation, quality gates, wall time,
  cost, tools, reads, source files, and tokens.
- [ ] The residual register, goal, and `PLAN.md` are reconciled before moving this
  task to `docs/tasks/done/`.

## Status

Complete. See
[Integration Points discovery contract validation](../../notes/integration-points-discovery-contract-validation-2026-07-19.md).
