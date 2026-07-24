# Task: Approve Adjudicated-to-Zero Mutation Components

## Goal

Approve three analyzer-sufficient components whose historical agent corrections
have all been adjudicated as invalid evidence, enabling analyzer-only routing
without any new extraction work.

## Context

After the v1 adjudication pass, three components have zero unresolved mutations.
All their historical corrections cited evidence from demo/, benchmarks/, or
examples/ directories and were recorded as invalid in
`lib/analyzer_correction_adjudications.json`. These components are
analyzer-sufficient but remain agent-routed because they were never formally
approved.

The question for each is whether, after adjudication removes all corrections,
the analyzer's category coverage contracts still pass. If every high-value
category is either populated with analyzer facts or provably empty for that
component, the component can be added to `lib/analyzer_only_approvals.json`.

## Source And Evidence

- Adjudications: `lib/analyzer_correction_adjudications.json`
- Eligibility report:
  `tmp/architecture-corpus-runs/rhoai.next-20260720T173035Z-static/reports/eligibility-v1.json`
- Residual register: `docs/notes/analyzer-residual-agent-gaps.md`

## Target Components

| Component | Adjudicated | Evidence class | Blocker |
|-----------|------------:|----------------|---------|
| `caikit-tgis-serving` | 8/8 | `demo/kserve/custom-manifests/` | Demo-only deployment manifests; no shipped production deployment evidence. |
| `distributed-workloads` | 4/4 | `benchmarks/`, `examples/` | Benchmark/example collection with no shipped service. |
| `vllm-cpu` | 3/3 | `benchmarks/` | Benchmark client-side corrections invalid; server auth may need Python FastAPI extraction. |

### vllm-cpu Conditional

The residual register notes that `vllm-cpu` server-side auth "needs Python
FastAPI extraction." If the eligibility replay shows an empty Authentication
category that requires population (not just absence-of-auth), then `vllm-cpu`
depends on the Python runtime extraction task
(`docs/tasks/pending/extract-python-runtime-source-surfaces.md`) and should be
deferred.

## Work

1. Run the 90-component eligibility replay for each target component.
2. For each component, verify that all high-value categories (Authentication,
   Internal Dependencies, Integration Points, Architecture Components) are
   either populated by analyzer facts or provably empty.
3. For provably-empty categories, document why the category is legitimately
   empty (e.g., no shipped entrypoint, no applicable runtime behavior).
4. If all categories pass, add the component to
   `lib/analyzer_only_approvals.json`.

## Negative Controls

- Must not approve a component with an empty high-value category that should
  be populated (e.g., a FastAPI server with no Authentication facts).
- Must not approve without running a fresh 90-component replay.
- Must not bypass the eligibility threshold by lowering coverage requirements.

## Acceptance Criteria

- [ ] Run a fresh 90-component replay with zero false nominations.
- [ ] Each approved component passes all category coverage contracts.
- [ ] For components not approved, document the specific blocking category
  and what extraction work is needed.
- [ ] Update `lib/analyzer_only_approvals.json` for approved components.
- [ ] Update `docs/notes/analyzer-residual-agent-gaps.md` to reflect
  dispositions.
- [ ] Run a bounded one-component production matrix if approval changes
  routing.
- [ ] Write a validation note and move this task to `docs/tasks/done/`.

## Likely Files

- `lib/analyzer_only_approvals.json`
- `lib/analyzer_correction_adjudications.json`
- `lib/architecture_routing.py`
- `docs/notes/analyzer-residual-agent-gaps.md`

## Status

Done. caikit-tgis-serving and distributed-workloads approved for analyzer-only
routing via source-audited empty category mechanism. vllm-cpu deferred — real
`AuthenticationMiddleware` requires Python runtime extraction. Validation note:
`docs/notes/adjudicated-zero-mutation-approval-2026-07-20.md`.
