# Define a Condition-Aware Canary Report

Added a deterministic, non-executing canary manifest and readiness report for
the analyzer-assisted condition experiment.

The canary fixes ten active question IDs across all four corpus tiers and
records corpus, experiment, and condition identities. The report emits sorted
machine-readable cells for planned, available, unavailable, and missing-result
states; detects no-fallback, provenance, condition-status, and coverage
violations; and keeps score status explicitly unavailable. It accepts
consumer-v1 raw-results envelopes with nested `results` records without
computing scores.

Validation: 207 focused tests passed, Ruff and `git diff --check` passed, the
default report had 10 planned and 30 unavailable cells with zero violations,
and a nested consumer-v1 result artifact resolved as available with score
status unavailable. No agents or evaluations were launched.
