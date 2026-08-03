# Bug: FACT-008 Per-Route Authentication Benchmark Contract

## Problem

The generated MLflow document explicitly states that individual FastAPI
gateway routes have no per-route middleware and that authentication is applied
at the server level. `FACT-008` still marks the answer as a gap-acknowledgment
failure because its scorer only recognizes wording such as `not documented` or
`known residual gap`.

## Evidence

- Benchmark: `tmp/evaluations/consumer-v1-rhoai-next-20260802T234823Z/`
- Candidate: `tmp/architecture-corpus-runs/rhoai.next-20260802T222449Z-2813199/architecture/rhoai.next/mlflow.md`
- Candidate states: `no per-route middleware in gateway router` and documents
  server-level authentication.
- Regression: `FACT-008` gap acknowledgment, Tree A `pass` and Tree B `fail`

## Expected Behavior

The benchmark must accept an evidence-backed answer that distinguishes “the
output does not document per-route enforcement” from “the source has no
per-route middleware.” Both are valid answers to the consumer question when
the response clearly answers `No` and cites the architecture document.

## Scope

Update the corpus variants or gap scorer contract, add focused regression tests,
and rerun `FACT-008`. Do not weaken source-citation or fabrication checks.
