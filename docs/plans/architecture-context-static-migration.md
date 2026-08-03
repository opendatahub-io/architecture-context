# Architecture Context Static Migration Plan

## Objective

Build a reproducible, source-backed architecture-context system in which
deterministic analysis owns structured facts and bounded agents add only the
narrative or residual evidence that cannot be derived safely from source.

This plan consolidates the 15 migration-era plans that shaped the migration:
analyzer ownership, analyzer-assisted synthesis, evidence quality, arch-query,
benchmarks, provenance, configuration integration, telemetry, and
architecture-document automation. The two pre-existing architecture-diagram
and provenance plans remain separate.

## Architecture

The project-owned `src/arch-analyzer` is responsible for extraction,
normalization, source evidence, coverage, schemas, and component Markdown. The
Python pipeline builds and runs it, stores component-local `.analyzer` artifacts,
and promotes validated component documents into the architecture tree.

`arch-query` provides deterministic retrieval over the architecture corpus and
overlays. Its design remains retrieval-oriented and auditable: richer
relationship commands are preferred over an embedded natural-language model.
Bundled distribution is a future packaging option; Markdown remains the source
of truth and disk mode remains supported.

The synthesis route consumes analyzer context, reviewed overlays, provenance,
and bounded evidence bundles. It must preserve analyzer-owned facts, explicit
unknowns, source citations, and merge protections. Prior architecture documents
are comparison fixtures, not synthesis inputs.

## Completed work

- Replaced the runtime dependency on the cloned upstream analyzer with the
  project-owned analyzer and renderer.
- Added cross-language extraction, normalization, complete-empty/coverage
  findings, source-linked narratives, webhook and runtime evidence, and
  analyzer schemas.
- Integrated analyzer-first routing, bounded partial synthesis, baseline
  recovery, clean-run isolation, section ownership, artifact promotion, and
  platform aggregation.
- Added evidence-gated merge, reviewed corrections, provenance, source-read
  justification, telemetry, insight validation, and deterministic benchmark
  contracts.
- Built corpus/replay wrappers and consumer-v1 evaluation support for
  preservation, structure, source citation, regression, runtime, and cost
  measurements.
- Established architecture-document requirements for implementation fidelity,
  component relationships, deployment/network topology, security boundaries,
  HA/DR, versioning, accessibility, and review ownership.
- Retired the legacy webhook inventory phase after moving deterministic webhook
  facts into the analyzer and platform aggregation path.

## Current policy and state

The current policy is recorded in `PLAN.md`:

- Valid analyzer artifacts use bounded partial/extend-and-improve synthesis for
  all readiness classifications.
- Synthesis migration entries remain operator-controlled and audit-oriented.
- Legacy generation is reserved for missing or invalid analyzer artifacts and
  explicit operator override.
- Current registries contain 62 analyzer-only approvals and 4 synthesis
  migration entries.
- Unsupported behavior remains in the residual register rather than being
  promoted to deterministic absence.

The implementation is locally complete. Full rollout claims and legacy-route
retirement remain gated on external MLflow/OTel integration, human root-cause
adjudication, semantic calibration, and other explicitly documented inputs.

## Follow-up work

1. Continue analyzer evidence-quality and route/context-efficiency measurement
   using matched full-run replays. Reduce unnecessary reads and duplicate
   evidence without weakening preservation or structural gates.
2. Complete post-migration consumer evaluation against the pinned corpus and
   convert failures into a prioritized analyzer/contract backlog.
3. Replace Markdown change records with the pending versioned JSON patch
   contract when the workflow hardening work begins.
4. Decide whether `arch-query` should be distributed as an embedded binary,
   including cache invalidation, version selection, freshness, and base-directory
   override behavior.
5. Integrate repository provenance and central sync configuration where those
   sources are available, keeping fallback discovery behavior intact.
6. Add OS-level tracing only if application telemetry cannot answer the required
   file-access, subprocess, or network-boundary questions; do not introduce
   strace as mandatory infrastructure.

## Boundaries

- Do not fabricate facts or infer absence from incomplete extraction.
- Do not use prior generated architecture documents as agent context.
- Do not move semantic architectural judgment into deterministic extraction
  without a source-backed contract.
- Do not retire legacy or claim full external rollout from provisional evidence.
- Do not commit raw logs, transcripts, API/OTel dumps, credentials, or generated
  runtime artifacts as documentation.

## Success criteria

- Analyzer-owned structured identities are preserved through generation and
  merge, with all corrections source-backed and reviewable.
- Generated architecture documents pass schema, structural, provenance, and
  synthesis-quality gates.
- Bounded routes reduce unnecessary discovery and source inspection without
  increasing false absence, unsupported claims, or unexplained conflicts.
- Consumer evaluation is reproducible from pinned inputs and distinguishes
  deterministic regressions from semantic or human-gated questions.
- Remaining agent responsibilities are explicit, source-backed, and maintained
  as a residual inventory.

## Authoritative references

- [Consolidated migration task](../tasks/done/complete-architecture-context-static-migration.md)
- [Consolidated migration note](../notes/architecture-context-static-migration.md)
- [Consolidated migration bug record](../bugs/fixed/architecture-context-static-migration-bug-cluster.md)
- [Analyzer ownership migration milestone](../milestones/analyzer-ownership-migration-v1.md)
- [Open partial-route runtime bug](../bugs/open/partial-route-component-runtime-remains-high.md)
- [Pending JSON patch follow-up](../tasks/pending/replace-markdown-change-record-with-json-patch.md)
- [Blocked external rollout gates](../tasks/blocked/resolve-external-analyzer-assisted-rollout-gates.md)

## Status

Local implementation complete; follow-up evaluation and external promotion gates
remain explicitly tracked. Consolidated on 2026-08-03.
