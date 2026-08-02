# Task: Reconcile KServe Deployment Classification

## Goal

Restore an evidence-backed KServe deployment classification that captures the
operator, SDK, and sidecar roles without hardcoding the backup document's
wording or allowing synthesis to overwrite analyzer-owned metadata.

## Evidence

The post-regeneration comparison at
`tmp/evaluations/consumer-v1-rhoai-next-vs-bak-20260801T003432Z/` flags
`FACT-001`. The backup document answers
"Operator (multi-controller) + Python SDK + Sidecar utilities," while the
regenerated document says only "Kubernetes Operator / Controller." The KServe
targeted replay reproduced the generic analyzer-owned deployment type, while
`arch-doc` correctly preserved the rest of the analyzer tables.

## Plan

1. [x] Trace how deployment type is classified and which analyzer facts identify
   controllers, SDKs, sidecars, and shipped runtime roles.
2. [x] Decide that the missing detail belongs in an analyzer-derived metadata
   projection, with the source rows remaining analyzer-owned.
3. [x] Implement the evidence-driven representation and update the skill contract
   without embedding KServe-specific strings.
4. [x] Add unit fixtures for nested Python SDK metadata, pod mutation evidence,
   and composite deployment roles.
5. [x] Re-evaluate `FACT-001` and confirm analyzer-row preservation remains
   100%.

## Acceptance Criteria

- The classification is derived from analyzer/source evidence, not a
  component-name conditional or hardcoded expected answer.
- The final KServe document distinguishes its controller, SDK, and sidecar
  roles when those facts are present.
- Analyzer-owned tables remain unchanged through assembly.
- `FACT-001` no longer flags for an evidence-backed reason.

## Validation

- Unit tests and `go vet` pass for `src/arch-analyzer`.
- The isolated KServe replay completed successfully. The final document passed
  `arch-doc validate`, preserved the composite deployment classification, and
  retained 589 analyzer-owned sections unchanged. One stale authentication
  proposal was rejected.
- Focused benchmark `tmp/evaluations/consumer-v1-rhoai-next-20260801T224523Z/`
  scored `FACT-001` at `1.0` for both Tree A and Tree B with no regressions.

## Status

Complete — the deployment classification is evidence-derived, the agent and
assembly path preserve it, and the focused contract benchmark passes. A full
canonical regeneration and architecture benchmark remain broader follow-up
validation, not blockers for this task.
