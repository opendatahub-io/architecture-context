# Task: Add rhoai.next Versus Backup Evaluation Wrapper

## Goal

Provide one command for comparing the current `architecture/rhoai.next` tree
with the prior `architecture/rhoai.next.bak` tree using the validated
architecture-only consumer corpus.

## Changes

- Added `scripts/run_consumer_v1_rhoai_next_vs_bak_eval.sh`.
- The wrapper derives the 40-question `architecture` slice from
  `benchmark/strategy-v1/corpus.json` before evaluation.
- `--all-domains` enables an explicit diagnostic run over all 60 questions and
  creates a temporary condition manifest so the planner schedules the
  `pipeline` and `sme-context` IDs too.
- All-domain mode skips the canonical 40-question analyzer-assisted manifest
  validation, which is not the source corpus for that diagnostic run.
- Extended the existing consumer-v1 wrapper to accept a custom corpus path for
  validation and scoring.
- Reused the existing consumer-v1 evaluation, tree sanitization, and report
  pipeline.
- Defaulted Tree A to `architecture/rhoai.next.bak` and Tree B to
  `architecture/rhoai.next`.
- Kept output under an untracked timestamped `tmp/evaluations` directory.

## Status

Accepted 2026-07-30 after shell syntax and dry-run validation.
