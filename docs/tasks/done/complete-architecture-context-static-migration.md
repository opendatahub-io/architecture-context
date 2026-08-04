# Task: Complete the Architecture Context Static Migration

## Goal

Replace the iterative, repository-discovery-heavy architecture generation flow
with a project-owned static architecture context pipeline and bounded synthesis
where deterministic extraction is insufficient. Preserve analyzer-owned facts,
source evidence, explicit unknowns, reviewed corrections, and safe legacy
fallbacks throughout the migration.

## Scope

This consolidated task replaces the individual implementation, extraction,
routing, evaluation, benchmark, and contract tasks created during the migration.
It covers:

- The project-owned `src/arch-analyzer` Go module for extraction, normalization,
  evidence tracking, rendering, schemas, and cross-language source analysis.
- Production integration that builds the local analyzer, writes component-local
  analyzer artifacts, renders `ANALYZER_ARCHITECTURE.md`, and keeps generated
  architecture documents structurally compatible.
- Analyzer-first routing, bounded partial/evidence-gated synthesis, analyzer
  baseline preservation, reviewed overlays, correction proposals, and explicit
  legacy fallback for missing or invalid analyzer context.
- Analyzer coverage, complete-empty findings, source-read justification,
  provenance, telemetry, runtime diagnostics, and deterministic merge/validation
  contracts.
- Corpus replay, consumer evaluation, regression scoring, targeted migration
  runs, and the validation needed to measure preservation, quality, cost, and
  runtime without treating historical agent output as authoritative fact.
- Skill and template changes that constrain agents to narrative synthesis and
  source-backed residual gaps instead of rediscovering analyzer-owned facts.

## Result

The migration is implemented and the iteration history is consolidated here.
The current production policy is recorded in `PLAN.md` and the supporting plans
and notes linked below:

- Valid analyzer artifacts use the bounded partial/extend-and-improve route for
  all readiness classifications. Synthesis is retained as an audit/migration
  allowlist path; legacy is reserved for missing or invalid artifacts and
  explicit operator override.
- The local analyzer is the runtime dependency; the cloned upstream analyzer is
  no longer required for normal generation.
- Structured analyzer facts remain authoritative through synthesis and merge.
  Agent-authored narrative and explicitly evidenced residual corrections remain
  bounded and reviewable.
- Analyzer artifacts are stored with each component under `.analyzer`, while
  final component documents are promoted only after validation.
- The current registries contain 62 analyzer-only approvals and 4 synthesis
  migration entries. Remaining unsupported behavior stays visible in the
  residual register rather than being promoted to deterministic absence.

## Validation and evidence

- [Component analyzer migration plan](../../plans/architecture-context-static-migration.md)
- [Analyzer-assisted agent architecture plan](../../plans/architecture-context-static-migration.md)
- [Analyzer ownership migration v1 milestone](../../milestones/analyzer-ownership-migration-v1.md)
- [Architecture context static migration plan](../../plans/architecture-context-static-migration.md)
- [Analyzer residual agent gaps](../../notes/architecture-context-static-migration.md)
- [Analyzer-assisted evaluation contract](../../notes/architecture-context-static-migration.md)
- [Analyzer-assisted targeted synthesis validation](../../notes/architecture-context-static-migration.md)

The implementation includes focused Python and Go tests, architecture/schema
validation, static replay, bounded route matrices, consumer benchmark checks,
and recorded telemetry. Generated architecture outputs remain separate from
this task summary and are evaluated through the migration’s preservation and
quality gates.

## Remaining follow-ups

These are deliberately not folded into the completed migration task:

- [Replace Markdown change records with a JSON patch contract](../pending/replace-markdown-change-record-with-json-patch.md)
  is pending workflow hardening.
- [Resolve external analyzer-assisted rollout gates](../blocked/resolve-external-analyzer-assisted-rollout-gates.md)
  remains blocked on external services and human adjudication; it does not
  block local implementation or the provisional analyzer-assisted track.

## Status

Done on 2026-08-03. The former iteration task files were consolidated into this
single record; detailed implementation evidence remains in the plans, notes,
milestone, source history, and validation artifacts above.
