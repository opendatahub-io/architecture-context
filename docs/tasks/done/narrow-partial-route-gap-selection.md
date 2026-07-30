# Task: Narrow Partial Route Gap Selection

## Goal

Reduce partial-route runtime by avoiding broad generic gap bundles when
category-specific analyzer evidence is already populated enough for bounded
extend-and-improve synthesis.

## Context

`docs/bugs/open/partial-route-component-runtime-remains-high.md` remains open
after the 2026-07-30 follow-up measurement. The latest 97-component run
succeeds, but 49 components still exceed 300s and most slow components receive
the same broad gap categories: authentication, integration points, internal
dependencies, HTTP endpoints, gRPC services, and services.

The route planner already honors `category_coverage.status == complete`, but
`partial` category coverage always keeps a category routed even when the
baseline table is populated and the partial limitation is only generic dynamic
resolution.

## Plan

1. Add route-planner logic that uses baseline table counts plus
   `category_coverage` to distinguish actionable partial categories from
   already-populated structural evidence.
2. Keep safety-critical categories conservative.
3. Add focused tests for populated structural categories and representative
   slow-component patterns.
4. Update the runtime bug and session log with the implementation result.

## Acceptance Criteria

- Partial categories with complete `category_coverage` remain suppressed.
- Safety-critical categories such as authentication remain routed when partial.
- High-value empty categories, category-covered zero-fact structural
  categories, and concrete unaccounted/unsupported evidence remain routed.
- Structural categories with populated baseline evidence and only generic
  dynamic-resolution limitations are no longer routed solely because broad
  analyzer coverage is partial.
- Focused routing tests pass.

## Status

Completed on 2026-07-30.

Implemented in `lib/architecture_routing.py`:

- category-specific partial coverage now suppresses generic structural gaps
  when the analyzer has populated facts/evidence and only generic dynamic
  resolution limitations;
- concrete unaccounted/unsupported limitations remain routed;
- partial safety-critical category coverage remains routed;
- empty baseline tables no longer nominate every low-priority category by
  themselves.

Local policy simulation over the current 97 `architecture/rhoai.next`
analyzer artifacts changed the routed gap-count distribution to:

| Gap count | Components |
|---:|---:|
| 2 | 1 |
| 3 | 15 |
| 4 | 40 |
| 5 | 18 |
| 6 | 23 |

Representative slow components:

| Component | Routed gaps after fix |
|---|---|
| `models-as-a-service` | authentication, integration_points, internal_dependencies, grpc_services |
| `llm-d-inference-scheduler` | authentication, integration_points, services |
| `odh-deployer` | authentication, integration_points, internal_dependencies, http_endpoints, grpc_services, services |
| `eval-hub` | authentication, integration_points, internal_dependencies, grpc_services, services |

Validation:

```bash
uv run pytest tests/test_architecture_routing.py -q -k 'populated_structural or unaccounted_structural or safety_critical_partial or category_contract_overrides or partial_policy_derives or batch_gateway or sparse_sufficient or explicit_language_coverage'
```

Result: 8 passed. Full `tests/test_architecture_routing.py` still has the
pre-existing unrelated failure
`test_synthesis_guard_denies_full_write_to_preseeded_output`.
