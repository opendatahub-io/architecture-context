# Add Consumer V1 rhoai.next Evaluation Wrapper

## Status

Done — 2026-07-28

## Context

After a fresh `rhoai.next` generation completed and passed structural
prechecks, the consumer-v1 benchmark command sequence needed a reusable wrapper
that writes raw results under `tmp/` instead of the committed benchmark results
tree.

## Changes

- Added `scripts/run_consumer_v1_rhoai_next_eval.sh`.
- Defaults to comparing `tmp/architecture-context/architecture/rhoai.next` against
  `architecture/rhoai.next`.
- Writes to a timestamped `tmp/evaluations/consumer-v1-rhoai-next-*`
  directory by default.
- Runs benchmark/corpus/manifest validation and architecture-doc lint before
  launching evaluation agents.
- Runs evaluation, scoring, and Markdown report generation in sequence.
- Supports `--dry-run`, `--question-id`, `--model`, `--max-concurrent`,
  `--seed`, `--condition`, `--tree-a`, `--tree-b`, and `--output-dir`.

## Validation

- `bash -n scripts/run_consumer_v1_rhoai_next_eval.sh`
- `scripts/run_consumer_v1_rhoai_next_eval.sh --dry-run --question-id FACT-001`

## Amendment — 2026-07-28

Changed the default tree A baseline from `architecture/rhoai.next.bak` to
`tmp/architecture-context/architecture/rhoai.next` so the wrapper compares the
prior generated architecture-context tree against the current generated tree.
