# Bug: Consumer V1 Rolling File Count Question Is Brittle

## Summary

`NAV-008` asks for a static count of Markdown files in the rolling
`rhoai.next` architecture directory. The clean rerun at `20260729T120959Z`
showed both materialized eval trees contained 98 top-level Markdown files,
while the corpus expected 94.

## Evidence

- Evaluation report:
  `tmp/evaluations/consumer-v1-rhoai-next-20260729T120959Z/report.md`
- Question: `NAV-008`
- Expected answer: 94 Markdown files, including `PLATFORM.md` and `README.md`
  alongside 92 component docs.
- Observed clean eval trees: 98 top-level Markdown files in both Tree A and
  Tree B.

## Impact

LOW to MEDIUM — the question creates noisy regressions for a rolling target.
It measures artifact drift more than consumer navigation quality unless pinned
to an immutable architecture snapshot.

## Expected

Retire the question, retarget it to a pinned immutable artifact, or change it
to validate navigability without relying on an exact rolling file count.

## Status

Fixed 2026-07-30 by retargeting `NAV-008` to architecture-tree layout instead
of an exact file count. The question now asks where component architecture
documents are stored in `rhoai.next` and which platform-level architecture file
accompanies them. The expected answer covers the flat top-level Markdown
layout and `PLATFORM.md`.

The four-file Tree A/Tree B name delta from the clean rerun was:

- Missing from Tree B relative to Tree A: `README.md`,
  `llm-d-batch-gateway.md`, `llm-d-model-service.md`,
  `llm-d-workload-variant-autoscaler.md`.
- Added in Tree B relative to Tree A: `llama-stack-provider-ragas.md`,
  `models-perf-benchmark-data.md`, `rhds-llama-stack-distribution.md`,
  `training_hub.md`.

Follow-up completed in
`docs/tasks/done/rework-consumer-v1-rolling-inventory-questions.md`.
Because the prompt text changed, old raw results for the former count question
are not semantically comparable; focused `NAV-008` re-evaluation should be
used to verify model behavior against the new layout question.

Focused re-evaluation `20260730T020654Z` verified both trees answered the new
layout question correctly and cited sources. Initial focused scores were
`0.5`/`0.5` because deterministic exact-match variants did not include the
observed "individual Markdown files at/directly in the tree root" phrasing.
Those narrow variants were added to the corpus.

The `20260731T215257Z` full rerun found one remaining variant gap: Tree B said
component documents were "at the root level of the tree directory," which is
semantically equivalent but was not accepted. The corpus now includes that
phrase as an additional navigation variant; this is a scoring-rubric fix, not
an architecture-tree change.
