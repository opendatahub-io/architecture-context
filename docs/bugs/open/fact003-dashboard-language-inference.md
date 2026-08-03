# Bug: FACT-003 Dashboard Language Inference

## Problem

The fresh analyzer-assisted `rhoai.next` generation reports `Go, Python,
TypeScript` for `odh-dashboard`, while the benchmark expects the runtime
languages `Go` and `TypeScript`. The generated metadata appears to promote a
Python source/dependency signal into a primary language classification.

## Evidence

- Benchmark: `tmp/evaluations/consumer-v1-rhoai-next-20260802T234823Z/`
- Candidate: `tmp/architecture-corpus-runs/rhoai.next-20260802T222449Z-2813199/architecture/rhoai.next/odh-dashboard.md`
- Candidate metadata: `Languages: Go, Python, TypeScript`
- Tree A metadata: `Languages: TypeScript, Go`
- Regression: `FACT-003` exact match, Tree A `pass` and Tree B `fail`

## Expected Behavior

Primary language metadata should represent shipped/runtime implementation
languages. Python package or utility-source signals must not add Python unless
the component has a Python runtime or shipped Python application.

## Scope

Determine whether the fix belongs in analyzer language classification or the
summary skill's metadata-preservation contract. Add focused regression coverage
and rerun the targeted dashboard generation before a full benchmark.
