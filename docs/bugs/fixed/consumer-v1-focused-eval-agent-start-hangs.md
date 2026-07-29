# Bug: Consumer V1 Focused Eval Agent Start Hangs

## Summary

Focused `consumer-v1` evaluator runs hung in the Codex sandbox in Phase 1
before the first answer body was written to the per-question log.

## Evidence

On 2026-07-29, focused reruns for `FACT-005` reached Phase 1 and created only
the Tree A log header:

- `tmp/evaluations/consumer-v1-rhoai-next-20260729T205600Z/logs/FACT-005_tree_a.log`
  using Opus.
- `tmp/evaluations/consumer-v1-rhoai-next-20260729T210900Z/logs/FACT-005_tree_a.log`
  using Opus with an outer `timeout 900`.
- `tmp/evaluations/consumer-v1-rhoai-next-20260729T211300Z-sonnet/logs/FACT-005_tree_a.log`
  using Sonnet with an outer `timeout 900`.

Each attempt was interrupted manually after the log remained at only the prompt
header. No `raw-results.json`, `scored-results.json`, or `report.md` was
written for these attempts.

## Impact

LOW — the symptom blocked the sandboxed validation attempt, but a host-run full
benchmark completed successfully and produced scored results for all 40
questions.

## Expected

The evaluator should either complete the question or fail with a bounded,
diagnostic error that records the model/session state in `raw-results.json`.

## Status

Fixed as not reproduced in the host-run benchmark. The user-run
`./scripts/run_consumer_v1_rhoai_next_eval.sh` completed at
`tmp/evaluations/consumer-v1-rhoai-next-20260729T215258Z/`, wrote raw/scored
results and a report, and evaluated all 40 questions. No repository code change
was made for this sandbox-only symptom.
