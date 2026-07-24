# Task: Extract Runtime Command Components

## Goal

Extract shipped Go executable components by correlating non-test `main` packages
with concrete build targets, starting with the three `batch-gateway` processes.

## Context

`batch-gateway` has three accepted Architecture Component additions. All three are
real executable commands, but treating every `package main` as a product component
would also promote examples, migration tools, generators, and developer utilities.

The repository independently proves that its three commands are shipped: production
Dockerfiles run `go build -o bin/<artifact> ./cmd/<path>`. The command package docs
and runtime lifecycle distinguish the API service from the processor and garbage
collector workers.

The accepted agent identity `batch-apiserver` differs from both the build artifact
and historical fixture identity `batch-gateway-apiserver`. The analyzer must keep
the source-derived identity and either normalize a proven equivalent or record the
agent spelling as an accepted correction mismatch; it must not invent a
component-name exception.

## Acceptance Criteria

- [x] Extract a Go command only when a non-test, non-generated `main` package with a
  concrete `main` function is selected by a shipping build invocation.
- [x] Parse structured Dockerfile build instructions and correlate the `go build`
  package argument to the command package and its `-o` artifact name.
- [x] Derive component identity from the build artifact, not the repository or an
  analyzer-specific alias table.
- [x] Emit separate command components only when the repository ships multiple
  distinct commands; leave a sole repository binary to its deployment/repository
  identity rather than creating a redundant generic `manager` component.
- [x] Preserve source-backed command documentation and lifecycle evidence in the
  component purpose/type without inferring unsupported request flows.
- [x] Reject unbuilt examples, support tools, test commands, malformed build
  instructions, and build targets whose package has no executable `main` function.
- [x] Deduplicate the same command built by standard and Konflux Dockerfiles while
  retaining stable source evidence.
- [x] Resolve or source-adjudicate the three accepted `batch-gateway` Architecture
  Component corrections, including the `batch-apiserver` naming discrepancy.
- [x] Keep `batch-gateway` agent-routed while Authentication and inference-gateway
  residuals remain.
- [x] A fresh 90-component replay has zero false approved nominations and passes
  preservation, structural, and synthesis gates.

## Files Likely Involved

- `src/arch-analyzer/internal/extractor/dockerfile.go`
- `src/arch-analyzer/internal/gosource/`
- `src/arch-analyzer/internal/model/input.go`
- `src/arch-analyzer/internal/normalize/normalize.go`
- `scripts/analyze_analyzer_only_eligibility.py`
- `lib/analyzer_correction_adjudications.json`

## Status

Completed

## Baseline Evidence

- Replay:
  `tmp/architecture-corpus-runs/rhoai-next-runtime-data-clients-static-20260719T160816Z`
- Checkout: `fac0c8d8c69369662d46edf1bfecacf3bd15b5d2`
- API server build:
  `docker/Dockerfile.apiserver:23`
- Processor build:
  `docker/Dockerfile.processor:23`
- Garbage collector build:
  `docker/Dockerfile.gc:14`
- Command entry points:
  `cmd/apiserver/main.go:29`, `cmd/batch-processor/main.go:44`, and
  `cmd/batch-gc/main.go:48`

## Progress

- Source audit selected build-to-command correlation over unconditional `cmd/`
  discovery because it establishes that the executable is shipped.
- The historical fixture uses the exact build-artifact identities. The accepted
  production pass shortens only the API server identity, so naming must be resolved
  explicitly rather than silently treating either agent document as ground truth.
- The extractor found shipped multi-command layouts in nine repositories. Focused
  tests cover positive build/runtime correlation, line continuations, local file
  targets, standard/Konflux deduplication, sole-command suppression, and negative
  test/example/malformed cases.
- Three reviewed correction adjudications preserve the exact `batch-gateway-*`
  build identities and reject the accepted agent's shortened duplicate additions.
- Replay
  `tmp/architecture-corpus-runs/rhoai-next-runtime-commands-static-20260719T162833Z`
  passed all gates with 32 approvals, zero false nominations, and 7/11 resolved or
  adjudicated `batch-gateway` corrections. See
  [runtime command component validation](../../notes/runtime-command-components-validation-2026-07-19.md).
