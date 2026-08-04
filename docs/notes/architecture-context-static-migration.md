# Architecture Context Static Migration

## Purpose

This note consolidates the 109 migration-era implementation, validation, replay,
evaluation, and session notes produced while moving architecture-context
generation to a project-owned static analyzer with bounded synthesis. The two
pre-existing architecture-requirements and webhook reference notes remain
separate. The migration notes were useful as an iteration ledger; this document
is now the compact evidence index.

## Final architecture

`src/arch-analyzer` owns deterministic extraction, normalization, source
evidence, coverage, schemas, and Markdown rendering. The production pipeline
builds the local analyzer and stores component-local artifacts under `.analyzer`
before promoting validated component documents into the architecture tree.

Analyzer output is the authoritative structured baseline. Agent work is limited
to bounded narrative synthesis and explicitly evidenced residual gaps. Reviewed
corrections and overlays are applied through validated merge contracts, while
unknown or unsupported behavior remains visible rather than being inferred as
absence.

## Routing and contracts

- Valid analyzer artifacts use bounded partial/extend-and-improve synthesis for
  all readiness classifications.
- Synthesis migration entries remain operator-controlled and audit-oriented.
- Legacy generation is reserved for missing or invalid analyzer artifacts and
  explicit operator override.
- Preservation, conflict, source-read, provenance, insight, and structural
  gates protect analyzer-owned rows and reject unsupported changes.
- Context access, source-read justification, runtime, and evaluation telemetry
  are recorded as local artifacts suitable for replay and diagnosis.

## Evidence summary

The migration work covered:

- Go, Python, Rust, web, manifest, Kubernetes API, authentication, dependency,
  runtime, webhook, serving-runtime, and platform-projection extraction.
- Analyzer coverage and complete-empty findings, compact context/index artifacts,
  source-linked factual narratives, and deterministic section assembly.
- Analyzer-first routing, bounded partial synthesis, analyzer-baseline recovery,
  artifact promotion, clean-run isolation, and platform aggregation.
- Consumer-v1 corpus design, source-citation and exact-match contracts,
  architecture-only scoring, condition-aware evaluations, local MLflow and OTel
  capture, and targeted/full-corpus replay wrappers.
- Runtime and quality follow-ups covering oversized reads, denied tools,
  source-read ledgers, change records, authentication row migrations, benchmark
  scope, language inference, serving paths, and regression reporting.

The current implementation state is summarized by `PLAN.md`, the migration task,
and the analyzer ownership milestone. Current registries contain 62 analyzer-only
approvals and 4 synthesis migration entries. The accepted policy continues to
track residual agent-owned behavior rather than forcing complete analyzer-only
coverage.

## Architecture documentation requirements

The consolidated architecture requirements remain: diagrams and generated
documents must reflect the deployed implementation, identify components,
relationships, data flows, deployment and network topology, authentication and
authorization boundaries, secrets and encryption, HA/DR behavior, versions,
ownership, and relevant source or decision records. Outputs should be readable,
accessible, version-aware, and validated against implementation rather than
aspirational design.

The migration also preserves the process lesson from the architecture-document
research: automation should improve freshness and enforce documentation gates,
not merely produce attractive diagrams for a workflow that still creates them
retroactively. Product installation documentation and detailed engineering/ADR
architecture references serve different audiences and should not be treated as
one interchangeable artifact.

## Webhook inventory disposition

Webhook extraction and cross-component references were initially tracked as a
separate inventory phase. That phase was retired during the migration. The
project-owned analyzer now provides the deterministic webhook facts and
`arch-query`/aggregate platform synthesis provides the query and platform-level
views. Ownership, conversion webhooks, overlay activation, platform webhooks,
external webhooks, handler evidence, and cross-cutting resource targets remain
part of the analyzer-backed architecture context rather than a separate legacy
agent phase.

## Authoritative references

- [Consolidated migration task](../tasks/done/complete-architecture-context-static-migration.md)
- [Consolidated migration bug record](../bugs/fixed/architecture-context-static-migration-bug-cluster.md)
- [Component analyzer migration plan](../plans/architecture-context-static-migration.md)
- [Analyzer-assisted agent architecture plan](../plans/architecture-context-static-migration.md)
- [Analyzer ownership migration v1 milestone](../milestones/analyzer-ownership-migration-v1.md)
- [Architecture context static migration plan](../plans/architecture-context-static-migration.md)
- [Open partial-route runtime bug](../bugs/open/partial-route-component-runtime-remains-high.md)
- [Pending JSON patch follow-up](../tasks/pending/replace-markdown-change-record-with-json-patch.md)
- [Blocked external rollout gates](../tasks/blocked/resolve-external-analyzer-assisted-rollout-gates.md)

## Status

The implementation and validation notes were consolidated on 2026-08-03. The
original checkout retains the detailed historical notes; this file is the
canonical note for the migration going forward.
