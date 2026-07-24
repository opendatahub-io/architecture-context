# Check-Eligibility CLI Command Validation

Date: 2026-07-21

## Summary

Added `check-eligibility` CLI subcommand that runs `analyzer_only_eligibility()`
against all components, always reading `ANALYZER_ARCHITECTURE.md` from checkout
directories. This prevents the false-positive class discovered in the batch
review, where ad-hoc checks read agent-written `GENERATED_ARCHITECTURE.md` via
collected `architecture/rhoai.next/` files.

## Implementation

### Files changed

| File | Change |
|------|--------|
| `lib/cli.py` | Added `check-eligibility` subparser with `--platform` and optional component positional args |
| `lib/phases/eligibility.py` | New module: enumerates checkouts via component-map.json, reads `ANALYZER_ARCHITECTURE.md` + `component-architecture.json`, calls `analyzer_only_eligibility()` |
| `lib/phases/orchestration.py` | Added dispatch for `check-eligibility` command |

### Design decisions

- Reuses `analyzer_only_eligibility()`, `_baseline_inventory()`,
  `load_analyzer_only_approvals()`, and `load_source_audited_empty_categories()`
  from `lib/architecture_routing.py` — zero logic reimplementation.
- Enumerates components via `read_component_map()` and `apply_platform_overrides()`
  from `lib/component_discovery.py` — same path as generate-architecture phase.
- Filters to `sufficient` readiness before checking eligibility (same gate as
  production routing in `load_architecture_agent_policy()`).
- Reads `ANALYZER_ARCHITECTURE.md` (not `GENERATED_ARCHITECTURE.md`) from the
  checkout directory for `_baseline_inventory()` — this is the key constraint
  that prevents false positives.

## Verification

### Full run

```
uv run main.py check-eligibility --platform=rhoai.next
```

Results:
- 68 sufficient components checked
- 53 eligible (52 approved + 1 newly eligible)
- 15 ineligible (bounded correction gaps)
- 22 skipped (no analyzer data)

### False-positive check

All 8 false-positive components from the batch review report as ineligible:

| Component | Result |
|-----------|--------|
| MLServer | `eligible=False` — authentication |
| caikit | `eligible=False` — authentication |
| caikit-tgis-backend | `eligible=False` — authentication |
| llama-stack-provider-trustyai-garak | `eligible=False` — authentication |
| pipelines-components | `eligible=False` — authentication |
| rhoai-mcp | `eligible=False` — authentication |
| llm-d-kv-cache | `eligible=False` — authentication, internal_dependencies |
| llm-d-routing-sidecar | `eligible=False` — internal_dependencies |

### Approved component check

All 52 approved components show `eligible=True approved=True`. Zero regressions.

### Newly eligible

Only `rhods-operator` shows as newly eligible — this is the known
technically-eligible permanent residual (deliberate prose classification).

### Component filter

```
uv run main.py check-eligibility --platform=rhoai.next -- MLServer caikit kserve
```

Correctly filters to only the requested components.
