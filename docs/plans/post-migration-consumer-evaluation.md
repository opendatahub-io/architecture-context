# Post-Migration Consumer Evaluation

**Status**: Pending; starts after
[Analyzer Ownership Expansion](../goals/analyzer-ownership-expansion.md) is complete.

## Goal

Freeze the completed `arch-analyzer` migration as a reproducible v1 baseline,
measure whether its collected Markdown supports real architecture-context consumers
as well as the accepted agent-generated documents, and convert measured failures
into a prioritized v2 improvement backlog.

This plan operationalizes the existing
[benchmark design](architecture-context-benchmark.md) using the consumer behavior in
the [skill ecosystem overview](../notes/skill-ecosystem-overview.md). It does not
extend the current extractor migration or assume that historical agent prose is
ground truth.

## Sequence

1. [Capture the analyzer migration v1 baseline](../tasks/pending/capture-analyzer-migration-v1-baseline.md), including a small consumer smoke test.
2. [Build the post-migration consumer benchmark](../tasks/pending/build-post-migration-consumer-benchmark.md) from real RFE and strategy use cases.
3. [Run the analyzer v1 consumer A/B evaluation](../tasks/pending/run-analyzer-v1-consumer-ab-evaluation.md) against the accepted agent baseline.
4. [Triage the analyzer v2 quality backlog](../tasks/pending/triage-analyzer-v2-quality-backlog.md) from observed failures.

## Boundaries

- Evaluate the collected `architecture/<version>/*.md`, `PLATFORM.md`, and overlay
  contract that downstream skills actually consume.
- Keep analyzer extraction, static synthesis, platform synthesis, navigation,
  freshness, and downstream-access failures as separate classifications.
- Treat `arch-query` adoption and fetch-script consolidation as separate consumer
  integration work unless evaluation evidence identifies them as the bottleneck.
- Do not reopen migration v1 for stylistic prose differences that do not affect
  accuracy, grounding, scope awareness, or gap acknowledgment.

## Completion

The plan is complete when the v1 baseline and benchmark are reproducible, the A/B
report quantifies downstream quality and cost, and every material regression has an
evidence-ranked v2 task or an explicit no-action decision.

