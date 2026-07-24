# Task: Build Post-Migration Consumer Benchmark

## Goal

Create a versioned, reviewable benchmark corpus that measures the architecture
questions downstream RFE and strategy skills actually need to answer.

## Prerequisite

[Capture Analyzer Migration V1 Baseline](capture-analyzer-migration-v1-baseline.md)
must be complete.

## Work

- Reuse the tiers and rubric in
  [Architecture-Context Benchmark Design](../../plans/architecture-context-benchmark.md).
- Start with a bounded 40-question corpus: component inventory, component facts,
  cross-component integrations, and navigation/overlay behavior.
- Prefer real, deduplicated RFE and strategy-review questions. When production
  traces are unavailable, use the documented examples and record that provenance.
- Store each question with its tier, consumer, expected answer, acceptable variants,
  source evidence, scope, and whether an honest "not documented" answer is expected.
- Establish ground truth from source, overlays, or reviewed domain evidence rather
  than copying either candidate document verbatim.
- Define a machine-readable schema and deterministic corpus validation.

## Acceptance Criteria

- [ ] The corpus has ten reviewed cases in each of the four benchmark tiers.
- [ ] Cases cover `PLATFORM.md`, component documents, overlay precedence,
  integrations/data flows, authentication/security, and known information gaps.
- [ ] Every expected factual claim has a reviewable source or an explicit domain
  reviewer decision.
- [ ] Corpus validation rejects missing evidence, duplicate identifiers, and invalid
  expected-answer types.
- [ ] A README documents how to extend and version the corpus without contaminating
  the evaluation.
- [ ] The task is moved to `docs/tasks/done/` and the follow-on plan is updated.

## Status

Pending.

