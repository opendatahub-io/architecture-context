# Task: Establish Analyzer-First Platform Viability

## Goal

Establish whether `ANALYZER_ARCHITECTURE.md` can replace most repository discovery
without paying for a full 90-agent production run before the approach is proven.

## Acceptance Criteria

- [x] Preserve a same-model control run using the legacy repository-exploration path.
- [x] Run the production static phase across all configured `rhoai.next` components.
- [x] Run same-revision representative analyzer-first component workflows.
- [x] Record static and component-agent timings independently.
- [x] Compare component documents by category and audit missing and conflicting facts.
- [x] Record readiness fallbacks and targeted source-read behavior across the corpus.
- [x] Set the next extractor and agent-preservation gates.
- [x] Confirm that `PLATFORM.md` synthesis and diagram implementation are unchanged.

## Status

Done on 2026-07-17.

## Notes

The four-repository technical corpus already shows 0.05-0.51 second extraction,
sub-0.01-second rendering, validator-clean Markdown, and strong identity coverage
for service-style repositories. This task measures the actual reduction from the
current approximately one-hour, ten-worker platform run; it should not change the
extractor before collecting the first full-corpus gap report.

## Initial Full-Corpus Finding

The first `rhoai.next` pass exposed two gates that the four-repository corpus did not:

- Repository robustness initially failed on templated YAML, strategic patches under
  modern `patches`, missing generated resources, and template helpers. After making
  these explicit partial-coverage cases, 89/89 mapped repositories extract and render
  successfully, and every rendered document passes structural validation.
- Exact structured identity recall is only 879/6109 (14.39%) across all 89 documents.
  Twenty-five repositories emit no high-value facts, primarily because 26 repositories
  use Python while the initial language corpus covered Go, TypeScript, and Rust.

This evidence rejected an unconditional analyzer-only skill path. Python/package/API
extraction and a minimum-coverage fallback gate were implemented before the agent A/B.

## Completed Evidence

- The production phase analyzed 90/90 components, rendered 90/90 Markdown baselines,
  extracted 325 CRD schemas, and failed zero components in 27.80 seconds with 10
  workers and `--force`.
- The stricter readiness gate classifies 65 components as sufficient, 17 as partial,
  and eight as insufficient. Only the insufficient set permits full legacy discovery.
- The same-model `caikit-nlp` control took 541 seconds; analyzer-first took 285
  seconds, reduced tool calls from 45 to 33, reduced cost from $0.962 to $0.556,
  and improved exact fixture recall from 37.89% to 40.00%.
- A copy-and-edit caikit treatment took 239 seconds and remained within 1.05 exact
  recall points of control, proving the deterministic Markdown can be retained rather
  than regenerated.
- The dashboard treatment retained the same 141/165 structured identities as the
  analyzer input while reading eight targeted files, making 19 tool calls, and
  spawning no sub-agents.
- No code in the `PLATFORM.md` synthesis or diagram phases changed.

The full 90-component agent run was intentionally not incurred. It would measure the
final production wall time but is no longer needed for the viability decision: the
static phase is proven on the full platform, the coverage fallback is explicit, and
the controlled agent A/B shows material savings without a quality regression.
