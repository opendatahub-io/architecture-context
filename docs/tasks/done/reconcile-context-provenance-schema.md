# Task: Reconcile Context Provenance with the Evaluation Schema

## Goal

Make the analyzer-assisted result schema and deterministic validator accept and
validate the context telemetry/provenance fields emitted by the evaluation
runner, without weakening provenance or allowing malformed telemetry.

## Acceptance criteria

- [x] Emitted per-tree context provenance and condition-level provenance
  validate against the schema.
- [x] Malformed, missing-required, wrong-version, and unpaired telemetry fields
  are rejected deterministically.
- [x] Legacy records with neither optional context provenance field remain
  valid; existing provenance and failure-classification checks remain intact.
- [x] 98 focused contract tests pass, telemetry regressions pass, the
  analyzer-assisted validator passes, Ruff passes, JSON parses, and diff checks
  pass.
- [x] No evaluation, MLflow run, or paid benchmark API call was performed.

## Implementation summary

Added versioned per-tree `context_provenance` and condition-level telemetry
provenance to `result_schema.json`, including serialized event kinds and nested
context metrics. Updated `validate.py` to enforce exact
`lib.context_telemetry.CONTRACT_VERSION`, event shape, and all-or-none pairing
of condition-level telemetry fields. Added focused valid, malformed, legacy,
and pairing tests.

## Validation

- Container: 98 focused tests passed, analyzer-assisted validator PASS, Ruff
  PASS, `git diff --check` PASS.
- Host: JSON parse, Python compilation, validator, and diff checks passed.
- Host `.venv` pytest was unavailable due a stale `/workspace/.venv` shebang;
  container evidence is authoritative for the focused suite.
- Delegated container runs cost $4.6117015 total; no evaluation or MLflow run.

## Status

Accepted 2026-07-25 after independent review. Checkpoint commit follows.
