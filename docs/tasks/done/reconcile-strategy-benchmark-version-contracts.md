# Task: Reconcile Strategy Benchmark Version Contracts

## Goal

Separate rolling `rhoai.next` version drift and ambiguous component contracts
from generation regressions in the strategy comparison corpus.

## Evidence

The post-regeneration comparison at
`tmp/evaluations/consumer-v1-rhoai-next-vs-bak-20260801T003432Z/` still flags
`INV-001`, `INV-010`, `FACT-010`, and `FACT-004`:

- current platform metadata reports 97 analyzed components rather than the
  backup's 92;
- current platform metadata reports `97+` images rather than the backup's
  474;
- current KubeRay documentation includes a different CRD set than the corpus
  expected answer;
- the `model-registry` question is ambiguous because both the service and
  `model-registry-operator` are documented components.

These are corpus/version-contract issues unless a pinned source comparison
shows evidence was lost during generation.

## Plan

1. Pin each expected answer to a documented architecture snapshot or make the
   question explicitly version-relative.
2. Rewrite `FACT-004` to name the model-registry service or operator directly.
3. Reconcile KubeRay CRD scope against current source and document the chosen
   core-versus-configuration contract.
4. Re-score unchanged raw results where semantics remain valid and run focused
   evaluations for changed questions.

## Acceptance Criteria

- Inventory and CRD count changes are reported as version drift, not synthesis
  regressions.
- The model-registry question has one unambiguous subject.
- The corpus and its README identify the snapshot/version assumptions.
- No generated architecture document is edited solely to satisfy stale counts.

## Status

Complete — 2026-08-01.

## Resolution

- Bumped both synchronized architecture corpus contracts to `1.0.1` and
  pinned them to the current architecture-context revision used for the
  comparison.
- Made rolling inventory values snapshot-relative for component count, CRD
  count, and shipped-image count. Accepted both the backup values and the
  current `rhoai.next` values without editing generated documents to satisfy
  stale expectations.
- Updated KServe deployment wording to accept the current Kubernetes
  Operator / Controller label and the older detailed classification.
- Re-authored `FACT-004` to ask specifically about the model-registry service,
  separate from model-registry-operator.
- Reconciled KubeRay as 4 core CRDs and 5 total CRD/API rows in the current
  snapshot, while retaining the backup's 4-CRD contract.
- Added equivalent citation and wording variants for InstructLab and the flat
  top-level architecture layout.
- Rescored the unchanged 40-question raw result at
  `tmp/evaluations/consumer-v1-rhoai-next-vs-bak-20260801T133940Z/` against
  corpus `1.0.1`: Tree A `0.6208`, Tree B `0.6667`, with no regressions.
