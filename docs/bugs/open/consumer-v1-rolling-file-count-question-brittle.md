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

Open.
