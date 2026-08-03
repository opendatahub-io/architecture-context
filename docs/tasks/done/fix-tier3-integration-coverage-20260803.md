# Fix Tier 3 Integration Coverage

## Goal

Improve Tier 3 cross-component benchmark coverage without treating verbose
source-backed answers as exact-match failures.

## Plan

1. [x] Add structured required-fact groups and synonym handling to the scorer.
2. [x] Validate the structured contract against the completed 40-question run.
3. [x] Synchronize the DSPO dependency contract for `INTG-001` to the current
   generated source.
4. [x] Align the training workflow contract for `INTG-008` with the currently
   documented Kueue and worker-pod sequence.
5. [x] Align the serving-path contract for `INTG-010` with the current MaaS
   Envoy ExtProc terminology and remove the absent KNative requirement.
6. [x] Rescore the completed raw run and verify the synchronized contract.

## Evidence

On raw results from
`tmp/evaluations/consumer-v1-rhoai-next-20260803T001316Z/`, structured scoring
first raised Tree B from `0.6333` to `0.7417` overall and from `0%` to `70%`
exact matches for Tier 3. After synchronizing the three stale contracts,
rescoring raised Tree B to `0.7792` overall, with Tier 3 at `100%` exact match
and `95%` composite, and the report found no regressions.
